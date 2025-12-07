// OpenAI Service - Image Analysis & Text Enhancement
const OpenAI = require('openai');

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// Analyze issue image with GPT-4 Vision
async function analyzeIssueImage(imageUrl) {
    try {
        const response = await openai.chat.completions.create({
            model: "gpt-4o",
            messages: [
                {
                    role: "system",
                    content: `You are an expert at analyzing civic infrastructure issues in Kenya.
                    Analyze the image and return JSON with:
                    - category: one of [Damaged Roads, Broken Streetlights, Water/Sanitation, School Infrastructure, Healthcare Facilities, Security Concerns, Other]
                    - title: short descriptive title (max 60 chars)
                    - description: detailed description of the issue (100-150 words)
                    - urgency: one of [low, medium, high, critical]
                    - confidence: 0-100 percentage of how confident you are
                    - estimatedResolutionTime: estimated time to fix (e.g. "2-3 days")`
                },
                {
                    role: "user",
                    content: [
                        { type: "image_url", image_url: { url: imageUrl } },
                        { type: "text", text: "Analyze this civic issue image and categorize it." }
                    ]
                }
            ],
            max_tokens: 500,
            response_format: { type: "json_object" }
        });

        return JSON.parse(response.choices[0].message.content);
    } catch (error) {
        console.error('OpenAI Vision error:', error.message);
        return {
            category: 'Other',
            title: 'Issue Report',
            description: 'Unable to analyze image automatically',
            urgency: 'medium',
            confidence: 0
        };
    }
}

// Enhance issue description
async function enhanceDescription(originalText, category) {
    try {
        const response = await openai.chat.completions.create({
            model: "gpt-4o",
            messages: [
                {
                    role: "system",
                    content: `You are a helpful assistant that improves civic issue reports for ${category}.
                    Enhance the description to be:
                    - Clear and professional
                    - Include technical details if visible
                    - Maintain original meaning
                    - Add safety concerns if relevant
                    - Keep under 150 words
                    Return only the enhanced text, no quotes or labels.`
                },
                { role: "user", content: originalText }
            ],
            max_tokens: 300
        });

        return response.choices[0].message.content.trim();
    } catch (error) {
        console.error('OpenAI enhance error:', error.message);
        return originalText;
    }
}

// Suggest solution for issue
async function suggestSolution(issueType, description) {
    try {
        const response = await openai.chat.completions.create({
            model: "gpt-4o",
            messages: [
                {
                    role: "system",
                    content: `You are a civic infrastructure expert in Kenya. Suggest solutions for issues.
                    Return JSON with:
                    - estimatedTime: time to resolve (e.g. "3-5 days")
                    - requiredResources: array of resources needed
                    - suggestedActions: array of step-by-step actions
                    - priority: low/medium/high/critical
                    - responsibleDepartment: which govt department handles this`
                },
                { role: "user", content: `Issue Type: ${issueType}\nDescription: ${description}` }
            ],
            max_tokens: 400,
            response_format: { type: "json_object" }
        });

        return JSON.parse(response.choices[0].message.content);
    } catch (error) {
        console.error('OpenAI solution error:', error.message);
        return null;
    }
}

// Chat assistant
async function chatWithAssistant(message, context = '') {
    try {
        const response = await openai.chat.completions.create({
            model: "gpt-4o",
            messages: [
                {
                    role: "system",
                    content: `You are VOO Assistant, a helpful civic engagement chatbot for VOO Ward platform in Kenya.
                    Help citizens:
                    - Report community issues
                    - Track their reported issues
                    - Understand local government processes
                    - Get information about services
                    Be friendly, concise, and helpful. Speak in simple English.
                    ${context ? `User context: ${context}` : ''}`
                },
                { role: "user", content: message }
            ],
            max_tokens: 300
        });

        return response.choices[0].message.content;
    } catch (error) {
        console.error('OpenAI chat error:', error.message);
        return "I'm having trouble connecting. Please try again.";
    }
}

module.exports = {
    analyzeIssueImage,
    enhanceDescription,
    suggestSolution,
    chatWithAssistant
};
