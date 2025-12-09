import { firestore } from '../../utils/db.js';
import { collection, getDocs, query, where } from 'firebase/firestore';
import config from '../../../config.js';

const getRandomItems = (arr, count) => {
    const shuffled = [...arr].sort(() => 0.5 - Math.random());
    return shuffled.slice(0, count);
};

const COLLECTION_NAME = config.firestoreNames.questionsCollection;

export const getDailyQuestions = async (req, res, next) => {
    try {
        const {
            number_of_immediate_questions,
            number_of_recent_questions,
            number_of_remote_questions
        } = config.questions;

        const {
            immediate,
            recent,
            remote
        } = config.question_category;
        const fetchCategoryQuestions = async (category, count) => {
            const q = query(
                collection(firestore, COLLECTION_NAME),
                where('category', '==', category)
            );
            const snap = await getDocs(q);
            const allQuestions = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            return getRandomItems(allQuestions, count);
        };

        const [selectedImmediate, selectedRecent, selectedRemote] = await Promise.all([
            fetchCategoryQuestions(immediate, number_of_immediate_questions),
            fetchCategoryQuestions(recent, number_of_recent_questions),
            fetchCategoryQuestions(remote, number_of_remote_questions)
        ]);

        const finalQuestions = [
            ...selectedImmediate,
            ...selectedRecent,
            ...selectedRemote
        ];

        res.status(200).json({
            success: true,
            count: finalQuestions.length,
            data: finalQuestions,
            meta: {
                immediate: selectedImmediate.length,
                recent: selectedRecent.length,
                remote: selectedRemote.length
            }
        });

        // const results = await Promise.allSettled([
        //     fetchCategoryQuestions(immediate, number_of_immediate_questions),
        //     fetchCategoryQuestions(recent, number_of_recent_questions),
        //     fetchCategoryQuestions(remote, number_of_remote_questions)
        // ]);

        // const extract = (r) => (r.status === 'fulfilled' ? r.value : []);

        // const selectedImmediate = extract(results[0]);
        // const selectedRecent = extract(results[1]);
        // const selectedRemote = extract(results[2]);

        // const finalQuestions = [
        //     ...selectedImmediate,
        //     ...selectedRecent,
        //     ...selectedRemote
        // ];

        // res.status(200).json({
        //     success: true,
        //     count: finalQuestions.length,
        //     data: finalQuestions,
        //     meta: {
        //         immediate: selectedImmediate.length,
        //         recent: selectedRecent.length,
        //         remote: selectedRemote.length
        //     }
        // });

    } catch (error) {
        next(error);
    }
};
