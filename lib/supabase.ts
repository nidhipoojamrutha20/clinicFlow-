import { createBrowserClient } from "@supabase/ssr";
export function createSupabaseBrowserClient(){
 const url=process.env.NEXT_PUBLIC_SUPABASE_URL;const key=process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
 if(!url||!key)throw new Error("Supabase credentials are missing. Use demo mode or configure your environment.");
 return createBrowserClient(url,key);
}
export const demoMode=process.env.NEXT_PUBLIC_DEMO_MODE!=="false"||!process.env.NEXT_PUBLIC_SUPABASE_URL||!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
