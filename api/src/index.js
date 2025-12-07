// VOO Citizen App - Production Backend API
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const { MongoClient, ObjectId } = require('mongodb');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');

// Services
const { analyzeIssueImage, enhanceDescription, suggestSolution, chatWithAssistant } = require('./services/openai');
const { uploadImage, uploadMultipleImages, getThumbnailUrl } = require('./services/cloudinary');
const { initFirebase, sendNotification, notifyIssueStatusChange } = require('./services/firebase');
const { sendBursaryApprovalSms, sendIdFoundSms } = require('./services/sms');

const app = express();
const PORT = process.env.PORT || 3001;

// ============ MIDDLEWARE ============
app.use(helmet());
app.use(cors({ origin: process.env.ALLOWED_ORIGINS?.split(',') || '*', credentials: true }));
app.use(express.json({ limit: '50mb' }));
app.use(mongoSanitize());

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100,
    message: { error: 'Too many requests, please try again later' }
});
app.use('/api/', limiter);

// ============ DATABASE ============
let db;
async function connectDB() {
    const client = new MongoClient(process.env.MONGO_URI);
    await client.connect();
    db = client.db('voo_citizen');

    // Create indexes
    await db.collection('app_users').createIndex({ phone: 1 }, { unique: true });
    await db.collection('issues').createIndex({ userId: 1, createdAt: -1 });
    await db.collection('issues').createIndex({ status: 1 });
    await db.collection('issues').createIndex({ 'location.coordinates': '2dsphere' });

    console.log('✅ Connected to MongoDB');
}

// Initialize Firebase
initFirebase();

// ============ AUTH MIDDLEWARE ============
function authMiddleware(req, res, next) {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'No token provided' });

    try {
        req.user = jwt.verify(token, process.env.JWT_SECRET);
        next();
    } catch (err) {
        res.status(401).json({ error: 'Invalid token' });
    }
}

function adminMiddleware(req, res, next) {
    if (req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Admin access required' });
    }
    next();
}

// ============ ISSUE NUMBER GENERATOR ============
async function generateIssueNumber() {
    const year = new Date().getFullYear();
    const count = await db.collection('issues').countDocuments({
        createdAt: { $gte: new Date(`${year}-01-01`) }
    });
    return `ISS-${year}-${String(count + 1).padStart(5, '0')}`;
}

// ============ AUTH ROUTES ============

// Register
app.post('/api/auth/register', async (req, res) => {
    try {
        const { fullName, phone, idNumber, password, ward, fcmToken } = req.body;

        if (!fullName || !phone || !idNumber || !password) {
            return res.status(400).json({ error: 'All fields are required' });
        }

        const existing = await db.collection('app_users').findOne({
            $or: [{ phone }, { idNumber }]
        });
        if (existing) {
            return res.status(400).json({ error: 'Phone or ID already registered' });
        }

        const user = {
            fullName,
            phone: phone.replace(/^0/, '+254'), // Convert 07... to +254...
            idNumber,
            password: await bcrypt.hash(password, 12),
            ward: ward || null,
            role: 'citizen',
            fcmToken: fcmToken || null,
            issuesReported: 0,
            issuesResolved: 0,
            createdAt: new Date(),
            lastLogin: new Date()
        };

        const result = await db.collection('app_users').insertOne(user);

        const token = jwt.sign(
            { userId: result.insertedId, phone: user.phone, role: 'citizen' },
            process.env.JWT_SECRET,
            { expiresIn: '30d' }
        );

        res.json({
            success: true,
            token,
            user: { id: result.insertedId, fullName, phone: user.phone, issuesReported: 0 }
        });
    } catch (error) {
        console.error('Register error:', error);
        res.status(500).json({ error: 'Registration failed' });
    }
});

// Login
app.post('/api/auth/login', async (req, res) => {
    try {
        const { phone, password, fcmToken } = req.body;

        const user = await db.collection('app_users').findOne({
            phone: { $in: [phone, phone.replace(/^0/, '+254')] }
        });

        if (!user || !(await bcrypt.compare(password, user.password))) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Update FCM token and last login
        await db.collection('app_users').updateOne(
            { _id: user._id },
            { $set: { fcmToken: fcmToken || user.fcmToken, lastLogin: new Date() } }
        );

        const token = jwt.sign(
            { userId: user._id, phone: user.phone, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '30d' }
        );

        res.json({
            success: true,
            token,
            user: {
                id: user._id,
                fullName: user.fullName,
                phone: user.phone,
                issuesReported: user.issuesReported,
                issuesResolved: user.issuesResolved
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Login failed' });
    }
});

// ============ AI ROUTES ============

// Analyze image with AI
app.post('/api/ai/analyze-image', authMiddleware, async (req, res) => {
    try {
        const { imageUrl } = req.body;
        if (!imageUrl) return res.status(400).json({ error: 'Image URL required' });

        const analysis = await analyzeIssueImage(imageUrl);
        res.json({ success: true, analysis });
    } catch (error) {
        console.error('AI analyze error:', error);
        res.status(500).json({ error: 'Image analysis failed' });
    }
});

// Enhance description
app.post('/api/ai/enhance-description', authMiddleware, async (req, res) => {
    try {
        const { text, category } = req.body;
        const enhanced = await enhanceDescription(text, category);
        res.json({ success: true, enhancedText: enhanced });
    } catch (error) {
        res.status(500).json({ error: 'Enhancement failed' });
    }
});

// Chat with AI assistant
app.post('/api/ai/chat', authMiddleware, async (req, res) => {
    try {
        const { message } = req.body;
        const reply = await chatWithAssistant(message);
        res.json({ success: true, reply });
    } catch (error) {
        res.status(500).json({ error: 'Chat unavailable' });
    }
});

// ============ IMAGE UPLOAD ============

app.post('/api/upload', authMiddleware, async (req, res) => {
    try {
        const { image } = req.body;
        if (!image) return res.status(400).json({ error: 'Image required' });

        const result = await uploadImage(image);
        res.json({ success: true, ...result });
    } catch (error) {
        console.error('Upload error:', error);
        res.status(500).json({ error: 'Upload failed' });
    }
});

// ============ ISSUES ROUTES ============

const CATEGORIES = [
    'Damaged Roads', 'Broken Streetlights', 'Water/Sanitation',
    'School Infrastructure', 'Healthcare Facilities', 'Security Concerns', 'Other'
];

app.get('/api/issues/categories', (req, res) => {
    res.json({ categories: CATEGORIES });
});

// Create issue with AI processing
app.post('/api/issues', authMiddleware, async (req, res) => {
    try {
        const { title, description, category, urgency, location, images } = req.body;

        // Upload images to Cloudinary
        let uploadedImages = [];
        if (images?.length) {
            uploadedImages = await uploadMultipleImages(images);
        }

        // Analyze first image with AI if available
        let aiAnalysis = null;
        if (uploadedImages.length > 0) {
            aiAnalysis = await analyzeIssueImage(uploadedImages[0].url);
        }

        // Enhance description with AI
        const enhancedDescription = await enhanceDescription(
            description,
            category || aiAnalysis?.category || 'Other'
        );

        // Generate issue number
        const issueNumber = await generateIssueNumber();

        const issue = {
            issueNumber,
            userId: new ObjectId(req.user.userId),
            userPhone: req.user.phone,
            title: title || aiAnalysis?.title || 'Issue Report',
            description,
            aiEnhancedDescription: enhancedDescription,
            category: category || aiAnalysis?.category || 'Other',
            urgency: urgency || aiAnalysis?.urgency || 'medium',
            status: 'new',
            location: {
                type: 'Point',
                coordinates: [location?.lng || 0, location?.lat || 0],
                address: location?.address || ''
            },
            images: uploadedImages.map(img => ({
                url: img.url,
                publicId: img.publicId,
                thumbnail: getThumbnailUrl(img.publicId)
            })),
            aiAnalysis: aiAnalysis ? {
                detectedCategory: aiAnalysis.category,
                confidence: aiAnalysis.confidence,
                suggestedUrgency: aiAnalysis.urgency,
                estimatedResolutionTime: aiAnalysis.estimatedResolutionTime
            } : null,
            timeline: [{
                status: 'new',
                comment: 'Issue submitted',
                timestamp: new Date()
            }],
            upvotes: 0,
            createdAt: new Date(),
            updatedAt: new Date()
        };

        const result = await db.collection('issues').insertOne(issue);

        // Update user stats
        await db.collection('app_users').updateOne(
            { _id: new ObjectId(req.user.userId) },
            { $inc: { issuesReported: 1 } }
        );

        res.json({
            success: true,
            issueId: result.insertedId,
            issueNumber,
            aiAnalysis,
            message: 'Issue reported successfully!'
        });
    } catch (error) {
        console.error('Create issue error:', error);
        res.status(500).json({ error: 'Failed to create issue' });
    }
});

// Get my issues
app.get('/api/issues/my', authMiddleware, async (req, res) => {
    try {
        const { status, page = 1, limit = 20 } = req.query;

        const filter = { userId: new ObjectId(req.user.userId) };
        if (status && status !== 'all') filter.status = status;

        const issues = await db.collection('issues')
            .find(filter)
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit))
            .toArray();

        const total = await db.collection('issues').countDocuments(filter);

        // Get stats
        const stats = await db.collection('issues').aggregate([
            { $match: { userId: new ObjectId(req.user.userId) } },
            { $group: { _id: '$status', count: { $sum: 1 } } }
        ]).toArray();

        res.json({
            issues,
            pagination: { page: parseInt(page), limit: parseInt(limit), total },
            stats: Object.fromEntries(stats.map(s => [s._id, s.count]))
        });
    } catch (error) {
        console.error('Get issues error:', error);
        res.status(500).json({ error: 'Failed to fetch issues' });
    }
});

// Get single issue
app.get('/api/issues/:id', authMiddleware, async (req, res) => {
    try {
        const issue = await db.collection('issues').findOne({
            _id: new ObjectId(req.params.id)
        });

        if (!issue) return res.status(404).json({ error: 'Issue not found' });

        // Get solution suggestion
        const solution = await suggestSolution(issue.category, issue.description);

        res.json({ issue, solution });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch issue' });
    }
});

// Update issue status (Admin only)
app.patch('/api/issues/:id/status', authMiddleware, adminMiddleware, async (req, res) => {
    try {
        const { status, comment } = req.body;

        const issue = await db.collection('issues').findOne({ _id: new ObjectId(req.params.id) });
        if (!issue) return res.status(404).json({ error: 'Issue not found' });

        const update = {
            $set: { status, updatedAt: new Date() },
            $push: {
                timeline: {
                    status,
                    comment: comment || `Status changed to ${status}`,
                    updatedBy: new ObjectId(req.user.userId),
                    timestamp: new Date()
                }
            }
        };

        if (status === 'resolved') {
            update.$set.resolvedAt = new Date();
        }

        await db.collection('issues').updateOne({ _id: new ObjectId(req.params.id) }, update);

        // Notify user
        const user = await db.collection('app_users').findOne({ _id: issue.userId });
        if (user) {
            await notifyIssueStatusChange(user, issue, status);

            if (status === 'resolved') {
                await db.collection('app_users').updateOne(
                    { _id: user._id },
                    { $inc: { issuesResolved: 1 } }
                );
            }
        }

        res.json({ success: true, message: 'Status updated' });
    } catch (error) {
        res.status(500).json({ error: 'Update failed' });
    }
});

// ============ PROFILE ============

app.get('/api/profile', authMiddleware, async (req, res) => {
    try {
        const user = await db.collection('app_users').findOne(
            { _id: new ObjectId(req.user.userId) },
            { projection: { password: 0 } }
        );
        res.json({ user });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch profile' });
    }
});

app.patch('/api/profile/fcm-token', authMiddleware, async (req, res) => {
    try {
        const { fcmToken } = req.body;
        await db.collection('app_users').updateOne(
            { _id: new ObjectId(req.user.userId) },
            { $set: { fcmToken } }
        );
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: 'Update failed' });
    }
});

// ============ BURSARY APPLICATIONS ============

// Generate bursary application number
async function generateBursaryNumber() {
    const year = new Date().getFullYear();
    const count = await db.collection('bursary_applications').countDocuments({
        createdAt: { $gte: new Date(`${year}-01-01`) }
    });
    return `BUR-${year}-${String(count + 1).padStart(5, '0')}`;
}

// Submit bursary application
app.post('/api/bursary/apply', authMiddleware, async (req, res) => {
    try {
        const {
            institutionName, institutionType, admissionNumber,
            course, yearOfStudy, annualFees, amountRequested,
            guardianName, guardianPhone, guardianRelation,
            reason
        } = req.body;

        // Check for existing pending application
        const existing = await db.collection('bursary_applications').findOne({
            userId: new ObjectId(req.user.userId),
            status: 'pending'
        });
        if (existing) {
            return res.status(400).json({ error: 'You already have a pending application' });
        }

        const applicationNumber = await generateBursaryNumber();

        const application = {
            applicationNumber,
            userId: new ObjectId(req.user.userId),
            userPhone: req.user.phone,
            institutionName,
            institutionType: institutionType || 'university',
            admissionNumber,
            course,
            yearOfStudy: parseInt(yearOfStudy) || 1,
            annualFees: parseFloat(annualFees) || 0,
            amountRequested: parseFloat(amountRequested) || 0,
            guardianName,
            guardianPhone,
            guardianRelation,
            reason,
            status: 'pending',
            createdAt: new Date(),
            updatedAt: new Date()
        };

        await db.collection('bursary_applications').insertOne(application);

        res.json({
            success: true,
            applicationNumber,
            message: 'Bursary application submitted successfully!'
        });
    } catch (error) {
        console.error('Bursary apply error:', error);
        res.status(500).json({ error: 'Application submission failed' });
    }
});

// Get my bursary applications
app.get('/api/bursary/my', authMiddleware, async (req, res) => {
    try {
        const applications = await db.collection('bursary_applications')
            .find({ userId: new ObjectId(req.user.userId) })
            .sort({ createdAt: -1 })
            .toArray();

        res.json({ applications });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch applications' });
    }
});

// Get single application
app.get('/api/bursary/:id', authMiddleware, async (req, res) => {
    try {
        const application = await db.collection('bursary_applications').findOne({
            _id: new ObjectId(req.params.id),
            userId: new ObjectId(req.user.userId)
        });

        if (!application) {
            return res.status(404).json({ error: 'Application not found' });
        }

        res.json({ application });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch application' });
    }
});

// Admin: Get all pending applications
app.get('/api/bursary/admin/pending', authMiddleware, adminMiddleware, async (req, res) => {
    try {
        const applications = await db.collection('bursary_applications')
            .find({ status: 'pending' })
            .sort({ createdAt: 1 })
            .toArray();

        res.json({ applications });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch applications' });
    }
});

// Admin: Approve application (sends notification)
app.patch('/api/bursary/:id/approve', authMiddleware, adminMiddleware, async (req, res) => {
    try {
        const { amountApproved, comments } = req.body;

        const application = await db.collection('bursary_applications').findOne({
            _id: new ObjectId(req.params.id)
        });

        if (!application) {
            return res.status(404).json({ error: 'Application not found' });
        }

        await db.collection('bursary_applications').updateOne(
            { _id: new ObjectId(req.params.id) },
            {
                $set: {
                    status: 'approved',
                    amountApproved: parseFloat(amountApproved) || application.amountRequested,
                    approvedBy: new ObjectId(req.user.userId),
                    approvedAt: new Date(),
                    adminComments: comments || '',
                    updatedAt: new Date()
                }
            }
        );

        // Notify user about approval
        const user = await db.collection('app_users').findOne({ _id: application.userId });
        if (user?.fcmToken) {
            await sendNotification(
                user.fcmToken,
                '🎉 Bursary Approved!',
                `Your bursary application ${application.applicationNumber} has been approved. Amount to be communicated.`,
                { type: 'bursary_approved', applicationId: req.params.id }
            );
        }

        // Send SMS notification
        if (user?.phone || application.userPhone) {
            await sendBursaryApprovalSms(user?.phone || application.userPhone, application.applicationNumber);
        }

        res.json({ success: true, message: 'Application approved, SMS sent' });
    } catch (error) {
        console.error('Approve error:', error);
        res.status(500).json({ error: 'Approval failed' });
    }
});

// Admin: Deny application (NO notification - silent denial)
app.patch('/api/bursary/:id/deny', authMiddleware, adminMiddleware, async (req, res) => {
    try {
        const { reason } = req.body;

        await db.collection('bursary_applications').updateOne(
            { _id: new ObjectId(req.params.id) },
            {
                $set: {
                    status: 'denied',
                    deniedBy: new ObjectId(req.user.userId),
                    deniedAt: new Date(),
                    denialReason: reason || '',
                    updatedAt: new Date()
                }
            }
        );

        // NO notification sent for denial - silent rejection
        res.json({ success: true, message: 'Application denied (user not notified)' });
    } catch (error) {
        res.status(500).json({ error: 'Denial failed' });
    }
});

// ============ LOST ID REPORTING ============

// Generate lost ID report number
async function generateLostIdNumber() {
    const year = new Date().getFullYear();
    const count = await db.collection('lost_ids').countDocuments({
        createdAt: { $gte: new Date(`${year}-01-01`) }
    });
    return `LID-${year}-${String(count + 1).padStart(5, '0')}`;
}

// Report lost ID
app.post('/api/lost-id/report', authMiddleware, async (req, res) => {
    try {
        const { idNumber, fullName, dateOfBirth, dateLost, locationLost, circumstances, contactPhone } = req.body;

        if (!idNumber || !fullName) {
            return res.status(400).json({ error: 'ID number and full name are required' });
        }

        // Check for existing report
        const existing = await db.collection('lost_ids').findOne({
            idNumber,
            status: { $in: ['pending', 'processing'] }
        });
        if (existing) {
            return res.status(400).json({ error: 'This ID is already reported as lost' });
        }

        const reportNumber = await generateLostIdNumber();

        const report = {
            reportNumber,
            userId: new ObjectId(req.user.userId),
            idNumber,
            fullName,
            dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
            dateLost: dateLost ? new Date(dateLost) : new Date(),
            locationLost: locationLost || '',
            circumstances: circumstances || '',
            contactPhone: contactPhone || req.user.phone,
            status: 'pending',
            createdAt: new Date(),
            updatedAt: new Date()
        };

        await db.collection('lost_ids').insertOne(report);

        res.json({
            success: true,
            reportNumber,
            message: 'Lost ID reported successfully. You will be notified when found.'
        });
    } catch (error) {
        console.error('Lost ID report error:', error);
        res.status(500).json({ error: 'Report submission failed' });
    }
});

// Get my lost ID reports
app.get('/api/lost-id/my', authMiddleware, async (req, res) => {
    try {
        const reports = await db.collection('lost_ids')
            .find({ userId: new ObjectId(req.user.userId) })
            .sort({ createdAt: -1 })
            .toArray();

        res.json({ reports });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch reports' });
    }
});

// Admin: Update lost ID status (notify only when found)
app.patch('/api/lost-id/:id/status', authMiddleware, adminMiddleware, async (req, res) => {
    try {
        const { status, collectionLocation, adminNotes } = req.body;

        const report = await db.collection('lost_ids').findOne({ _id: new ObjectId(req.params.id) });
        if (!report) return res.status(404).json({ error: 'Report not found' });

        await db.collection('lost_ids').updateOne(
            { _id: new ObjectId(req.params.id) },
            { $set: { status, collectionLocation, adminNotes, updatedAt: new Date() } }
        );

        // Only notify when ID is found
        if (status === 'found') {
            const user = await db.collection('app_users').findOne({ _id: report.userId });
            if (user?.fcmToken) {
                await sendNotification(
                    user.fcmToken,
                    '🎉 Your ID Has Been Found!',
                    `Your ID (${report.idNumber}) has been found. Collect from: ${collectionLocation || 'Contact office'}`,
                    { type: 'id_found', reportId: req.params.id }
                );
            }
        }

        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: 'Update failed' });
    }
});

// ============ ANNOUNCEMENTS ============

// Get announcements (public)
app.get('/api/announcements', async (req, res) => {
    try {
        const announcements = await db.collection('announcements')
            .find({ isActive: true, expiresAt: { $gte: new Date() } })
            .sort({ priority: -1, createdAt: -1 })
            .limit(20)
            .toArray();

        res.json({ announcements });
    } catch (error) {
        res.json({ announcements: [] });
    }
});

// Admin: Create announcement
app.post('/api/announcements', authMiddleware, adminMiddleware, async (req, res) => {
    try {
        const { title, content, category, priority, expiresAt } = req.body;

        const announcement = {
            title,
            content,
            category: category || 'general',
            priority: priority || 0,
            isActive: true,
            createdBy: new ObjectId(req.user.userId),
            expiresAt: expiresAt ? new Date(expiresAt) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            createdAt: new Date()
        };

        await db.collection('announcements').insertOne(announcement);
        res.json({ success: true, message: 'Announcement created' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to create announcement' });
    }
});

// ============ EMERGENCY CONTACTS ============

// Get emergency contacts
app.get('/api/emergency-contacts', async (req, res) => {
    try {
        const contacts = await db.collection('emergency_contacts')
            .find({ isActive: true })
            .sort({ order: 1 })
            .toArray();

        // Default contacts if none exist
        if (contacts.length === 0) {
            return res.json({
                contacts: [
                    { name: 'Police Emergency', phone: '999', category: 'police', icon: 'shield' },
                    { name: 'Ambulance', phone: '112', category: 'medical', icon: 'medical' },
                    { name: 'Fire Brigade', phone: '999', category: 'fire', icon: 'fire' },
                    { name: 'County Office', phone: '+254700000000', category: 'government', icon: 'building' }
                ]
            });
        }

        res.json({ contacts });
    } catch (error) {
        res.json({ contacts: [] });
    }
});

// Admin: Add emergency contact
app.post('/api/emergency-contacts', authMiddleware, adminMiddleware, async (req, res) => {
    try {
        const { name, phone, category, icon, order } = req.body;

        await db.collection('emergency_contacts').insertOne({
            name, phone, category, icon, order: order || 0, isActive: true, createdAt: new Date()
        });

        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: 'Failed to add contact' });
    }
});

// ============ FEEDBACK & COMPLAINTS ============

// Submit feedback
app.post('/api/feedback', authMiddleware, async (req, res) => {
    try {
        const { type, subject, message, rating } = req.body;

        const feedback = {
            userId: new ObjectId(req.user.userId),
            type: type || 'feedback', // feedback, complaint, suggestion
            subject,
            message,
            rating: rating || null, // 1-5 stars
            status: 'new',
            createdAt: new Date()
        };

        await db.collection('feedback').insertOne(feedback);
        res.json({ success: true, message: 'Thank you for your feedback!' });
    } catch (error) {
        res.status(500).json({ error: 'Submission failed' });
    }
});

// Get my feedback
app.get('/api/feedback/my', authMiddleware, async (req, res) => {
    try {
        const feedback = await db.collection('feedback')
            .find({ userId: new ObjectId(req.user.userId) })
            .sort({ createdAt: -1 })
            .toArray();

        res.json({ feedback });
    } catch (error) {
        res.json({ feedback: [] });
    }
});

// ============ HEALTH CHECK ============

app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        services: {
            database: !!db,
            firebase: true
        }
    });
});

// ============ ERROR HANDLER ============

app.use((err, req, res, next) => {
    console.error('Error:', err);

    if (err.name === 'ValidationError') {
        return res.status(400).json({ error: 'Validation error', details: err.errors });
    }
    if (err.name === 'JsonWebTokenError') {
        return res.status(401).json({ error: 'Invalid token' });
    }

    res.status(500).json({ error: 'Internal server error' });
});

// ============ START SERVER ============

connectDB()
    .then(() => {
        app.listen(PORT, () => {
            console.log(`🚀 VOO Citizen API running on port ${PORT}`);
            console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
        });
    })
    .catch(err => {
        console.error('Failed to start:', err);
        process.exit(1);
    });
