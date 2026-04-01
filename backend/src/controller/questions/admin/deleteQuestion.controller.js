import {
    doc,
    getDoc,
    deleteDoc
} from 'firebase/firestore';
import { firestore } from '../../../utils/db.js';
import config from '../../../../config.js';
import { validationResult } from 'express-validator';
import { getLocalToday } from '../../../utils/dateUtils.js';

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

        // Verify question exists - Check subcollections first
        const today = getLocalToday();
        const dailyDocRef = doc(firestore, USERS_COLLECTION, patient_documentId, QUESTIONS_SUBCOLLECTION, today);

        let questionRef = null;
        let questionSnap = null;

        const subcollections = ['immediateQuestions', 'recentQuestions', 'remoteQuestions'];

        const promises = subcollections.map(async (sub) => {
            const tempRef = doc(dailyDocRef, sub, questionId);
            const tempSnap = await getDoc(tempRef);
            return { tempRef, tempSnap };
        });

        const results = await Promise.all(promises);

        const found = results.find(result => result.tempSnap.exists());
        if (found) {
            questionRef = found.tempRef;
            questionSnap = found.tempSnap;
        }

        // Fallback to legacy path if not found in daily subcollections
        if (!questionSnap) {
            const legacyRef = doc(firestore, USERS_COLLECTION, patient_documentId, QUESTIONS_SUBCOLLECTION, questionId);
            const legacySnap = await getDoc(legacyRef);
            if (legacySnap.exists()) {
                questionRef = legacyRef;
                questionSnap = legacySnap;
            }
        }

        if (!questionSnap) {
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
