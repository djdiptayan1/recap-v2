import express from 'express';
import { body, param, query } from 'express-validator';
import smritiController from '../controller/smriti/smriti.controller.js';

const router = express.Router();

router.post('/', [
    body('query').notEmpty().withMessage('Query is required').isString().withMessage('Query must be a string')
], smritiController.smriti);

export default router;