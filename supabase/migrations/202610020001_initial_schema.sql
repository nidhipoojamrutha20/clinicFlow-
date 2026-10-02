create extension if not exists pgcrypto;

create table public.clinics (
  id uuid primary key default gen_random_uuid(), name text not null, email text not null default '',
  phone text not null default '', default_appointment_duration integer not null default 30 check (default_appointment_duration between 5 and 240),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade, clinic_id uuid not null references public.clinics(id) on delete cascade,
  full_name text not null, email text not null, role text not null default 'staff' check (role in ('staff','owner')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.patients (
  id uuid primary key default gen_random_uuid(), clinic_id uuid not null references public.clinics(id) on delete cascade,
  full_name text not null check (char_length(full_name) between 2 and 160), phone text not null check (char_length(phone) between 7 and 30),
  email text not null default '', date_of_birth date, gender text, admin_notes text not null default '' check (char_length(admin_notes) <= 500),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.appointments (
  id uuid primary key default gen_random_uuid(), clinic_id uuid not null references public.clinics(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade, appointment_date date not null, appointment_time time not null,
  visit_type text not null, status text not null default 'Scheduled' check (status in ('Scheduled','Confirmed','Completed','Cancelled','Missed')),
  notes text not null default '' check (char_length(notes) <= 500), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.follow_ups (
  id uuid primary key default gen_random_uuid(), clinic_id uuid not null references public.clinics(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade, appointment_id uuid references public.appointments(id) on delete set null,
  reason text not null, due_date date not null, priority text not null default 'Medium' check (priority in ('Low','Medium','High')),
  status text not null default 'Pending' check (status in ('Pending','Contacted','Completed','Snoozed')),
  assigned_to text not null default '', notes text not null default '' check (char_length(notes) <= 500), last_contacted_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.activity_logs (
  id uuid primary key default gen_random_uuid(), clinic_id uuid not null references public.clinics(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete set null, user_id uuid references auth.users(id) on delete set null,
  action text not null, entity_type text not null, entity_id uuid, created_at timestamptz not null default now()
);
create index patients_clinic_name_idx on public.patients(clinic_id, full_name);
create index patients_clinic_phone_idx on public.patients(clinic_id, phone);
create index appointments_clinic_date_idx on public.appointments(clinic_id, appointment_date, appointment_time);
create index appointments_patient_date_idx on public.appointments(patient_id, appointment_date desc);
create index follow_ups_clinic_due_idx on public.follow_ups(clinic_id, due_date, status);
create index follow_ups_patient_idx on public.follow_ups(patient_id, status);
create index activity_logs_clinic_created_idx on public.activity_logs(clinic_id, created_at desc);

create or replace function public.set_updated_at() returns trigger language plpgsql set search_path = public
as $$ begin new.updated_at = now(); return new; end $$;
create trigger clinics_set_updated_at before update on public.clinics for each row execute function public.set_updated_at();
create trigger profiles_set_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger patients_set_updated_at before update on public.patients for each row execute function public.set_updated_at();
create trigger appointments_set_updated_at before update on public.appointments for each row execute function public.set_updated_at();
create trigger follow_ups_set_updated_at before update on public.follow_ups for each row execute function public.set_updated_at();

create or replace function public.current_clinic_id() returns uuid language sql stable security definer set search_path = public
as $$ select clinic_id from public.profiles where id = auth.uid() $$;
alter table public.clinics enable row level security;
alter table public.profiles enable row level security;
alter table public.patients enable row level security;
alter table public.appointments enable row level security;
alter table public.follow_ups enable row level security;
alter table public.activity_logs enable row level security;
create policy "Clinic members can read their clinic" on public.clinics for select to authenticated using (id = public.current_clinic_id());
create policy "Clinic members can update their clinic" on public.clinics for update to authenticated using (id = public.current_clinic_id()) with check (id = public.current_clinic_id());
create policy "Users can read own profile" on public.profiles for select to authenticated using (id = auth.uid());
create policy "Clinic members manage patients" on public.patients for all to authenticated using (clinic_id = public.current_clinic_id()) with check (clinic_id = public.current_clinic_id());
create policy "Clinic members manage appointments" on public.appointments for all to authenticated using (clinic_id = public.current_clinic_id()) with check (clinic_id = public.current_clinic_id());
create policy "Clinic members manage follow ups" on public.follow_ups for all to authenticated using (clinic_id = public.current_clinic_id()) with check (clinic_id = public.current_clinic_id());
create policy "Clinic members read activity" on public.activity_logs for select to authenticated using (clinic_id = public.current_clinic_id());
create policy "Clinic members create activity" on public.activity_logs for insert to authenticated with check (clinic_id = public.current_clinic_id());
