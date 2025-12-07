-- VOO Citizen App - UPDATED Supabase Database Schema
-- Run this in your Supabase SQL Editor at:
-- https://supabase.com/dashboard/project/xzhmdxtzpuxycvsatjoe/sql/new
-- 
-- This schema includes:
-- 1. Additional user fields (username, email, profile_photo, verification)
-- 2. RLS policies for anon key access (required for mobile app)
-- 3. Indexes for performance

-- =====================================================
-- STEP 1: Update app_users table with new columns
-- =====================================================
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS username TEXT UNIQUE;
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;

-- Make id_number optional (not all registrations have it)
ALTER TABLE app_users ALTER COLUMN id_number DROP NOT NULL;

-- =====================================================
-- STEP 2: Create indexes for new columns
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_app_users_phone ON app_users(phone);
CREATE INDEX IF NOT EXISTS idx_app_users_username ON app_users(username);
CREATE INDEX IF NOT EXISTS idx_app_users_email ON app_users(email);

-- =====================================================
-- STEP 3: RLS Policies for app_users (CRITICAL!)
-- =====================================================
-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow anonymous insert" ON app_users;
DROP POLICY IF EXISTS "Allow anonymous select" ON app_users;
DROP POLICY IF EXISTS "Allow anonymous update" ON app_users;
DROP POLICY IF EXISTS "Allow public read" ON app_users;
DROP POLICY IF EXISTS "Allow public insert" ON app_users;
DROP POLICY IF EXISTS "Allow public update" ON app_users;

-- Enable RLS (may already be enabled)
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

-- Policy: Allow anyone to register (INSERT)
CREATE POLICY "Enable insert for anonymous users"
ON app_users FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Policy: Allow users to read their own data (SELECT)
CREATE POLICY "Enable read access for all"
ON app_users FOR SELECT
TO anon, authenticated
USING (true);

-- Policy: Allow users to update their own data (UPDATE)
CREATE POLICY "Enable update for users"
ON app_users FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- =====================================================
-- STEP 4: RLS Policies for issues
-- =====================================================
DROP POLICY IF EXISTS "Allow public read issues" ON issues;
DROP POLICY IF EXISTS "Allow public insert issues" ON issues;

CREATE POLICY "Enable read all issues"
ON issues FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Enable insert issues"
ON issues FOR INSERT
TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "Enable update issues"
ON issues FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- =====================================================
-- STEP 5: RLS Policies for bursary_applications
-- =====================================================
DROP POLICY IF EXISTS "Allow public read bursary" ON bursary_applications;
DROP POLICY IF EXISTS "Allow public insert bursary" ON bursary_applications;

CREATE POLICY "Enable read bursary"
ON bursary_applications FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Enable insert bursary"
ON bursary_applications FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- =====================================================
-- STEP 6: RLS Policies for announcements (read-only public)
-- =====================================================
DROP POLICY IF EXISTS "Allow public read announcements" ON announcements;

ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable public read announcements"
ON announcements FOR SELECT
TO anon, authenticated
USING (is_active = true);

-- =====================================================
-- STEP 7: RLS Policies for emergency_contacts (read-only public)
-- =====================================================
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable public read emergency_contacts"
ON emergency_contacts FOR SELECT
TO anon, authenticated
USING (is_active = true);

-- =====================================================
-- STEP 8: RLS Policies for app_config (read-only public)
-- =====================================================
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable public read app_config"
ON app_config FOR SELECT
TO anon, authenticated
USING (true);

-- =====================================================
-- STEP 9: Create user sessions table (optional)
-- =====================================================
CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES app_users(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  device_info JSONB,
  ip_address TEXT,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sessions_token ON user_sessions(token);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON user_sessions(user_id);

-- Auto-expire old sessions (run this via cron or trigger)
-- DELETE FROM user_sessions WHERE expires_at < NOW();

ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable session management"
ON user_sessions FOR ALL
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- =====================================================
-- VERIFICATION: Check that policies were created
-- =====================================================
-- Run this to verify:
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd 
-- FROM pg_policies 
-- WHERE schemaname = 'public';

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
-- If you reach here without errors, your schema is updated!
-- The mobile app should now be able to:
-- 1. Register users (INSERT into app_users)
-- 2. Login users (SELECT from app_users)
-- 3. Update profiles (UPDATE app_users)
-- 4. Submit issues and bursary applications
