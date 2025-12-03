import express from 'express';
import { body, param, query } from 'express-validator';

import articlesController from '../controller/articles.controler.js';

const router = express.Router();

/**
 * GET /api/articles
 * List all articles with optional pagination
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
    articlesController.getAllArticles
);

/**
 * GET /api/articles/:id
 * Get a single article by ID
 */
router.get('/:id',
    [
        param('id')
            .trim()
            .notEmpty()
            .withMessage('Article ID is required')
            .isString()
            .withMessage('Article ID must be a string'),
    ],
    articlesController.getArticleByID
);

/**
 * POST /api/articles
 * Create a new article
 */
router.post('/',
    [
        body('title')
            .trim()
            .notEmpty()
            .withMessage('Title is required')
            .isString()
            .withMessage('Title must be a string')
            .isLength({ min: 1, max: 500 })
            .withMessage('Title must be between 1 and 500 characters'),
        body('content')
            .trim()
            .notEmpty()
            .withMessage('Content is required')
            .isString()
            .withMessage('Content must be a string')
            .isLength({ min: 1 })
            .withMessage('Content cannot be empty'),
        body('author')
            .trim()
            .notEmpty()
            .withMessage('Author is required')
            .isString()
            .withMessage('Author must be a string')
            .isLength({ min: 1, max: 200 })
            .withMessage('Author must be between 1 and 200 characters'),
        body('citation')
            .optional()
            .trim()
            .isString()
            .withMessage('Citation must be a string'),
        body('image')
            .optional()
            .trim()
            .isString()
            .withMessage('Image must be a string')
            .isURL()
            .withMessage('Image must be a valid URL'),
        body('link')
            .optional()
            .trim()
            .isString()
            .withMessage('Link must be a string')
            .isURL()
            .withMessage('Link must be a valid URL'),
        body('source')
            .optional()
            .trim()
            .isString()
            .withMessage('Source must be a string')
            .isURL()
            .withMessage('Source must be a valid URL'),
    ],
    articlesController.createArticle
);

/**
 * PUT /api/articles/:id
 * Update an existing article
 */
router.put('/:id',
    [
        param('id')
            .trim()
            .notEmpty()
            .withMessage('Article ID is required')
            .isString()
            .withMessage('Article ID must be a string'),
        body('title')
            .optional()
            .trim()
            .isString()
            .withMessage('Title must be a string')
            .isLength({ min: 1, max: 500 })
            .withMessage('Title must be between 1 and 500 characters'),
        body('content')
            .optional()
            .trim()
            .isString()
            .withMessage('Content must be a string')
            .isLength({ min: 1 })
            .withMessage('Content cannot be empty'),
        body('author')
            .optional()
            .trim()
            .isString()
            .withMessage('Author must be a string')
            .isLength({ min: 1, max: 200 })
            .withMessage('Author must be between 1 and 200 characters'),
        body('citation')
            .optional()
            .trim()
            .isString()
            .withMessage('Citation must be a string'),
        body('image')
            .optional()
            .trim()
            .isString()
            .withMessage('Image must be a string')
            .isURL()
            .withMessage('Image must be a valid URL'),
        body('link')
            .optional()
            .trim()
            .isString()
            .withMessage('Link must be a string')
            .isURL()
            .withMessage('Link must be a valid URL'),
        body('source')
            .optional()
            .trim()
            .isString()
            .withMessage('Source must be a string')
            .isURL()
            .withMessage('Source must be a valid URL'),
    ],
    articlesController.updateArticle
);

/**
 * DELETE /api/articles/:id
 * Delete an article by ID
 */
router.delete('/:id',
    [
        param('id')
            .trim()
            .notEmpty()
            .withMessage('Article ID is required')
            .isString()
            .withMessage('Article ID must be a string'),
    ],
    articlesController.deleteArticle
);

export default router;