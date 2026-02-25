import express from 'express';
import { body, param, query } from 'express-validator';
import smritiController from '../controller/smriti/smriti.controller.js';

const router = express.Router();

router.post('/', [
    body('query').notEmpty().withMessage('Query is required').isString().withMessage('Query must be a string'),
    body('context').optional().isObject().withMessage('Context must be an object'),
    body('context.patientName').optional().isString(),
    body('context.stage').optional().isString(),
    body('context.familyMembers').optional().isArray(),
    body('history').optional().isArray().withMessage('History must be an array'),
], smritiController.smriti);

export default router;