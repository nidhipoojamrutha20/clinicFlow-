import type { CurrentUser, UserRole } from "@/types";
import { getData } from "@/lib/store";
export const DEMO_PASSWORD="clinicflow-demo";
export function demoAccountForRole(role:UserRole):CurrentUser|undefined{
 if(role==="doctor"){const doctor=getData().doctors.find(d=>d.active);return doctor?{id:doctor.profile_id,full_name:doctor.full_name,email:doctor.email,role,doctor_id:doctor.id}:undefined}
 const staff=getData().staff.find(s=>s.active);return staff?{id:staff.id,full_name:staff.full_name,email:staff.email,role}:undefined;
}
export function demoAccountForCredentials(email:string,password:string):CurrentUser|undefined{
 if(password!==DEMO_PASSWORD)return undefined;
 const normalized=email.trim().toLowerCase();
 const doctor=getData().doctors.find(d=>d.email.toLowerCase()===normalized&&d.active);
 if(doctor)return{id:doctor.profile_id,full_name:doctor.full_name,email:doctor.email,role:"doctor",doctor_id:doctor.id};
 const staff=getData().staff.find(s=>s.email.toLowerCase()===normalized&&s.active);
 return staff?{id:staff.id,full_name:staff.full_name,email:staff.email,role:"receptionist"}:undefined;
}
