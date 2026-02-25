import { GoogleGenAI, Type } from '@google/genai';
import config from '../../../config.js';
import { validationResult } from 'express-validator';

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

        const ai = new GoogleGenAI({
            apiKey: config.gemini.apiKey,
        });

        // Build context block if patient info is provided
        let contextBlock = '';
        if (context) {
            const parts = [];
            if (context.patientName) parts.push(`Patient: ${context.patientName}`);
            if (context.stage) parts.push(`Stage: ${context.stage}`);
            if (context.familyMembers && context.familyMembers.length > 0) {
                const familyStr = context.familyMembers.map(m => `${m.name} (${m.relation})`).join(', ');
                parts.push(`Family: ${familyStr}`);
            }
            if (parts.length > 0) {
                contextBlock = `\n\nPATIENT CONTEXT:\n${parts.join('. ')}.\nUse this to personalize. Address by name. Reference family naturally.`;
            }
        }

        // const tools = [
        //     { urlContext: {} },
        //     {
        //         googleSearch: {}
        //     },
        // ];

        const aiConfig = {
            temperature: 0.95,
            maxOutputTokens: 2000,
            thinkingConfig: {
                thinkingLevel: 'HIGH',
            },
            // tools,
            responseMimeType: 'application/json',
            responseSchema: {
                type: Type.OBJECT,
                description: "Structured response for Alzheimer’s, dementia, and elderly care guidance.",
                required: ["summary", "answer", "care_strategies", "medical_disclaimer", "sources"],
                properties: {
                    summary: {
                        type: Type.STRING,
                        description: "Concise restatement of the user's question or concern.",
                    },
                    answer: {
                        type: Type.STRING,
                        description: "Clear, empathetic explanation related to Alzheimer’s or dementia.",
                    },
                    care_strategies: {
                        type: Type.ARRAY,
                        description: "Actionable caregiving or coping strategies.",
                        items: {
                            type: Type.STRING,
                        },
                    },
                    medical_disclaimer: {
                        type: Type.STRING,
                        description: "Reminder that this is not a medical diagnosis or treatment advice.",
                    },
                    sources: {
                        type: Type.ARRAY,
                        description: "Authoritative references supporting the response.",
                        items: {
                            type: Type.OBJECT,
                            required: ["name", "url"],
                            properties: {
                                name: {
                                    type: Type.STRING,
                                },
                                url: {
                                    type: Type.STRING,
                                    format: "uri",
                                },
                            },
                        },
                    },
                    supportive_note: {
                        type: Type.STRING,
                        description: "Brief empathetic statement for caregivers or family members.",
                    },
                    followup_prompt: {
                        type: Type.STRING,
                        description: "A warm reminiscence question about the patient's past memories, childhood, family, or favorite experiences.",
                    },
                },
            },
            systemInstruction: [
                {
                    text: `You are Smriti, an Alzheimer's & Dementia Care expert. You educate, support, and guide patients, caregivers and families with empathy and evidence-based info.

SCOPE: ONLY Alzheimer's, dementia, memory loss, elderly care, caregiver strategies. Politely refuse other topics with: "I'm here to help with Alzheimer's, dementia, and elderly care. I'm happy to help with questions about memory loss or caregiving."

MEDICAL SAFETY: Never diagnose or prescribe. Always remind to consult a healthcare professional.

TONE: Empathetic, calm, simple language. Concise but meaningful. No fear-based messaging.

EMOTION DETECTION: If the user seems confused, frustrated, or distressed — simplify language, use shorter sentences, acknowledge their feelings first, and be extra reassuring before providing information.

REMINISCENCE THERAPY: Always include a warm follow-up question in "followup_prompt" to gently encourage memory recall (e.g., about their wedding day, childhood games, favorite foods, family traditions, old hobbies, school days). Make it personal using patient context if available.

SOURCES: Include 2-4 sources from WHO, Alzheimer's Association, NIH/NIA, NHS, Mayo Clinic, or CDC.${contextBlock}`,
                }
            ],
        };

        const model = 'gemini-3-flash-preview';

        // Build conversation contents with history for multi-turn context
        const contents = [];
        if (history && Array.isArray(history)) {
            const recentHistory = history.slice(-6);
            for (const msg of recentHistory) {
                contents.push({
                    role: msg.role === 'user' ? 'user' : 'model',
                    parts: [{ text: msg.text }],
                });
            }
        }
        contents.push({
            role: 'user',
            parts: [{ text: query }],
        });

        const result = await ai.models.generateContent({
            model: model,
            config: aiConfig,
            contents,
        });

        if (result && (result.text || result.candidates)) {
            const responseText = typeof result.text === 'function' ? result.text() : (result.text || result.candidates?.[0]?.content?.parts?.[0]?.text);

            if (!responseText) {
                throw new Error("Empty response from AI");
            }

            const jsonResponse = JSON.parse(responseText);
            return res.status(200).json(jsonResponse);
        } else {
            throw new Error("No response from AI");
        }

    } catch (error) {
        // console.error("Error in Smriti AI:", error); // Handled by global error handler
        next(error);
    }
}

export default {
    smriti
};