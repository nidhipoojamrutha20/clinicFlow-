import type { Appointment, Doctor } from "@/types";
const minutes=(time:string)=>{const [h,m]=time.split(":").map(Number);return h*60+m};
const time=(value:number)=>`${String(Math.floor(value/60)).padStart(2,"0")}:${String(value%60).padStart(2,"0")}`;
export function availableSlots(doctor:Doctor|undefined,date:string,appointments:Appointment[],excludeId?:string,durationOverride?:number):string[]{
 if(!doctor||!date||!doctor.active||doctor.unavailable_dates.includes(date))return[];
 const weekday=new Date(`${date}T12:00:00`).getDay();if(!doctor.working_days.includes(weekday))return[];
 const duration=durationOverride??doctor.appointment_duration_minutes;const dayHours=doctor.availability?.find(a=>a.day_of_week===weekday);const open=minutes(dayHours?.start_time??doctor.start_time);const close=minutes(dayHours?.end_time??doctor.end_time);
 const occupied=appointments.filter(a=>a.id!==excludeId&&a.doctor_id===doctor.id&&a.appointment_date===date&&a.status!=="Cancelled").map(a=>({start:minutes(a.appointment_time),end:a.end_time?minutes(a.end_time):minutes(a.appointment_time)+duration}));
 const now=new Date();const localToday=`${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,"0")}-${String(now.getDate()).padStart(2,"0")}`;const currentMinutes=now.getHours()*60+now.getMinutes();
 const result:string[]=[];for(let start=open;start+duration<=close;start+=duration){const end=start+duration;if(date===localToday&&start<=currentMinutes)continue;if(!occupied.some(slot=>start<slot.end&&end>slot.start))result.push(time(start))}return result;
}
export function endTime(start:string,duration:number){return time(minutes(start)+duration)}
export function isDoctorAvailable(doctor:Doctor|undefined,date:string,start:string,appointments:Appointment[],excludeId?:string){return availableSlots(doctor,date,appointments,excludeId).includes(start)}
