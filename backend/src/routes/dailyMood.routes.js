import express from 'express';
import { body, param, query } from 'express-validator';
import dailyMoodController from '../controller/mood/dailyMood.controller.js';
import { DAILY_MOOD_KEYS } from '../models/dailyMood.model.js';

const router = express.Router();

router.post(
    '/',
    [
        body('patientId')
            .notEmpty()
            .withMessage('Patient ID is required')
            .isString()
            .withMessage('Patient ID must be a string'),
        body('moodKey')
            .notEmpty()
            .withMessage('Mood key is required')
            .isIn(DAILY_MOOD_KEYS)
            .withMessage('Invalid mood key'),
    ],
    dailyMoodController.upsertMoodEntry
);

router.get(
    '/today/:patientId',
    [
        param('patientId')
            .notEmpty()
            .withMessage('Patient ID is required')
            .isString()
            .withMessage('Patient ID must be a string'),
    ],
    dailyMoodController.getTodayMood
);

router.get(
    '/history/:patientId',
    [
        param('patientId')
            .notEmpty()
            .withMessage('Patient ID is required')
            .isString()
            .withMessage('Patient ID must be a string'),
        query('days')
            .optional()
            .isInt({ min: 1, max: 30 })
            .withMessage('days must be an integer between 1 and 30'),
    ],
    dailyMoodController.getMoodHistory
);

export default router;
