// VOO Citizen App - Backend API with OpenAI
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { MongoClient, ObjectId } = require('mongodb');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const OpenAI = require('openai');

const app = express();
const PORT = process.env.PORT || 3001;

// OpenAI Client
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));

// MongoDB Connection
let db;
async function connectDB() {
    const client = new MongoClient(process.env.MONGO_URI);
    await client.connect();
    db = client.db('voo_ward');
    console.log('✅ Connected to MongoDB');
}

// JWT Middleware
function authMiddleware(req, res, next) {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'No token provided' });
    try {
        req.user = jwt.verify(token, process.env.JWT_SECRET || 'voo-secret');
        next();
    } catch (err) {
        res.status(401).json({ error: 'Invalid token' });
    }
}

// Upload to ImgBB (free image hosting)
async function uploadToImgBB(base64Image) {
    try {
        const res = await axios.post('https://api.imgbb.com/1/upload', null, {
            params: { key: process.env.IMGBB_API_KEY, image: base64Image.replace(/^data:image\/\w+;base64,/, '') }
        });
        return res.data.data.url;
    } catch (e) { return null; }
}

// ============ OPENAI AI FEATURES ============
async function suggestCategory(description) {
    try {
        const res = await openai.chat.completions.create({
            model: 'gpt-3.5-turbo',
            messages: [
                { role: 'system', content: 'Categorize this civic issue. Reply with ONLY one: Damaged Roads, Broken Streetlights, Water/Sanitation, School Infrastructure, Healthcare Facilities, Security Concerns, Other' },
                { role: 'user', content: description }
            ],
            max_tokens: 20
        });
        return res.choices[0].message.content.trim();
    } catch (e) { return 'Other'; }
}

// AI Chat endpoint
app.post('/api/ai/chat', authMiddleware, async (req, res) => {
    try {
        const response = await openai.chat.completions.create({
            model: 'gpt-3.5-turbo',
            messages: [
                { role: 'system', content: 'You are VOO Assistant, a helpful civic engagement chatbot for VOO Ward platform in Kenya. Help citizens report issues and understand local services. Be friendly and concise.' },
                { role: 'user', content: req.body.message }
            ],
            max_tokens: 300
        });
        res.json({ reply: response.choices[0].message.content });
    } catch (e) { res.status(500).json({ error: 'AI unavailable' }); }
});

// AI Suggest Category
app.post('/api/ai/suggest-category', authMiddleware, async (req, res) => {
    const category = await suggestCategory(req.body.description);
    res.json({ category });
});

// ============ AUTH ROUTES ============
app.post('/api/auth/register', async (req, res) => {
    try {
        const { fullName, phone, idNumber, password } = req.body;
        const existing = await db.collection('app_users').findOne({ $or: [{ phone }, { idNumber }] });
        if (existing) return res.status(400).json({ error: 'Phone or ID already registered' });

        const user = {
            fullName, phone, idNumber,
            password: await bcrypt.hash(password, 10),
            createdAt: new Date(),
            issuesReported: 0
        };
        const result = await db.collection('app_users').insertOne(user);
        const token = jwt.sign({ userId: result.insertedId, phone }, process.env.JWT_SECRET || 'voo-secret', { expiresIn: '30d' });
        res.json({ success: true, token, user: { fullName, phone, idNumber } });
    } catch (e) { res.status(500).json({ error: 'Registration failed' }); }
});

app.post('/api/auth/login', async (req, res) => {
    try {
        const { phone, password } = req.body;
        const user = await db.collection('app_users').findOne({ phone });
        if (!user || !(await bcrypt.compare(password, user.password))) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        const token = jwt.sign({ userId: user._id, phone }, process.env.JWT_SECRET || 'voo-secret', { expiresIn: '30d' });
        res.json({ success: true, token, user: { fullName: user.fullName, phone: user.phone, issuesReported: user.issuesReported || 0 } });
    } catch (e) { res.status(500).json({ error: 'Login failed' }); }
});

// ============ ISSUES ROUTES ============
const CATEGORIES = ['Damaged Roads', 'Broken Streetlights', 'Water/Sanitation', 'School Infrastructure', 'Healthcare Facilities', 'Security Concerns', 'Other'];

app.get('/api/issues/categories', (req, res) => res.json({ categories: CATEGORIES }));

app.post('/api/issues', authMiddleware, async (req, res) => {
    try {
        const { title, description, category, location, images } = req.body;
        const imageUrls = [];
        if (images?.length) {
            for (const img of images.slice(0, 5)) {
                const url = await uploadToImgBB(img);
                if (url) imageUrls.push(url);
            }
        }
        const issue = {
            title, description, category,
            location: { address: location?.address || '', lat: location?.lat, lng: location?.lng },
            images: imageUrls,
            status: 'pending',
            reportedBy: new ObjectId(req.user.userId),
            reporterPhone: req.user.phone,
            createdAt: new Date(),
            source: 'mobile_app'
        };
        const result = await db.collection('issues').insertOne(issue);
        await db.collection('app_users').updateOne({ _id: new ObjectId(req.user.userId) }, { $inc: { issuesReported: 1 } });
        res.json({ success: true, issueId: result.insertedId });
    } catch (e) { res.status(500).json({ error: 'Failed to report issue' }); }
});

app.get('/api/issues/my', authMiddleware, async (req, res) => {
    const issues = await db.collection('issues').find({ reportedBy: new ObjectId(req.user.userId) }).sort({ createdAt: -1 }).toArray();
    res.json({ issues });
});

app.get('/api/issues/:id', authMiddleware, async (req, res) => {
    const issue = await db.collection('issues').findOne({ _id: new ObjectId(req.params.id) });
    issue ? res.json({ issue }) : res.status(404).json({ error: 'Not found' });
});

app.get('/api/profile', authMiddleware, async (req, res) => {
    const user = await db.collection('app_users').findOne({ _id: new ObjectId(req.user.userId) }, { projection: { password: 0 } });
    res.json({ user });
});

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

// Start server
connectDB().then(() => app.listen(PORT, () => console.log(`🚀 VOO API on port ${PORT}`))).catch(e => process.exit(1));
