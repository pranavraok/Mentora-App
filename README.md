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
