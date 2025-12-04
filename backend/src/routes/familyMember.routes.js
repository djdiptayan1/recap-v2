import express from 'express';
import { param } from 'express-validator';
import fetchFamilyController from '../controller/family_member/fetchFamily.controller.js';

const router = express.Router();

/**
 * GET /api/familymembers/:documentId
 * Get family members for a user
 */
router.get('/:documentId',
    [
        param('documentId')
            .trim()
            .notEmpty()
            .withMessage('documentId is required')
            .isString()
            .withMessage('documentId must be a string'),
    ],
    fetchFamilyController.getFamilyMembers
);

export default router;
