import config from '../../../config.js';
import { validationResult } from 'express-validator';

async function smriti(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        // Mock data matching your 'CareResponse' Schema
        const demoResponse = {
            summary: "Understanding and managing 'Sundowning' (late-day confusion).",
            answer: "What you are describing sounds like 'Sundowning.' This is a symptom of Alzheimer's disease and other forms of dementia. It specifically refers to increased confusion, anxiety, and agitation that occurs in the late afternoon or early evening. It may be caused by fatigue, low lighting, or a disrupted internal body clock.",
            care_strategies: [
                "Increase lighting in the evening to reduce shadows and confusion.",
                "Stick to a consistent daily routine for waking up, meals, and sleep.",
                "Limit caffeine and sugar to the morning hours.",
                "Plan more active days to discourage afternoon napping.",
                "Play familiar, calming music during the late afternoon."
            ],
            medical_disclaimer: "I am an AI companion, not a doctor. This information is for educational purposes only. Please consult a qualified healthcare professional for medical diagnosis and treatment.",
            sources: [
                {
                    name: "Mayo Clinic - Sundowning",
                    url: "https://www.mayoclinic.org/diseases-conditions/alzheimers-disease/expert-answers/sundowning/faq-20058511"
                },
                {
                    name: "Alzheimer's Association",
                    url: "https://www.alz.org/help-support/caregiving/stages-behaviors/sleep-issues-sundowning"
                }
            ],
            supportive_note: "Handling sundowning can be exhausting for caregivers. Remember to take a deep breath. You are doing your best, and that is enough."
        };

        return res.status(200).json(demoResponse);
    } catch (error) {
        next(error);
    }
}

export default {
    smriti
};