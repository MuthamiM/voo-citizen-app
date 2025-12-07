-- Run this in Supabase SQL Editor to update app version
-- Go to: https://supabase.com/dashboard → Select Project → SQL Editor

-- First, check what's in app_config
SELECT * FROM app_config;

-- Insert or Update min_version
INSERT INTO app_config (key, value) 
VALUES ('min_version', '11.0.6')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- Insert or Update download_url
INSERT INTO app_config (key, value) 
VALUES ('download_url', 'https://github.com/MuthamiM/voo-citizen-app/releases/download/v9.5.0/VOO-Citizen-App-v9.5.apk')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- Verify the updates
SELECT * FROM app_config;
