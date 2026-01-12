
import { firestore } from '../../utils/db.js';
import { doc, updateDoc, arrayUnion } from 'firebase/firestore';
import config from '../../../config.js';
import streakController from '../streaks/updateStreak.controller.js';

const { updateStreak } = streakController;


const USERS_COLLECTION = config.firestoreNames.usersCollection;
const USER_QUESTIONS_COLLECTION = config.firestoreNames.personalQuestions_SubCollection;

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
        // users/{patientId}/questions/{date}/{subCollectionName}/{questionId}
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
            // Family answers go to 'correctAnswers'
            updateData.correctAnswers = arrayUnion(...answersToAdd);
            updateData.updatedAt = new Date().toISOString();
        } else if (answeredBy === 'patient') {
            // Patient answers go to 'answers'
            updateData.answers = arrayUnion(...answersToAdd);
            updateData.isAnswered = true;
            updateData.patientAnswer = answer; // Store latest answer input
            updateData.lastAnsweredDate = new Date().toISOString();
        } else {
            return res.status(400).json({
                success: false,
                message: `Invalid answeredBy value: ${answeredBy}. Must be 'family' or 'patient'.`
            });
        }

        // ...

        await updateDoc(questionRef, updateData);

        // If patient answered, update their streak
        if (answeredBy === 'patient') {
            try {
                // Mock Express objects to reuse the existing controller logic
                const mockReq = { body: { documentId: patientId } };
                const mockRes = {
                    status: (code) => ({
                        json: (data) => console.log(`Internal Streak Update [${code}]:`, data)
                    })
                };
                const mockNext = (err) => console.error("Internal Streak Update Error:", err);

                // Call the controller as if it were a route handler
                await updateStreak(mockReq, mockRes, mockNext);
            } catch (error) {
                console.error('Error updating streak:', error);
            }
        }

        res.status(200).json({
            success: true,
            message: 'Answer submitted successfully',
            data: {
                questionId,
                date,
                updatedField: answeredBy === 'family' ? 'correctAnswers' : 'answers'
            }
        });

    } catch (error) {
        next(error);
    }
};