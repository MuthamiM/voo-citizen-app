-- Force update for all users below 10.0.0
UPDATE app_config 
SET value = '10.0.0' 
WHERE key = 'min_version';

-- Set the download URL to the new Release v10.0.0
UPDATE app_config 
SET value = 'https://github.com/MuthamiM/voo-citizen-app/releases/download/v10.0.0/app-release.apk' 
WHERE key = 'download_url';

-- Verify the changes
SELECT * FROM app_config;
