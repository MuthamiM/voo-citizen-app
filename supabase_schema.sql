-- VOO Citizen App - Supabase Database Schema
-- Run this in your Supabase SQL Editor at:
-- https://supabase.com/dashboard/project/xzhmdxtzpuxycvsatjoe/sql/new

-- 1. Users Table
CREATE TABLE app_users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  id_number TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  village TEXT,
  ward TEXT DEFAULT 'Kyamatu',
  fcm_token TEXT,
  issues_reported INTEGER DEFAULT 0,
  issues_resolved INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Issues Table
CREATE TABLE issues (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  issue_number TEXT UNIQUE NOT NULL,
  user_id UUID REFERENCES app_users(id),
  user_phone TEXT,
  title TEXT NOT NULL,
  description TEXT,
  enhanced_description TEXT,
  category TEXT NOT NULL,
  urgency TEXT DEFAULT 'medium',
  status TEXT DEFAULT 'pending',
  images TEXT[],
  location JSONB,
  assigned_team TEXT,
  resolution_notes TEXT,
  resolution_images TEXT[],
  upvotes INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Issue Timeline Table
CREATE TABLE issue_timeline (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  issue_id UUID REFERENCES issues(id) ON DELETE CASCADE,
  status TEXT NOT NULL,
  note TEXT,
  updated_by TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Bursary Applications Table
CREATE TABLE bursary_applications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES app_users(id),
  institution_name TEXT NOT NULL,
  course TEXT NOT NULL,
  year_of_study TEXT NOT NULL,
  institution_type TEXT,
  reason TEXT,
  status TEXT DEFAULT 'pending',
  amount_requested NUMERIC,
  amount_approved NUMERIC DEFAULT 0,
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Announcements Table
CREATE TABLE announcements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  priority TEXT DEFAULT 'normal',
  target_audience TEXT DEFAULT 'all',
  created_by TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Emergency Contacts Table
CREATE TABLE emergency_contacts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  icon TEXT,
  is_active BOOLEAN DEFAULT true
);

-- Seed emergency contacts
INSERT INTO emergency_contacts (name, phone, icon) VALUES
  ('Police Emergency', '999', 'shield'),
  ('Ambulance', '112', 'medical_services'),
  ('Fire Brigade', '999', 'local_fire_department'),
  ('County Office', '+254700000000', 'business');

-- Enable Row Level Security (optional but recommended)
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE bursary_applications ENABLE ROW LEVEL SECURITY;

-- Create indexes for performance
CREATE INDEX idx_issues_user_id ON issues(user_id);
CREATE INDEX idx_issues_status ON issues(status);
CREATE INDEX idx_bursary_user_id ON bursary_applications(user_id);

-- 7. App Config Table (for app updates and settings)
CREATE TABLE app_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed app config for update management
INSERT INTO app_config (key, value) VALUES 
  ('min_version', '7.0.0'),
  ('download_url', 'https://github.com/MuthamiM/voo-citizen-app/releases/download/v7.0/VOO-Citizen-App-v7.0.apk'),
  ('latest_version', '7.0.0');
