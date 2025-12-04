import express from 'express';
import { body, param, query } from 'express-validator';
import updateStreakController from '../controller/streaks/updateStreak.controller.js';
import fetchStreakController from '../controller/streaks/fetchStreak.controller.js';

const router = express.Router();

/**
 * POST /api/streaks/activity
 * Record user activity and update streaks
 */
router.post('/activity',
    [
        body('documentId')
            .trim()
            .notEmpty()
            .withMessage('documentId is required')
            .isString()
            .withMessage('documentId must be a string'),
    ],
    updateStreakController.updateStreak
);

/**
 * GET /api/streaks/stats/:documentId
 * Get streak statistics for a user
 */
router.get('/stats/:documentId',
    [
        param('documentId')
            .trim()
            .notEmpty()
            .withMessage('documentId is required')
            .isString()
            .withMessage('documentId must be a string'),
    ],
    fetchStreakController.getStreakStats
);

/**
 * GET /api/streaks/month/:documentId
 * Get monthly streak data for a user
 */
router.get('/month/:documentId',
    [
        param('documentId')
            .trim()
            .notEmpty()
            .withMessage('documentId is required')
            .isString()
            .withMessage('documentId must be a string'),
        query('yearMonth')
            .trim()
            .notEmpty()
            .withMessage('yearMonth is required (YYYY-MM)')
            .matches(/^\d{4}-\d{2}$/)
            .withMessage('yearMonth must be in YYYY-MM format'),
    ],
    fetchStreakController.getMonthStreak
);

/**
 * GET /api/streaks/year/:documentId
 * Get yearly streak data for a user
 */
router.get('/year/:documentId',
    [
        param('documentId')
            .trim()
            .notEmpty()
            .withMessage('documentId is required')
            .isString()
            .withMessage('documentId must be a string'),
        query('year')
            .trim()
            .notEmpty()
            .withMessage('year is required (YYYY)')
            .matches(/^\d{4}$/)
            .withMessage('year must be in YYYY format'),
    ],
    fetchStreakController.getYearStreaks
);

export default router;
