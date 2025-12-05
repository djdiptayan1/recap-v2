import express from 'express';
import { body, param, query } from 'express-validator';
import memoryQuizController from '../controller/memoryQuiz/getQuizQuestions.js';

const router = express.Router();

/**
 * GET /api/memory-quiz
 * List all memory quiz questions
 */
router.get('/', memoryQuizController.getQuizQuestions);

export default router;
