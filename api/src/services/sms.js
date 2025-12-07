// SMS Service - Africa's Talking (or Termii)
const axios = require('axios');

// SMS configuration
const SMS_PROVIDER = process.env.SMS_PROVIDER || 'africastalking'; // or 'termii'
const AT_API_KEY = process.env.AFRICASTALKING_API_KEY;
const AT_USERNAME = process.env.AFRICASTALKING_USERNAME || 'sandbox';
const TERMII_API_KEY = process.env.TERMII_API_KEY;
const TERMII_SENDER_ID = process.env.TERMII_SENDER_ID || 'VOO';

// Send SMS via Africa's Talking
async function sendATSms(phone, message) {
    try {
        const response = await axios.post(
            'https://api.africastalking.com/version1/messaging',
            `username=${AT_USERNAME}&to=${phone}&message=${encodeURIComponent(message)}`,
            {
                headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'apiKey': AT_API_KEY
                }
            }
        );
        console.log('SMS sent via AT:', response.data);
        return { success: true, provider: 'africastalking' };
    } catch (error) {
        console.error('AT SMS error:', error.message);
        return { success: false, error: error.message };
    }
}

// Send SMS via Termii
async function sendTermiiSms(phone, message) {
    try {
        const response = await axios.post('https://api.ng.termii.com/api/sms/send', {
            to: phone,
            from: TERMII_SENDER_ID,
            sms: message,
            type: 'plain',
            api_key: TERMII_API_KEY,
            channel: 'generic'
        });
        console.log('SMS sent via Termii:', response.data);
        return { success: true, provider: 'termii' };
    } catch (error) {
        console.error('Termii SMS error:', error.message);
        return { success: false, error: error.message };
    }
}

// Main SMS function
async function sendSms(phone, message) {
    // Normalize phone number
    let normalizedPhone = phone.replace(/\s/g, '');
    if (normalizedPhone.startsWith('0')) {
        normalizedPhone = '+254' + normalizedPhone.slice(1);
    }
    if (!normalizedPhone.startsWith('+')) {
        normalizedPhone = '+' + normalizedPhone;
    }

    if (SMS_PROVIDER === 'termii') {
        return sendTermiiSms(normalizedPhone, message);
    }
    return sendATSms(normalizedPhone, message);
}

// Bursary approval SMS
async function sendBursaryApprovalSms(phone, applicationNumber) {
    const message = `VOO Citizen: Your bursary application ${applicationNumber} has been APPROVED! Amount to be communicated. Visit ward office for details.`;
    return sendSms(phone, message);
}

// Lost ID found SMS
async function sendIdFoundSms(phone, location) {
    const message = `VOO Citizen: Your lost ID has been FOUND! Collect from: ${location}. Bring original documents.`;
    return sendSms(phone, message);
}

module.exports = {
    sendSms,
    sendBursaryApprovalSms,
    sendIdFoundSms
};
