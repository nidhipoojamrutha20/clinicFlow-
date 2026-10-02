import type { Metadata } from "next";
import "./globals.css";
export const metadata:Metadata={title:"ClinicFlow | Clinic Workflow",description:"Keep appointments and patient follow-ups moving."};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}
