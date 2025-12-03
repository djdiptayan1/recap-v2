import express from 'express';
import articlesRouter from './articles.routes.js';

const router = express.Router();

router.use('/articles', articlesRouter);

export default router;
