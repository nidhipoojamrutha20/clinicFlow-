# ClinicFlow

ClinicFlow is a small-clinic workflow MVP for appointments, patient contact coordination, doctor schedules and routine follow-ups. Its records are synthetic and its notes are for administrative coordination only.

> **Demonstration only.** This app does not provide diagnosis, prescriptions, treatment or clinical decision support. Use synthetic records for evaluation. Production use with real health information requires dedicated security, privacy, legal and regulatory review.

## Included workflows

- Role-based doctor and receptionist workspaces with separate navigation and dashboards
- Doctor profiles, clinic schedules, working hours, appointment duration and leave dates
- Appointment booking with availability-aware time slots and duplicate-slot checks
- Rescheduling that creates a linked replacement appointment and preserves the original record
- Patient contact details, consent preferences, contact history, and operational audit timeline
- Check-in queue for booked patients and walk-ins, with queue tokens and approximate waiting bands
- Missed-visit recovery, manual cancellation waitlist, follow-up outcomes, and reminder preview
- Clickable dashboard counts with filtered lists, operational measures, and chronological schedules
- Clinic setup for doctors, hours, locations, CSV patient import, and patient/appointment/backup export
- Browser-local demo mode and Supabase Auth/data adapters with clinic-scoped RLS
- Team management simulated in demo mode; secure Auth account provisioning requires a trusted backend

Payments, billing, insurance, prescriptions, diagnoses and other clinical functions are outside this MVP. Calls use `tel:` links. Reminder delivery is simulated only; consent and opt-out checks are enforced and no SMS, WhatsApp or email is sent.

## Run locally

Use a current Node.js LTS release and npm. From the project directory:

```bash
npm install
cp .env.example .env.local
npm run dev
```

Open [http://localhost:3000](http://localhost:3000). With `NEXT_PUBLIC_DEMO_MODE=true`, the login page offers role-specific demo entry. You can also sign in with:

| Role | Email | Password |
| --- | --- | --- |
| Doctor (Dr. Ananya Rao) | `doctor@clinicflow.demo` | `clinicflow-demo` |
| Doctor (Dr. Meera Shah) | `meera@clinicflow.demo` | `clinicflow-demo` |
| Doctor (Dr. Kavya Nair) | `kavya@clinicflow.demo` | `clinicflow-demo` |
| Receptionist (Riya Sharma) | `reception@clinicflow.demo` | `clinicflow-demo` |

Demo records persist in browser local storage under `clinicflow-demo-v1`. Clear that key in browser developer tools to reset the local demo.

## Supabase setup

1. Set the project URL and anon/publishable key in `.env.local`, and set `NEXT_PUBLIC_DEMO_MODE=false`:

   ```dotenv
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
   NEXT_PUBLIC_DEMO_MODE=false
   ```

2. Run all migrations in order: `202610020001_initial_schema.sql`, `202610020002_doctors_roles_availability.sql`, then `202610020003_queue_communications_locations.sql` from `supabase/migrations/`.
3. Run `supabase/seed.sql` once to create the synthetic clinic and two sample locations.
4. Create Auth users for doctors and receptionists, then insert each `profiles` row with its Auth UUID, clinic UUID, full name, email and role (`doctor` or `receptionist`).
5. For each doctor, add a `doctor_profiles` row tied to the same clinic and profile, then add `doctor_availability` rows for working weekdays. Re-run the seed to attach synthetic appointments to provisioned doctors and add the reminder templates.
6. Restart the app and sign in through `/login`. RLS scopes data to the active user's clinic and role. Doctors see their assigned appointments and related patients; receptionists manage clinic scheduling and patient contacts. Appointment writes are checked for overlapping doctor times in the database.

Creating Supabase Auth users requires a trusted server-side Edge Function or API that validates the doctor/admin session and keeps the service-role key in server secrets. This repository deliberately does not create Auth users from browser code. The demo Team page simulates receptionist accounts in local storage with the shared demo password; no invitation is sent.

Never put a service-role key in a `NEXT_PUBLIC_*` variable or client code. Review the RLS policies with separate clinic accounts before deployment. The included schema provides row isolation and role-scoped access, but this demonstration has not received a production security or privacy audit.

## Project structure

```text
app/                  Public landing, login and role workspaces
components/           Shared shell, forms, dashboards and UI
lib/                  Demo data/store, scheduling, validation and Supabase client
services/              Supabase data adapter and notification placeholder
supabase/migrations/  Schema, availability and RLS
supabase/seed.sql      Synthetic example records
types/                 Shared domain types
```

## Demo-only behavior

Account recovery displays local guidance and sends no email. A session signs out after 20 minutes without interaction. CSV import previews rows and skips those with missing required fields or duplicate phone numbers. Exports are generated in the browser. Demo queue, waitlist, communication, and audit data persist in local storage. Supabase reminders are recorded as simulations and never delivered to patients.

## Quality checks

```bash
npm run lint
npm run build
```

Before production use, implement trusted Auth provisioning and password recovery, validate RLS and database migrations independently, and complete security, privacy, accessibility and regulatory review. Real notification delivery remains intentionally postponed.
