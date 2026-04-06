
import { firestore } from '../../utils/db.js';
import { doc, updateDoc, arrayUnion } from 'firebase/firestore';
import config from '../../../config.js';
import streakController from '../streaks/updateStreak.controller.js';

const { updateStreak } = streakController;


const USERS_COLLECTION = config.firestoreNames.usersCollection;
const USER_QUESTIONS_COLLECTION = config.firestoreNames.personalQuestions_SubCollection;
const ANALYTICS_CACHE_COLLECTION = config.firestoreNames.analyticsCache_SubCollection;

export const answerDailyQuestion = async (req, res, next) => {
    try {
        const { patientId, questionId, answer, answeredBy, date, category } = req.body;
        console.log("Answer Request Body:", req.body);

        // Validation
        if (!patientId || !questionId || !answer || !answeredBy || !date || !category) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: patientId, questionId, answer, answeredBy, date, category'
            });
        }

        // Map category to subcollection
        let subCollectionName = '';
        if (category === config.question_category.immediate) subCollectionName = 'immediateQuestions';
        else if (category === config.question_category.recent) subCollectionName = 'recentQuestions';
        else if (category === config.question_category.remote) subCollectionName = 'remoteQuestions';
        else {
            return res.status(400).json({
                success: false,
                message: `Invalid category: ${category}`
            });
        }

        // Construct document reference
        const questionRef = doc(
            firestore,
            USERS_COLLECTION,
            patientId,
            USER_QUESTIONS_COLLECTION,
            date,
            subCollectionName,
            questionId
        );

        const updateData = {};
        const answersToAdd = Array.isArray(answer) ? answer : [answer];

        if (answeredBy === 'family') {
            updateData.correctAnswers = arrayUnion(...answersToAdd);
            updateData.updatedAt = new Date().toISOString();
        } else if (answeredBy === 'patient') {
            updateData.answers = arrayUnion(...answersToAdd);
            updateData.isAnswered = true;
            updateData.patientAnswer = answer;
            updateData.lastAnsweredDate = new Date().toISOString();
        } else {
            return res.status(400).json({
                success: false,
                message: `Invalid answeredBy value: ${answeredBy}`
            });
        }

        // Prepare background tasks
        const backgroundTasks = [updateDoc(questionRef, updateData)];

        // 1. Parallel Streak Update
        if (answeredBy === 'patient') {
            const streakTask = (async () => {
                try {
                    const mockReq = { body: { documentId: patientId } };
                    const mockRes = { status: () => ({ json: () => {} }) };
                    const mockNext = () => {};
                    await updateStreak(mockReq, mockRes, mockNext);
                } catch (e) { console.error("Streak update error:", e); }
            })();
            backgroundTasks.push(streakTask);
        }

        // 2. Parallel Cache Invalidation
        const cacheDocRef = doc(firestore, USERS_COLLECTION, patientId, ANALYTICS_CACHE_COLLECTION, date);
        backgroundTasks.push(updateDoc(cacheDocRef, { updatedAt: new Date().getTime() }).catch(() => {}));

        // Fire all in parallel
        await Promise.all(backgroundTasks);

        res.status(200).json({
            success: true,
            message: 'Answer submitted successfully',
            data: { questionId, date }
        });

    } catch (error) {
        next(error);
    }
};
