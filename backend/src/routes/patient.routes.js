import express from 'express';
import { body, param } from 'express-validator';
import { getPatient } from '../controller/patient/fetch.controller.js';

const router = express.Router();

router.get(
    '/:documentId',
    param('documentId')
        .isString()
        .withMessage('documentId must be a string'),
    getPatient
);

export default router;
