-- Operational queue, communication preferences, reminders, waitlist, and locations.
alter table public.patients add column if not exists preferred_language text not null default 'English';
alter table public.patients add column if not exists preferred_channel text not null default 'SMS' check (preferred_channel in ('SMS','WhatsApp'));
alter table public.patients add column if not exists messaging_consent boolean not null default false;
alter table public.patients add column if not exists opted_out boolean not null default false;

create table if not exists public.clinic_locations (
  id uuid primary key default gen_random_uuid(), clinic_id uuid not null references public.clinics(id) on delete cascade,
  name text not null, address text not null default '', active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(id,clinic_id)
);
alter table public.appointments add column if not exists location_id uuid;
alter table public.appointments add column if not exists duration_minutes integer not null default 30 check(duration_minutes between 5 and 240);
alter table public.appointments add column if not exists kind text not null default 'appointment' check(kind in ('appointment','walk-in'));
alter table public.appointments add column if not exists queue_status text check(queue_status in ('waiting','called','in_consultation','completed','no_show'));
alter table public.appointments add column if not exists queue_token integer;
alter table public.appointments add column if not exists checked_in_at timestamptz;
alter table public.appointments add column if not exists rescheduled_from_status text;
alter table public.appointments drop constraint if exists appointments_id_clinic_unique;
alter table public.appointments add constraint appointments_id_clinic_unique unique(id,clinic_id);
alter table public.appointments drop constraint if exists appointments_location_clinic_fk;
alter table public.appointments add constraint appointments_location_clinic_fk foreign key(location_id,clinic_id) references public.clinic_locations(id,clinic_id);
create index if not exists appointments_clinic_queue_idx on public.appointments(clinic_id,appointment_date,queue_status,queue_token);

-- Serialize booking writes by doctor and date so adjacent times cannot overlap,
-- even when two clinic users submit at nearly the same time.
create or replace function public.reject_overlapping_appointment() returns trigger
language plpgsql security definer set search_path=public
as $$
declare new_end timestamp;
begin
  if new.doctor_id is null or new.status='Cancelled' then return new; end if;
  perform pg_advisory_xact_lock(hashtextextended(new.doctor_id::text || new.appointment_date::text,0));
  new_end := new.appointment_date + coalesce(new.end_time,new.appointment_time + make_interval(mins=>coalesce(new.duration_minutes,30)));
  if exists(
    select 1 from public.appointments a
    where a.doctor_id=new.doctor_id and a.appointment_date=new.appointment_date
      and a.id is distinct from new.id and a.status<>'Cancelled'
      and new.appointment_date + new.appointment_time < a.appointment_date + coalesce(a.end_time,a.appointment_time + make_interval(mins=>coalesce(a.duration_minutes,30)))
      and new_end > a.appointment_date + a.appointment_time
  ) then
    raise exception 'This doctor already has an appointment that overlaps this time.' using errcode='23P01';
  end if;
  return new;
end $$;
drop trigger if exists appointments_reject_overlap on public.appointments;
create trigger appointments_reject_overlap before insert or update of doctor_id,appointment_date,appointment_time,end_time,duration_minutes,status
on public.appointments for each row execute function public.reject_overlapping_appointment();

alter table public.follow_ups drop constraint if exists follow_ups_status_check;
update public.follow_ups set status='Due' where status='Pending';
alter table public.follow_ups add constraint follow_ups_status_check check(status in ('Due','Contacted','Booked','Declined','Unreachable','Deferred','Pending','Completed','Snoozed'));

create table if not exists public.cancellation_waitlist (
  id uuid primary key default gen_random_uuid(), clinic_id uuid not null references public.clinics(id) on delete cascade,
  patient_id uuid not null, doctor_id uuid not null, preferred_date date not null, preferred_time time,
  offered_appointment_id uuid, status text not null default 'Waiting' check(status in ('Waiting','Offered','Refilled','Declined')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  foreign key(patient_id,clinic_id) references public.patients(id,clinic_id) on delete cascade,
  foreign key(doctor_id,clinic_id) references public.doctor_profiles(id,clinic_id),
  foreign key(offered_appointment_id,clinic_id) references public.appointments(id,clinic_id)
);
create index if not exists cancellation_waitlist_clinic_status_idx on public.cancellation_waitlist(clinic_id,status,preferred_date);

create table if not exists public.communication_logs (
  id uuid primary key default gen_random_uuid(), clinic_id uuid not null references public.clinics(id) on delete cascade,
  patient_id uuid not null, channel text not null check(channel in ('SMS','WhatsApp')), language text not null,
  template_id text not null, preview text not null, result text not null check(result in ('Simulated','Blocked')),
  reason text, created_at timestamptz not null default now(),
  foreign key(patient_id,clinic_id) references public.patients(id,clinic_id) on delete cascade
);
create index if not exists communication_logs_clinic_created_idx on public.communication_logs(clinic_id,created_at desc);
create table if not exists public.reminder_templates (
  id text not null, clinic_id uuid not null references public.clinics(id) on delete cascade,
  name text not null, language text not null, body text not null check(char_length(body)<=500), active boolean not null default true,
  updated_at timestamptz not null default now(), primary key(id,clinic_id)
);

alter table public.clinic_locations enable row level security;
alter table public.cancellation_waitlist enable row level security;
alter table public.communication_logs enable row level security;
alter table public.reminder_templates enable row level security;
create policy "Clinic staff read locations" on public.clinic_locations for select to authenticated using(clinic_id=public.current_clinic_id());
create policy "Doctors manage clinic locations" on public.clinic_locations for all to authenticated using(clinic_id=public.current_clinic_id() and public.current_profile_role()='doctor') with check(clinic_id=public.current_clinic_id() and public.current_profile_role()='doctor');
create policy "Clinic staff manage waitlist" on public.cancellation_waitlist for all to authenticated using(clinic_id=public.current_clinic_id() and (public.current_profile_role()='receptionist' or doctor_id=public.current_doctor_id())) with check(clinic_id=public.current_clinic_id() and (public.current_profile_role()='receptionist' or doctor_id=public.current_doctor_id()));
create policy "Clinic staff manage communication logs" on public.communication_logs for all to authenticated using(clinic_id=public.current_clinic_id()) with check(clinic_id=public.current_clinic_id());
create policy "Clinic staff read reminder templates" on public.reminder_templates for select to authenticated using(clinic_id=public.current_clinic_id());
create policy "Clinic staff manage reminder templates" on public.reminder_templates for all to authenticated using(clinic_id=public.current_clinic_id()) with check(clinic_id=public.current_clinic_id());
