import express from 'express';
import { param } from 'express-validator';
import fetchFamilyController from '../controller/family_member/fetchFamily.controller.js';
import deleteFamilyController from '../controller/family_member/deleteFamily.controller.js';

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

/**
 * DELETE /api/familymembers/:documentId/:memberId
 * Delete a family member
 */
router.delete('/:documentId/:memberId',
    [
        param('documentId')
            .trim()
            .notEmpty()
            .withMessage('documentId is required')
            .isString()
            .withMessage('documentId must be a string'),
        param('memberId')
            .trim()
            .notEmpty()
            .withMessage('memberId is required')
            .isString()
            .withMessage('memberId must be a string'),
    ],
    deleteFamilyController.deleteFamilyMember
);

export default router;
