import express from 'express';
import { getQuestions } from '../controller/questions/fetch.controller.js';

const router = express.Router();

router.get('/', getQuestions);

export default router;
