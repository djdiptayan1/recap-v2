import express from 'express';
import { body, param } from 'express-validator';
import { getQuestions } from '../controller/questions/fetch.controller.js';
import { getDailyQuestions } from '../controller/questions/getDailyQuestions.controller.js';
import { addQuestion } from '../controller/questions/admin/addQuestion.controller.js';
import { editQuestion } from '../controller/questions/admin/editQuestions.controller.js';

const router = express.Router();

import { getFamilyQuestions } from '../controller/questions/family/fetchFamilyQuestions.controller.js';
const extendedValidation = [
    body('image').optional({ nullable: true }).isString().withMessage('Image must be a string or null'),
    body('audio').optional({ nullable: true }).isString().withMessage('Audio must be a string or null'),
    body('hint').optional().isString().withMessage('Hint must be a string'),
    body('isActive').optional().isBoolean().withMessage('isActive must be a boolean'),
    body('correctAnswers').optional().isArray().withMessage('Correct answers must be an array')
];

router.get('/', getQuestions);
router.get('/dailyquestions', getDailyQuestions);

import { answerDailyQuestion } from '../controller/questions/answerDailyQuestion.controller.js';
router.post(
    '/answer',
    [
        body('patientId').isString().notEmpty(),
        body('questionId').isString().notEmpty(),
        body('answer').exists().withMessage('Answer is required'), // Can be string or array
        body('answeredBy').isIn(['patient', 'family']),
        body('date').isString().notEmpty(),
        body('category').isString().notEmpty()
    ],
    answerDailyQuestion
);

router.get(
    '/family/:patient_documentId',
    [
        param('patient_documentId').isString().notEmpty().withMessage('Patient document ID is required')
    ],
    getFamilyQuestions
);

router.post(
    '/family/:patient_documentId/add',
    [
        param('patient_documentId').isString().notEmpty().withMessage('Patient document ID is required'),
        body('answerOptions').isArray().withMessage('Answer options must be an array'),
        body('askInterval').isNumeric().withMessage('Ask interval must be a number'),
        body('category').isString().notEmpty().withMessage('Category is required'),
        body('text').isString().notEmpty().withMessage('Question text is required'),
        body('timeFrame').isObject().withMessage('Time frame must be an object'),
        body('timeFrame.from').exists().withMessage('Time frame from is required'),
        body('timeFrame.to').exists().withMessage('Time frame to is required'),
        body('tag').isString().withMessage('Tag must be a string'),
        body('questionType').isString().withMessage('Question type must be a string'),
        body('subcategory').isString().withMessage('Subcategory must be a string'),
        ...extendedValidation
    ],
    addQuestion
);

router.put(
    '/family/:patient_documentId/edit/:questionId',
    [
        param('patient_documentId').isString().notEmpty().withMessage('Patient document ID is required'),
        param('questionId').isString().notEmpty().withMessage('Question ID is required'),
        body('answerOptions').optional().isArray().withMessage('Answer options must be an array'),
        body('askInterval').optional().isNumeric().withMessage('Ask interval must be a number'),
        body('category').optional().isString().notEmpty().withMessage('Category is required'),
        body('text').optional().isString().notEmpty().withMessage('Question text is required'),
        body('timeFrame').optional().isObject().withMessage('Time frame must be an object'),
        body('tag').optional().isString().withMessage('Tag must be a string'),
        body('questionType').optional().isString().withMessage('Question type must be a string'),
        body('subcategory').optional().isString().withMessage('Subcategory must be a string'),
        ...extendedValidation
    ],
    editQuestion
);

// Delete Question Route
import { deleteQuestion } from '../controller/questions/admin/deleteQuestion.controller.js';

router.delete(
    '/family/:patient_documentId/delete/:questionId',
    [
        param('patient_documentId').isString().notEmpty().withMessage('Patient document ID is required'),
        param('questionId').isString().notEmpty().withMessage('Question ID is required')
    ],
    deleteQuestion
);

export default router;
