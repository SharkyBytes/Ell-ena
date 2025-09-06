ALTER TABLE meetings
ADD COLUMN meeting_summary_json JSONB;

CREATE OR REPLACE FUNCTION trigger_summary_generation()
RETURNS TRIGGER AS $$
DECLARE
    function_url TEXT := 'https://project--ref.supabase.co/functions/v1/summarise-meeting';
BEGIN
    -- Call your Edge Function when final_transcription is updated
    IF NEW.final_transcription IS NOT NULL AND (TG_OP = 'INSERT' OR OLD.final_transcription IS DISTINCT FROM NEW.final_transcription) THEN
        PERFORM net.http_post(
            url := function_url,
            body := jsonb_build_object('meeting_id', NEW.id),
            headers := '{
                "Content-Type": "application/json",
                "Authorization": "Bearer YOUR-SERVICE-ROLE-KEY"
            }'::jsonb
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER meetings_after_transcription_update
AFTER INSERT OR UPDATE OF final_transcription ON meetings
FOR EACH ROW
EXECUTE FUNCTION trigger_summary_generation();