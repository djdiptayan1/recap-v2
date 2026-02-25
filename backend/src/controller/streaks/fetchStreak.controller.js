import {
    doc,
    getDoc,
    collection,
    getDocs,
} from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import { calculateStreakMetrics } from '../../utils/streakCalculator.js';
import config from '../../../config.js';
import { validationResult } from 'express-validator';
import { getLocalToday } from '../../utils/dateUtils.js';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const STREAKS_COLLECTION = config.firestoreNames.streaks_SubCollection;
// const STREAKS_CORE_COLLECTION = config.firestoreNames.streaksCore_SubCollection;

async function getStreakStats(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }
        const { documentId } = req.params;

        // Check if user exists
        const userRef = doc(firestore, USERS_COLLECTION, documentId);
        const userSnap = await getDoc(userRef);

        if (!userSnap.exists()) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        // Fetch ALL streak documents
        const streaksRef = collection(firestore, USERS_COLLECTION, documentId, STREAKS_COLLECTION);
        const snapshot = await getDocs(streaksRef);

        let allStreakData = {};
        snapshot.forEach(doc => {
            const monthData = doc.data();
            // Merge this month's data into the master object
            // keys are 'YYYY-MM-DD'
            Object.assign(allStreakData, monthData);
        });

        const { currentStreak, maxStreak, activeDays, lastAnsweredDate } = calculateStreakMetrics(allStreakData);

        // Determine if answered today
        const todayStr = getLocalToday();
        const answeredToday = !!allStreakData[todayStr];

        return res.status(200).json({
            success: true,
            data: {
                currentStreak,
                maxStreak,
                activeDays,
                answeredToday,
                lastAnsweredDate: lastAnsweredDate ? new Date(lastAnsweredDate) : null,
                totalQuestionsAnswered: activeDays // Approximate, or if stored separately kept elsewhere. Assuming 1 Q per day for now based on 'activeDays' logic request.
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

        // Check if user exists
        const userRef = doc(firestore, USERS_COLLECTION, documentId);
        const userSnap = await getDoc(userRef);

        if (!userSnap.exists()) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

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

        // Check if user exists
        const userRef = doc(firestore, USERS_COLLECTION, documentId);
        const userSnap = await getDoc(userRef);

        if (!userSnap.exists()) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

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
