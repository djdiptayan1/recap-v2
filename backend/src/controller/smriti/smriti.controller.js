import { GoogleGenAI, Type } from '@google/genai';
import config from '../../../config.js';
import { validationResult } from 'express-validator';

const SYSTEM_PROMPT = `You are Smriti, a warm Alzheimer's & Dementia Care companion. You help patients, caregivers, and families with empathy and evidence-based care.

RULES:
- ONLY discuss Alzheimer's, dementia, memory, elderly care, caregiving, or engage in reminiscence therapy about the patient's past. Politely decline unrelated topics.
- Never diagnose or prescribe. Suggest consulting healthcare professionals for medical concerns.
- Keep answers concise (2-4 paragraphs max). Use simple, calm language.
- If the user seems confused or frustrated: acknowledge feelings first, simplify language, be extra reassuring.
- Use patient context naturally: reference their name, family members, activities. Make it personal.
- If mode is "memoryLane": Act as a reminiscence therapy companion. Gently ask about the patient's past — wedding day, childhood, favorite foods, school days, family traditions, old hobbies. Use family names. Be warm, curious, patient. Celebrate every memory shared.
- Always include a warm followup_prompt to encourage memory recall. Use patient's family names if available.
- Only include care_strategies, sources, medical_disclaimer when genuinely relevant — skip for casual conversation and reminiscence.`;

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

function buildContents(history, query) {
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
    return contents;
}

async function smriti(req, res, next) {
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
            responseMimeType: 'application/json',
            responseSchema: {
                type: Type.OBJECT,
                description: "Smriti AI response",
                required: ["answer", "followup_prompt"],
                properties: {
                    answer: {
                        type: Type.STRING,
                        description: "Clear, empathetic response.",
                    },
                    care_strategies: {
                        type: Type.ARRAY,
                        description: "Actionable tips (only if relevant).",
                        items: { type: Type.STRING },
                    },
                    medical_disclaimer: {
                        type: Type.STRING,
                        description: "Brief reminder to consult a doctor (only for medical questions).",
                    },
                    sources: {
                        type: Type.ARRAY,
                        description: "1-2 references (only if citing specific info).",
                        items: {
                            type: Type.OBJECT,
                            required: ["name", "url"],
                            properties: {
                                name: { type: Type.STRING },
                                url: { type: Type.STRING, format: "uri" },
                            },
                        },
                    },
                    supportive_note: {
                        type: Type.STRING,
                        description: "Brief empathetic note (only for emotional topics).",
                    },
                    followup_prompt: {
                        type: Type.STRING,
                        description: "A warm reminiscence question about the patient's memories. Make it personal.",
                    },
                },
            },
            systemInstruction: [{ text: SYSTEM_PROMPT + contextBlock }],
        };

        const model = 'gemini-3-flash-preview';
        const contents = buildContents(history, query);

        const result = await ai.models.generateContent({
            model,
            config: aiConfig,
            contents,
        });

        if (result && (result.text || result.candidates)) {
            const responseText = typeof result.text === 'function' ? result.text() : (result.text || result.candidates?.[0]?.content?.parts?.[0]?.text);

            if (!responseText) {
                throw new Error("Empty response from AI");
            }

            const jsonResponse = JSON.parse(responseText);

            // Increment usage ONLY on successful response
            if (typeof req.incrementSmritiUsage === 'function') {
                await req.incrementSmritiUsage();
            }

            return res.status(200).json(jsonResponse);
        } else {
            throw new Error("No response from AI");
        }

    } catch (error) {
        console.error("Smriti structured error:", error.message);
        next(error);
    }
}

export default { smriti };