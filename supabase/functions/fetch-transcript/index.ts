import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const VEXA_API_KEY = Deno.env.get("VEXA_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

serve(async (req) => {
  const { meeting_url, meeting_id } = await req.json();
  
  // Extract meeting ID from Google Meet URL
  const meetId = meeting_url.split('/').pop().split('?')[0];
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  try {
    // Fetch transcript
    const transcriptRes = await fetch(
      `https://gateway.dev.vexa.ai/transcripts/google_meet/${meetId}`,
      { headers: { "X-API-Key": VEXA_API_KEY } }
    );
    
    const transcript = await transcriptRes.text();

    // Stop bot
    await fetch(
      `https://gateway.dev.vexa.ai/bots/google_meet/${meetId}`,
      {
        method: "DELETE",
        headers: { "X-API-Key": VEXA_API_KEY }
      }
    );

    // Update meeting record with transcript
    await supabase
      .from('meetings')
      .update({ 
        transcription: transcript,
        transcription_attempted_at: new Date().toISOString() 
      })
      .eq('id', meeting_id);

    return new Response(JSON.stringify({ success: true, transcript }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    // Mark as attempted even if failed
    await supabase
      .from('meetings')
      .update({ transcription_attempted_at: new Date().toISOString() })
      .eq('id', meeting_id);
      
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
}) 