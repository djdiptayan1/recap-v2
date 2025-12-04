import express from 'express';
import { body, param, query } from 'express-validator';

import citationsController from '../controller/citations.controller.js';

const router = express.Router();

/**
 * GET /api/citations
 * List all citations with optional pagination
 */
router.get('/',
    [
        query('limit')
            .optional()
            .isInt({ min: 1, max: 100 })
            .withMessage('Limit must be an integer between 1 and 100'),
        query('after')
            .optional()
            .isString()
            .withMessage('After must be a string (document ID)'),
    ],
    citationsController.getAllCitations
);

/**
 * GET /api/citations/:id
 * Get a single citation by ID
 */
router.get('/:id',
    [
        param('id')
            .trim()
            .notEmpty()
            .withMessage('Citation ID is required')
            .isString()
            .withMessage('Citation ID must be a string'),
    ],
    citationsController.getCitationByID
);

/**
 * POST /api/citations
 * Create a new citation
 */
router.post('/',
    [
        body('authors')
            .trim()
            .notEmpty()
            .withMessage('Authors is required')
            .isString()
            .withMessage('Authors must be a string'),
        body('doi')
            .optional()
            .trim()
            .isString()
            .withMessage('DOI must be a string'),
        body('journal')
            .optional()
            .trim()
            .isString()
            .withMessage('Journal must be a string'),
        body('source')
            .optional()
            .trim()
            .isString()
            .withMessage('Source must be a string'),
        body('title')
            .trim()
            .notEmpty()
            .withMessage('Title is required')
            .isString()
            .withMessage('Title must be a string'),
        body('url')
            .optional()
            .trim()
            .isString()
            .withMessage('URL must be a string')
            .isURL()
            .withMessage('URL must be a valid URL'),
        body('year')
            .optional()
            .trim()
            .isString()
            .withMessage('Year must be a string'),
    ],
    citationsController.createCitation
);

/**
 * PUT /api/citations/:id
 * Update an existing citation
 */
router.put('/:id',
    [
        param('id')
            .trim()
            .notEmpty()
            .withMessage('Citation ID is required')
            .isString()
            .withMessage('Citation ID must be a string'),
        body('authors')
            .optional()
            .trim()
            .isString()
            .withMessage('Authors must be a string'),
        body('doi')
            .optional()
            .trim()
            .isString()
            .withMessage('DOI must be a string'),
        body('journal')
            .optional()
            .trim()
            .isString()
            .withMessage('Journal must be a string'),
        body('source')
            .optional()
            .trim()
            .isString()
            .withMessage('Source must be a string'),
        body('title')
            .optional()
            .trim()
            .isString()
            .withMessage('Title must be a string'),
        body('url')
            .optional()
            .trim()
            .isString()
            .withMessage('URL must be a string')
            .isURL()
            .withMessage('URL must be a valid URL'),
        body('year')
            .optional()
            .trim()
            .isString()
            .withMessage('Year must be a string'),
    ],
    citationsController.updateCitation
);

/**
 * DELETE /api/citations/:id
 * Delete a citation by ID
 */
router.delete('/:id',
    [
        param('id')
            .trim()
            .notEmpty()
            .withMessage('Citation ID is required')
            .isString()
            .withMessage('Citation ID must be a string'),
    ],
    citationsController.deleteCitation
);

export default router;
