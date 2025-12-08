# 🚀 Production Deployment Checklist

## Pre-Deployment

### 1. Environment Setup

- [ ] Supabase CLI installed (`npm install -g supabase`)
- [ ] Deno installed (for Edge Functions)
- [ ] Git repository initialized
- [ ] `.env` file created (never commit!)
- [ ] Supabase project created at [supabase.com/dashboard](https://supabase.com/dashboard)

### 2. Configuration Files

- [ ] `supabase/config.toml` configured
- [ ] `.env.example` updated with all required variables
- [ ] Database connection URL obtained
- [ ] Gemini API key obtained from [ai.google.dev](https://ai.google.dev)

## Database Deployment

### 3. Schema & Tables

```bash
# Deploy database schema
cd "d:\3rd sem\Mentora-App"
supabase db push

# OR using direct SQL
psql -h db.your-project.supabase.co -U postgres -d postgres -f supabase/schema.sql
```

- [ ] All 12 tables created successfully
- [ ] Indexes created for performance
- [ ] RLS (Row Level Security) policies enabled
- [ ] Triggers and functions deployed
- [ ] Sample seed data inserted (optional)

### 4. Verify Tables

Run in Supabase SQL Editor:

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

Expected tables:

- [ ] users
- [ ] user_skills
- [ ] roadmap_nodes
- [ ] projects
- [ ] user_project_progress
- [ ] courses
- [ ] user_course_progress
- [ ] achievements
- [ ] notifications
- [ ] xp_history
- [ ] leaderboard_cache
- [ ] resume_analyses

## Edge Functions Deployment

### 5. Deploy Functions

```powershell
# Set secrets first
supabase secrets set GEMINI_API_KEY=your-key-here

# Deploy all functions
supabase functions deploy generate-roadmap
supabase functions deploy analyze-resume
supabase functions deploy award-xp
supabase functions deploy unlock-project
supabase functions deploy complete-project
supabase functions deploy leaderboard
supabase functions deploy daily-rewards
```

- [ ] `generate-roadmap` deployed
- [ ] `analyze-resume` deployed
- [ ] `award-xp` deployed
- [ ] `unlock-project` deployed
- [ ] `complete-project` deployed
- [ ] `leaderboard` deployed
- [ ] `daily-rewards` deployed

### 6. Test Functions

```bash
# Test generate-roadmap
curl -i --location --request POST 'https://your-project.supabase.co/functions/v1/generate-roadmap' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"user_profile": {...}}'
```

- [ ] All functions return 200 OK
- [ ] Authentication working
- [ ] Gemini API calls successful
- [ ] Database writes confirmed

## Storage Configuration

### 7. Create Buckets

Go to Dashboard > Storage > Create Bucket

- [ ] **career-resumes**

  - Public: Read only
  - Allowed MIME types: `application/pdf, image/*`
  - Max file size: 10MB

- [ ] **user-avatars**

  - Public: Read only
  - Allowed MIME types: `image/*`
  - Max file size: 2MB

- [ ] **project-thumbnails**
  - Public: Read only
  - Allowed MIME types: `image/*`
  - Max file size: 5MB

### 8. Storage Policies

```sql
-- Allow authenticated users to upload resumes
CREATE POLICY "Users can upload own resume"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'career-resumes' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow public read
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id IN ('career-resumes', 'user-avatars', 'project-thumbnails'));
```

## Authentication Setup

### 9. Email Authentication

Dashboard > Authentication > Providers > Email

- [ ] Email provider enabled
- [ ] Confirm email: OFF (for development) or ON (for production)
- [ ] Secure password enabled (min 6 characters)

### 10. OAuth Providers

#### Google OAuth

- [ ] Create OAuth credentials at [console.cloud.google.com](https://console.cloud.google.com)
- [ ] Authorized redirect URI: `https://your-project.supabase.co/auth/v1/callback`
- [ ] Client ID and Secret configured in Supabase Dashboard

#### GitHub OAuth

- [ ] Create OAuth App at [github.com/settings/developers](https://github.com/settings/developers)
- [ ] Authorization callback URL: `https://your-project.supabase.co/auth/v1/callback`
- [ ] Client ID and Secret configured in Supabase Dashboard

## Realtime Configuration

### 11. Enable Realtime

Dashboard > Database > Replication

Enable Realtime for these tables:

- [ ] `users`
- [ ] `roadmap_nodes`
- [ ] `achievements`
- [ ] `notifications`
- [ ] `leaderboard_cache`
- [ ] `user_project_progress`

## Security Hardening

### 12. RLS Verification

```sql
-- Verify RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
```

- [ ] All tables have `rowsecurity = true`
- [ ] Policies tested with different user roles
- [ ] Service role key kept secret (never in client code!)

### 13. API Rate Limiting

Dashboard > Settings > API

- [ ] Rate limiting enabled
- [ ] Set appropriate limits (e.g., 100 req/min per IP)
- [ ] CORS configured for your domain

### 14. Secrets Management

```bash
# Set all required secrets
supabase secrets set GEMINI_API_KEY=xxx
supabase secrets set SENTRY_DSN=xxx (optional)
supabase secrets set OPENAI_API_KEY=xxx (fallback, optional)
```

- [ ] All secrets set via CLI (not hardcoded)
- [ ] `.env` file in `.gitignore`
- [ ] Production secrets different from development

## Flutter App Integration

### 15. Update Flutter App

File: `lib/core/supabase_config.dart`

```dart
static const String supabaseUrl = 'YOUR_ACTUAL_URL';
static const String supabaseAnonKey = 'YOUR_ACTUAL_ANON_KEY';
```

- [ ] Supabase URL updated
- [ ] Anon Key updated
- [ ] `supabase_flutter` package added
- [ ] Initialization in `main.dart`

### 16. Test Integration

- [ ] Authentication flow working
- [ ] Roadmap generation successful
- [ ] Realtime updates working
- [ ] File uploads working
- [ ] Notifications appearing

## Monitoring & Logging

### 17. Setup Monitoring

- [ ] Sentry configured (optional)
- [ ] Supabase logs reviewed
- [ ] Function logs accessible
- [ ] Database performance monitored

### 18. Error Tracking

```bash
# View function logs
supabase functions logs generate-roadmap --tail
```

- [ ] Error handling in all functions
- [ ] Structured logging implemented
- [ ] Alerts configured for critical errors

## Performance Optimization

### 19. Database Optimization

- [ ] Indexes verified
- [ ] Query performance tested
- [ ] Connection pooling configured
- [ ] Vacuum scheduled (auto)

### 20. Edge Functions Optimization

- [ ] Cold start times acceptable (<3s)
- [ ] Response times monitored
- [ ] Memory usage within limits
- [ ] Timeouts configured (default 30s)

## Backup & Recovery

### 21. Backups

Dashboard > Settings > Backup

- [ ] Daily automated backups enabled
- [ ] Point-in-time recovery configured (Pro plan)
- [ ] Backup restoration tested

## Final Tests

### 22. End-to-End Testing

- [ ] User signup/login
- [ ] Onboarding flow
- [ ] Roadmap generation
- [ ] Project unlock/complete
- [ ] Resume analysis
- [ ] Leaderboard display
- [ ] Notifications working
- [ ] Daily rewards claiming

### 23. Load Testing (Optional)

```bash
# Use Apache Bench or similar
ab -n 1000 -c 10 https://your-project.supabase.co/functions/v1/leaderboard
```

- [ ] Functions handle concurrent requests
- [ ] Database performs under load
- [ ] No memory leaks detected

## Go Live

### 24. Production Checklist

- [ ] All environment variables set
- [ ] CORS configured for production domain
- [ ] SSL/TLS working (auto with Supabase)
- [ ] Custom domain configured (optional)
- [ ] Privacy policy link added
- [ ] Terms of service added

### 25. Post-Launch Monitoring

- [ ] Monitor function invocations
- [ ] Track database query performance
- [ ] Watch error rates
- [ ] Monitor user signups
- [ ] Check Gemini API quotas

## Rollback Plan

### 26. Emergency Procedures

```bash
# Rollback to previous migration
supabase db reset --db-url your-db-url

# Disable a function
supabase functions delete function-name
```

- [ ] Rollback procedure documented
- [ ] Database backup downloaded
- [ ] Emergency contacts listed

---

## Quick Deploy Script

Run this in PowerShell:

```powershell
cd "d:\3rd sem\Mentora-App\supabase"
.\deploy.ps1
```

## Useful Commands

```bash
# Check deployment status
supabase status

# View function logs
supabase functions logs --tail

# Generate types for Flutter
supabase gen types typescript --local > lib/database.types.ts

# Reset local database (DESTRUCTIVE)
supabase db reset

# Check migrations
supabase migration list
```

---

**🎉 Congratulations! Your backend is production-ready!**

Support: [Supabase Discord](https://discord.supabase.com/) | [Docs](https://supabase.com/docs)
