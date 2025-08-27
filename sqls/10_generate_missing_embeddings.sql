-- Create a function to process meetings with summaries but missing embeddings
CREATE OR REPLACE FUNCTION process_meetings_missing_embeddings()
RETURNS void AS $$
DECLARE
    meeting_record RECORD;
    embedding_function_url TEXT := 'https://project--ref.supabase.co/functions/v1/generate-embeddings';
    resp jsonb;
BEGIN
    FOR meeting_record IN
        SELECT id
        FROM meetings
        WHERE meeting_summary_json IS NOT NULL
          AND summary_embedding IS NULL
          AND created_at > NOW() - INTERVAL '30 days' -- Process meetings from the last 30 days
    LOOP
        RAISE LOG 'Generating embedding for meeting_id=%', meeting_record.id;
        
        -- Generate embedding for the summary
        resp := net.http_post(
            url := embedding_function_url,
            body := jsonb_build_object('meeting_id', meeting_record.id),
            headers := '{
                "Content-Type": "application/json",
                "Authorization": "Bearer SERVICE_ROLE_KEY"
            }'::jsonb
        );

        RAISE LOG 'Embedding Function response for meeting_id=% : %', meeting_record.id, resp;

        -- Small delay so you don't overwhelm your Edge Function
        PERFORM pg_sleep(0.2);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Schedule it to run every 5 minutes
-- Using a different schedule than the summary generation to avoid resource contention
SELECT cron.schedule(
    'process-missing-embeddings',
    '* * * * *',
    $$SELECT process_meetings_missing_embeddings();$$
);

-- You can also run it manually once to process existing meetings:
-- SELECT process_meetings_missing_embeddings();


