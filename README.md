# 🚀 Mentora - AI-Powered Career Mentorship Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.8.0-blue.svg)](https://flutter.dev/)
[![Gemini](https://img.shields.io/badge/Google%20Gemini-2.5%20Flash%20Lite-orange.svg)](https://ai.google.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green.svg)](https://supabase.com/)
[![License](https://img.shields.io/badge/License-Hackathon-red.svg)]()

**Mentora** transforms career guidance into an engaging, gamified learning journey powered by Google's Gemini AI. Get personalized roadmaps, ATS-optimized resume analysis, and structured learning paths tailored to your goals.

---

## 🎯 Problem We're Solving

75% of resumes are rejected by Applicant Tracking Systems (ATS) before reaching human recruiters. Most students lack personalized career guidance, facing overwhelming resources with no clear progression. **Mentora bridges this gap** with AI-driven, actionable mentorship.

---

## ✨ Key Features

### 🗺️ **AI-Generated Career Roadmaps**
- Personalized 15-25 node learning paths based on your skills, interests, and timeline
- Progressive difficulty (Beginner → Intermediate → Advanced)
- Real course recommendations with URLs (Coursera, Udemy, freeCodeCamp)
- Hands-on project ideas for portfolio building
- Visual roadmap with themed progression (Grassland → Space)

### 📄 **ATS Resume Analyzer**
- Upload PDF/DOCX resumes for instant AI analysis
- 6-dimensional scoring: Summary, Experience, Education, Skills, Projects, Formatting
- Overall score (0-100) + ATS compatibility rating
- Keyword gap identification for target roles
- Optimized bullet point examples and rewrite suggestions
- Cached analysis to save time on repeat uploads

### 🎮 **Gamification System**
- Earn XP (Experience Points) by completing roadmap nodes
- Dynamic leveling system (Level = √(XP/1000))
- Collect coins (10% of XP earned)
- Unlock achievements and milestones
- Real-time leaderboards (Daily, Weekly, Monthly, All-Time)

### 📊 **Progress Tracking**
- Visual dashboard with XP charts (fl_chart)
- Skill gap analysis with proficiency scores
- Daily rewards and streak tracking
- Activity history and notifications

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| **Frontend** | Flutter 3.8.0 (Dart) |
| **Backend** | Supabase (PostgreSQL + Edge Functions) |
| **AI Engine** | Google Gemini 2.5 Flash Lite API |
| **Authentication** | Supabase Auth (JWT) |
| **State Management** | Provider + Riverpod |
| **Animations** | Rive, Lottie, Flutter Animate |
| **Charts** | FL Chart |
| **Deployment** | Android/iOS APK builds |

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK 3.8.0+
- Dart SDK 3.8.0+
- Supabase account
- Google Gemini API key

### 1. Clone Repository
```bash
git clone https://github.com/pranavraok/Mentora-App.git
cd Mentora-App
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Supabase
Create `.env` file in project root:
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

Update `lib/config/supabase_config.dart`:
```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### 4. Configure Gemini API (Edge Functions)
In Supabase Dashboard → Project Settings → Edge Functions → Secrets:
```
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-2.5-flash-lite
```

### 5. Deploy Edge Functions
```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link project
supabase link --project-ref your_project_ref

# Deploy functions
supabase functions deploy analyze-resume
supabase functions deploy generate-roadmap
supabase functions deploy award-xp
supabase functions deploy leaderboard
```

### 6. Run Database Migrations
Execute SQL files in `supabase/migrations/` via Supabase SQL Editor:
- `001_users_table.sql`
- `002_roadmap_nodes.sql`
- `003_resume_analyses.sql`
- `004_leaderboard.sql`

### 7. Build & Run
```bash
# Run on Android emulator/device
flutter run

# Build APK
flutter build apk --release

# Build iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## 🔑 API Key Usage Disclaimer

⚠️ **IMPORTANT: Gemini API Key Security**

This application integrates **Google Gemini 2.5 Flash Lite API** for AI-powered features. API keys are **securely stored in Supabase Edge Function environment variables** and are **never exposed** to the client app.

### Security Measures:
✅ **Server-Side API Calls**: All Gemini API requests originate from Supabase Edge Functions (backend), not the Flutter app  
✅ **Environment Variables**: API keys stored in Supabase project secrets (not in code)  
✅ **No Client Exposure**: Flutter app communicates with Edge Functions via authenticated HTTP requests (JWT tokens)  
✅ **Rate Limiting**: In-memory rate limiter prevents abuse (10 requests/60 seconds per user)  
✅ **Quota Management**: 429 error handling with user-friendly fallback messages

### Free Tier Optimization:
- **Caching**: Database-level caching reduces redundant API calls by ~80%
- **Hash-Based Deduplication**: Resume analyses cached by file content hash
- **User-Level Roadmaps**: One roadmap per user, retrieved from cache on repeat access
- **Daily Capacity**: ~120-150 Gemini operations without caching, 600-750 with caching

### For Developers:
When setting up your own instance:
1. Obtain a free Gemini API key: https://ai.google.dev/
2. Add to Supabase Edge Function secrets (see Setup step 4)
3. **Never commit API keys to GitHub**
4. Use environment variables for all sensitive credentials

---

## 🧠 Gemini API Integration

### Core Features Powered by Gemini

#### 1. Roadmap Generation (`/functions/v1/generate-roadmap`)
**Prompt Engineering Strategy:**
- **Context Injection**: User profile (career goal, skills, interests, timeline, learning style)
- **Structured Output**: JSON schema with 15-25 progressive nodes
- **Few-Shot Learning**: Example roadmap nodes in prompt for consistency
- **Constraints**: Realistic time estimates, real course URLs, prerequisite chains

**API Configuration:**
```javascript
{
  temperature: 0.7,        // Balanced creativity
  topK: 40,                // Diverse recommendations
  topP: 0.95,              // Quality threshold
  maxOutputTokens: 8192,   // Comprehensive roadmaps
  responseMimeType: "application/json"
}
```

**Sample Prompt Structure:**
```
Generate a personalized career roadmap for:
- Career Goal: Full Stack Developer
- Current Skills: HTML (Beginner), JavaScript (Beginner)
- Target Skills: React (Advanced), Node.js (Advanced)
- Timeline: 6 months
- Interests: Web development, UI/UX

Requirements:
1. Create 15-25 progressive nodes (course/project/skill/milestone)
2. Include prerequisites and difficulty levels
3. Provide real course URLs (Coursera, Udemy, freeCodeCamp)
4. Suggest portfolio-worthy projects
5. Calculate realistic time estimates
6. Output strict JSON format: { roadmap_title, nodes[], skill_gaps[], ... }
```

#### 2. Resume Analysis (`/functions/v1/analyze-resume`)
**Prompt Engineering Strategy:**
- **Multi-Dimensional Analysis**: 6 section scoring (Summary, Experience, Education, Skills, Projects, Formatting)
- **ATS Optimization Focus**: Keyword extraction, formatting checks, action verb analysis
- **Actionable Recommendations**: Specific improvements, not generic advice
- **Role-Aware**: Incorporates target job role and company when provided

**Sample Prompt Structure:**
```
Analyze this resume for ATS compatibility:

RESUME TEXT: [extracted text]
TARGET ROLE: Software Engineer
TARGET COMPANY: Google

Provide:
1. Overall Score (0-100) + ATS Compatibility (0-100)
2. Section analysis with strengths/weaknesses/recommendations
3. Missing keywords for target role
4. Optimized summary rewrite example
5. Better experience bullet examples with metrics
6. Skills to add based on job requirements
7. Output strict JSON: { overall_score, ats_compatibility, sections{}, improvements[], ... }
```

### Why Gemini 2.5 Flash Lite?
- **High RPD Limits**: 1,500 requests/day on free tier (vs. 50 for Pro models)
- **Fast Response Times**: <2 seconds for roadmap generation
- **JSON Mode**: Native structured output (`responseMimeType: "application/json"`)
- **Cost-Effective**: Free tier sufficient for 600-750 cached user interactions/day

---

## 📊 Database Schema

### Core Tables
- **users**: User profiles, XP, levels, coins, streaks
- **roadmap_nodes**: Generated learning paths with positions, rewards, prerequisites
- **resume_analyses**: Cached ATS scores, extracted text, recommendations
- **xp_history**: XP transaction log with sources (course, project, achievement)
- **achievements**: Unlocked milestones with rarity (Common, Rare, Epic, Legendary)
- **leaderboard_cache**: Pre-computed rankings (daily/weekly/monthly/all-time)
- **notifications**: Real-time alerts for level-ups, achievements, milestones
- **user_skills**: Skill proficiency tracking with gap analysis
- **projects**: Community-contributed project templates
- **courses**: Curated course catalog with ratings

---

## 🎨 UI/UX Highlights

- **Glassmorphism Effects**: Modern frosted glass cards (glassmorphism package)
- **Rive Animations**: 3D character animations for level-ups and achievements
- **Lottie Animations**: Smooth loading states and success celebrations
- **Flutter Animate**: Advanced entrance/exit effects and parallax scrolling
- **Confetti Effects**: Celebration animations for milestones
- **Shimmer Loading**: Premium skeleton screens during data fetching
- **Dark/Light Themes**: System-adaptive color schemes
- **Custom Fonts**: Google Fonts integration (Poppins, Inter)

---

## 🏆 Gamification Mechanics

### XP System
- **Formula**: Level = floor(√(XP / 1000)) + 1
- **Level 1 → 2**: 1,000 XP
- **Level 2 → 3**: 4,000 XP
- **Level 5 → 6**: 25,000 XP

### Reward Structure
| Activity | XP | Coins |
|----------|-----|-------|
| Complete Beginner Node | 100-200 | 10-20 |
| Complete Intermediate Node | 200-400 | 20-40 |
| Complete Advanced Node | 400-800 | 40-80 |
| Upload Resume | 50 | 5 |
| Daily Login | 25 | 2 |
| Level Up Bonus | 100 | 50 |
| Achievement Unlock | 50-500 | 10-100 |

### Achievements
- **Milestone**: Reach Level 5, 10, 20, 50
- **Streak**: 7-day, 30-day, 100-day login streaks
- **Skill Master**: Complete all nodes in a skill category
- **Project Pro**: Complete 10 projects
- **Resume Expert**: Upload 5 optimized resumes

---

## 🧪 Testing & Demo

### Test User Accounts
```
Email: demo@mentora@gmail.com
Password: Demo@1234
```

### Demo Flow
1. **Onboarding**: Complete profile setup (career goal, skills, interests)
2. **Roadmap Generation**: AI generates personalized 20-node learning path (~10 seconds)
3. **Resume Upload**: Upload sample resume for ATS analysis (~8 seconds)
4. **Node Completion**: Complete first 3 unlocked nodes, earn XP, level up
5. **Leaderboard**: View rankings and compare progress with peers

### Performance Metrics
- **Roadmap Generation**: 8-12 seconds (including DB storage)
- **Resume Analysis**: 6-10 seconds (including text extraction)
- **Dashboard Load**: <2 seconds with cached data
- **Leaderboard Refresh**: <1 second (pre-computed cache)

---

## 📈 Future Enhancements

- **AI Mentor Chat**: Real-time Q&A with context-aware Gemini chatbot
- **Peer Collaboration**: Team projects and shared roadmaps
- **Video Content**: Embed YouTube tutorials directly in nodes
- **Mobile Notifications**: Push alerts for daily reminders and achievements
- **Social Features**: Follow mentors, share achievements, community forums
- **Advanced Analytics**: Learning pace insights, skill proficiency predictions
- **Premium Features**: 1-on-1 expert sessions, resume templates, certification tracking

---

## 👥 Team

**Pranav Rao K**  
M S Ramaiah University of Applied Sciences, Bengaluru  
GitHub: [@pranavraok](https://github.com/pranavraok)  
Role: Full Stack Development, Flutter UI/UX, Gemini Integration

**Tushar P**  
RV College of Engineering, Bengaluru  
GitHub: [@tung-programming](https://github.com/tung-programming)  
Role: Backend Architecture, Edge Functions, Database Design, API calls

---

## 📄 License

This project is submitted for **Google Gemini APP Development Competition**. All code is original and developed during the hackathon development phase.

---

**Built with ❤️ and ☕ in Bengaluru**