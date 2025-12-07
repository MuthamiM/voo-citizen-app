-- VOO Citizen App - Google Auth Migration
-- Run this in your Supabase SQL Editor to add Google auth support
-- https://supabase.com/dashboard/project/xzhmdxtzpuxycvsatjoe/sql/new

-- Add Google auth columns to app_users
ALTER TABLE app_users 
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS google_id TEXT,
ADD COLUMN IF NOT EXISTS photo_url TEXT,
ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'phone';

-- Make phone and id_number optional for Google users
ALTER TABLE app_users 
ALTER COLUMN phone DROP NOT NULL,
ALTER COLUMN id_number DROP NOT NULL,
ALTER COLUMN password_hash DROP NOT NULL;

-- Add unique constraint on google_id
CREATE UNIQUE INDEX IF NOT EXISTS idx_app_users_google_id ON app_users(google_id) WHERE google_id IS NOT NULL;

-- Add index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_app_users_email ON app_users(email);

-- Add app_config table for version checking
CREATE TABLE IF NOT EXISTS app_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert initial config values
INSERT INTO app_config (key, value) VALUES
  ('min_version', '1.0.0'),
  ('download_url', 'https://github.com/MuthamiM/voo-citizen-app/releases/latest')
ON CONFLICT (key) DO NOTHING;

-- Create RLS policy for app_config (public read)
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read on app_config" ON app_config FOR SELECT USING (true);
