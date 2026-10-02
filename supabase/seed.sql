-- Synthetic-only seed. Replace auth user email below with an existing Supabase Auth user.
-- Run after creating that user in Authentication > Users.
do $$
declare clinic_key uuid := '10000000-0000-4000-8000-000000000001';
begin
  insert into public.clinics(id,name,email,phone) values(clinic_key,'Willow Creek Clinic','hello@willowcreek.demo','+91 22 4890 2100') on conflict(id) do nothing;
  insert into public.clinic_locations(id,clinic_id,name,address) values
    ('50000000-0000-4000-8000-000000000001',clinic_key,'Main Clinic','12 Lake Road'),
    ('50000000-0000-4000-8000-000000000002',clinic_key,'North Clinic','4 Market Street')
  on conflict(id) do nothing;
  insert into public.reminder_templates(id,clinic_id,name,language,body,active) values
    ('reminder-en',clinic_key,'Appointment reminder','English','Hello {{name}}, this is a reminder of your appointment at {{clinic}} on {{date}} at {{time}}. Reply to the clinic if you need to make a change.',true),
    ('reminder-hi',clinic_key,'Appointment reminder','Hindi','नमस्ते {{name}}, {{date}} को {{time}} बजे {{clinic}} में आपकी अपॉइंटमेंट है। बदलाव के लिए क्लिनिक से संपर्क करें।',true)
  on conflict(id,clinic_id) do nothing;
  -- Add a profile manually after substituting a real auth.users UUID and email.
  -- Example: insert into public.profiles(id,clinic_id,full_name,email) values('<auth-user-uuid>',clinic_key,'Demo Staff','staff@example.com');
  insert into public.patients(id,clinic_id,full_name,phone,email,date_of_birth,gender,admin_notes) values
  ('20000000-0000-4000-8000-000000000001',clinic_key,'Aarav Mehta','+91 98765 41021','aarav.mehta@example.com','1991-04-12','Male','Prefers morning appointments.'),
  ('20000000-0000-4000-8000-000000000002',clinic_key,'Priya Nair','+91 98210 73654','priya.nair@example.com','1985-11-03','Female',''),
  ('20000000-0000-4000-8000-000000000003',clinic_key,'Kabir Shah','+91 99870 12468','kabir.shah@example.com','1978-06-21','Male',''),
  ('20000000-0000-4000-8000-000000000004',clinic_key,'Ananya Iyer','+91 98190 56231','ananya.iyer@example.com','1998-02-14','Female',''),
  ('20000000-0000-4000-8000-000000000005',clinic_key,'Rohan Desai','+91 97690 38142','rohan.desai@example.com','1969-09-08','Male',''),
  ('20000000-0000-4000-8000-000000000006',clinic_key,'Meera Joshi','+91 98920 64713','meera.joshi@example.com','2001-12-19','Female',''),
  ('20000000-0000-4000-8000-000000000007',clinic_key,'Ishaan Kapoor','+91 98203 51980','ishaan.kapoor@example.com','1989-01-26','Male',''),
  ('20000000-0000-4000-8000-000000000008',clinic_key,'Diya Menon','+91 98197 24860','diya.menon@example.com','1994-07-17','Female',''),
  ('20000000-0000-4000-8000-000000000009',clinic_key,'Arjun Rao','+91 98702 83514','arjun.rao@example.com','1973-05-30','Male',''),
  ('20000000-0000-4000-8000-000000000010',clinic_key,'Sara Khan','+91 99204 17326','sara.khan@example.com','1996-10-02','Female',''),
  ('20000000-0000-4000-8000-000000000011',clinic_key,'Neel Kulkarni','+91 98195 34062','neel.kulkarni@example.com','1982-03-23','Male',''),
  ('20000000-0000-4000-8000-000000000012',clinic_key,'Tara Fernandes','+91 98330 72146','tara.fernandes@example.com','1990-08-09','Female',''),
  ('20000000-0000-4000-8000-000000000013',clinic_key,'Vivaan Patel','+91 98218 90635','vivaan.patel@example.com','2003-12-01','Male',''),
  ('20000000-0000-4000-8000-000000000014',clinic_key,'Aditi Sinha','+91 98704 51827','aditi.sinha@example.com','1977-01-16','Female',''),
  ('20000000-0000-4000-8000-000000000015',clinic_key,'Dev Malhotra','+91 98193 46270','dev.malhotra@example.com','1987-06-04','Male',''),
  ('20000000-0000-4000-8000-000000000016',clinic_key,'Nisha Pillai','+91 98201 87453','nisha.pillai@example.com','1999-09-27','Female',''),
  ('20000000-0000-4000-8000-000000000017',clinic_key,'Om Prakash','+91 98670 29318','om.prakash@example.com','1965-11-11','Male',''),
  ('20000000-0000-4000-8000-000000000018',clinic_key,'Leela Thomas','+91 98922 60547','leela.thomas@example.com','1993-03-06','Female','')
  on conflict(id) do nothing;
  insert into public.appointments(id,clinic_id,patient_id,appointment_date,appointment_time,visit_type,status) values
  ('30000000-0000-4000-8000-000000000001',clinic_key,'20000000-0000-4000-8000-000000000001',current_date,'09:00','General consultation','Confirmed'),
  ('30000000-0000-4000-8000-000000000002',clinic_key,'20000000-0000-4000-8000-000000000002',current_date,'09:30','Routine visit','Scheduled'),
  ('30000000-0000-4000-8000-000000000003',clinic_key,'20000000-0000-4000-8000-000000000003',current_date,'10:00','Review visit','Completed'),
  ('30000000-0000-4000-8000-000000000004',clinic_key,'20000000-0000-4000-8000-000000000004',current_date,'10:30','Wellness visit','Confirmed'),
  ('30000000-0000-4000-8000-000000000005',clinic_key,'20000000-0000-4000-8000-000000000005',current_date,'11:00','Routine visit','Missed'),
  ('30000000-0000-4000-8000-000000000006',clinic_key,'20000000-0000-4000-8000-000000000006',current_date,'11:30','New patient visit','Scheduled'),
  ('30000000-0000-4000-8000-000000000007',clinic_key,'20000000-0000-4000-8000-000000000007',current_date,'14:00','Routine visit','Completed'),
  ('30000000-0000-4000-8000-000000000008',clinic_key,'20000000-0000-4000-8000-000000000008',current_date,'15:00','Review visit','Scheduled'),
  ('30000000-0000-4000-8000-000000000009',clinic_key,'20000000-0000-4000-8000-000000000009',current_date-1,'09:00','General consultation','Missed'),
  ('30000000-0000-4000-8000-000000000010',clinic_key,'20000000-0000-4000-8000-000000000010',current_date-2,'09:30','Routine visit','Completed'),
  ('30000000-0000-4000-8000-000000000011',clinic_key,'20000000-0000-4000-8000-000000000011',current_date+1,'10:00','Review visit','Confirmed'),
  ('30000000-0000-4000-8000-000000000012',clinic_key,'20000000-0000-4000-8000-000000000012',current_date+2,'10:30','Wellness visit','Scheduled'),
  ('30000000-0000-4000-8000-000000000013',clinic_key,'20000000-0000-4000-8000-000000000013',current_date-3,'11:00','Routine visit','Missed'),
  ('30000000-0000-4000-8000-000000000014',clinic_key,'20000000-0000-4000-8000-000000000014',current_date-4,'11:30','New patient visit','Completed'),
  ('30000000-0000-4000-8000-000000000015',clinic_key,'20000000-0000-4000-8000-000000000015',current_date+4,'14:00','General consultation','Scheduled')
  on conflict(id) do nothing;
  insert into public.follow_ups(id,clinic_id,patient_id,appointment_id,reason,due_date,priority,status,assigned_to,last_contacted_at) values
  ('40000000-0000-4000-8000-000000000001',clinic_key,'20000000-0000-4000-8000-000000000001',null,'Routine check-in',current_date,'High','Pending','Nidhi Sharma',null),
  ('40000000-0000-4000-8000-000000000002',clinic_key,'20000000-0000-4000-8000-000000000002',null,'Post-visit follow-up',current_date-2,'Medium','Pending','Nidhi Sharma',null),
  ('40000000-0000-4000-8000-000000000003',clinic_key,'20000000-0000-4000-8000-000000000003',null,'Appointment rescheduling',current_date+1,'Medium','Pending','Nidhi Sharma',null),
  ('40000000-0000-4000-8000-000000000004',clinic_key,'20000000-0000-4000-8000-000000000004',null,'Wellness visit reminder',current_date+3,'Low','Pending','Nidhi Sharma',null),
  ('40000000-0000-4000-8000-000000000005',clinic_key,'20000000-0000-4000-8000-000000000005',null,'Patient requested callback',current_date-1,'High','Contacted','Nidhi Sharma',now()),
  ('40000000-0000-4000-8000-000000000006',clinic_key,'20000000-0000-4000-8000-000000000006',null,'Review visit coordination',current_date,'Medium','Pending','Nidhi Sharma',null),
  ('40000000-0000-4000-8000-000000000007',clinic_key,'20000000-0000-4000-8000-000000000007',null,'Missed appointment outreach',current_date+5,'High','Pending','Nidhi Sharma',null),
  ('40000000-0000-4000-8000-000000000008',clinic_key,'20000000-0000-4000-8000-000000000008',null,'Confirm next visit',current_date+2,'Low','Pending','Nidhi Sharma',null),
  ('40000000-0000-4000-8000-000000000009',clinic_key,'20000000-0000-4000-8000-000000000009',null,'Follow-up call',current_date-4,'High','Pending','Nidhi Sharma',null),
  ('40000000-0000-4000-8000-000000000010',clinic_key,'20000000-0000-4000-8000-000000000010',null,'Appointment confirmation',current_date+7,'Medium','Pending','Nidhi Sharma',null),
  ('40000000-0000-4000-8000-000000000011',clinic_key,'20000000-0000-4000-8000-000000000011',null,'Routine follow-up',current_date,'Medium','Completed','Nidhi Sharma',now())
  on conflict(id) do nothing;

  -- Doctor profiles are created only for doctor Auth users that have already
  -- been linked to this clinic through public.profiles.
  insert into public.doctor_profiles(profile_id,clinic_id,specialization,appointment_duration_minutes)
  select p.id,clinic_key,
    case lower(p.email)
      when 'doctor@clinicflow.demo' then 'Dermatology'
      when 'meera@clinicflow.demo' then 'General Medicine'
      when 'kavya@clinicflow.demo' then 'Pediatrics'
      else 'General practice'
    end,30
  from public.profiles p
  where p.clinic_id=clinic_key and p.role='doctor'
  on conflict(profile_id) do nothing;

  insert into public.doctor_availability(doctor_id,day_of_week,start_time,end_time)
  select d.id,weekday,
    case lower(p.email) when 'meera@clinicflow.demo' then '10:00'::time else '09:00'::time end,
    case lower(p.email) when 'doctor@clinicflow.demo' then '14:00'::time when 'meera@clinicflow.demo' then '18:00'::time else '16:00'::time end
  from public.doctor_profiles d join public.profiles p on p.id=d.profile_id,
       lateral generate_series(0,6) as weekdays(weekday)
  where d.clinic_id=clinic_key and p.role='doctor'
    and case lower(p.email)
      when 'doctor@clinicflow.demo' then weekday between 1 and 5
      when 'meera@clinicflow.demo' then weekday between 1 and 6
      when 'kavya@clinicflow.demo' then weekday between 2 and 6
      else weekday between 1 and 5
    end
  on conflict(doctor_id,day_of_week) do nothing;

  with doctor_list as (
    select d.id,row_number() over(order by p.email) as number,
           count(*) over() as total
    from public.doctor_profiles d join public.profiles p on p.id=d.profile_id
    where d.clinic_id=clinic_key and d.active and p.active
  ), assignments as (
    select a.id,
      (select d.id from doctor_list d
       where d.number=((right(a.id::text,12)::bigint-1) % nullif((select max(total) from doctor_list),0))+1) as doctor_id
    from public.appointments a where a.clinic_id=clinic_key and a.doctor_id is null
  )
  update public.appointments a
  set doctor_id=assignments.doctor_id,
      end_time=a.appointment_time + interval '30 minutes',
      location_id='50000000-0000-4000-8000-000000000001'
  from assignments where a.id=assignments.id and assignments.doctor_id is not null;
end $$;
