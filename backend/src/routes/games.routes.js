import express from 'express';
import {
    getGameAnalytics,
    getGameHistory,
    submitGameSession,
} from '../controller/games/games.controller.js';

const router = express.Router();

router.post('/session', submitGameSession);
router.get('/history/:patientId', getGameHistory);
router.get('/analytics/:patientId', getGameAnalytics);

export default router;
