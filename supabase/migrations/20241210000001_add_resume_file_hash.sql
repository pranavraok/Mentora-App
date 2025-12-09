-- =====================================================
-- ADD FILE_HASH TO RESUME_ANALYSES FOR CACHING
-- =====================================================

-- Add file_hash column to resume_analyses table for resume caching
ALTER TABLE resume_analyses 
ADD COLUMN IF NOT EXISTS file_hash VARCHAR(32);

-- Add index for efficient cache lookups
CREATE INDEX IF NOT EXISTS idx_resume_analyses_user_hash 
ON resume_analyses(user_id, file_hash);

-- Add comment explaining the purpose
COMMENT ON COLUMN resume_analyses.file_hash IS 'Hash of resume extracted_text for cache key (prevent re-analysis of same resume)';
