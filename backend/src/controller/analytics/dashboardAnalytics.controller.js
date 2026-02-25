import { firestore } from '../../utils/db.js';
import { collection, doc, getDoc, getDocs } from 'firebase/firestore';
import config from '../../../config.js';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const USER_QUESTIONS_COLLECTION = config.firestoreNames.personalQuestions_SubCollection;

const SUBCOLLECTIONS = ['immediateQuestions', 'recentQuestions', 'remoteQuestions'];

/**
 * Fetch all questions for a patient on a given date
 */
async function fetchQuestionsForDate(patientId, dateStr) {
    const dailyDocRef = doc(firestore, USERS_COLLECTION, patientId, USER_QUESTIONS_COLLECTION, dateStr);
    const dailyDocSnap = await getDoc(dailyDocRef);

    if (!dailyDocSnap.exists()) {
        return [];
    }

    const questions = [];
    for (const subCol of SUBCOLLECTIONS) {
        const subColRef = collection(dailyDocRef, subCol);
        const snapshot = await getDocs(subColRef);
        snapshot.docs.forEach(d => {
            questions.push({ id: d.id, ...d.data() });
        });
    }
    return questions;
}

/**
 * Determine if a patient's answer is correct by comparing with correctAnswers
 */
function isAnswerCorrect(question) {
    if (!question.isAnswered) return null; // unanswered

    const correctAnswers = question.correctAnswers || [];
    if (correctAnswers.length === 0) return null; // no correct answers set

    const patientAnswers = question.answers || [];
    const patientAnswer = question.patientAnswer;

    // Build set of patient answers
    const answerSet = new Set();
    if (Array.isArray(patientAnswer)) {
        patientAnswer.forEach(a => answerSet.add(String(a).trim().toLowerCase()));
    } else if (patientAnswer) {
        answerSet.add(String(patientAnswer).trim().toLowerCase());
    }
    patientAnswers.forEach(a => answerSet.add(String(a).trim().toLowerCase()));

    const correctSet = new Set(correctAnswers.map(a => String(a).trim().toLowerCase()));

    // Check if any patient answer matches any correct answer
    for (const ans of answerSet) {
        if (correctSet.has(ans)) return true;
    }
    return false;
}

/**
 * Calculate stats for a set of questions
 */
function calculateStats(questions) {
    let correct = 0;
    let incorrect = 0;
    let unanswered = 0;
    const total = questions.length;

    for (const q of questions) {
        const result = isAnswerCorrect(q);
        if (result === true) correct++;
        else if (result === false) incorrect++;
        else unanswered++;
    }

    const answered = correct + incorrect;
    const score = answered > 0 ? Math.round((correct / answered) * 100 * 10) / 10 : 0;

    return { correct, incorrect, unanswered, total, score };
}

/**
 * Format date as YYYY-MM-DD
 */
function formatDate(date) {
    return date.toISOString().split('T')[0];
}

/**
 * Get short day name
 */
function getDayLabel(date) {
    return date.toLocaleDateString('en-US', { weekday: 'short' });
}

/**
 * Get month short name
 */
function getMonthLabel(date) {
    return date.toLocaleDateString('en-US', { month: 'short' });
}

/**
 * GET /api/analytics/dashboard/:patientId
 * Returns daily, weekly, and monthly analytics for the family-side dashboard
 */
export const getDashboardAnalytics = async (req, res, next) => {
    try {
        const { patientId } = req.params;

        if (!patientId) {
            return res.status(400).json({
                success: false,
                message: 'Patient ID is required'
            });
        }

        // Check if user exists
        const userRef = doc(firestore, USERS_COLLECTION, patientId);
        const userSnap = await getDoc(userRef);

        if (!userSnap.exists()) {
            return res.status(404).json({
                success: false,
                message: 'Patient not found'
            });
        }

        const now = new Date();
        const today = formatDate(now);

        // Cache question data to avoid redundant Firestore reads
        const questionCache = new Map();
        async function getCachedQuestions(dateStr) {
            if (questionCache.has(dateStr)) return questionCache.get(dateStr);
            const questions = await fetchQuestionsForDate(patientId, dateStr);
            questionCache.set(dateStr, questions);
            return questions;
        }

        // 1. Daily stats (today)
        const todayQuestions = await getCachedQuestions(today);
        const dailyStats = calculateStats(todayQuestions);

        // 2. Weekly stats (last 7 days)
        const weeklyData = [];
        for (let i = 6; i >= 0; i--) {
            const d = new Date(now);
            d.setDate(d.getDate() - i);
            const dateStr = formatDate(d);
            const questions = await getCachedQuestions(dateStr);
            const stats = calculateStats(questions);
            weeklyData.push({
                date: dateStr,
                label: getDayLabel(d),
                score: stats.score,
                correct: stats.correct,
                incorrect: stats.incorrect,
                total: stats.total
            });
        }

        // 3. Monthly stats (last 4 months)
        const monthlyData = [];
        for (let i = 3; i >= 0; i--) {
            const monthDate = new Date(now.getFullYear(), now.getMonth() - i, 1);
            const year = monthDate.getFullYear();
            const month = monthDate.getMonth();
            const daysInMonth = new Date(year, month + 1, 0).getDate();

            let totalCorrect = 0;
            let totalAnswered = 0;
            let totalQuestions = 0;

            for (let day = 1; day <= daysInMonth; day++) {
                const d = new Date(year, month, day);
                if (d > now) break; // Don't go past today
                const dateStr = formatDate(d);
                const questions = await getCachedQuestions(dateStr);
                const stats = calculateStats(questions);
                totalCorrect += stats.correct;
                totalAnswered += stats.correct + stats.incorrect;
                totalQuestions += stats.total;
            }

            const score = totalAnswered > 0 ? Math.round((totalCorrect / totalAnswered) * 100 * 10) / 10 : 0;
            monthlyData.push({
                month: `${year}-${String(month + 1).padStart(2, '0')}`,
                label: getMonthLabel(monthDate),
                score,
                correct: totalCorrect,
                total: totalQuestions
            });
        }

        // 4. Decline detection (check last 4 weeks)
        const weeklyScores = [];
        for (let w = 3; w >= 0; w--) {
            let weekCorrect = 0;
            let weekAnswered = 0;
            for (let d = 6; d >= 0; d--) {
                const date = new Date(now);
                date.setDate(date.getDate() - (w * 7 + d));
                const dateStr = formatDate(date);
                const questions = await getCachedQuestions(dateStr);
                const stats = calculateStats(questions);
                weekCorrect += stats.correct;
                weekAnswered += stats.correct + stats.incorrect;
            }
            const weekScore = weekAnswered > 0 ? Math.round((weekCorrect / weekAnswered) * 100 * 10) / 10 : 0;
            weeklyScores.push(weekScore);
        }

        let declineAlert = { detected: false, message: '', weeklyScores };
        // Check for 3 consecutive weeks of decline
        let consecutiveDeclines = 0;
        for (let i = 1; i < weeklyScores.length; i++) {
            if (weeklyScores[i] < weeklyScores[i - 1] && weeklyScores[i - 1] > 0) {
                consecutiveDeclines++;
            } else {
                consecutiveDeclines = 0;
            }
        }

        if (consecutiveDeclines >= 2) { // 3 consecutive declining values = 2 drops
            declineAlert = {
                detected: true,
                message: `Scores have declined for ${consecutiveDeclines + 1} consecutive weeks. Consider consulting a doctor.`,
                weeklyScores
            };
        }

        res.status(200).json({
            success: true,
            data: {
                daily: {
                    correct: dailyStats.correct,
                    incorrect: dailyStats.incorrect,
                    unanswered: dailyStats.unanswered,
                    total: dailyStats.total,
                    score: dailyStats.score
                },
                weekly: weeklyData,
                monthly: monthlyData,
                declineAlert
            }
        });

    } catch (error) {
        next(error);
    }
};
