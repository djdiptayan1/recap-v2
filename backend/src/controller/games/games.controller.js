import {
    addDoc,
    collection,
    doc,
    getDoc,
    getDocs,
    limit,
    orderBy,
    query,
    serverTimestamp,
} from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import config from '../../../config.js';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const GAME_SESSIONS_COLLECTION = config.firestoreNames.gameSessions_SubCollection;
const TIMEZONE = config.timezone || 'Asia/Kolkata';

const SUPPORTED_GAME_TYPES = new Set([
    'dailyObjects',
    'matchMania',
    'numberBubbles',
    'wordAssociation',
    'patternMemory',
]);

function formatDate(date) {
    return date.toLocaleDateString('en-CA', { timeZone: TIMEZONE });
}

function dayLabel(date) {
    return date.toLocaleDateString('en-US', { weekday: 'short', timeZone: TIMEZONE });
}

function toISODate(value) {
    if (!value) return null;
    if (typeof value?.toDate === 'function') {
        return value.toDate().toISOString();
    }
    if (value instanceof Date) {
        return value.toISOString();
    }
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
}

function normalizeNumber(value, fallback = 0) {
    return typeof value === 'number' && Number.isFinite(value) ? value : fallback;
}

function mapSession(docSnap) {
    const data = docSnap.data();
    return {
        id: docSnap.id,
        ...data,
        startedAt: toISODate(data.startedAt),
        completedAt: toISODate(data.completedAt),
        createdAt: toISODate(data.createdAt),
        updatedAt: toISODate(data.updatedAt),
    };
}

function average(values) {
    if (!values.length) return 0;
    const total = values.reduce((sum, value) => sum + value, 0);
    return Math.round((total / values.length) * 10) / 10;
}

function buildGameAnalytics(sessions) {
    const now = new Date();
    const last7DaysCutoff = new Date(now);
    last7DaysCutoff.setDate(last7DaysCutoff.getDate() - 6);

    const last30DaysCutoff = new Date(now);
    last30DaysCutoff.setDate(last30DaysCutoff.getDate() - 29);

    const sessionsLast7Days = sessions.filter(session => {
        const completedAt = new Date(session.completedAt);
        return completedAt >= last7DaysCutoff;
    });

    const sessionsLast30Days = sessions.filter(session => {
        const completedAt = new Date(session.completedAt);
        return completedAt >= last30DaysCutoff;
    });

    const byGameMap = new Map();
    for (const session of sessionsLast30Days) {
        const existing = byGameMap.get(session.gameType) || [];
        existing.push(session);
        byGameMap.set(session.gameType, existing);
    }

    const byGame = Array.from(byGameMap.entries()).map(([gameType, items]) => ({
        gameType,
        sessions: items.length,
        averageScore: average(items.map(item => normalizeNumber(item.score))),
        averageAccuracy: average(items.map(item => normalizeNumber(item.accuracy))),
        bestScore: Math.max(...items.map(item => normalizeNumber(item.score))),
        averageDurationSeconds: average(items.map(item => normalizeNumber(item.durationSeconds))),
        lastPlayedAt: items
            .map(item => item.completedAt)
            .filter(Boolean)
            .sort((a, b) => new Date(b) - new Date(a))[0] ?? null,
    })).sort((a, b) => b.sessions - a.sessions);

    const favoriteGame = byGame[0]?.gameType ?? null;

    const trend = [];
    for (let i = 6; i >= 0; i -= 1) {
        const date = new Date(now);
        date.setDate(date.getDate() - i);
        const key = formatDate(date);
        const daySessions = sessionsLast7Days.filter(session => formatDate(new Date(session.completedAt)) === key);

        trend.push({
            date: key,
            label: dayLabel(date),
            sessions: daySessions.length,
            averageScore: average(daySessions.map(item => normalizeNumber(item.score))),
            averageAccuracy: average(daySessions.map(item => normalizeNumber(item.accuracy))),
        });
    }

    return {
        overall: {
            sessionsLast7Days: sessionsLast7Days.length,
            sessionsLast30Days: sessionsLast30Days.length,
            averageScore: average(sessionsLast30Days.map(item => normalizeNumber(item.score))),
            averageAccuracy: average(sessionsLast30Days.map(item => normalizeNumber(item.accuracy))),
            averageDurationSeconds: average(sessionsLast30Days.map(item => normalizeNumber(item.durationSeconds))),
            favoriteGame,
            lastPlayedAt: sessions[0]?.completedAt ?? null,
        },
        byGame,
        trend,
        recentSessions: sessions.slice(0, 8),
    };
}

export const submitGameSession = async (req, res, next) => {
    try {
        const {
            documentId,
            gameType,
            score,
            durationSeconds,
            startedAt,
            completedAt,
            outcome,
            completed,
            levelReached,
            accuracy,
            mistakes,
            difficulty,
            metadata,
        } = req.body;

        if (!documentId) {
            return res.status(400).json({ success: false, message: 'Document ID is required.' });
        }

        if (!gameType || !SUPPORTED_GAME_TYPES.has(gameType)) {
            return res.status(400).json({ success: false, message: 'Unsupported game type.' });
        }

        const userRef = doc(firestore, USERS_COLLECTION, documentId);
        const userSnap = await getDoc(userRef);
        if (!userSnap.exists()) {
            return res.status(404).json({ success: false, message: 'User not found.' });
        }

        const payload = {
            gameType,
            score: normalizeNumber(score),
            durationSeconds: normalizeNumber(durationSeconds),
            startedAt: startedAt ? new Date(startedAt) : serverTimestamp(),
            completedAt: completedAt ? new Date(completedAt) : serverTimestamp(),
            outcome: outcome || 'completed',
            completed: typeof completed === 'boolean' ? completed : true,
            levelReached: typeof levelReached === 'number' ? levelReached : null,
            accuracy: typeof accuracy === 'number' ? accuracy : null,
            mistakes: normalizeNumber(mistakes),
            difficulty: difficulty || null,
            metadata: metadata && typeof metadata === 'object' ? metadata : {},
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp(),
        };

        const sessionsRef = collection(firestore, USERS_COLLECTION, documentId, GAME_SESSIONS_COLLECTION);
        const sessionRef = await addDoc(sessionsRef, payload);

        return res.status(201).json({
            success: true,
            message: 'Game session saved successfully.',
            data: {
                id: sessionRef.id,
                ...payload,
                startedAt: startedAt || null,
                completedAt: completedAt || null,
            },
        });
    } catch (error) {
        next(error);
    }
};

export const getGameHistory = async (req, res, next) => {
    try {
        const { patientId } = req.params;

        if (!patientId) {
            return res.status(400).json({ success: false, message: 'Patient ID is required.' });
        }

        const userRef = doc(firestore, USERS_COLLECTION, patientId);
        const userSnap = await getDoc(userRef);
        if (!userSnap.exists()) {
            return res.status(404).json({ success: false, message: 'Patient not found.' });
        }

        const sessionsRef = collection(firestore, USERS_COLLECTION, patientId, GAME_SESSIONS_COLLECTION);
        const sessionsQuery = query(sessionsRef, orderBy('completedAt', 'desc'), limit(50));
        const snapshot = await getDocs(sessionsQuery);
        const sessions = snapshot.docs.map(mapSession);

        return res.status(200).json({ success: true, data: sessions });
    } catch (error) {
        next(error);
    }
};

export const getGameAnalytics = async (req, res, next) => {
    try {
        const { patientId } = req.params;

        if (!patientId) {
            return res.status(400).json({ success: false, message: 'Patient ID is required.' });
        }

        const userRef = doc(firestore, USERS_COLLECTION, patientId);
        const userSnap = await getDoc(userRef);
        if (!userSnap.exists()) {
            return res.status(404).json({ success: false, message: 'Patient not found.' });
        }

        const sessionsRef = collection(firestore, USERS_COLLECTION, patientId, GAME_SESSIONS_COLLECTION);
        const sessionsQuery = query(sessionsRef, orderBy('completedAt', 'desc'), limit(200));
        const snapshot = await getDocs(sessionsQuery);
        const sessions = snapshot.docs.map(mapSession);

        return res.status(200).json({
            success: true,
            data: buildGameAnalytics(sessions),
        });
    } catch (error) {
        next(error);
    }
};
