import express from 'express';
import { body, param, query } from 'express-validator';
import journalController from '../controller/journal/journal.controller.js';

const router = express.Router();

/**
 * POST /api/journal/uploads/sign
 * Generate signed Cloudinary upload params for direct client uploads
 */
router.post('/uploads/sign',
    [
        body('patientId')
            .notEmpty()
            .withMessage('Patient ID is required')
            .isString()
            .withMessage('Patient ID must be a string'),
        body('mediaType')
            .notEmpty()
            .withMessage('mediaType is required')
            .isIn(['audio', 'photo'])
            .withMessage('mediaType must be "audio" or "photo"'),
        body('index')
            .optional()
            .isInt({ min: 0, max: 100 })
            .withMessage('index must be an integer between 0 and 100'),
    ],
    journalController.createUploadSignature
);

/**
 * POST /api/journal/uploads/sign-batch
 * Generate upload params for all assets needed by one journal save
 */
router.post('/uploads/sign-batch',
    [
        body('patientId')
            .notEmpty()
            .withMessage('Patient ID is required')
            .isString()
            .withMessage('Patient ID must be a string'),
        body('photoCount')
            .optional()
            .isInt({ min: 0, max: 10 })
            .withMessage('photoCount must be an integer between 0 and 10'),
        body('includeAudio')
            .optional()
            .isBoolean()
            .withMessage('includeAudio must be a boolean'),
    ],
    journalController.createUploadSignaturesBatch
);

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
        body('audioUpload.url')
            .optional()
            .isString()
            .withMessage('audioUpload.url must be a string'),
        body('audioUpload.publicId')
            .optional()
            .isString()
            .withMessage('audioUpload.publicId must be a string'),
        body('audioDuration')
            .optional()
            .isNumeric()
            .withMessage('audioDuration must be a number'),
        body('createdBy')
            .optional()
            .isIn(['patient', 'family'])
            .withMessage('createdBy must be "patient" or "family"'),
        body('entryType')
            .optional()
            .isIn(['journal', 'memory'])
            .withMessage('entryType must be "journal" or "memory"'),
        body('people')
            .optional()
            .isString()
            .withMessage('people must be a string'),
        body('place')
            .optional()
            .isString()
            .withMessage('place must be a string'),
        body('eventTag')
            .optional()
            .isString()
            .withMessage('eventTag must be a string'),
        body('photoBase64s')
            .optional()
            .isArray()
            .withMessage('photoBase64s must be an array'),
        body('photoBase64s.*.imageBase64')
            .optional()
            .isString()
            .withMessage('Each photo imageBase64 must be a string'),
        body('photoBase64s.*.caption')
            .optional()
            .isString()
            .withMessage('Photo caption must be a string'),
        body('photoUploads')
            .optional()
            .isArray()
            .withMessage('photoUploads must be an array'),
        body('photoUploads.*.url')
            .optional()
            .isString()
            .withMessage('Each photo upload url must be a string'),
        body('photoUploads.*.publicId')
            .optional()
            .isString()
            .withMessage('Each photo upload publicId must be a string'),
        body('photoUploads.*.caption')
            .optional()
            .isString()
            .withMessage('Each photo upload caption must be a string'),
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
        body('audioUpload.url')
            .optional()
            .isString()
            .withMessage('audioUpload.url must be a string'),
        body('audioUpload.publicId')
            .optional()
            .isString()
            .withMessage('audioUpload.publicId must be a string'),
        body('audioDuration')
            .optional()
            .isNumeric()
            .withMessage('audioDuration must be a number'),
        body('entryType')
            .optional()
            .isIn(['journal', 'memory'])
            .withMessage('entryType must be "journal" or "memory"'),
        body('people')
            .optional()
            .isString()
            .withMessage('people must be a string'),
        body('place')
            .optional()
            .isString()
            .withMessage('place must be a string'),
        body('eventTag')
            .optional()
            .isString()
            .withMessage('eventTag must be a string'),
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
