import {
    doc,
    getDoc,
    collection,
    getDocs,
} from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import config from '../../../config.js';
import { validationResult } from 'express-validator';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const STREAKS_COLLECTION = config.firestoreNames.streaks_SubCollection;
const STREAKS_CORE_COLLECTION = config.firestoreNames.streaksCore_SubCollection;

async function getStreakStats(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }
        const { documentId } = req.params;
        const coreRef = doc(firestore, USERS_COLLECTION, documentId, STREAKS_CORE_COLLECTION, 'streakData');
        const docSnap = await getDoc(coreRef);

        if (!docSnap.exists()) {
            return res.status(200).json({ success: true, data: { initialized: false } });
        }

        const data = docSnap.data();

        // Calculate effective streak for display
        const lastAnsweredDate = data.lastAnsweredDate ? data.lastAnsweredDate.toDate() : new Date(0);
        const today = new Date();
        const todayDate = new Date(today.getFullYear(), today.getMonth(), today.getDate());
        const lastDate = new Date(lastAnsweredDate.getFullYear(), lastAnsweredDate.getMonth(), lastAnsweredDate.getDate());

        const diffTime = Math.abs(todayDate - lastDate);
        const daysSinceLastAnswer = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

        let effectiveCurrentStreak = data.currentStreak || 0;
        let effectiveAnsweredToday = false;

        if (daysSinceLastAnswer === 0) {
            effectiveAnsweredToday = true;
        } else if (daysSinceLastAnswer > 1) {
            effectiveCurrentStreak = 0;
        }

        return res.status(200).json({
            success: true,
            data: {
                ...data,
                currentStreak: effectiveCurrentStreak,
                answeredToday: effectiveAnsweredToday
            }
        });
    } catch (err) {
        next(err);
    }
}

async function getMonthStreak(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }
        const { documentId } = req.params;
        const { yearMonth } = req.query; // e.g., 2025-04

        if (!yearMonth) {
            return res.status(400).json({ success: false, error: 'yearMonth query param is required (YYYY-MM)' });
        }

        const streakDocRef = doc(firestore, USERS_COLLECTION, documentId, STREAKS_COLLECTION, yearMonth);
        const docSnap = await getDoc(streakDocRef);

        if (!docSnap.exists()) {
            return res.status(404).json({ success: false, error: 'Streak data not found for this month' });
        }

        return res.status(200).json({ success: true, data: docSnap.data() });
    } catch (err) {
        next(err);
    }
}

async function getYearStreaks(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }
        const { documentId } = req.params;
        const { year } = req.query; // e.g., 2025

        if (!year) {
            return res.status(400).json({ success: false, error: 'year query param is required (YYYY)' });
        }

        const streaksRef = collection(firestore, USERS_COLLECTION, documentId, STREAKS_COLLECTION);
        const snap = await getDocs(streaksRef);

        const data = {};
        snap.docs.forEach(d => {
            if (d.id.startsWith(year)) {
                data[d.id] = d.data();
            }
        });

        return res.status(200).json({ success: true, data });
    } catch (err) {
        next(err);
    }
}

export default {
    getStreakStats,
    getMonthStreak,
    getYearStreaks,
};
