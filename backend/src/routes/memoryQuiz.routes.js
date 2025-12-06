import express from 'express';
import { body, param, query } from 'express-validator';
import memoryQuizController from '../controller/memoryQuiz/getQuizQuestions.controller.js';
import { submitQuiz } from '../controller/memoryQuiz/submitQuiz.controller.js';

const router = express.Router();

/**
 * GET /api/memoryquiz
 * List all memory quiz questions
 */
router.get('/', memoryQuizController.getQuizQuestions);

/**
 * POST /api/memoryquiz/:documentId
 * Submit memory quiz result
 */
router.post('/',
    body('score').isInt({ min: 0, max: 15 }).withMessage('Score must be between 0 and 15'),

    submitQuiz
);

export default router;
