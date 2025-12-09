-- =====================================================
-- STORAGE BUCKET POLICIES FOR RESUME UPLOADS
-- =====================================================

-- Enable storage schema if not already enabled
CREATE SCHEMA IF NOT EXISTS storage;

-- Create career-resumes bucket if it doesn't exist (idempotent)
INSERT INTO storage.buckets (id, name, public, avif_autodetection, file_size_limit, allowed_mime_types)
VALUES (
  'career-resumes',
  'career-resumes',
  false,
  false,
  52428800,  -- 50MB limit
  ARRAY['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword']
)
ON CONFLICT (id) DO UPDATE SET updated_at = now();

-- Allow authenticated users to upload their own resumes
CREATE POLICY "Authenticated users can upload resumes"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'career-resumes' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Allow authenticated users to read their own resumes
CREATE POLICY "Authenticated users can read their own resumes"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'career-resumes' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Allow service role full access
CREATE POLICY "Service role can manage resumes"
  ON storage.objects
  FOR ALL
  TO service_role
  USING (bucket_id = 'career-resumes')
  WITH CHECK (bucket_id = 'career-resumes');
