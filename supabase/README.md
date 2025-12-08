# 🚀 AI-Powered Career Platform - Supabase Backend

Complete serverless backend implementation with Supabase + Google Gemini API.

## 📁 Project Structure

```
supabase/
├── schema.sql                 # Complete database schema with RLS
├── config.toml               # Supabase project configuration
├── .env.example              # Environment variables template
├── functions/                # Edge Functions (TypeScript/Deno)
│   ├── generate-roadmap/
│   ├── analyze-resume/
│   ├── award-xp/
│   ├── unlock-project/
│   ├── complete-project/
│   ├── leaderboard/
│   ├── daily-rewards/
│   └── _shared/              # Shared utilities
├── migrations/               # Database migrations
└── seed.sql                  # Sample data for testing
```

## 🛠️ Prerequisites

1. **Supabase CLI**

   ```bash
   npm install -g supabase
   ```

2. **Deno** (for Edge Functions)

   ```bash
   # Windows (PowerShell)
   irm https://deno.land/install.ps1 | iex
   ```

3. **Supabase Project**
   - Create project at https://supabase.com/dashboard
   - Get API keys from Settings > API

## ⚡ Quick Start

### 1. Initialize Supabase

```bash
cd "d:\3rd sem\Mentora-App"
supabase init
supabase login
```

### 2. Link to Your Project

```bash
supabase link --project-ref your-project-ref
```

### 3. Setup Environment Variables

```bash
cp supabase/.env.example supabase/.env
# Edit .env with your actual values
```

### 4. Deploy Database Schema

```bash
supabase db push --db-url "your-database-url"

# OR using psql directly
psql -h db.your-project.supabase.co -U postgres -d postgres -f supabase/schema.sql
```

### 5. Create Storage Buckets

```bash
# Via Supabase Dashboard > Storage
# Create these buckets:
- career-resumes (public read, authenticated write)
- user-avatars (public read)
- project-thumbnails (public read)
```

### 6. Deploy Edge Functions

```bash
# Deploy all functions
supabase functions deploy generate-roadmap
supabase functions deploy analyze-resume
supabase functions deploy award-xp
supabase functions deploy unlock-project
supabase functions deploy complete-project
supabase functions deploy leaderboard
supabase functions deploy daily-rewards

# Set secrets
supabase secrets set GEMINI_API_KEY=your-key-here
```

### 7. Enable Realtime

```bash
# Via Supabase Dashboard > Database > Replication
# Enable realtime for these tables:
- users
- roadmap_nodes
- achievements
- notifications
- leaderboard_cache
```

## 🧪 Local Development

```bash
# Start local Supabase
supabase start

# Run specific function locally
supabase functions serve generate-roadmap --env-file supabase/.env

# Test function
curl -i --location --request POST 'http://localhost:54321/functions/v1/generate-roadmap' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"user_profile": {...}}'
```

## 📊 Database Management

```bash
# Create new migration
supabase migration new add_feature_name

# Reset database (DESTRUCTIVE)
supabase db reset

# Generate TypeScript types
supabase gen types typescript --local > lib/database.types.ts
```

## 🔐 Authentication Setup

### Enable OAuth Providers

1. **Google OAuth**

   ```
   Dashboard > Authentication > Providers > Google
   - Get credentials from Google Cloud Console
   - Add redirect URL: https://your-project.supabase.co/auth/v1/callback
   ```

2. **GitHub OAuth**
   ```
   Dashboard > Authentication > Providers > GitHub
   - Create OAuth App on GitHub
   - Add redirect URL
   ```

## 🚀 Production Deployment Checklist

- [ ] Database schema deployed
- [ ] RLS policies verified
- [ ] Storage buckets created
- [ ] All Edge Functions deployed
- [ ] Secrets set (Gemini API key)
- [ ] Realtime enabled
- [ ] OAuth providers configured
- [ ] CORS configured for your domain
- [ ] Rate limiting enabled
- [ ] Monitoring setup (Sentry)

## 📚 API Endpoints

### Authentication

```
POST /auth/v1/signup
POST /auth/v1/token?grant_type=password
GET  /auth/v1/user
```

### Edge Functions

```
POST /functions/v1/generate-roadmap
POST /functions/v1/analyze-resume
POST /functions/v1/award-xp
POST /functions/v1/unlock-project
POST /functions/v1/complete-project
GET  /functions/v1/leaderboard?period=weekly
POST /functions/v1/daily-rewards
```

## 🔗 Useful Links

- [Supabase Docs](https://supabase.com/docs)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Gemini API Docs](https://ai.google.dev/docs)
- [Database Migrations](https://supabase.com/docs/guides/cli/local-development)

## 🐛 Troubleshooting

### Connection Issues

```bash
supabase status  # Check if services are running
supabase stop && supabase start  # Restart services
```

### Function Errors

```bash
supabase functions logs generate-roadmap  # View logs
```

### Database Issues

```bash
supabase db diff  # Check schema differences
supabase db reset  # Nuclear option - resets everything
```

## 📝 Notes

- Edge Functions run on Deno (not Node.js)
- Use `import` syntax, not `require`
- Service role key grants admin access - keep it secret!
- Test locally before deploying to production
