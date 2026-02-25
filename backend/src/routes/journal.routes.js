import express from 'express';
import { body, param, query } from 'express-validator';
import journalController from '../controller/journal/journal.controller.js';

const router = express.Router();

/**
 * GET /api/journal
 * List journal entries for a patient with optional pagination
 */
router.get('/',
    [
        query('patientId')
            .notEmpty()
            .withMessage('Patient ID is required')
            .isString()
            .withMessage('Patient ID must be a string'),
        query('limit')
            .optional()
            .isInt({ min: 1, max: 100 })
            .withMessage('Limit must be an integer between 1 and 100'),
        query('after')
            .optional()
            .isString()
            .withMessage('After must be a string (document ID)'),
    ],
    journalController.getEntries
);

/**
 * GET /api/journal/:id
 * Get a single journal entry by ID
 */
router.get('/:id',
    [
        param('id')
            .trim()
            .notEmpty()
            .withMessage('Entry ID is required')
            .isString()
            .withMessage('Entry ID must be a string'),
        query('patientId')
            .notEmpty()
            .withMessage('Patient ID is required')
            .isString()
            .withMessage('Patient ID must be a string'),
    ],
    journalController.getEntryById
);

/**
 * POST /api/journal
 * Create a new journal entry
 */
router.post('/',
    [
        body('patientId')
            .notEmpty()
            .withMessage('Patient ID is required')
            .isString()
            .withMessage('Patient ID must be a string'),
        body('title')
            .optional()
            .trim()
            .isString()
            .withMessage('Title must be a string')
            .isLength({ max: 200 })
            .withMessage('Title must be at most 200 characters'),
        body('content')
            .optional()
            .isString()
            .withMessage('Content must be a string'),
        body('mood')
            .optional()
            .isIn(['happy', 'sad', 'neutral', 'anxious', 'calm', 'grateful'])
            .withMessage('Invalid mood value'),
        body('audioBase64')
            .optional()
            .isString()
            .withMessage('audioBase64 must be a string'),
        body('audioDuration')
            .optional()
            .isNumeric()
            .withMessage('audioDuration must be a number'),
        body('createdBy')
            .optional()
            .isIn(['patient', 'family'])
            .withMessage('createdBy must be "patient" or "family"'),
    ],
    journalController.createEntry
);

/**
 * PUT /api/journal/:id
 * Update an existing journal entry
 */
router.put('/:id',
    [
        param('id')
            .trim()
            .notEmpty()
            .withMessage('Entry ID is required')
            .isString()
            .withMessage('Entry ID must be a string'),
        body('patientId')
            .notEmpty()
            .withMessage('Patient ID is required')
            .isString()
            .withMessage('Patient ID must be a string'),
        body('title')
            .optional()
            .trim()
            .isString()
            .withMessage('Title must be a string')
            .isLength({ max: 200 })
            .withMessage('Title must be at most 200 characters'),
        body('content')
            .optional()
            .isString()
            .withMessage('Content must be a string'),
        body('mood')
            .optional()
            .isIn(['happy', 'sad', 'neutral', 'anxious', 'calm', 'grateful'])
            .withMessage('Invalid mood value'),
        body('audioBase64')
            .optional()
            .isString()
            .withMessage('audioBase64 must be a string'),
        body('audioDuration')
            .optional()
            .isNumeric()
            .withMessage('audioDuration must be a number'),
    ],
    journalController.updateEntry
);

/**
 * DELETE /api/journal/:id
 * Delete a journal entry
 */
router.delete('/:id',
    [
        param('id')
            .trim()
            .notEmpty()
            .withMessage('Entry ID is required')
            .isString()
            .withMessage('Entry ID must be a string'),
        query('patientId')
            .notEmpty()
            .withMessage('Patient ID is required')
            .isString()
            .withMessage('Patient ID must be a string'),
    ],
    journalController.deleteEntry
);

export default router;
