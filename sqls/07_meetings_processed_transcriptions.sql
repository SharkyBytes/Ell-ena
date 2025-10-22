ALTER TABLE meetings ADD COLUMN final_transcription jsonb; 

CREATE OR REPLACE FUNCTION update_final_transcription()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process when transcription changes
    IF NEW.transcription IS DISTINCT FROM OLD.transcription THEN
        NEW.final_transcription := extract_clean_transcription(NEW.transcription::jsonb);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER populate_final_transcription
BEFORE INSERT OR UPDATE OF transcription ON meetings
FOR EACH ROW
EXECUTE FUNCTION update_final_transcription();


CREATE OR REPLACE FUNCTION extract_clean_transcription(transcription_data jsonb)
RETURNS jsonb AS $$
BEGIN
    RETURN (
        SELECT jsonb_agg(
            jsonb_build_object(
                'speaker', seg->>'speaker',
                'text', seg->>'text'
            )
        )
        FROM jsonb_array_elements(transcription_data -> 'segments') seg
    );
END;
$$ LANGUAGE plpgsql;

-- This update should be after creating extract_clean_transcription function
UPDATE meetings
SET final_transcription = extract_clean_transcription(transcription::jsonb)
WHERE transcription IS NOT NULL;