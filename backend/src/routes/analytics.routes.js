import express from 'express';
import { param } from 'express-validator';
import { getDashboardAnalytics } from '../controller/analytics/dashboardAnalytics.controller.js';

const router = express.Router();

/**
 * GET /api/analytics/dashboard/:patientId
 * Get dashboard analytics for a patient (daily, weekly, monthly stats + decline alerts)
 */
router.get('/dashboard/:patientId',
    [
        param('patientId')
            .trim()
            .notEmpty()
            .withMessage('patientId is required')
            .isString()
            .withMessage('patientId must be a string'),
    ],
    getDashboardAnalytics
);

export default router;
