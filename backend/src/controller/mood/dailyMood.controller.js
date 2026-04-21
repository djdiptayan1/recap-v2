import {
    collection,
    deleteDoc,
    doc,
    getDoc,
    getDocs,
    limit as limitFn,
    orderBy,
    query,
    serverTimestamp,
    setDoc,
} from 'firebase/firestore';
import { validationResult } from 'express-validator';
import config from '../../../config.js';
import { firestore } from '../../utils/db.js';
import { DAILY_MOOD_LOOKUP } from '../../models/dailyMood.model.js';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const DAILY_MOOD_SUBCOLLECTION = config.firestoreNames.dailyMood_SubCollection;
const ANALYTICS_CACHE_COLLECTION = config.firestoreNames.analyticsCache_SubCollection;
const TIMEZONE = config.timezone || 'Asia/Kolkata';

function formatDate(date) {
    return date.toLocaleDateString('en-CA', { timeZone: TIMEZONE });
}

function serializeMoodEntry(id, data) {
    const result = { id };

    for (const [key, value] of Object.entries(data || {})) {
        if (value && typeof value.toDate === 'function') {
            result[key] = value.toDate().toISOString();
        } else {
            result[key] = value;
        }
    }

    return result;
}

function moodDocRef(patientId, dateKey) {
    return doc(firestore, USERS_COLLECTION, patientId, DAILY_MOOD_SUBCOLLECTION, dateKey);
}

function moodCollectionRef(patientId) {
    return collection(firestore, USERS_COLLECTION, patientId, DAILY_MOOD_SUBCOLLECTION);
}

async function invalidateAnalyticsCache(patientId, dateKey) {
    try {
        const cacheRef = doc(
            firestore,
            USERS_COLLECTION,
            patientId,
            ANALYTICS_CACHE_COLLECTION,
            dateKey
        );
        await deleteDoc(cacheRef);
    } catch (error) {
        console.error('Failed to invalidate analytics cache after mood update:', error);
    }
}

async function upsertMoodEntry(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patientId, moodKey } = req.body;
        const userRef = doc(firestore, USERS_COLLECTION, patientId);
        const userSnap = await getDoc(userRef);

        if (!userSnap.exists()) {
            return res.status(404).json({ success: false, message: 'Patient not found' });
        }

        const mood = DAILY_MOOD_LOOKUP[moodKey];
        const dateKey = formatDate(new Date());
        const entryRef = moodDocRef(patientId, dateKey);
        const existingSnap = await getDoc(entryRef);

        const payload = {
            patientId,
            dateKey,
            moodKey: mood.key,
            label: mood.label,
            score: mood.score,
            updatedAt: serverTimestamp(),
        };

        if (!existingSnap.exists()) {
            payload.createdAt = serverTimestamp();
        }

        await setDoc(entryRef, payload, { merge: true });
        await invalidateAnalyticsCache(patientId, dateKey);

        const savedSnap = await getDoc(entryRef);
        return res.status(200).json({
            success: true,
            data: serializeMoodEntry(savedSnap.id, savedSnap.data()),
        });
    } catch (error) {
        next(error);
    }
}

async function getTodayMood(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patientId } = req.params;
        const dateKey = formatDate(new Date());
        const moodSnap = await getDoc(moodDocRef(patientId, dateKey));

        return res.status(200).json({
            success: true,
            data: moodSnap.exists() ? serializeMoodEntry(moodSnap.id, moodSnap.data()) : null,
        });
    } catch (error) {
        next(error);
    }
}

async function getMoodHistory(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patientId } = req.params;
        const days = Math.min(30, Math.max(1, parseInt(req.query.days, 10) || 7));

        const moodQuery = query(
            moodCollectionRef(patientId),
            orderBy('dateKey', 'desc'),
            limitFn(days)
        );
        const snapshot = await getDocs(moodQuery);
        const data = snapshot.docs.map(docSnap => serializeMoodEntry(docSnap.id, docSnap.data()));

        return res.status(200).json({
            success: true,
            data,
            count: data.length,
        });
    } catch (error) {
        next(error);
    }
}

export default {
    upsertMoodEntry,
    getTodayMood,
    getMoodHistory,
};
