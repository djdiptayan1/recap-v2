import express from 'express';
import { body, param } from 'express-validator';
import smritiController from '../controller/smriti/smriti.controller.js';
import smritiStreamController from '../controller/smriti/smriti.stream.controller.js';
import { smritiRateLimit, getSmritiUsage } from '../middleware/smritiRateLimit.js';

const router = express.Router();

// Shared validation for POST endpoints
const postValidation = [
    body('query').notEmpty().withMessage('Query is required').isString().withMessage('Query must be a string'),
    body('userIdentifier').notEmpty().withMessage('userIdentifier is required').isString().withMessage('userIdentifier must be a string'),
    body('context').optional().isObject().withMessage('Context must be an object'),
    body('context.patientName').optional().isString(),
    body('context.stage').optional().isString(),
    body('context.mode').optional().isString(),
    body('context.familyMembers').optional().isArray(),
    body('context.recentActivities').optional().isObject(),
    body('history').optional().isArray().withMessage('History must be an array'),
];

// Structured response endpoint
router.post('/', postValidation, smritiRateLimit, smritiController.smriti);

// Streaming response endpoint
router.post('/stream', postValidation, smritiRateLimit, smritiStreamController.smritiStream);

// Usage info endpoint — returns remaining quota for a user
router.get('/usage/:userIdentifier', [
    param('userIdentifier').notEmpty().withMessage('userIdentifier is required').isString(),
], getSmritiUsage);

export default router;