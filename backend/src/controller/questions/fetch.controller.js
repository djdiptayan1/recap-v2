import { firestore } from '../../utils/db.js';
import { collection, getDocs, query, where } from 'firebase/firestore';
import config from '../../../config.js';

/**
 * Fetches all questions or filters by category if provided.
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 */
const COLLECTION_NAME = config.firestoreNames.questionsCollection;

export const getQuestions = async (req, res, next) => {
    try {
        const { category } = req.query;
        let q;

        if (category) {
            const mappedCategory = config.question_category[category] || category;

            q = query(
                collection(firestore, COLLECTION_NAME),
                where('category', '==', mappedCategory)
            );
        } else {
            q = collection(firestore, COLLECTION_NAME);
        }

        const querySnapshot = await getDocs(q);
        const questions = [];

        querySnapshot.forEach((doc) => {
            questions.push({
                id: doc.id,
                ...doc.data()
            });
        });

        res.status(200).json({
            success: true,
            count: questions.length,
            data: questions
        });
    } catch (error) {
        next(error);
    }
};