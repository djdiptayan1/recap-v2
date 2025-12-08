import {
    doc,
    getDoc,
    setDoc,
    updateDoc,
    collection,
    getDocs
} from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import { calculateStreakMetrics } from '../../utils/streakCalculator.js';
import config from '../../../config.js';
import { validationResult } from 'express-validator';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const STREAKS_COLLECTION = config.firestoreNames.streaks_SubCollection;
// const STREAKS_CORE_COLLECTION = config.firestoreNames.streaksCore_SubCollection;

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

async function ensureCurrentMonthExists(documentId, yearMonth) {
    const streakDocRef = doc(firestore, USERS_COLLECTION, documentId, STREAKS_COLLECTION, yearMonth);
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

async function updateStreak(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }
        const { documentId } = req.body;
        if (!documentId) {
            return res.status(400).json({ success: false, error: 'documentId is required' });
        }

        // Check if user exists
        const userRef = doc(firestore, USERS_COLLECTION, documentId);
        const userSnap = await getDoc(userRef);

        if (!userSnap.exists()) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        const { full: todayFull, yearMonth } = getFormattedDate();

        // 1. Ensure monthly doc exists
        await ensureCurrentMonthExists(documentId, yearMonth);

        // 2. Update today's streak in monthly doc
        const streakDocRef = doc(firestore, USERS_COLLECTION, documentId, STREAKS_COLLECTION, yearMonth);
        await updateDoc(streakDocRef, {
            [todayFull]: true
        });

        // 3. Dynamic Calculation: Fetch ALL streak documents to return updated stats
        const streaksRef = collection(firestore, USERS_COLLECTION, documentId, STREAKS_COLLECTION);
        const snapshot = await getDocs(streaksRef);

        let allStreakData = {};
        snapshot.forEach(doc => {
            const monthData = doc.data();
            Object.assign(allStreakData, monthData);
        });

        // Ensure the current update is reflected (in case of eventual consistency lag, though usually safe within same client context, but good safety)
        allStreakData[todayFull] = true;

        const { currentStreak, maxStreak, activeDays, lastAnsweredDate } = calculateStreakMetrics(allStreakData);

        return res.status(200).json({
            success: true,
            data: {
                currentStreak,
                maxStreak,
                activeDays,
                lastAnsweredDate: lastAnsweredDate ? new Date(lastAnsweredDate) : null
            }
        });
    } catch (err) {
        next(err);
    }
}

export default {
    updateStreak,
};
