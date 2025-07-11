import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const VEXA_API_KEY = Deno.env.get("VEXA_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

serve(async (req) => {
  const { meeting_url, meeting_id } = await req.json();
  
  // Validate if URL is Google Meet
  if (!meeting_url.includes("meet.google.com")) {
    return new Response(
      JSON.stringify({ error: "Only Google Meet URLs are supported" }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }
  
  // Extract meeting ID from Google Meet URL
  const meetId = meeting_url.split('/').pop().split('?')[0];
  
  try {
    // Start bot
    const response = await fetch("https://gateway.dev.vexa.ai/bots", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-API-Key": VEXA_API_KEY
      },
      body: JSON.stringify({
        platform: "google_meet",
        native_meeting_id: meetId,
        bot_name: "EllenaTranscriber"
      })
    });
    
    const result = await response.json();
    
    // Update meeting record
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    await supabase
      .from('meetings')
      .update({ bot_started_at: new Date().toISOString() })
      .eq('id', meeting_id);
    
    return new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
}) 