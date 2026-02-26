import { firestore } from '../../utils/db.js';
import { collection, getDocs, query, where, doc, getDoc, setDoc, writeBatch } from 'firebase/firestore';
import config from '../../../config.js';
import { getLocalToday } from '../../utils/dateUtils.js';

const getRandomItems = (arr, count) => {
    const shuffled = [...arr].sort(() => 0.5 - Math.random());
    return shuffled.slice(0, count);
};

const COLLECTION_NAME = config.firestoreNames.questionsCollection;
const USERS_COLLECTION = config.firestoreNames.usersCollection;
const USER_QUESTIONS_COLLECTION = config.firestoreNames.personalQuestions_SubCollection;



export const getDailyQuestions = async (req, res, next) => {
    try {
        const { patientId } = req.query;

        if (!patientId) {
            return res.status(400).json({
                success: false,
                message: 'patientId query parameter is required'
            });
        }

        // Get today's date string (YYYY-MM-DD) in configured timezone
        const today = getLocalToday();

        // Base reference: users/{patientId}/questions/{today}
        const dailyDocRef = doc(firestore, USERS_COLLECTION, patientId, USER_QUESTIONS_COLLECTION, today);
        const dailyDocSnap = await getDoc(dailyDocRef);

        const subcollections = [
            { name: 'immediateQuestions', category: config.question_category.immediate },
            { name: 'recentQuestions', category: config.question_category.recent },
            { name: 'remoteQuestions', category: config.question_category.remote }
        ];

        if (dailyDocSnap.exists()) {
            // Fetch from subcollections
            const fetchPromises = subcollections.map(async (sub) => {
                const subColRef = collection(dailyDocRef, sub.name);
                const snapshot = await getDocs(subColRef);
                return {
                    name: sub.name,
                    docs: snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }))
                };
            });

            const results = await Promise.all(fetchPromises);
            const allQuestions = results.flatMap(r => r.docs);

            // Calculate counts for metadata
            const counts = results.reduce((acc, curr) => {
                if (curr.name === 'immediateQuestions') acc.immediate = curr.docs.length;
                else if (curr.name === 'recentQuestions') acc.recent = curr.docs.length;
                else if (curr.name === 'remoteQuestions') acc.remote = curr.docs.length;
                return acc;
            }, { immediate: 0, recent: 0, remote: 0 });

            return res.status(200).json({
                success: true,
                count: allQuestions.length,
                data: allQuestions,
                meta: {
                    source: 'persisted',
                    date: today,
                    ...counts
                }
            });
        }

        // --- GENERATE NEW QUESTIONS ---

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

        // Create the batch
        const batch = writeBatch(firestore);

        // 1. Create the main date document
        batch.set(dailyDocRef, {
            createdAt: new Date().toISOString(),
            date: today
        });

        // Helper to add questions to batch
        const addToBatch = (questions, subColName) => {
            questions.forEach(q => {
                const qRef = doc(collection(dailyDocRef, subColName), q.id);
                const questionData = {
                    ...q,
                    isAnswered: false,
                    patientAnswer: null,
                    familyAnswer: null,
                    assignedDate: today,
                    addedAt: new Date().toISOString()
                };
                batch.set(qRef, questionData);
            });
        };

        addToBatch(selectedImmediate, 'immediateQuestions');
        addToBatch(selectedRecent, 'recentQuestions');
        addToBatch(selectedRemote, 'remoteQuestions');

        await batch.commit();

        const finalQuestions = [
            ...selectedImmediate,
            ...selectedRecent,
            ...selectedRemote
        ].map(q => ({
            ...q,
            isAnswered: false,
            patientAnswer: null,
            familyAnswer: null,
            assignedDate: today,
            addedAt: new Date().toISOString()
        }));

        res.status(200).json({
            success: true,
            count: finalQuestions.length,
            data: finalQuestions,
            meta: {
                immediate: selectedImmediate.length,
                recent: selectedRecent.length,
                remote: selectedRemote.length,
                source: 'generated-v2-subcollections'
            }
        });

    } catch (error) {
        next(error);
    }
};
