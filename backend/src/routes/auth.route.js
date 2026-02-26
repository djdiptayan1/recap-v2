import express from 'express';
import { body } from 'express-validator';
import { verifyUID } from '../auth/verifyUID.controller.js';
import { verifyFamilyMember } from '../auth/verifyFamilyMember.controller.js';
import { patientSignup } from '../auth/patientSignup.controller.js';
import { familySignup } from '../auth/familySignup.controller.js';
import { forgotPassword } from '../auth/forgotPassword.controller.js';
import { deleteAccount } from '../auth/deleteAccount.controller.js';

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
    body('firstName').isString().notEmpty(),
    body('lastName').isString().notEmpty(),
    body('dateOfBirth').isString().notEmpty(),
    body('bloodGroup').isString().notEmpty(),
    body('sex').isString().notEmpty(),
    body('stage').isString().notEmpty(),
    body('profileImageBase64').isString().notEmpty(),
    patientSignup
);

router.post(
    '/familysignup',
    body('patient_documentId').isString().notEmpty().withMessage('patient_documentId is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('name').isString().notEmpty().withMessage('Name is required'),
    body('profileImageBase64').isString().notEmpty().withMessage('Image is required'),
    body('phone').isString().notEmpty().withMessage('Phone number is required'),
    body('relation').isString().notEmpty().withMessage('Relation is required'),
    familySignup
);

router.post(
    '/forgot-password',
    body('email').isEmail().withMessage('Valid email is required'),
    forgotPassword
);

router.post(
    '/delete-account',
    body('documentId').isString().notEmpty().withMessage('documentId is required'),
    deleteAccount
);

export default router;
