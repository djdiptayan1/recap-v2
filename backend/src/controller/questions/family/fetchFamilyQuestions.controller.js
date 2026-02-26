import {
    collection,
    getDocs,
    doc,
    getDoc,
    query,
    orderBy
} from 'firebase/firestore';
import { firestore } from '../../../utils/db.js';
import config from '../../../../config.js';
import { getLocalToday } from '../../../utils/dateUtils.js';

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

        const today = getLocalToday();
        // The daily questions are stored under: users/{pid}/questions/{today}
        const dailyDocRef = doc(firestore, USERS_COLLECTION, patient_documentId, QUESTIONS_SUBCOLLECTION, today);
        const dailyDocSnap = await getDoc(dailyDocRef);

        let allQuestions = [];

        if (dailyDocSnap.exists()) {
            const { immediate, recent, remote } = config.question_category;
            const subcollections = [
                { name: 'immediateQuestions', category: immediate },
                { name: 'recentQuestions', category: recent },
                { name: 'remoteQuestions', category: remote }
            ];

            const fetchPromises = subcollections.map(async (sub) => {
                const subColRef = collection(dailyDocRef, sub.name);
                // We can't easily order by createdAt across multiple subcollections without combining first, 
                // or we query each and sort in memory.
                // For simplicity, fetch all and sort in memory.
                const snapshot = await getDocs(subColRef);
                return snapshot.docs.map(doc => ({
                    id: doc.id,
                    ...doc.data(),
                    // Ensure category is set if missing, though it should be there
                    category: doc.data().category || sub.category
                }));
            });

            const results = await Promise.all(fetchPromises);
            allQuestions = results.flat();
        }

        // Sort in memory
        allQuestions.sort((a, b) => {
            const dateA = new Date(a.createdAt || 0);
            const dateB = new Date(b.createdAt || 0);
            return sortOrder === 'asc' ? dateA - dateB : dateB - dateA;
        });

        return res.status(200).json({
            success: true,
            count: allQuestions.length,
            order: sortOrder,
            meta: { date: today, source: 'daily-subcollections' },
            data: allQuestions
        });

    } catch (error) {
        console.error('Error fetching family questions:', error);
        next(error);
    }
};