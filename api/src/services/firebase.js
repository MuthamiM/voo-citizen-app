// Firebase Service - Push Notifications
const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
let firebaseInitialized = false;

function initFirebase() {
    if (firebaseInitialized) return;

    try {
        const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './firebase-service-account.json';
        const serviceAccount = require(path.resolve(serviceAccountPath));

        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });

        firebaseInitialized = true;
        console.log('✅ Firebase Admin initialized');
    } catch (error) {
        console.error('Firebase init error:', error.message);
    }
}

// Send notification to single device
async function sendNotification(fcmToken, title, body, data = {}) {
    if (!firebaseInitialized) initFirebase();

    try {
        const message = {
            notification: { title, body },
            data: {
                ...data,
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            token: fcmToken
        };

        const response = await admin.messaging().send(message);
        console.log('Notification sent:', response);
        return { success: true, messageId: response };
    } catch (error) {
        console.error('Send notification error:', error.message);
        return { success: false, error: error.message };
    }
}

// Send notification to multiple devices
async function sendMulticastNotification(fcmTokens, title, body, data = {}) {
    if (!firebaseInitialized) initFirebase();

    try {
        const message = {
            notification: { title, body },
            data: {
                ...data,
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            tokens: fcmTokens
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`Sent to ${response.successCount}/${fcmTokens.length} devices`);
        return response;
    } catch (error) {
        console.error('Multicast notification error:', error.message);
        return null;
    }
}

// Notify user about issue status change
async function notifyIssueStatusChange(user, issue, newStatus) {
    if (!user.fcmToken) return;

    const statusMessages = {
        'in_progress': {
            title: '🔄 Issue Being Addressed',
            body: `Your issue "${issue.title}" is now being worked on!`
        },
        'resolved': {
            title: '✅ Issue Resolved!',
            body: `Great news! "${issue.title}" has been resolved.`
        },
        'rejected': {
            title: '❌ Issue Update',
            body: `Your issue "${issue.title}" requires more information.`
        }
    };

    const message = statusMessages[newStatus] || {
        title: '📋 Issue Update',
        body: `Status update for "${issue.title}"`
    };

    return sendNotification(user.fcmToken, message.title, message.body, {
        type: 'status_update',
        issueId: issue._id.toString(),
        status: newStatus
    });
}

// Subscribe to topic
async function subscribeToTopic(fcmToken, topic) {
    if (!firebaseInitialized) initFirebase();

    try {
        await admin.messaging().subscribeToTopic(fcmToken, topic);
        return true;
    } catch (error) {
        console.error('Subscribe error:', error.message);
        return false;
    }
}

module.exports = {
    initFirebase,
    sendNotification,
    sendMulticastNotification,
    notifyIssueStatusChange,
    subscribeToTopic
};
