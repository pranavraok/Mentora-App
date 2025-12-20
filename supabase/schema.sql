-- =====================================================
-- AI-POWERED GAMIFIED CAREER PLATFORM - SUPABASE SCHEMA
-- =====================================================
-- Complete PostgreSQL schema with RLS policies
-- Deploy via: psql -h [DB_URL] -f schema.sql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- CORE TABLES
-- =====================================================

-- 1. USERS (Core Profile)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supabase_uid UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    photo_url TEXT,
    college VARCHAR(100),
    major VARCHAR(100),
    graduation_year INTEGER,
    gpa DECIMAL(3,2),
    location VARCHAR(100),
    career_goal VARCHAR(100),
    
    -- Gamification
    current_level INTEGER DEFAULT 1 CHECK (current_level >= 1),
    total_xp BIGINT DEFAULT 0 CHECK (total_xp >= 0),
    total_coins BIGINT DEFAULT 0 CHECK (total_coins >= 0),
    streak_days INTEGER DEFAULT 0 CHECK (streak_days >= 0),
    last_activity TIMESTAMP DEFAULT NOW(),
    last_login_date DATE DEFAULT CURRENT_DATE,
    
    -- Onboarding
    onboarding_complete BOOLEAN DEFAULT false,
    onboarding_data JSONB DEFAULT '{}'::jsonb,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. USER_SKILLS (Current vs Target Proficiency)
CREATE TABLE IF NOT EXISTS user_skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    
    skill_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'Programming', 'Web', 'Data Science', 'Design', etc
    
    current_level VARCHAR(20) DEFAULT 'Beginner', -- 'Beginner', 'Intermediate', 'Advanced', 'Expert'
    target_level VARCHAR(20) DEFAULT 'Advanced',
    
    proficiency_score INTEGER DEFAULT 0 CHECK (proficiency_score BETWEEN 0 AND 100),
    importance_score INTEGER DEFAULT 3 CHECK (importance_score BETWEEN 1 AND 5),
    
    is_gap BOOLEAN DEFAULT false, -- True if target > current
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(user_id, skill_name)
);

-- 3. ROADMAP_NODES (Weavery-style Interactive Roadmap)
CREATE TABLE IF NOT EXISTS roadmap_nodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    
    -- Node Properties
    node_type VARCHAR(50) NOT NULL, -- 'course', 'project', 'skill', 'challenge', 'milestone', 'checkpoint'
    title VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Visual Positioning
    position_x DECIMAL NOT NULL,
    position_y DECIMAL NOT NULL,
    background_theme VARCHAR(50) DEFAULT 'grassland', -- 'grassland', 'forest', 'mountain', 'space', 'ocean'
    icon_url TEXT,
    
    -- Progress Tracking
    status VARCHAR(20) DEFAULT 'locked', -- 'locked', 'unlocked', 'in_progress', 'completed'
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage BETWEEN 0 AND 100),
    
    -- Rewards
    xp_reward INTEGER DEFAULT 100 CHECK (xp_reward >= 0),
    coin_reward INTEGER DEFAULT 10 CHECK (coin_reward >= 0),
    
    -- Metadata
    time_estimate_hours INTEGER,
    difficulty VARCHAR(20), -- 'Beginner', 'Intermediate', 'Advanced'
    
    -- Dependencies (Array of node IDs)
    prerequisites UUID[] DEFAULT ARRAY[]::UUID[],
    required_skills TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    -- Unlock Requirements (JSON)
    unlock_requirements JSONB DEFAULT '{}'::jsonb,
    
    -- Ordering
    order_index INTEGER DEFAULT 0,
    
    -- External Links
    external_url TEXT,
    resource_links TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- 4. PROJECTS (Gamified Project Library)
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Ownership (NULL = global template, UUID = user-owned project from Gemini)
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'Web Dev', 'Mobile', 'Data Science', 'AI/ML', etc
    difficulty VARCHAR(20) NOT NULL, -- 'Beginner', 'Intermediate', 'Advanced'
    
    thumbnail_url TEXT,
    banner_url TEXT,
    
    -- Rewards
    xp_reward INTEGER DEFAULT 200 CHECK (xp_reward >= 0),
    coin_reward INTEGER DEFAULT 50 CHECK (coin_reward >= 0),
    
    -- Requirements
    required_skills TEXT[] DEFAULT ARRAY[]::TEXT[],
    prerequisites UUID[] DEFAULT ARRAY[]::UUID[], -- Other project IDs
    
    -- Time Estimation
    time_estimate_hours INTEGER NOT NULL,
    
    -- Project Structure
    tasks JSONB DEFAULT '[]'::jsonb, -- Step-by-step checklist
    resources JSONB DEFAULT '{}'::jsonb, -- Starter code, docs, APIs
    
    -- Metadata
    completion_count INTEGER DEFAULT 0,
    trending_score INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT false,
    
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 5. USER_PROJECT_PROGRESS (User-specific project tracking)
CREATE TABLE IF NOT EXISTS user_project_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
    
    status VARCHAR(20) DEFAULT 'locked', -- 'locked', 'unlocked', 'in_progress', 'completed', 'verified'
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage BETWEEN 0 AND 100),
    
    -- Submission Data
    github_url TEXT,
    demo_url TEXT,
    submission_data JSONB DEFAULT '{}'::jsonb,
    
    -- Task Completion Tracking
    completed_tasks UUID[] DEFAULT ARRAY[]::UUID[],
    
    -- Timestamps
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(user_id, project_id)
);

-- 6. COURSES (LLM-Recommended Learning Resources)
CREATE TABLE IF NOT EXISTS courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    title VARCHAR(200) NOT NULL,
    platform VARCHAR(50) NOT NULL, -- 'Coursera', 'Udemy', 'YouTube', 'freeCodeCamp', etc
    instructor VARCHAR(100),
    url TEXT NOT NULL,
    
    duration_hours INTEGER,
    difficulty VARCHAR(20), -- 'Beginner', 'Intermediate', 'Advanced'
    
    thumbnail_url TEXT,
    rating DECIMAL(3,2),
    price DECIMAL(10,2) DEFAULT 0.00,
    
    description TEXT,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    skills_covered TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    is_free BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- 7. USER_COURSE_PROGRESS (Course completion tracking)
CREATE TABLE IF NOT EXISTS user_course_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE NOT NULL,
    
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage BETWEEN 0 AND 100),
    
    started_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    certificate_url TEXT,
    
    notes TEXT,
    
    UNIQUE(user_id, course_id)
);

-- 8. ACHIEVEMENTS (Gamification Rewards)
CREATE TABLE IF NOT EXISTS achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    
    achievement_type VARCHAR(50) NOT NULL, -- 'milestone', 'streak', 'project', 'skill', 'social'
    title VARCHAR(100) NOT NULL,
    description TEXT,
    
    rarity VARCHAR(20) DEFAULT 'Common', -- 'Common', 'Rare', 'Epic', 'Legendary'
    icon_url TEXT,
    
    xp_bonus INTEGER DEFAULT 0,
    coin_bonus INTEGER DEFAULT 0,
    
    metadata JSONB DEFAULT '{}'::jsonb,
    
    unlocked_at TIMESTAMP DEFAULT NOW()
);

-- 9. NOTIFICATIONS (Realtime User Updates)
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'achievement', 'deadline', 'unlock', 'level_up', 'social', 'system'
    
    read BOOLEAN DEFAULT false,
    
    action_url TEXT,
    data JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP
);

-- 10. XP_HISTORY (Audit Trail for XP Awards)
CREATE TABLE IF NOT EXISTS xp_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    
    amount INTEGER NOT NULL,
    reason VARCHAR(200) NOT NULL,
    source VARCHAR(50) NOT NULL, -- 'project', 'course', 'daily', 'achievement', 'milestone'
    
    metadata JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- 11. LEADERBOARD_CACHE (Optimized Leaderboard Queries)
CREATE TABLE IF NOT EXISTS leaderboard_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    
    period VARCHAR(20) NOT NULL, -- 'daily', 'weekly', 'monthly', 'all_time'
    category VARCHAR(50) DEFAULT 'overall', -- 'overall', 'projects', 'courses', 'streak'
    
    score BIGINT NOT NULL,
    rank INTEGER,
    
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(user_id, period, category)
);

-- 12. RESUME_ANALYSES (Resume Analysis History)
CREATE TABLE IF NOT EXISTS resume_analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    
    file_url TEXT NOT NULL,
    file_name VARCHAR(200),
    
    overall_score INTEGER CHECK (overall_score BETWEEN 0 AND 100),
    ats_compatibility INTEGER CHECK (ats_compatibility BETWEEN 0 AND 100),
    
    extracted_text TEXT,
    analysis_result JSONB NOT NULL,
    
    improvements TEXT[] DEFAULT ARRAY[]::TEXT[],
    keyword_gaps TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX idx_users_supabase_uid ON users(supabase_uid);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_level_xp ON users(current_level, total_xp DESC);

CREATE INDEX idx_user_skills_user_id ON user_skills(user_id);
CREATE INDEX idx_user_skills_category ON user_skills(category);
CREATE INDEX idx_user_skills_gap ON user_skills(is_gap);

CREATE INDEX idx_roadmap_user_id ON roadmap_nodes(user_id);
CREATE INDEX idx_roadmap_status ON roadmap_nodes(user_id, status);
CREATE INDEX idx_roadmap_type ON roadmap_nodes(node_type);

CREATE INDEX idx_projects_user_id ON projects(user_id);
CREATE INDEX idx_projects_category ON projects(category);
CREATE INDEX idx_projects_difficulty ON projects(difficulty);
CREATE INDEX idx_projects_trending ON projects(trending_score DESC);

CREATE INDEX idx_user_project_user_id ON user_project_progress(user_id);
CREATE INDEX idx_user_project_status ON user_project_progress(status);

CREATE INDEX idx_courses_platform ON courses(platform);
CREATE INDEX idx_courses_free ON courses(is_free);

CREATE INDEX idx_achievements_user_id ON achievements(user_id);
CREATE INDEX idx_achievements_type ON achievements(achievement_type);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, read);

CREATE INDEX idx_xp_history_user_id ON xp_history(user_id);
CREATE INDEX idx_xp_history_created ON xp_history(created_at DESC);

CREATE INDEX idx_leaderboard_period ON leaderboard_cache(period, category, rank);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE roadmap_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_project_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_course_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE xp_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE resume_analyses ENABLE ROW LEVEL SECURITY;

-- USERS: Can view/update own profile
CREATE POLICY "Users can view own profile" 
    ON users FOR SELECT 
    USING (supabase_uid = auth.uid());

CREATE POLICY "Users can update own profile" 
    ON users FOR UPDATE 
    USING (supabase_uid = auth.uid());

CREATE POLICY "Users can insert own profile" 
    ON users FOR INSERT 
    WITH CHECK (supabase_uid = auth.uid());

-- USER_SKILLS: Own data only
CREATE POLICY "Users can manage own skills" 
    ON user_skills FOR ALL 
    USING (user_id IN (SELECT id FROM users WHERE supabase_uid = auth.uid()));

-- ROADMAP_NODES: Own data only
CREATE POLICY "Users can manage own roadmap" 
    ON roadmap_nodes FOR ALL 
    USING (user_id IN (SELECT id FROM users WHERE supabase_uid = auth.uid()));

-- PROJECTS: Public read, authenticated write
CREATE POLICY "Anyone can view projects" 
    ON projects FOR SELECT 
    USING (true);

CREATE POLICY "Service role can manage projects" 
    ON projects FOR ALL 
    USING (auth.role() = 'service_role');

-- USER_PROJECT_PROGRESS: Own data only
CREATE POLICY "Users can manage own project progress" 
    ON user_project_progress FOR ALL 
    USING (user_id IN (SELECT id FROM users WHERE supabase_uid = auth.uid()));

-- COURSES: Public read
CREATE POLICY "Anyone can view courses" 
    ON courses FOR SELECT 
    USING (true);

CREATE POLICY "Service role can manage courses" 
    ON courses FOR ALL 
    USING (auth.role() = 'service_role');

-- USER_COURSE_PROGRESS: Own data only
CREATE POLICY "Users can manage own course progress" 
    ON user_course_progress FOR ALL 
    USING (user_id IN (SELECT id FROM users WHERE supabase_uid = auth.uid()));

-- ACHIEVEMENTS: Own data, public read
CREATE POLICY "Users can view own achievements" 
    ON achievements FOR SELECT 
    USING (user_id IN (SELECT id FROM users WHERE supabase_uid = auth.uid()));

CREATE POLICY "Anyone can view achievements for leaderboard" 
    ON achievements FOR SELECT 
    USING (true);

CREATE POLICY "Service role can create achievements" 
    ON achievements FOR INSERT 
    WITH CHECK (auth.role() = 'service_role');

-- NOTIFICATIONS: Own data only
CREATE POLICY "Users can manage own notifications" 
    ON notifications FOR ALL 
    USING (user_id IN (SELECT id FROM users WHERE supabase_uid = auth.uid()));

-- XP_HISTORY: Own data read, service writes
CREATE POLICY "Users can view own XP history" 
    ON xp_history FOR SELECT 
    USING (user_id IN (SELECT id FROM users WHERE supabase_uid = auth.uid()));

CREATE POLICY "Service role can insert XP" 
    ON xp_history FOR INSERT 
    WITH CHECK (auth.role() = 'service_role');

-- LEADERBOARD_CACHE: Public read
CREATE POLICY "Anyone can view leaderboard" 
    ON leaderboard_cache FOR SELECT 
    USING (true);

CREATE POLICY "Service role can update leaderboard" 
    ON leaderboard_cache FOR ALL 
    USING (auth.role() = 'service_role');

-- RESUME_ANALYSES: Own data only
CREATE POLICY "Users can manage own resume analyses" 
    ON resume_analyses FOR ALL 
    USING (user_id IN (SELECT id FROM users WHERE supabase_uid = auth.uid()));

-- =====================================================
-- TRIGGERS & FUNCTIONS
-- =====================================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER user_skills_updated_at 
    BEFORE UPDATE ON user_skills 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER projects_updated_at 
    BEFORE UPDATE ON projects 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Calculate level from XP
CREATE OR REPLACE FUNCTION calculate_level_from_xp(xp BIGINT)
RETURNS INTEGER AS $$
BEGIN
    -- Exponential formula: level = floor(sqrt(xp / 1000)) + 1
    RETURN FLOOR(SQRT(xp / 1000.0)) + 1;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Update user level on XP change
CREATE OR REPLACE FUNCTION update_user_level()
RETURNS TRIGGER AS $$
BEGIN
    NEW.current_level = calculate_level_from_xp(NEW.total_xp);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_level_update 
    BEFORE UPDATE OF total_xp ON users 
    FOR EACH ROW EXECUTE FUNCTION update_user_level();

-- =====================================================
-- INITIAL SEED DATA (Sample Projects & Courses)
-- =====================================================

-- Sample Projects
INSERT INTO projects (title, description, category, difficulty, xp_reward, coin_reward, time_estimate_hours, required_skills, tasks) VALUES
('Personal Portfolio Website', 'Build a responsive portfolio website showcasing your projects and skills', 'Web Dev', 'Beginner', 150, 30, 8, ARRAY['HTML', 'CSS', 'JavaScript'], 
 '[{"id": "1", "title": "Setup HTML structure", "completed": false}, {"id": "2", "title": "Style with CSS", "completed": false}, {"id": "3", "title": "Add JavaScript interactivity", "completed": false}, {"id": "4", "title": "Deploy to Netlify/Vercel", "completed": false}]'::jsonb),

('REST API with Node.js', 'Create a full-featured REST API with authentication and CRUD operations', 'Backend', 'Intermediate', 300, 75, 16, ARRAY['Node.js', 'Express', 'MongoDB'], 
 '[{"id": "1", "title": "Setup Express server", "completed": false}, {"id": "2", "title": "Create database models", "completed": false}, {"id": "3", "title": "Implement JWT authentication", "completed": false}, {"id": "4", "title": "Add CRUD endpoints", "completed": false}, {"id": "5", "title": "Write API tests", "completed": false}]'::jsonb),

('Machine Learning Image Classifier', 'Build an image classification model using TensorFlow/PyTorch', 'AI/ML', 'Advanced', 500, 150, 24, ARRAY['Python', 'TensorFlow', 'Data Science'], 
 '[{"id": "1", "title": "Prepare dataset", "completed": false}, {"id": "2", "title": "Build CNN model", "completed": false}, {"id": "3", "title": "Train and evaluate", "completed": false}, {"id": "4", "title": "Deploy with Flask API", "completed": false}]'::jsonb);

-- Sample Courses
INSERT INTO courses (title, platform, url, duration_hours, difficulty, is_free, skills_covered, rating) VALUES
('Complete Web Development Bootcamp', 'Udemy', 'https://www.udemy.com/course/the-complete-web-development-bootcamp/', 60, 'Beginner', false, ARRAY['HTML', 'CSS', 'JavaScript', 'Node.js', 'React'], 4.7),
('CS50: Introduction to Computer Science', 'Harvard', 'https://cs50.harvard.edu/', 120, 'Beginner', true, ARRAY['C', 'Python', 'SQL', 'Algorithms'], 4.9),
('Machine Learning Specialization', 'Coursera', 'https://www.coursera.org/specializations/machine-learning-introduction', 80, 'Intermediate', false, ARRAY['Python', 'Machine Learning', 'TensorFlow'], 4.8);

-- =====================================================
-- COMPLETED - Ready for deployment
-- =====================================================
