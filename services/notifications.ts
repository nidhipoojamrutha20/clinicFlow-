export interface NotificationService { sendAppointmentReminder(input:{patientName:string;date:string;time:string;phone:string}):Promise<{queued:boolean}>; sendFollowUpReminder(input:{patientName:string;dueDate:string;phone:string}):Promise<{queued:boolean}>; }
// TODO: Replace mock service with WhatsApp Business API provider.
export const notificationService:NotificationService={async sendAppointmentReminder(){return{queued:false}},async sendFollowUpReminder(){return{queued:false}}};
