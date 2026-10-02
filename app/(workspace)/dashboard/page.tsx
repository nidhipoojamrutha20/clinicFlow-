"use client";
import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useClinicData } from "@/lib/store";
export default function LegacyDashboardRedirect(){const router=useRouter();const data=useClinicData();useEffect(()=>{router.replace(data.currentUser?.role==="doctor"?"/doctor/dashboard":"/reception/dashboard")},[data.currentUser?.role,router]);return <div className="empty">Opening your workspace…</div>}
