-- Extend clinic profiles to explicit doctor/receptionist roles.
alter table public.profiles add column if not exists active boolean not null default true;
alter table public.profiles drop constraint if exists profiles_role_check;
update public.profiles set role='receptionist' where role='staff';
update public.profiles set role='doctor' where role='owner';
alter table public.profiles add constraint profiles_role_check check (role in ('doctor','receptionist'));

create table public.doctor_profiles (
  id uuid primary key default gen_random_uuid(), profile_id uuid not null unique references public.profiles(id) on delete cascade,
  clinic_id uuid not null references public.clinics(id) on delete cascade, specialization text not null default '',
  appointment_duration_minutes integer not null default 30 check (appointment_duration_minutes between 5 and 240),
  active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(id,clinic_id)
);
create table public.doctor_availability (
  id uuid primary key default gen_random_uuid(), doctor_id uuid not null references public.doctor_profiles(id) on delete cascade,
  day_of_week smallint not null check(day_of_week between 0 and 6), start_time time not null, end_time time not null check(end_time > start_time),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(doctor_id,day_of_week)
);
create table public.doctor_time_off (
  id uuid primary key default gen_random_uuid(), doctor_id uuid not null references public.doctor_profiles(id) on delete cascade,
  unavailable_date date not null, reason text not null default '', created_at timestamptz not null default now(), unique(doctor_id,unavailable_date)
);
alter table public.appointments add column if not exists doctor_id uuid;
alter table public.appointments add column if not exists end_time time;
alter table public.appointments add column if not exists created_by uuid references auth.users(id) on delete set null;
alter table public.appointments add column if not exists rescheduled_from uuid references public.appointments(id) on delete set null;
alter table public.appointments add column if not exists rescheduled_at timestamptz;
alter table public.patients add constraint patients_id_clinic_unique unique(id,clinic_id);
alter table public.appointments drop constraint if exists appointments_patient_id_fkey;
alter table public.appointments add constraint appointments_patient_clinic_fk foreign key(patient_id,clinic_id) references public.patients(id,clinic_id) on delete cascade;
alter table public.appointments add constraint appointments_doctor_clinic_fk foreign key(doctor_id,clinic_id) references public.doctor_profiles(id,clinic_id);
alter table public.follow_ups drop constraint if exists follow_ups_patient_id_fkey;
alter table public.follow_ups add constraint follow_ups_patient_clinic_fk foreign key(patient_id,clinic_id) references public.patients(id,clinic_id) on delete cascade;
alter table public.profiles alter column role set default 'receptionist';
create index doctor_profiles_clinic_idx on public.doctor_profiles(clinic_id,active);
create index doctor_availability_doctor_day_idx on public.doctor_availability(doctor_id,day_of_week);
create index appointments_doctor_date_time_idx on public.appointments(doctor_id,appointment_date,appointment_time);
create unique index appointments_no_double_booking_idx on public.appointments(doctor_id,appointment_date,appointment_time)
  where doctor_id is not null and status in ('Scheduled','Confirmed');

create or replace function public.current_profile_role() returns text language sql stable security definer set search_path = public
as $$ select role from public.profiles where id = auth.uid() and active $$;
create or replace function public.current_doctor_id() returns uuid language sql stable security definer set search_path = public
as $$ select id from public.doctor_profiles where profile_id = auth.uid() and active $$;
create or replace function public.current_clinic_id() returns uuid language sql stable security definer set search_path = public
as $$ select clinic_id from public.profiles where id=auth.uid() and active $$;

alter table public.doctor_profiles enable row level security;
alter table public.doctor_availability enable row level security;
alter table public.doctor_time_off enable row level security;
drop policy if exists "Users can read own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
create policy "Clinic staff can read clinic profiles" on public.profiles for select to authenticated using (clinic_id = public.current_clinic_id());
create policy "Clinic staff read doctor profiles" on public.doctor_profiles for select to authenticated using (clinic_id=public.current_clinic_id());
create policy "Doctors update own doctor profile" on public.doctor_profiles for update to authenticated using (profile_id=auth.uid()) with check (profile_id=auth.uid() and clinic_id=public.current_clinic_id());
create policy "Clinic staff read doctor availability" on public.doctor_availability for select to authenticated using (exists(select 1 from public.doctor_profiles d where d.id=doctor_id and d.clinic_id=public.current_clinic_id()));
create policy "Doctors manage own availability" on public.doctor_availability for all to authenticated using (doctor_id=public.current_doctor_id()) with check (doctor_id=public.current_doctor_id());
create policy "Clinic staff read doctor time off" on public.doctor_time_off for select to authenticated using (exists(select 1 from public.doctor_profiles d where d.id=doctor_id and d.clinic_id=public.current_clinic_id()));
create policy "Doctors manage own time off" on public.doctor_time_off for all to authenticated using (doctor_id=public.current_doctor_id()) with check (doctor_id=public.current_doctor_id());
drop policy if exists "Clinic members can update their clinic" on public.clinics;
create policy "Doctors can update their clinic" on public.clinics for update to authenticated using (id=public.current_clinic_id() and public.current_profile_role()='doctor') with check (id=public.current_clinic_id() and public.current_profile_role()='doctor');

drop policy if exists "Clinic members manage patients" on public.patients;
create policy "Clinic staff read relevant patients" on public.patients for select to authenticated
 using (clinic_id=public.current_clinic_id() and (public.current_profile_role()='receptionist' or exists(select 1 from public.appointments a where a.patient_id=patients.id and a.doctor_id=public.current_doctor_id())));
create policy "Receptionists manage patient contacts" on public.patients for all to authenticated using (clinic_id=public.current_clinic_id() and public.current_profile_role()='receptionist') with check (clinic_id=public.current_clinic_id() and public.current_profile_role()='receptionist');
drop policy if exists "Clinic members manage appointments" on public.appointments;
create policy "Clinic staff read appointments" on public.appointments for select to authenticated using (clinic_id=public.current_clinic_id() and (public.current_profile_role()='receptionist' or doctor_id=public.current_doctor_id()));
create policy "Clinic staff create appointments" on public.appointments for insert to authenticated with check (clinic_id=public.current_clinic_id() and (public.current_profile_role()='receptionist' or doctor_id=public.current_doctor_id()));
create policy "Clinic staff update appointments" on public.appointments for update to authenticated using (clinic_id=public.current_clinic_id() and (public.current_profile_role()='receptionist' or doctor_id=public.current_doctor_id())) with check (clinic_id=public.current_clinic_id() and (public.current_profile_role()='receptionist' or doctor_id=public.current_doctor_id()));
drop policy if exists "Clinic members manage follow ups" on public.follow_ups;
create policy "Clinic staff read follow ups" on public.follow_ups for select to authenticated using (clinic_id=public.current_clinic_id() and (public.current_profile_role()='receptionist' or exists(select 1 from public.appointments a where a.patient_id=follow_ups.patient_id and a.doctor_id=public.current_doctor_id())));
create policy "Clinic staff manage follow ups" on public.follow_ups for all to authenticated using (clinic_id=public.current_clinic_id() and (public.current_profile_role()='receptionist' or exists(select 1 from public.appointments a where a.patient_id=follow_ups.patient_id and a.doctor_id=public.current_doctor_id()))) with check (clinic_id=public.current_clinic_id() and (public.current_profile_role()='receptionist' or exists(select 1 from public.appointments a where a.patient_id=follow_ups.patient_id and a.doctor_id=public.current_doctor_id())));
