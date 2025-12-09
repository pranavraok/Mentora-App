-- Fix RLS policy for user signup
-- The issue: During signup, the INSERT was being blocked
-- Solution: Explicitly allow authenticated users to insert

DROP POLICY IF EXISTS "Users can insert own profile" ON users;

CREATE POLICY "Users can insert own profile" 
    ON users FOR INSERT 
    TO authenticated
    WITH CHECK (supabase_uid = auth.uid());
