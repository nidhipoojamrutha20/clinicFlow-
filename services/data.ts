import { createSupabaseBrowserClient } from "@/lib/supabase";
import type { ClinicData, Patient, Appointment, FollowUp, Doctor, StaffUser, CurrentUser, Availability, ClinicActivity, WaitlistEntry, CommunicationLog, ReminderTemplate, ClinicLocation } from "@/types";
export async function loadClinicDataFromSupabase():Promise<{data:ClinicData;clinicId:string}>{
 const client=createSupabaseBrowserClient();
 const {data:{user},error:userError}=await client.auth.getUser();
 if(userError||!user)throw new Error("You are not signed in to Supabase.");
 const {data:profile,error:profileError}=await client.from("profiles").select("id,clinic_id,full_name,email,role,active").eq("id",user.id).single();
 if(profileError||!profile)throw new Error("Your signed-in account has no clinic profile. Ask your clinic administrator to finish setup.");
 if(!profile.active||!["doctor","receptionist"].includes(profile.role))throw new Error("This clinic account is inactive or has an unsupported role.");
 const clinicId=String(profile.clinic_id);
 const [clinicResult,patientsResult,appointmentsResult,followUpsResult,doctorProfilesResult,staffResult,locationsResult,activityResult,waitlistResult,communicationResult,templatesResult]=await Promise.all([
  client.from("clinics").select("name,email,phone,default_appointment_duration").eq("id",clinicId).single(),
  client.from("patients").select("*").eq("clinic_id",clinicId).order("full_name"),
  client.from("appointments").select("*").eq("clinic_id",clinicId).order("appointment_date",{ascending:false}),
  client.from("follow_ups").select("*").eq("clinic_id",clinicId).order("due_date"),
  client.from("doctor_profiles").select("*").eq("clinic_id",clinicId),
  profile.role==="doctor"?Promise.resolve({data:[],error:null}):client.from("profiles").select("id,clinic_id,full_name,email,role,active").eq("clinic_id",clinicId).eq("role","receptionist"),
  client.from("clinic_locations").select("id,name,address,active").eq("clinic_id",clinicId),
  client.from("activity_logs").select("id,patient_id,user_id,action,entity_type,entity_id,created_at").eq("clinic_id",clinicId).order("created_at",{ascending:false}).limit(250),
  client.from("cancellation_waitlist").select("*").eq("clinic_id",clinicId).order("created_at",{ascending:false}),
  client.from("communication_logs").select("*").eq("clinic_id",clinicId).order("created_at",{ascending:false}).limit(100),
  client.from("reminder_templates").select("id,name,language,body,active").eq("clinic_id",clinicId)
 ]);
 for(const r of [clinicResult,patientsResult,appointmentsResult,followUpsResult,doctorProfilesResult,staffResult,locationsResult,activityResult,waitlistResult,communicationResult,templatesResult])if(r.error)throw r.error;
 if(!clinicResult.data)throw new Error("Clinic record not found.");
 const profileIds=(doctorProfilesResult.data??[]).map(d=>d.profile_id as string);const availabilityIds=(doctorProfilesResult.data??[]).map(d=>d.id as string);
 const [doctorUsers,availabilityResult,timeOffResult]=await Promise.all([
  profileIds.length?client.from("profiles").select("id,full_name,email,active").in("id",profileIds):Promise.resolve({data:[],error:null}),
  availabilityIds.length?client.from("doctor_availability").select("doctor_id,day_of_week,start_time,end_time").in("doctor_id",availabilityIds):Promise.resolve({data:[],error:null}),
  availabilityIds.length?client.from("doctor_time_off").select("doctor_id,unavailable_date").in("doctor_id",availabilityIds):Promise.resolve({data:[],error:null})
 ]);
 if(doctorUsers.error)throw doctorUsers.error;if(availabilityResult.error)throw availabilityResult.error;if(timeOffResult.error)throw timeOffResult.error;
 const doctors:Doctor[]=(doctorProfilesResult.data??[]).map(d=>{const user=doctorUsers.data?.find(p=>p.id===d.profile_id);const days=(availabilityResult.data??[]).filter(a=>a.doctor_id===d.id) as Availability[];return{id:String(d.id),profile_id:String(d.profile_id),full_name:String(user?.full_name??"Doctor"),email:String(user?.email??""),specialization:String(d.specialization),active:Boolean(d.active&&user?.active),working_days:days.map(a=>a.day_of_week),availability:days,start_time:days.map(a=>a.start_time).sort()[0]??"09:00",end_time:days.map(a=>a.end_time).sort().at(-1)??"17:00",appointment_duration_minutes:Number(d.appointment_duration_minutes),unavailable_dates:(timeOffResult.data??[]).filter(t=>t.doctor_id===d.id).map(t=>String(t.unavailable_date))}});
 const userDoctor=doctors.find(d=>d.profile_id===profile.id);const currentUser:CurrentUser={id:String(profile.id),full_name:String(profile.full_name),email:String(profile.email),role:profile.role as CurrentUser["role"],doctor_id:userDoctor?.id};
 const staff:StaffUser[]=(staffResult.data??[]).map(s=>({id:String(s.id),clinic_id:String(s.clinic_id),full_name:String(s.full_name),email:String(s.email),role:"receptionist",active:Boolean(s.active)}));
 const activity:ClinicActivity[]=(activityResult.data??[]).map(a=>({id:String(a.id),patient_id:a.patient_id?String(a.patient_id):undefined,appointment_id:a.entity_type==="appointment"&&a.entity_id?String(a.entity_id):undefined,follow_up_id:a.entity_type==="follow_up"&&a.entity_id?String(a.entity_id):undefined,actor:String(a.user_id===profile.id?profile.full_name:"Clinic staff"),action:String(a.action),detail:String(a.action),created_at:String(a.created_at)}));
 const waitlist:WaitlistEntry[]=(waitlistResult.data??[]).map(w=>({id:String(w.id),patient_id:String(w.patient_id),doctor_id:String(w.doctor_id),preferred_date:String(w.preferred_date),preferred_time:w.preferred_time?String(w.preferred_time).slice(0,5):undefined,offered_appointment_id:w.offered_appointment_id?String(w.offered_appointment_id):undefined,status:w.status as WaitlistEntry["status"],created_at:String(w.created_at),updated_at:String(w.updated_at)}));
 const communicationLog:CommunicationLog[]=(communicationResult.data??[]).map(m=>({id:String(m.id),patient_id:String(m.patient_id),channel:m.channel as CommunicationLog["channel"],language:String(m.language),template_id:String(m.template_id),preview:String(m.preview),result:m.result as CommunicationLog["result"],reason:m.reason?String(m.reason):undefined,created_at:String(m.created_at)}));
 const locations:ClinicLocation[]=(locationsResult.data??[]).map(l=>({id:String(l.id),name:String(l.name),address:String(l.address),active:Boolean(l.active)}));
 const reminderTemplates:ReminderTemplate[]=(templatesResult.data??[]).map(t=>({id:String(t.id),name:String(t.name),language:String(t.language),body:String(t.body),active:Boolean(t.active)}));
 return {clinicId,data:{clinic:{name:clinicResult.data.name,email:clinicResult.data.email,phone:clinicResult.data.phone,duration:clinicResult.data.default_appointment_duration},patients:patientsResult.data as Patient[],appointments:appointmentsResult.data as Appointment[],followUps:followUpsResult.data as FollowUp[],doctors,staff,currentUser,activity,waitlist,communicationLog,locations,reminderTemplates}};
}
export async function persistClinicDataToSupabase(data:ClinicData,clinicId:string){
 const client=createSupabaseBrowserClient();const myDoctor=data.doctors.find(d=>d.id===data.currentUser?.doctor_id);const isReceptionist=data.currentUser?.role==="receptionist";const isDoctor=data.currentUser?.role==="doctor";
 const ownAppointments=isDoctor?data.appointments.filter(a=>a.doctor_id===myDoctor?.id):data.appointments;
 const ownFollowUps=isDoctor?data.followUps.filter(f=>data.appointments.some(a=>a.doctor_id===myDoctor?.id&&a.patient_id===f.patient_id)):data.followUps;
 const ownWaitlist=isDoctor?data.waitlist?.filter(w=>w.doctor_id===myDoctor?.id)??[]:data.waitlist??[];
 const [clinic,patients,appointments,followUps,doctorProfile,availability,timeOff,locations,waitlist,communications,templates,activity]=await Promise.all([
  isDoctor?client.from("clinics").update({name:data.clinic.name,email:data.clinic.email,phone:data.clinic.phone,default_appointment_duration:data.clinic.duration}).eq("id",clinicId):Promise.resolve({error:null}),
  isReceptionist&&data.patients.length?client.from("patients").upsert(data.patients.map(p=>({...p,clinic_id:clinicId})),{onConflict:"id"}):Promise.resolve({error:null}),
  ownAppointments.length?client.from("appointments").upsert(ownAppointments.map(a=>({...a,clinic_id:clinicId,doctor_id:a.doctor_id??null})),{onConflict:"id"}):Promise.resolve({error:null}),
  ownFollowUps.length?client.from("follow_ups").upsert(ownFollowUps.map(f=>({...f,clinic_id:clinicId,status:f.status==="Due"?"Due":f.status})),{onConflict:"id"}):Promise.resolve({error:null}),
  myDoctor?client.from("doctor_profiles").update({specialization:myDoctor.specialization,appointment_duration_minutes:myDoctor.appointment_duration_minutes,active:myDoctor.active}).eq("id",myDoctor.id):Promise.resolve({error:null}),
  myDoctor?client.from("doctor_availability").delete().eq("doctor_id",myDoctor.id):Promise.resolve({error:null}),
  myDoctor?client.from("doctor_time_off").delete().eq("doctor_id",myDoctor.id):Promise.resolve({error:null}),
  isDoctor&&data.locations?.length?client.from("clinic_locations").upsert(data.locations.map(l=>({...l,clinic_id:clinicId})),{onConflict:"id"}):Promise.resolve({error:null}),
  ownWaitlist.length?client.from("cancellation_waitlist").upsert(ownWaitlist.map(w=>({...w,clinic_id:clinicId})),{onConflict:"id"}):Promise.resolve({error:null}),
  data.communicationLog?.length?client.from("communication_logs").upsert(data.communicationLog.map(m=>({...m,clinic_id:clinicId})),{onConflict:"id"}):Promise.resolve({error:null}),
  data.currentUser&&data.reminderTemplates?.length?client.from("reminder_templates").upsert(data.reminderTemplates.map(t=>({...t,clinic_id:clinicId})),{onConflict:"id,clinic_id"}):Promise.resolve({error:null}),
  data.activity?.length?client.from("activity_logs").upsert(data.activity.map(a=>({id:a.id,clinic_id:clinicId,patient_id:a.patient_id??null,user_id:data.currentUser?.id??null,action:`${a.action}: ${a.detail}`,entity_type:a.appointment_id?"appointment":a.follow_up_id?"follow_up":"patient",entity_id:a.appointment_id??a.follow_up_id??a.patient_id??null,created_at:a.created_at})),{onConflict:"id",ignoreDuplicates:true}):Promise.resolve({error:null})
 ]);
 const availabilityInsert=myDoctor?.availability?.length?await client.from("doctor_availability").insert(myDoctor.availability.map(a=>({doctor_id:myDoctor.id,day_of_week:a.day_of_week,start_time:a.start_time,end_time:a.end_time}))):{error:null};
 const timeOffInsert=myDoctor?.unavailable_dates.length?await client.from("doctor_time_off").insert(myDoctor.unavailable_dates.map(unavailable_date=>({doctor_id:myDoctor.id,unavailable_date}))):{error:null};
 const error=clinic.error??patients.error??appointments.error??followUps.error??doctorProfile.error??availability.error??timeOff.error??locations.error??waitlist.error??communications.error??templates.error??activity.error??availabilityInsert.error??timeOffInsert.error;if(error)throw error;
}
