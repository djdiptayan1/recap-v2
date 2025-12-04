import express from 'express';
import articlesRouter from './articles.routes.js';
import citationsRouter from './citations.routes.js';
import memoryQuizRouter from './memoryQuiz.routes.js';
import streaksRouter from './streaks.routes.js';
import familyMemberRouter from './familyMember.routes.js';

const router = express.Router();

router.use('/articles', articlesRouter);
router.use('/citations', citationsRouter);
router.use('/memoryquiz', memoryQuizRouter);
router.use('/streaks', streaksRouter);
router.use('/familymembers', familyMemberRouter);

export default router;