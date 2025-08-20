CREATE OR REPLACE FUNCTION queue_embedding(query_text TEXT)
RETURNS BIGINT AS $$
DECLARE
    resp_id BIGINT;
BEGIN
    resp_id := net.http_post(
       url := 'https://vcyzvymahcfmfjfzaebm.supabase.co/functions/v1/get-embedding',
        body := jsonb_build_object('text', query_text),
        headers := '{
            "Content-Type": "application/json",
            "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjeXp2eW1haGNmbWZqZnphZWJtIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTc2MTk2NywiZXhwIjoyMDY1MzM3OTY3fQ.Rru5vRGbPeNggwykN-JqgKqqgDY6UwLn67l0rhkW8hI"
        }'::jsonb
    );
    RETURN resp_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_embedding_response(resp_id BIGINT)
RETURNS JSONB AS $$
DECLARE
    api_response JSONB;
    attempts INT := 0;
BEGIN
    RAISE LOG 'Waiting for embedding response for resp_id: %', resp_id;

    LOOP
        SELECT content::jsonb INTO api_response
        FROM net._http_response
        WHERE id = resp_id
        ORDER BY created DESC
        LIMIT 1;

        IF api_response IS NOT NULL THEN
            RAISE LOG 'Received response for resp_id: %', resp_id;
            EXIT;
        END IF;

        PERFORM pg_sleep(0.1);  -- wait 100ms
        attempts := attempts + 1;

        IF attempts >= 100 THEN
            RAISE EXCEPTION 'Embedding response did not arrive for resp_id %', resp_id;
        END IF;
    END LOOP;

    RAISE LOG 'API response content: %', api_response;
    RETURN api_response;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION extract_embedding(api_response JSONB)
RETURNS vector(768) AS $$
DECLARE
    embedding_json JSONB;
    embedding_vec vector(768);
BEGIN
    RAISE LOG 'Extracting embedding from API response';
    embedding_json := api_response->'embedding';

    IF embedding_json IS NULL THEN
        RAISE EXCEPTION 'No embedding found in API response: %', api_response;
    END IF;

    -- Cast the JSON directly to vector
    embedding_vec := embedding_json::text::vector;

    -- Log as text (cannot slice vector)
    RAISE LOG 'Embedding vector extracted: %', embedding_vec::text;

    RETURN embedding_vec;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION get_similar_meetings(
    query_embedding vector(768),
    match_count INT DEFAULT 3
)
RETURNS TABLE (
    meeting_id UUID,
    title TEXT,
    meeting_date TIMESTAMP WITH TIME ZONE,
    similarity FLOAT,
    summary JSONB
) AS $$
BEGIN
    RAISE LOG 'Querying meetings with a given embedding';

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

    RAISE LOG 'get_similar_meetings completed';
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION search_meeting_summaries_by_resp_id(resp_id BIGINT, match_count INT DEFAULT 3, similarity_threshold FLOAT DEFAULT 0.0)
RETURNS TABLE (
    meeting_id UUID,
    title TEXT,
    meeting_date TIMESTAMP WITH TIME ZONE,
    similarity FLOAT,
    summary JSONB
) AS $$
DECLARE
    api_response JSONB;
    query_embedding vector(768);
BEGIN
    RAISE LOG 'Starting search_meeting_summaries_by_resp_id for resp_id: %', resp_id;

    -- Step 1: Wait for response
    api_response := get_embedding_response(resp_id);
    RAISE LOG 'Embedding response received: %', api_response;

    -- Step 2: Extract vector
    query_embedding := extract_embedding(api_response);
    -- RAISE LOG 'Embedding vector extracted with dimensions: %', array_length(query_embedding, 1);

    -- Step 3: Return similar meetings
    RETURN QUERY
    SELECT * FROM get_similar_meetings(query_embedding, match_count);
    
    RAISE LOG 'search_meeting_summaries_by_resp_id completed';
END;
$$ LANGUAGE plpgsql;

