## Gemini-Generated Projects: user_id Implementation Summary

### Task Completed ✅

When Gemini returns recommended projects during profile creation/onboarding and those projects are saved to the database, the `projects.user_id` column is now set to the currently signed-in user's ID instead of NULL.

---

## Files Modified

### 1. **Edge Function: `supabase/functions/generate-roadmap/index.ts`** (Line 215)

**Change:** Added `user_id: profile.id` to the projects insert payload

**Before:**

```typescript
await supabase.from("projects").insert({
  title: project.title,
  description: project.description,
  // ... other fields
});
```

**After:**

```typescript
await supabase.from("projects").insert({
  user_id: profile.id, // ← NEW: Set to current user's ID
  title: project.title,
  description: project.description,
  // ... other fields
});
```

**Why:** This ensures every Gemini-generated project is automatically assigned to the user who completed onboarding. The `profile.id` is already authenticated from the Edge Function's auth flow.

---

### 2. **Database Migration: `supabase/migrations/20241221000001_add_user_id_to_projects.sql`** (NEW)

**Changes:**

- Adds `user_id UUID` column to `projects` table
- Column references `users(id)` with `ON DELETE CASCADE`
- Creates index on `user_id` for fast filtering
- Column is nullable (NULL = global template, UUID = user-owned)

```sql
ALTER TABLE projects
ADD COLUMN user_id UUID REFERENCES users(id) ON DELETE CASCADE;

CREATE INDEX idx_projects_user_id ON projects(user_id);
CREATE INDEX idx_projects_user_id_nullable ON projects(user_id) WHERE user_id IS NULL;
```

---

### 3. **Schema Documentation: `supabase/schema.sql`**

**Changes:**

- Updated `CREATE TABLE projects` to document `user_id` column
- Added comment: "NULL = global template, UUID = user-owned project from Gemini"
- Added index on `projects(user_id)` to the indexes section

```sql
-- Ownership (NULL = global template, UUID = user-owned project from Gemini)
user_id UUID REFERENCES users(id) ON DELETE CASCADE,
```

---

### 4. **Dart Model: `lib/models/project.dart`**

**Changes:**

- Added `final String? userId;` field to `Project` class
- Updated constructor to accept `userId` parameter
- Modified `fromJson` factory to parse `user_id` from Supabase response

```dart
final String? userId; // NULL = global template, UUID = user-owned project

// In constructor:
userId: json['user_id'] as String? ?? json['userId'] as String?,
```

---

## Data Flow: Gemini → Database

```
Onboarding Page (onboarding_page.dart)
    ↓
RoadmapService.generateRoadmap(userId: userId, ...)
    ↓
Edge Function: generate-roadmap
    ↓
Gemini API generates: recommended_projects: [{ title, description, ... }]
    ↓
For each project in geminiResponse.recommended_projects:
    → projects table INSERT with:
      - user_id: profile.id ← ✅ Current user is captured here
      - title, description, difficulty, xp_reward, etc.
    ↓
Newly created projects now have owner_id set correctly
```

---

## Verification: How to Test

### Step 1: Deploy the migration

```bash
# The migration will be automatically applied when Supabase syncs
# File: supabase/migrations/20241221000001_add_user_id_to_projects.sql
# This adds the user_id column to the existing projects table
```

### Step 2: Create a new test account

1. Log out of the app
2. Create a brand-new account (or use an incognito/private browser)
3. Complete the 6-step onboarding:
   - Step 1: Career field + experience level
   - Step 2: Education
   - Step 3: Current skills
   - Step 4: Career goal + motivation
   - Step 5: Target interests
   - Step 6: Weekly hours + learning style
4. Click "🎉 Complete Setup" (this triggers Gemini + Edge Function)

### Step 3: Verify in Supabase

1. Open your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Run this query:
   ```sql
   SELECT id, title, user_id, created_at
   FROM projects
   WHERE user_id IS NOT NULL
   ORDER BY created_at DESC
   LIMIT 10;
   ```

### Expected Result ✅

All newly created projects should show:

- **id:** (UUID)
- **title:** (Project name from Gemini)
- **user_id:** (Same UUID as the user who just signed up)
- **created_at:** (Current timestamp)

### Verify User ID Matches

```sql
-- Check the newly created user
SELECT id, name, email FROM users WHERE email = '<new_user_email>';

-- Check their projects all have the same user_id
SELECT user_id, COUNT(*) as project_count
FROM projects
WHERE user_id IS NOT NULL
GROUP BY user_id;
```

---

## Unchanged Behavior ✅

### What Did NOT Change:

- ✅ Existing projects with `user_id = NULL` remain as global templates
- ✅ Manual project creation flow (not affected)
- ✅ Roadmap node generation (not affected)
- ✅ XP/coins/leaderboard logic (not affected)
- ✅ Resume checker (not affected)
- ✅ Auth system (not affected)

### Backward Compatibility:

- Column is nullable, so existing global templates (user_id = NULL) continue to work
- Filters using `.isFilter('user_id', true)` for global templates are unaffected
- No existing data is modified; migration only adds the column

---

## Security & RLS Notes

If you have Row-Level Security (RLS) policies on the `projects` table, you may want to consider:

1. **Global Templates** (user_id IS NULL):

   - Should be readable by all authenticated users
   - Should NOT be updatable by regular users

2. **User-Owned Projects** (user_id = <uuid>):
   - Should be readable by that specific user
   - Should be updatable/deletable only by that user

Example RLS policy to add (optional, depends on your security model):

```sql
-- Allow anyone to read global templates
CREATE POLICY "public_read_global_templates" ON projects
FOR SELECT USING (user_id IS NULL);

-- Allow users to read their own projects
CREATE POLICY "user_read_own_projects" ON projects
FOR SELECT USING (user_id = auth.uid());
```

---

## Code Flow Summary

**Complete Data Path (Gemini → Database):**

1. **onboarding_page.dart** (line 203-213)

   - Calls `RoadmapService().generateRoadmap(userId, ...)`

2. **roadmap_service_supabase.dart** (line 13-39)

   - Invokes Edge Function `generate-roadmap` with user profile data

3. **generate-roadmap/index.ts** (line ~80-120)

   - Calls Gemini API with user profile
   - Receives: `geminiResponse.recommended_projects[]`

4. **generate-roadmap/index.ts** (line 213-228) ← ✅ **FIXED HERE**

   - Loops through projects array
   - **For each project, inserts with `user_id: profile.id`**
   - `profile.id` is the authenticated user's internal ID

5. **Supabase Database**
   - Projects table receives insert with user_id
   - Row-level indexing enables fast user-scoped queries

---

## Deployment Checklist

- [ ] Run migration to add `user_id` column: `supabase db push`
- [ ] Deploy updated Edge Function: `supabase functions deploy`
- [ ] Test with new account (fresh onboarding)
- [ ] Verify projects appear in Supabase with correct `user_id`
- [ ] Confirm existing global templates (NULL `user_id`) still work
- [ ] Monitor logs for any Gemini API errors

---

## No Additional Changes Needed

You do NOT need to:

- ❌ Change environment variables
- ❌ Modify existing RLS policies (unless you want stricter access control)
- ❌ Update Firebase/other backend systems
- ❌ Change how projects are displayed in the UI
- ❌ Modify the projects_page.dart (it already handles this data correctly)

The implementation is **backward compatible** and **minimal** — only the necessary changes to wire `user_id` into the Gemini project insert.
