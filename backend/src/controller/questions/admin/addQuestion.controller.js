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

        const { category } = req.body;

        // Map category to subcollection
        let subCollectionName = '';
        const { immediate, recent, remote } = config.question_category; // immediateMemory, recentMemory, etc.

        if (category === immediate) subCollectionName = 'immediateQuestions';
        else if (category === recent) subCollectionName = 'recentQuestions';
        else if (category === remote) subCollectionName = 'remoteQuestions';
        else {
            // Fallback or error? User said "ADD THE TYPE".
            // If category is "Personal" or "General" (frontend old default), map to something?
            // But I updated Frontend to send the correct keys.
            // Let's assume valid keys or default to immediateQuestions as safety.
            subCollectionName = 'immediateQuestions';
        }

        // Prepare the question object
        const newQuestion = {
            ...questionData,
            createdAt: new Date().toISOString(), // Use string to match typical Firestore JSON
            addedAt: new Date().toISOString(), // Use string
            isActive: true,
            isAnswered: false,
            timesAsked: 0,
            timesAnsweredCorrectly: 0,
            // Ensure category is set correctly on the doc
            category: category
        };

        // Path: users/{patientId}/questions/{today}/{subCollectionName}
        const today = new Date().toISOString().split('T')[0];

        // Ensure the date document exists (it might not if it's a new day and getDaily hasn't run)
        // Check if date doc exists at users/{pid}/questions/{today}
        // Actually, getDailyQuestions creates it. If we add before getDaily runs, we should create it.
        const dailyQuestionsCollection = config.firestoreNames.personalQuestions_SubCollection; // 'questions'
        const dateDocRef = doc(firestore, USERS_COLLECTION, patient_documentId, dailyQuestionsCollection, today);

        const dateSnap = await getDoc(dateDocRef);
        if (!dateSnap.exists()) {
            await setDoc(dateDocRef, {
                createdAt: new Date().toISOString(),
                date: today
            });
        }

        const questionsRef = collection(dateDocRef, subCollectionName);
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
