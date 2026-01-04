import {
    doc,
    getDoc,
    deleteDoc
} from 'firebase/firestore';
import { firestore } from '../../../utils/db.js';
import config from '../../../../config.js';
import { validationResult } from 'express-validator';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const QUESTIONS_SUBCOLLECTION = config.firestoreNames.personalQuestions_SubCollection;

export const deleteQuestion = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patient_documentId, questionId } = req.params;

        if (!patient_documentId) {
            return res.status(400).json({ success: false, error: 'Patient document ID is required' });
        }
        if (!questionId) {
            return res.status(400).json({ success: false, error: 'Question ID is required' });
        }

        // Verify patient exists
        const userRef = doc(firestore, USERS_COLLECTION, patient_documentId);
        const userSnap = await getDoc(userRef);

        if (!userSnap.exists()) {
            return res.status(404).json({ success: false, error: 'Patient not found' });
        }

        // Verify question exists
        const questionRef = doc(firestore, USERS_COLLECTION, patient_documentId, QUESTIONS_SUBCOLLECTION, questionId);
        const questionSnap = await getDoc(questionRef);

        if (!questionSnap.exists()) {
            return res.status(404).json({ success: false, error: 'Question not found' });
        }

        await deleteDoc(questionRef);

        return res.status(200).json({
            success: true,
            message: 'Question deleted successfully',
            data: { id: questionId }
        });

    } catch (error) {
        console.error('Error deleting question:', error);
        next(error);
    }
};
