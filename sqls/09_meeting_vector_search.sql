-- First, ensure we have the vector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Add a vector column to the meetings table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'meetings' 
    AND column_name = 'summary_embedding'
  ) THEN
    ALTER TABLE meetings
    ADD COLUMN summary_embedding vector(768);
  END IF;
END $$;

-- Create a function to search for relevant meeting summaries
CREATE OR REPLACE FUNCTION search_meeting_summaries(query_text TEXT, match_count INT DEFAULT 3)
RETURNS TABLE (
    meeting_id UUID,
    title TEXT,
    meeting_date TIMESTAMP WITH TIME ZONE,
    similarity FLOAT,
    summary JSONB
) AS $$
DECLARE
    query_embedding vector(768);
    resp jsonb;
    api_response jsonb;
BEGIN
    -- Generate embedding for the query using the Gemini API via Edge Function
    resp := net.http_post(
        url := 'https://vcyzvymahcfmfjfzaebm.supabase.co/functions/v1/get-embedding',
        body := jsonb_build_object('text', query_text),
        headers := '{
            "Content-Type": "application/json",
            "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjeXp2eW1haGNmbWZqZnphZWJtIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTc2MTk2NywiZXhwIjoyMDY1MzM3OTY3fQ.Rru5vRGbPeNggwykN-JqgKqqgDY6UwLn67l0rhkW8hI"
        }'::jsonb
    );

    -- Check if response has status 200
    IF (resp->>'status')::int <> 200 THEN
        RAISE EXCEPTION 'Failed to get embedding: HTTP status %', resp->>'status';
    END IF;

    -- Extract the embedding from the response
    api_response := resp->'body';
    query_embedding := (api_response->>'embedding')::vector;

    -- Return meetings with similar summary content
    RETURN QUERY
    SELECT 
        m.id AS meeting_id,
        m.title,
        m.meeting_date,
        1 - (m.summary_embedding <=> query_embedding) AS similarity,
        m.meeting_summary_json AS summary
    FROM meetings m
    WHERE m.summary_embedding IS NOT NULL
    ORDER BY m.summary_embedding <=> query_embedding
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql;
