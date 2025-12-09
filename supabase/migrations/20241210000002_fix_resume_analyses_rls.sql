-- =====================================================
-- FIX RESUME_ANALYSES RLS POLICY FOR AUTHENTICATED USERS
-- =====================================================

-- Drop the old policy if it exists
DROP POLICY IF EXISTS "Users can manage own resume analyses" ON resume_analyses;

-- Create a new policy that allows authenticated users to insert their own resume analyses
CREATE POLICY "Authenticated users can manage own resume analyses" 
    ON resume_analyses FOR ALL 
    USING (user_id IN (SELECT id FROM users WHERE supabase_uid = auth.uid()))
    WITH CHECK (user_id IN (SELECT id FROM users WHERE supabase_uid = auth.uid()));

-- Service role can always manage resume analyses
CREATE POLICY "Service role can manage all resume analyses" 
    ON resume_analyses FOR ALL 
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');
