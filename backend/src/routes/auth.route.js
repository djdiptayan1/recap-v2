import express from 'express';
import { body } from 'express-validator';
import { verifyUID } from '../auth/verifyUID.controller.js';
import { verifyFamilyMember } from '../auth/verifyFamilyMember.controller.js';
import { patientSignup } from '../auth/patientSignup.controller.js';

const router = express.Router();

router.post(
    '/verify-uid',
    body('patientUID')
        .isString()
        .isLength({ min: 6, max: 6 })
        .withMessage('patientUID must be exactly 6 characters'),
    verifyUID
);

router.post(
    '/verify-familymember',
    body('email').isEmail().withMessage('Invalid email format'),
    body('documentId').isString().notEmpty().withMessage('documentId is required'),
    verifyFamilyMember
);

router.post(
    '/patientsignup',
    body('uid').isString().notEmpty(),
    body('email').isEmail(),
    patientSignup
);

export default router;
