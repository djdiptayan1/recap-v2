import express from 'express';
import { body, param, query } from 'express-validator';
import smritiController from '../controller/smriti/smriti.controller.js';

const router = express.Router();

router.post('/', smritiController.smriti);

export default router;