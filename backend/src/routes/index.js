import express from 'express';
import articlesRouter from './articles.routes.js';
import citationsRouter from './citations.routes.js';
import memoryQuizRouter from './memoryQuiz.routes.js';
import streaksRouter from './streaks.routes.js';
import familyMemberRouter from './familyMember.routes.js';
import authRouter from './auth.route.js';
import patientRouter from './patient.routes.js';
import questionsRouter from './questions.routes.js';
import smritiRouter from './smriti.routes.js';
import remindersRouter from './reminders.route.js';
import journalRouter from './journal.routes.js';
import analyticsRouter from './analytics.routes.js';
import gamesRouter from './games.routes.js';
import dailyMoodRouter from './dailyMood.routes.js';

const router = express.Router();

router.use('/articles', articlesRouter);
router.use('/citations', citationsRouter);
router.use('/memoryquiz', memoryQuizRouter);
router.use('/streaks', streaksRouter);
router.use('/patient', patientRouter);
router.use('/familymembers', familyMemberRouter);
router.use('/auth', authRouter);
router.use('/questions', questionsRouter);
router.use('/smriti', smritiRouter);
router.use('/reminders', remindersRouter);
router.use('/journal', journalRouter);
router.use('/analytics', analyticsRouter);
router.use('/games', gamesRouter);
router.use('/mood', dailyMoodRouter);

export default router;
