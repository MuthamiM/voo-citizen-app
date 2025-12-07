// Update Supabase app_config for v9.5.0 release
const https = require('https');

const supabaseUrl = 'xzhmdxtzpuxycvsatjoe.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6aG1keHR6cHV4eWN2c2F0am9lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxNTYwNzAsImV4cCI6MjA4MDczMjA3MH0.2tZ7eu6DtBg2mSOitpRa4RNvgCGg3nvMWeDmn9fPJY0';

async function updateConfig(key, value) {
    return new Promise((resolve, reject) => {
        const data = JSON.stringify({ value });

        const options = {
            hostname: supabaseUrl,
            path: `/rest/v1/app_config?key=eq.${key}`,
            method: 'PATCH',
            headers: {
                'apikey': supabaseKey,
                'Authorization': `Bearer ${supabaseKey}`,
                'Content-Type': 'application/json',
                'Prefer': 'return=representation',
                'Content-Length': Buffer.byteLength(data)
            }
        };

        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                console.log(`Updated ${key}: Status ${res.statusCode}`);
                console.log('Response:', body || '(empty)');
                resolve({ status: res.statusCode, body });
            });
        });

        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

async function main() {
    console.log('Updating Supabase app_config for v9.5.0...\n');

    // Update min_version to 9.5.0 (forces v7.0/v8.0 to update)
    await updateConfig('min_version', '9.5.0');

    // Update download URL to new release
    await updateConfig('download_url', 'https://github.com/MuthamiM/voo-citizen-app/releases/download/v9.5.0/VOO-Citizen-App-v9.5.apk');

    console.log('\nDone! Fetching current config...\n');

    // Verify
    https.get(`https://${supabaseUrl}/rest/v1/app_config?select=*`, {
        headers: { 'apikey': supabaseKey }
    }, (res) => {
        let data = '';
        res.on('data', (c) => data += c);
        res.on('end', () => {
            console.log('Current app_config:');
            console.log(JSON.stringify(JSON.parse(data), null, 2));
        });
    });
}

main();
