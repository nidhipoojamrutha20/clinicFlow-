export type AppointmentStatus = "Scheduled" | "Confirmed" | "Completed" | "Cancelled" | "Missed";
export type FollowUpStatus = "Due" | "Contacted" | "Booked" | "Declined" | "Unreachable" | "Deferred" | "Pending" | "Completed" | "Snoozed";
export type Priority = "Low" | "Medium" | "High";
export type UserRole = "doctor" | "receptionist";
export type QueueStatus = "waiting" | "called" | "in_consultation" | "completed" | "no_show";
export type ContactChannel = "SMS" | "WhatsApp";
export interface Availability { day_of_week:number; start_time:string; end_time:string; }
export interface Doctor { id:string; profile_id:string; full_name:string; email:string; specialization:string; active:boolean; working_days:number[]; start_time:string; end_time:string; availability?:Availability[]; appointment_duration_minutes:number; unavailable_dates:string[]; }
export interface StaffUser { id:string; full_name:string; email:string; role:UserRole; active:boolean; clinic_id:string; }
export interface CurrentUser { id:string; full_name:string; email:string; role:UserRole; doctor_id?:string; }
export interface Patient { id:string; full_name:string; phone:string; email:string; date_of_birth:string; gender?:string; admin_notes:string; preferred_language?:string; preferred_channel?:ContactChannel; messaging_consent?:boolean; opted_out?:boolean; created_at:string; updated_at:string; }
export interface Appointment { id:string; patient_id:string; doctor_id?:string; location_id?:string; appointment_date:string; appointment_time:string; end_time?:string; duration_minutes?:number; visit_type:string; status:AppointmentStatus; notes:string; kind?:"appointment"|"walk-in"; queue_status?:QueueStatus; queue_token?:number; checked_in_at?:string; created_by?:string; rescheduled_from?:string; rescheduled_at?:string; rescheduled_from_status?:AppointmentStatus; created_at:string; updated_at:string; }
export interface FollowUp { id:string; patient_id:string; appointment_id?:string; reason:string; due_date:string; priority:Priority; status:FollowUpStatus; assigned_to:string; notes:string; last_contacted_at?:string; created_at:string; updated_at:string; }
export interface Clinic { name:string; email:string; phone:string; duration:number; }
export interface ClinicActivity { id:string; patient_id?:string; appointment_id?:string; follow_up_id?:string; actor:string; action:string; detail:string; created_at:string; }
export interface WaitlistEntry { id:string; patient_id:string; doctor_id:string; preferred_date:string; preferred_time?:string; offered_appointment_id?:string; status:"Waiting"|"Offered"|"Refilled"|"Declined"; created_at:string; updated_at:string; }
export interface CommunicationLog { id:string; patient_id:string; channel:ContactChannel; language:string; template_id:string; preview:string; result:"Simulated"|"Blocked"; reason?:string; created_at:string; }
export interface ReminderTemplate { id:string; name:string; language:string; body:string; active:boolean; }
export interface ClinicLocation { id:string; name:string; address:string; active:boolean; }
export interface ClinicData { patients:Patient[]; appointments:Appointment[]; followUps:FollowUp[]; clinic:Clinic; doctors:Doctor[]; staff:StaffUser[]; currentUser?:CurrentUser; activity?:ClinicActivity[]; waitlist?:WaitlistEntry[]; communicationLog?:CommunicationLog[]; reminderTemplates?:ReminderTemplate[]; locations?:ClinicLocation[]; }
