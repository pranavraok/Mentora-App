-- =====================================================
-- VERIFICATION QUERIES FOR user_id IMPLEMENTATION
-- =====================================================
-- Run these queries in Supabase SQL Editor after completing onboarding

-- 1. Check if migration was applied (user_id column exists)
-- =====================================================
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'projects'
ORDER BY ordinal_position;

-- Expected: Should see "user_id" column of type "uuid" with is_nullable = YES


-- 2. View all user-owned projects (created by Gemini during onboarding)
-- =====================================================
SELECT 
    id,
    title,
    user_id,
    difficulty,
    xp_reward,
    created_at
FROM projects
WHERE user_id IS NOT NULL
ORDER BY created_at DESC;

-- Expected: All projects should have non-NULL user_id values


-- 3. View all global templates (existing projects without owner)
-- =====================================================
SELECT 
    id,
    title,
    user_id,
    difficulty,
    xp_reward,
    created_at
FROM projects
WHERE user_id IS NULL
ORDER BY created_at DESC;

-- Expected: Existing template projects should have NULL user_id


-- 4. Count projects per user (to verify distribution)
-- =====================================================
SELECT 
    u.id,
    u.name,
    u.email,
    COUNT(p.id) as project_count,
    MAX(p.created_at) as most_recent_project
FROM users u
LEFT JOIN projects p ON u.id = p.user_id
WHERE u.id IS NOT NULL
GROUP BY u.id, u.name, u.email
ORDER BY project_count DESC;

-- Expected: Users should have 5 projects each (slice(0, 5) in Edge Function)


-- 5. Verify the specific new user's projects
-- =====================================================
-- Replace 'test@example.com' with the test account email
SELECT 
    u.id as user_id,
    u.name,
    u.email,
    p.id as project_id,
    p.title,
    p.difficulty,
    p.xp_reward,
    p.created_at
FROM users u
JOIN projects p ON u.id = p.user_id
WHERE u.email = 'test@example.com'
ORDER BY p.created_at DESC;

-- Expected: Should see all 5 projects created during onboarding


-- 6. Check for any projects with mismatched user_id (data integrity check)
-- =====================================================
SELECT 
    p.id,
    p.title,
    p.user_id,
    u.id as valid_user_id,
    CASE 
        WHEN u.id IS NULL THEN 'ORPHANED - user_id points to non-existent user'
        ELSE 'OK'
    END as status
FROM projects p
LEFT JOIN users u ON p.user_id = u.id
WHERE p.user_id IS NOT NULL AND u.id IS NULL;

-- Expected: Should return 0 rows (no orphaned projects)


-- 7. Index performance check (verify indexes were created)
-- =====================================================
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'projects'
ORDER BY indexname;

-- Expected: Should include:
-- - idx_projects_user_id
-- - idx_projects_user_id_nullable (partial index on WHERE user_id IS NULL)
-- - idx_projects_category
-- - idx_projects_difficulty
-- - idx_projects_trending


-- 8. Quick performance test: Query by user_id (should be fast)
-- =====================================================
EXPLAIN ANALYZE
SELECT * FROM projects
WHERE user_id = (SELECT id FROM users LIMIT 1)
ORDER BY created_at DESC;

-- Expected: Should use the idx_projects_user_id index
-- (Look for "Index Scan" in the EXPLAIN output, not "Seq Scan")


-- 9. Verify migration timestamp (when was it applied)
-- =====================================================
SELECT 
    name,
    executed_at
FROM schema_migrations
WHERE name LIKE '%add_user_id_to_projects%'
ORDER BY executed_at DESC;

-- Expected: Should show the migration 20241221000001_add_user_id_to_projects.sql
