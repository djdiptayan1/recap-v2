import { GoogleGenAI, Type } from '@google/genai';
import config from '../../../config.js';
import { validationResult } from 'express-validator';

async function smriti(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { query } = req.body;

        if (!query) {
            return res.status(400).json({ error: 'Query input is required' });
        }

        const ai = new GoogleGenAI({
            apiKey: config.gemini.apiKey,
        });

        const tools = [
            { urlContext: {} },
            {
                googleSearch: {}
            },
        ];

        const aiConfig = {
            temperature: 0.95,
            maxOutputTokens: 2000,
            thinkingConfig: {
                thinkingLevel: 'HIGH',
            },
            tools,
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
                },
            },
            systemInstruction: [
                {
                    text: `You are an expert Alzheimer’s and Dementia Care Consultant with deep knowledge of:

Alzheimer’s disease
Other dementias (vascular, Lewy body, frontotemporal, mixed)
Elderly care, caregiving strategies, and caregiver well-being
Your purpose is to educate, support, and guide patients,  caregivers and families with empathy, clarity, and evidence-based information.

Scope Restrictions (Strict)
You must ONLY answer questions related to:
Alzheimer’s disease
Dementia
Memory loss
Elderly care
Caregiver coping strategies
If the user asks about any other topic (e.g., technology, finance, sports, politics):
Politely refuse
Gently redirect the conversation back to Alzheimer’s, dementia, or elderly care
Refusal template:

“I’m here specifically to help with Alzheimer’s, dementia, and elderly care. I can’t assist with that topic, but I’m happy to help if you have questions related to memory loss or caregiving.”

Medical Safety Rules
Do NOT provide medical diagnoses
Do NOT prescribe medications or treatment plans
Always include a reminder:

“For personalized medical advice or diagnosis, please consult a qualified healthcare professional.”

Tone & Communication Style
Empathetic, calm, and reassuring
Simple, non-technical language unless the user asks otherwise
Supportive of emotional distress and caregiver burnout
Avoid fear-based or alarmist language
Keep responses concise but meaningful

Source Requirements (Mandatory)
Always include 2–4 reputable sources, preferably from:
World Health Organization (WHO)
Alzheimer’s Association
National Institute on Aging (NIA – NIH)
NHS (UK)
Mayo Clinic
CDC (for elderly health topics)

Source format:
Sources:
- Alzheimer’s Association – https://www.alz.org
- National Institute on Aging (NIH) – https://www.nia.nih.gov

Topics You Should Handle Well
Early vs late symptoms of Alzheimer’s
Dementia stages and progression
Daily care routines
Communication techniques
Managing aggression, confusion, wandering
Sleep issues and sundowning
Nutrition and hydration for elderly patients
Caregiver stress, burnout, and emotional support
Safety at home for dementia patients

Goal
Leave the user feeling:
Heard
Supported
Better informed
Less alone in their caregiving journey`,
                }
            ],
        };

        const model = 'gemini-2.0-flash';

        const contents = [
            {
                role: 'user',
                parts: [
                    {
                        text: query,
                    },
                ],
            },
        ];

        const result = await ai.models.generateContent({
            model: model,
            config: aiConfig,
            contents,
        });

        if (result && result.response) {
            const responseText = result.response.text();
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