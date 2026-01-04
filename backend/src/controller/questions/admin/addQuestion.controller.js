import {
    collection,
    doc,
    addDoc,
    getDoc,
    Timestamp
} from 'firebase/firestore';
import { firestore } from '../../../utils/db.js';
import config from '../../../../config.js';
import { validationResult } from 'express-validator';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const QUESTIONS_SUBCOLLECTION = config.firestoreNames.personalQuestions_SubCollection;

export const addQuestion = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patient_documentId } = req.params;
        const questionData = req.body;

        if (!patient_documentId) {
            return res.status(400).json({ success: false, error: 'Patient document ID is required' });
        }

        // Verify patient exists
        const userRef = doc(firestore, USERS_COLLECTION, patient_documentId);
        const userSnap = await getDoc(userRef);

        if (!userSnap.exists()) {
            return res.status(404).json({ success: false, error: 'Patient not found' });
        }

        // Prepare the question object
        // Ensure default values are set if not provided, though the user request suggests they might send a full object.
        // We'll trust the body for now but add server-side timestamps.
        const newQuestion = {
            ...questionData,
            createdAt: Timestamp.now(),
            addedAt: Timestamp.now(),
            isActive: true,
            isAnswered: false,
            timesAsked: 0,
            timesAnsweredCorrectly: 0
        };

        const questionsRef = collection(firestore, USERS_COLLECTION, patient_documentId, QUESTIONS_SUBCOLLECTION);
        const docRef = await addDoc(questionsRef, newQuestion);

        return res.status(201).json({
            success: true,
            message: 'Question added successfully',
            data: { id: docRef.id, ...newQuestion }
        });

    } catch (error) {
        console.error('Error adding question:', error);
        next(error);
    }
};
