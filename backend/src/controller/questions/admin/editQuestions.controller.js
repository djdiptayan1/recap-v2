import {
    doc,
    getDoc,
    updateDoc,
    serverTimestamp
} from 'firebase/firestore';
import { firestore } from '../../../utils/db.js';
import config from '../../../../config.js';
import { validationResult } from 'express-validator';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const QUESTIONS_SUBCOLLECTION = config.firestoreNames.personalQuestions_SubCollection;

export const editQuestion = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patient_documentId, questionId } = req.params;
        const updateData = req.body;

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
        // Search for question in subcollections under today's date
        const today = new Date().toISOString().split('T')[0];
        const dailyDocRef = doc(firestore, USERS_COLLECTION, patient_documentId, QUESTIONS_SUBCOLLECTION, today);

        const subcollections = ['immediateQuestions', 'recentQuestions', 'remoteQuestions'];
        let foundSubCollection = null;
        let questionSnap = null;
        let questionRef = null;

        for (const subName of subcollections) {
            const tempRef = doc(dailyDocRef, subName, questionId);
            const tempSnap = await getDoc(tempRef);
            if (tempSnap.exists()) {
                foundSubCollection = subName;
                questionSnap = tempSnap;
                questionRef = tempRef;
                break;
            }
        }

        if (!questionSnap) {
            return res.status(404).json({ success: false, error: 'Question not found' });
        }

        // Add updatedAt timestamp
        const finalUpdateData = {
            ...updateData,
            updatedAt: serverTimestamp()
        };

        // Remove fields that shouldn't be updated loosely if necessary, but for now allow all
        // Prevent updating ID or immutable fields if they exist in body (optional but good practice)
        delete finalUpdateData.id;
        delete finalUpdateData.createdAt;
        delete finalUpdateData.addedAt; // Maybe preserve original addedAt

        await updateDoc(questionRef, finalUpdateData);

        return res.status(200).json({
            success: true,
            message: 'Question updated successfully',
            data: { id: questionId, ...finalUpdateData }
        });

    } catch (error) {
        console.error('Error editing question:', error);
        next(error);
    }
};
