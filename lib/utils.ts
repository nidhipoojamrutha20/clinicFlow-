import { differenceInYears, format, parseISO } from "date-fns";
import type { Patient } from "@/types";
export const todayISO=()=>new Date().toISOString().slice(0,10);
export const prettyDate=(s:string,pattern="MMM d, yyyy")=>{try{return format(parseISO(s),pattern)}catch{return s}};
export const ageOf=(p:Patient)=>p.date_of_birth?differenceInYears(new Date(),parseISO(p.date_of_birth)):"—";
export const initials=(name:string)=>name.split(" ").map(v=>v[0]).slice(0,2).join("").toUpperCase();
export const patientName=(patients:Patient[],id:string)=>patients.find(p=>p.id===id)?.full_name??"Unknown patient";
