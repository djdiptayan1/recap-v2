import express from 'express';
import memoryQuizController from '../controller/memoryQuiz/getQuizQuestions.js';

const router = express.Router();

/**
 * GET /api/memory-quiz
 * List all memory quiz questions
 */
router.get('/', memoryQuizController.getQuizQuestions);

export default router;
