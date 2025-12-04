import {
    doc,
    getDoc,
    setDoc,
    updateDoc,
    serverTimestamp,
} from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import config from '../../../config.js';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const STREAKS_COLLECTION = config.firestoreNames.streaksCollection;
const STREAKS_CORE_COLLECTION = config.firestoreNames.streaksCoreCollection;

// Helper to get formatted date strings
const getFormattedDate = (date = new Date()) => {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return {
        full: `${year}-${month}-${day}`,
        yearMonth: `${year}-${month}`,
    };
};

const getDaysInMonth = (yearMonth) => {
    const [year, month] = yearMonth.split('-').map(Number);
    return new Date(year, month, 0).getDate();
};

async function ensureCurrentMonthExists(userId, yearMonth) {
    const streakDocRef = doc(firestore, USERS_COLLECTION, userId, STREAKS_COLLECTION, yearMonth);
    const docSnap = await getDoc(streakDocRef);

    if (!docSnap.exists()) {
        const totalDays = getDaysInMonth(yearMonth);
        const streakData = {};
        for (let day = 1; day <= totalDays; day++) {
            const dayStr = String(day).padStart(2, '0');
            streakData[`${yearMonth}-${dayStr}`] = false;
        }
        await setDoc(streakDocRef, streakData);
    }
}

async function ensureStreaksCoreExists(userId) {
    const coreRef = doc(firestore, USERS_COLLECTION, userId, STREAKS_CORE_COLLECTION, 'streakData');
    const docSnap = await getDoc(coreRef);

    if (!docSnap.exists()) {
        await setDoc(coreRef, { initialized: true }, { merge: true });
    }
}

async function calculateStreakStats(userId) {
    await ensureStreaksCoreExists(userId);
    const coreRef = doc(firestore, USERS_COLLECTION, userId, STREAKS_CORE_COLLECTION, 'streakData');
    const docSnap = await getDoc(coreRef);

    if (!docSnap.exists()) return;

    const data = docSnap.data();
    const maxStreak = data.maxStreak || 0;
    const currentStreak = data.currentStreak || 0;
    const activeDays = data.activeDays || 0;
    const lastAnsweredDate = data.lastAnsweredDate ? data.lastAnsweredDate.toDate() : new Date(0);
    const totalQuestionsAnswered = data.totalQuestionsAnswered || 0;
    const correctAnswers = data.correctAnswers || 0;
    let longestBreak = data.longestBreak || 0;

    const today = new Date();
    const todayDate = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const lastDate = new Date(lastAnsweredDate.getFullYear(), lastAnsweredDate.getMonth(), lastAnsweredDate.getDate());

    const diffTime = Math.abs(todayDate - lastDate);
    const daysSinceLastAnswer = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    let newCurrentStreak = currentStreak;
    let newMaxStreak = maxStreak;
    let newActiveDays = activeDays;
    let newAnsweredToday = false;
    let newLongestBreak = longestBreak;
    const newTotalQuestionsAnswered = totalQuestionsAnswered + 1;

    if (daysSinceLastAnswer === 0) {
        newAnsweredToday = true;
    } else if (daysSinceLastAnswer === 1) {
        newCurrentStreak += 1;
        newActiveDays += 1;
        newAnsweredToday = true;
    } else {
        newCurrentStreak = 1; // Reset to 1 if break > 1 day
        newAnsweredToday = true;
        newActiveDays += 1;
        if (totalQuestionsAnswered > 0) {
            newLongestBreak = Math.max(newLongestBreak, daysSinceLastAnswer);
        }
    }

    newMaxStreak = Math.max(newMaxStreak, newCurrentStreak);

    await setDoc(coreRef, {
        maxStreak: newMaxStreak,
        answeredToday: newAnsweredToday,
        currentStreak: newCurrentStreak,
        activeDays: newActiveDays,
        totalQuestionsAnswered: newTotalQuestionsAnswered,
        correctAnswers: correctAnswers,
        longestBreak: newLongestBreak,
        lastAnsweredDate: serverTimestamp(),
    }, { merge: true });

    return {
        maxStreak: newMaxStreak,
        currentStreak: newCurrentStreak,
        activeDays: newActiveDays,
    };
}

async function updateStreak(req, res, next) {
    try {
        const { userId } = req.body;
        if (!userId) {
            return res.status(400).json({ success: false, error: 'UserId is required' });
        }

        const { full: todayFull, yearMonth } = getFormattedDate();

        // 1. Ensure monthly doc exists
        await ensureCurrentMonthExists(userId, yearMonth);

        // 2. Update today's streak in monthly doc
        const streakDocRef = doc(firestore, USERS_COLLECTION, userId, STREAKS_COLLECTION, yearMonth);
        await updateDoc(streakDocRef, {
            [todayFull]: true
        });

        // 3. Calculate and update core stats
        const stats = await calculateStreakStats(userId);

        return res.status(200).json({ success: true, data: stats });
    } catch (err) {
        next(err);
    }
}

export default {
    updateStreak,
};
