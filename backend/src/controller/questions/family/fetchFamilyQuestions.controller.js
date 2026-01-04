import {
    collection,
    getDocs,
    doc,
    query,
    orderBy
} from 'firebase/firestore';
import { firestore } from '../../../utils/db.js';
import config from '../../../../config.js';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const QUESTIONS_SUBCOLLECTION = config.firestoreNames.personalQuestions_SubCollection;

export const getFamilyQuestions = async (req, res, next) => {
    try {
        const { patient_documentId } = req.params;
        const { order = 'desc' } = req.query;

        if (!patient_documentId) {
            return res.status(400).json({
                success: false,
                error: 'Patient document ID is required'
            });
        }

        // Normalize sort order
        const sortOrder = order === 'asc' ? 'asc' : 'desc';

        const questionsRef = collection(
            firestore,
            USERS_COLLECTION,
            patient_documentId,
            QUESTIONS_SUBCOLLECTION
        );

        // Firestore ordered query
        const questionsQuery = query(
            questionsRef,
            orderBy('createdAt', sortOrder)
        );

        const snapshot = await getDocs(questionsQuery);

        const questions = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        return res.status(200).json({
            success: true,
            count: questions.length,
            order: sortOrder,
            data: questions
        });

    } catch (error) {
        console.error('Error fetching family questions:', error);
        next(error);
    }
};