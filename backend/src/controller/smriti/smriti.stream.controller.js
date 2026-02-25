import { GoogleGenAI } from '@google/genai';
import config from '../../../config.js';
import { validationResult } from 'express-validator';

const SYSTEM_PROMPT = `You are Smriti, a warm Alzheimer's & Dementia Care companion.

RULES:
- ONLY discuss Alzheimer's, dementia, memory, elderly care, caregiving, or engage in reminiscence therapy. Politely decline unrelated topics.
- Never diagnose or prescribe. Suggest consulting healthcare professionals when needed.
- Keep answers concise (2-4 paragraphs). Use simple, calm language.
- If user seems confused or frustrated: acknowledge feelings first, simplify, be reassuring.
- Use patient context naturally: reference name, family, activities personally.
- If mode is "memoryLane": Be a reminiscence therapy companion. Gently explore the patient's past — wedding, childhood, favorite foods, school, hobbies, family traditions. Use family names. Celebrate every memory.
- End every response with a warm reminiscence question on a new line starting with "💭" (about wedding day, childhood, food, family traditions). Use family names if available.`;

function buildContextBlock(context) {
    if (!context) return '';
    const parts = [];
    if (context.patientName) parts.push(`Patient: ${context.patientName}`);
    if (context.stage) parts.push(`Stage: ${context.stage}`);
    if (context.dob) parts.push(`DOB: ${context.dob}`);
    if (context.familyMembers && context.familyMembers.length > 0) {
        const familyStr = context.familyMembers.map(m => `${m.name} (${m.relation})`).join(', ');
        parts.push(`Family: ${familyStr}`);
    }
    if (context.recentActivities) {
        const a = context.recentActivities;
        if (a.streakDays != null) parts.push(`Current streak: ${a.streakDays} days`);
        if (a.reminders && a.reminders.length > 0) {
            parts.push(`Active reminders: ${a.reminders.join(', ')}`);
        }
    }
    if (context.mode === 'memoryLane') parts.push('MODE: memoryLane (reminiscence therapy active)');
    return parts.length > 0 ? `\n\nPATIENT CONTEXT:\n${parts.join('. ')}.` : '';
}

async function smritiStream(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { query, context, history } = req.body;

        if (!query) {
            return res.status(400).json({ error: 'Query input is required' });
        }

        const ai = new GoogleGenAI({ apiKey: config.gemini.apiKey });
        const contextBlock = buildContextBlock(context);

        const aiConfig = {
            temperature: 1.0,
            maxOutputTokens: 1000,
            thinkingConfig: {
                thinkingLevel: 'low',
            },
            systemInstruction: [{ text: SYSTEM_PROMPT + contextBlock }],
        };

        const model = 'gemini-3-flash-preview';

        // Build conversation contents with last 20 messages
        const contents = [];
        if (history && Array.isArray(history)) {
            const recentHistory = history.slice(-20);
            for (const msg of recentHistory) {
                contents.push({
                    role: msg.role === 'user' ? 'user' : 'model',
                    parts: [{ text: msg.text }],
                });
            }
        }
        contents.push({ role: 'user', parts: [{ text: query }] });

        // Set SSE headers
        res.setHeader('Content-Type', 'text/event-stream');
        res.setHeader('Cache-Control', 'no-cache');
        res.setHeader('Connection', 'keep-alive');
        res.setHeader('X-Accel-Buffering', 'no');
        res.flushHeaders();

        const response = await ai.models.generateContentStream({
            model,
            config: aiConfig,
            contents,
        });

        for await (const chunk of response) {
            // Extract text from chunk — handle both SDK formats
            let text = '';
            if (typeof chunk.text === 'string') {
                text = chunk.text;
            } else if (typeof chunk.text === 'function') {
                text = chunk.text();
            } else if (chunk.candidates?.[0]?.content?.parts?.[0]?.text) {
                text = chunk.candidates[0].content.parts[0].text;
            }

            if (text) {
                res.write(`data: ${JSON.stringify({ text })}\n\n`);
            }
        }

        res.write(`data: [DONE]\n\n`);
        res.end();

    } catch (error) {
        console.error("Smriti stream error:", error.message);
        if (res.headersSent) {
            res.write(`data: ${JSON.stringify({ error: "Sorry, I'm having trouble right now. Please try again." })}\n\n`);
            res.write(`data: [DONE]\n\n`);
            res.end();
        } else {
            // Return proper HTTP error so iOS fallback kicks in
            const statusCode = error.status || error.code || 500;
            res.status(typeof statusCode === 'number' ? statusCode : 500).json({
                error: error.message || 'Internal server error'
            });
        }
    }
}

export default { smritiStream };
