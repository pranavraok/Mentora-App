# 🚀 ACTUAL QUICK START - Your Backend is Ready!

## ✅ What's Already Done

All backend code is created and ready in your project:

- ✅ 12 database tables with SQL schema
- ✅ 7 Edge Functions (TypeScript)
- ✅ Complete Flutter integration code
- ✅ Deployment scripts

## 🎯 Deploy in 3 Steps (10 minutes)

### Step 1: Create Supabase Project (3 min)

1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Fill in:
   - **Name**: Mentora Career Platform
   - **Database Password**: (create a strong password - save it!)
   - **Region**: Choose closest to you
4. Wait ~2 minutes for setup
5. **Copy these from Settings > API**:
   - Project URL: `https://xxx.supabase.co`
   - Anon key: `eyJh...` (long string)
   - Service role key: `eyJh...` (different long string)

### Step 2: Get Gemini API Key (2 min)

1. Go to https://ai.google.dev
2. Click "Get API Key"
3. Create or select a Google Cloud project
4. Copy the API key

### Step 3: Login & Link Project (2 min)

```powershell
# Login to Supabase (opens browser)
.\supabase.exe login

# Link to your project (get ref from dashboard URL)
# Example: https://supabase.com/dashboard/project/abcdefghijklmnop
# Project ref = abcdefghijklmnop
.\supabase.exe link --project-ref YOUR_PROJECT_REF
```

### Step 4: Deploy Database (1 min)

```powershell
# Deploy the schema
.\supabase.exe db push --db-url "postgresql://postgres.YOUR_PROJECT_REF:[YOUR_PASSWORD]@aws-0-us-west-1.pooler.supabase.com:6543/postgres"
```

Replace:

- `YOUR_PROJECT_REF` - from dashboard URL
- `YOUR_PASSWORD` - the database password you created

### Step 5: Set Secrets (1 min)

```powershell
# Set Gemini API key
.\supabase.exe secrets set GEMINI_API_KEY=your-gemini-key-here
```

### Step 6: Deploy Functions (1 min each)

```powershell
.\supabase.exe functions deploy generate-roadmap
.\supabase.exe functions deploy analyze-resume
.\supabase.exe functions deploy award-xp
.\supabase.exe functions deploy unlock-project
.\supabase.exe functions deploy complete-project
.\supabase.exe functions deploy daily-rewards
.\supabase.exe functions deploy leaderboard
```

---

## 📱 Quick Flutter Setup

### 1. Add Dependency

```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.3.4
```

```bash
flutter pub get
```

### 2. Create Config File

Create `lib/core/supabase_config.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // PASTE YOUR VALUES HERE
  static const String supabaseUrl = 'https://xxx.supabase.co';
  static const String supabaseAnonKey = 'eyJh...your-anon-key...';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
```

### 3. Initialize in main.dart

```dart
import 'package:mentora_app/core/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add this line
  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: MyApp()));
}
```

### 4. Test Connection

Add this anywhere in your app and call it:

```dart
Future<void> testSupabase() async {
  try {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .limit(1);
    print('✅ Supabase connected!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

---

## 🎮 Manual Dashboard Setup (5 min)

### Enable Realtime

1. Dashboard > Database > Replication
2. Click these tables and toggle ON:
   - `users`
   - `roadmap_nodes`
   - `achievements`
   - `notifications`
   - `leaderboard_cache`

### Create Storage Buckets

1. Dashboard > Storage > New Bucket
2. Create:
   - **Name**: `career-resumes`
     - Public: ✅ Read only
     - File size limit: 10MB
   - **Name**: `user-avatars`
     - Public: ✅ Read only
     - File size limit: 2MB
   - **Name**: `project-thumbnails`
     - Public: ✅ Read only
     - File size limit: 5MB

---

## 🧪 Test Your Backend

### Test 1: Auth

```dart
final response = await Supabase.instance.client.auth.signUp(
  email: 'test@example.com',
  password: 'test123',
);
print('User created: ${response.user?.id}');
```

### Test 2: Generate Roadmap

```dart
final response = await Supabase.instance.client.functions.invoke(
  'generate-roadmap',
  body: {
    'user_profile': {
      'name': 'Test User',
      'career_goal': 'Full-Stack Developer',
      'current_skills': [{'skill': 'HTML', 'level': 'Beginner'}],
      'target_skills': [{'skill': 'React', 'level': 'Advanced'}],
      'timeline_months': 6,
    }
  },
);
print('Roadmap: ${response.data}');
```

---

## 🚨 Common Issues

### "supabase.exe not found"

```powershell
# Use full path
.\supabase.exe --version
```

### "Database connection failed"

- Check password is correct
- Verify project ref in URL
- Ensure project is fully created (wait 2-3 min)

### "Function deployment failed"

```powershell
# Check function exists
ls supabase\functions

# Try deploying one at a time
.\supabase.exe functions deploy generate-roadmap --debug
```

### "Gemini API error"

- Verify key is correct
- Check you enabled Gemini API in Google Cloud Console
- Free tier: 60 requests/minute limit

---

## 📚 Full Documentation

For complete service implementations and advanced features:

- **FLUTTER_INTEGRATION.md** - Complete Dart service classes
- **BACKEND_README.md** - Full API documentation
- **DEPLOYMENT_CHECKLIST.md** - Production checklist

---

## ✅ Verification Checklist

Before connecting Flutter:

- [ ] Supabase project created
- [ ] Database schema deployed (12 tables)
- [ ] All 7 functions deployed
- [ ] Gemini API key set
- [ ] Realtime enabled (5 tables)
- [ ] Storage buckets created (3 buckets)
- [ ] `supabase_flutter` package added
- [ ] Config file created with your keys
- [ ] Initialization in main.dart

---

## 🎉 You're Ready!

Once these steps are done, your Flutter app can:

- ✅ Generate AI-powered career roadmaps
- ✅ Analyze resumes with ATS scoring
- ✅ Track XP, levels, achievements
- ✅ Unlock/complete projects
- ✅ Show realtime leaderboards
- ✅ Send push notifications

**Next: Copy service classes from FLUTTER_INTEGRATION.md and connect your existing UI!**

---

## 💡 Quick Commands Reference

```powershell
# Check status
.\supabase.exe status

# View function logs
.\supabase.exe functions logs generate-roadmap

# List deployed functions
.\supabase.exe functions list

# List secrets
.\supabase.exe secrets list

# Help
.\supabase.exe --help
```

---

**Need help? Check FLUTTER_INTEGRATION.md for complete examples!**
