import express from 'express';
import { getQuestions } from '../controller/questions/fetch.controller.js';
import { getDailyQuestions } from '../controller/questions/getDailyQuestions.controller.js';

const router = express.Router();

router.get('/', getQuestions);
router.get('/dailyquestions', getDailyQuestions);

export default router;
