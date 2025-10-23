-- Add transcription_error column to meetings table
ALTER TABLE meetings ADD COLUMN IF NOT EXISTS transcription_error TEXT;

-- Add comment for documentation
COMMENT ON COLUMN meetings.transcription_error IS 'Stores error messages when transcription processing fails';