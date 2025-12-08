# 🎯 QUICK START GUIDE - Backend Setup

**Get your AI-powered career platform backend running in 15 minutes!**

## ✅ What You're Getting

- **Complete Supabase Backend** (PostgreSQL + Auth + Storage + Realtime)
- **7 AI-Powered Edge Functions** (TypeScript/Deno with Gemini integration)
- **12 Database Tables** with Row Level Security
- **Realtime Notifications** and **Gamification System**
- **Flutter Integration** ready to copy-paste

## 🚀 Step-by-Step Setup

### Step 1: Install Prerequisites (5 min)

```powershell
# Install Supabase CLI
npm install -g supabase

# Install Deno (for Edge Functions)
irm https://deno.land/install.ps1 | iex

# Verify
supabase --version
deno --version
```

### Step 2: Create Supabase Project (2 min)

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Click "New Project"
3. Fill in:
   - **Name**: Mentora Career Platform
   - **Database Password**: (save this!)
   - **Region**: Choose closest to you
4. Wait ~2 minutes for project creation
5. Copy from **Settings > API**:
   - Project URL (e.g., `https://xxx.supabase.co`)
   - Anon/Public Key
   - Service Role Key (keep secret!)

### Step 3: Get Gemini API Key (3 min)

1. Go to [ai.google.dev](https://ai.google.dev)
2. Click "Get API Key in Google AI Studio"
3. Create new key or use existing project
4. Copy the API key

### Step 4: Configure Environment (1 min)

```powershell
cd "d:\3rd sem\Mentora-App\supabase"

# Copy template
cp .env.example .env

# Edit .env file with your values:
# - SUPABASE_URL=your-url
# - SUPABASE_ANON_KEY=your-anon-key
# - SUPABASE_SERVICE_ROLE_KEY=your-service-key
# - GEMINI_API_KEY=your-gemini-key
```

### Step 5: Deploy Backend (4 min)

```powershell
# Login to Supabase
supabase login

# Run automated deployment
.\deploy.ps1
```

When prompted:

- Enter your **Supabase project reference ID** (from dashboard URL)
- Confirm database reset: **yes**
- Enter **Gemini API key**

This script will:

- ✅ Deploy database schema (12 tables)
- ✅ Deploy all 7 Edge Functions
- ✅ Set environment secrets
- ✅ Configure security policies

### Step 6: Manual Configuration (5 min)

#### A. Enable Realtime

1. Dashboard > Database > Replication
2. Enable for these tables:
   - `users`
   - `roadmap_nodes`
   - `achievements`
   - `notifications`
   - `leaderboard_cache`

#### B. Create Storage Buckets

1. Dashboard > Storage > New Bucket
2. Create:
   - **career-resumes** (public read, authenticated write)
   - **user-avatars** (public read)
   - **project-thumbnails** (public read)

#### C. Enable OAuth (Optional but Recommended)

1. Dashboard > Authentication > Providers
2. Enable **Google**:
   - Get credentials from [console.cloud.google.com](https://console.cloud.google.com)
   - Redirect URI: `https://your-project.supabase.co/auth/v1/callback`
3. Enable **GitHub**:
   - Create OAuth app at [github.com/settings/developers](https://github.com/settings/developers)
   - Same redirect URI pattern

### Step 7: Integrate with Flutter (5 min)

#### A. Add Dependency

```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.3.4
```

```bash
flutter pub get
```

#### B. Initialize Supabase

```dart
// lib/core/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_ACTUAL_URL';
  static const String supabaseAnonKey = 'YOUR_ACTUAL_ANON_KEY';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}
```

```dart
// lib/main.dart
import 'package:mentora_app/core/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize(); // Add this
  runApp(const ProviderScope(child: MyApp()));
}
```

#### C. Test Connection

```dart
void testConnection() async {
  try {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .limit(1);
    print('✅ Supabase connected!');
  } catch (e) {
    print('❌ Connection error: $e');
  }
}
```

Run in your app and check console.

## 🧪 Test Your Backend

### Test 1: Generate Roadmap

```dart
final response = await Supabase.instance.client.functions.invoke(
  'generate-roadmap',
  body: {
    'user_profile': {
      'name': 'Test User',
      'career_goal': 'Full-Stack Developer',
      'current_skills': [{'skill': 'JavaScript', 'level': 'Beginner'}],
      'target_skills': [{'skill': 'React', 'level': 'Advanced'}],
      'timeline_months': 6,
    }
  },
);

print('Roadmap: ${response.data}');
```

### Test 2: Fetch Leaderboard

```dart
final response = await Supabase.instance.client.functions.invoke(
  'leaderboard',
  method: HttpMethod.get,
  queryParameters: {'period': 'all_time', 'limit': '10'},
);

print('Top Users: ${response.data['leaderboard']}');
```

### Test 3: Authentication

```dart
// Sign up
final authResponse = await Supabase.instance.client.auth.signUp(
  email: 'test@example.com',
  password: 'password123',
);

print('User ID: ${authResponse.user?.id}');
```

## 📁 What Was Created

```
d:\3rd sem\Mentora-App\
├── supabase/
│   ├── schema.sql                 # Database with 12 tables + RLS
│   ├── config.toml               # Project configuration
│   ├── .env.example              # Environment template
│   ├── deploy.ps1                # Deployment script
│   └── functions/                # 7 Edge Functions
│       ├── _shared/utils.ts      # Shared utilities
│       ├── generate-roadmap/     # AI roadmap generation ⭐
│       ├── analyze-resume/       # Resume analysis ⭐
│       ├── award-xp/             # Gamification
│       ├── unlock-project/       # Project gating
│       ├── complete-project/     # Project completion
│       ├── daily-rewards/        # Daily bonuses
│       └── leaderboard/          # Rankings
│
├── BACKEND_README.md             # Complete documentation
├── FLUTTER_INTEGRATION.md        # Flutter setup guide
└── DEPLOYMENT_CHECKLIST.md       # Production checklist
```

## 🎯 Next Steps

1. **Copy Flutter Services**: See [FLUTTER_INTEGRATION.md](./FLUTTER_INTEGRATION.md) for:

   - `AuthService`
   - `RoadmapServiceSupabase`
   - `GamificationService`
   - `ProjectServiceSupabase`
   - `LeaderboardService`
   - `ResumeService`

2. **Update Your UI**: Connect existing UI to new services:

   ```dart
   // Example: Onboarding
   final roadmapService = ref.read(roadmapServiceProvider);
   await roadmapService.generateRoadmap(userProfile: {...});
   ```

3. **Enable Realtime**: Add subscriptions for live updates:
   ```dart
   roadmapService.subscribeToRoadmap(userId, (update) {
     // Update UI
   });
   ```

## 🚨 Common Issues

### "Function not found"

- Run: `supabase functions deploy generate-roadmap`
- Check: `supabase functions list`

### "Invalid API key"

- Verify: `supabase secrets list`
- Re-set: `supabase secrets set GEMINI_API_KEY=xxx`

### "RLS policy violation"

- Check you're authenticated
- Verify RLS policies in SQL Editor

### "CORS error"

- Add your domain in Dashboard > Settings > API > CORS

## 📊 Usage Stats

After setup, monitor in Dashboard:

- **Functions**: Invocations, errors, duration
- **Database**: Queries, connections, storage
- **Auth**: Signups, logins, sessions
- **Storage**: Uploads, bandwidth

## 🎉 You're Done!

Your backend is now:

- ✅ Deployed to production
- ✅ Secured with RLS
- ✅ Connected to Gemini AI
- ✅ Ready for Flutter integration
- ✅ Monitoring enabled

**Time to build something amazing! 🚀**

## 💡 Pro Tips

1. **Use Service Providers**: Create Riverpod providers for all services
2. **Handle Errors**: Add try-catch blocks with user-friendly messages
3. **Cache Data**: Use local storage for offline support
4. **Test Realtime**: Ensure subscriptions are unsubscribed on dispose
5. **Monitor Costs**: Free tier limits:
   - 50,000 MAU (Monthly Active Users)
   - 500MB database
   - 1GB storage
   - 2GB bandwidth

## 📚 Learn More

- **Full Documentation**: [BACKEND_README.md](./BACKEND_README.md)
- **Flutter Services**: [FLUTTER_INTEGRATION.md](./FLUTTER_INTEGRATION.md)
- **Production Deploy**: [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)
- **Supabase Docs**: [supabase.com/docs](https://supabase.com/docs)
- **Gemini Docs**: [ai.google.dev/docs](https://ai.google.dev/docs)

## 🆘 Need Help?

- Check [Troubleshooting](#-common-issues) section
- Review function logs: `supabase functions logs --tail`
- Join [Supabase Discord](https://discord.supabase.com/)
- Check [GitHub Issues](https://github.com/supabase/supabase/issues)

---

**Made with ❤️ for your AI-Powered Career Platform**
