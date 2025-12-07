-- Add columns for Google/social auth to app_users table
-- Run this in Supabase SQL Editor

ALTER TABLE app_users ADD COLUMN IF NOT EXISTS email TEXT UNIQUE;
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS google_id TEXT UNIQUE;
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'phone';

-- Make phone and id_number nullable for Google users
ALTER TABLE app_users ALTER COLUMN phone DROP NOT NULL;
ALTER TABLE app_users ALTER COLUMN id_number DROP NOT NULL;
ALTER TABLE app_users ALTER COLUMN password_hash DROP NOT NULL;

-- Create index on email and google_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_app_users_email ON app_users(email);
CREATE INDEX IF NOT EXISTS idx_app_users_google_id ON app_users(google_id);
