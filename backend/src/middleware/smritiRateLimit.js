import { firestore } from '../utils/db.js';
import { doc, getDoc, setDoc, Timestamp } from 'firebase/firestore';
import config from '../../config.js';

/**
 * Get the start of the current day in the configured timezone (IST by default).
 * Returns a JS Date representing midnight of today in that timezone.
 */
function getStartOfDay() {
    const now = new Date();
    const dateStr = now.toLocaleDateString('en-CA', { timeZone: config.timezone }); // 'YYYY-MM-DD'
    // Create date at midnight UTC, then adjust — but since we compare same-tz, just use the date string
    return new Date(dateStr + 'T00:00:00');
}

/**
 * Get the start of the current week (Monday) in the configured timezone.
 * Returns a JS Date representing Monday 00:00 of the current week.
 */
function getStartOfWeek() {
    const now = new Date();
    const dateStr = now.toLocaleDateString('en-CA', { timeZone: config.timezone });
    const today = new Date(dateStr + 'T00:00:00');
    const dayOfWeek = today.getDay(); // 0 = Sunday, 1 = Monday, ...
    const diff = dayOfWeek === 0 ? 6 : dayOfWeek - 1; // Days since Monday
    today.setDate(today.getDate() - diff);
    return today;
}

/**
 * Get the next daily reset time (tomorrow midnight in configured timezone).
 */
function getNextDailyReset() {
    const startOfDay = getStartOfDay();
    startOfDay.setDate(startOfDay.getDate() + 1);
    return startOfDay;
}

/**
 * Get the next weekly reset time (next Monday midnight in configured timezone).
 */
function getNextWeeklyReset() {
    const startOfWeek = getStartOfWeek();
    startOfWeek.setDate(startOfWeek.getDate() + 7);
    return startOfWeek;
}

/**
 * Express middleware: enforces per-user rate limits for Smriti AI endpoints.
 *
 * - Skips rate limiting if aiProvider !== 'gemini' (future-proofing for Apple Intelligence)
 * - Tracks daily and weekly usage in Firestore
 * - Returns HTTP 429 with structured error when limit exceeded
 * - Attaches usage info to req.smritiUsage for downstream use
 */
export async function smritiRateLimit(req, res, next) {
    try {
        const { aiProvider, rateLimits, firestoreCollection } = config.smriti;

        // Future-proofing: skip rate limiting for non-Gemini providers
        if (aiProvider !== 'gemini') {
            req.smritiUsage = {
                dailyRemaining: Infinity,
                weeklyRemaining: Infinity,
                rateLimited: false,
                aiProvider,
            };
            return next();
        }

        const userIdentifier = req.body.userIdentifier;
        if (!userIdentifier) {
            return res.status(400).json({
                error: 'userIdentifier is required',
                message: 'Please provide a userIdentifier to use Smriti AI.',
            });
        }

        const compositeId = `${userIdentifier}_${aiProvider}`;
        const usageRef = doc(firestore, firestoreCollection, compositeId);
        const usageSnap = await getDoc(usageRef);

        const startOfDay = getStartOfDay();
        const startOfWeek = getStartOfWeek();

        let dailyCount = 0;
        let weeklyCount = 0;

        if (usageSnap.exists()) {
            const data = usageSnap.data();

            // Check if daily counter needs reset
            const lastDailyReset = data.lastDailyReset?.toDate?.() || new Date(0);
            if (lastDailyReset < startOfDay) {
                dailyCount = 0; // New day — reset
            } else {
                dailyCount = data.dailyCount || 0;
            }

            // Check if weekly counter needs reset
            const lastWeeklyReset = data.lastWeeklyReset?.toDate?.() || new Date(0);
            if (lastWeeklyReset < startOfWeek) {
                weeklyCount = 0; // New week — reset
            } else {
                weeklyCount = data.weeklyCount || 0;
            }
        }

        const dailyRemaining = Math.max(0, rateLimits.daily - dailyCount);
        const weeklyRemaining = Math.max(0, rateLimits.weekly - weeklyCount);

        // Check if rate limited
        if (dailyRemaining <= 0 || weeklyRemaining <= 0) {
            const isDailyLimited = dailyRemaining <= 0;
            const resetAt = isDailyLimited
                ? getNextDailyReset().toISOString()
                : getNextWeeklyReset().toISOString();

            return res.status(429).json({
                error: 'Rate limit exceeded',
                message: isDailyLimited
                    ? `You've reached your daily limit of ${rateLimits.daily} messages. Come back tomorrow! 💛`
                    : `You've reached your weekly limit of ${rateLimits.weekly} messages. Your quota resets on Monday! 💛`,
                dailyRemaining: 0,
                weeklyRemaining: Math.max(0, weeklyRemaining),
                dailyLimit: rateLimits.daily,
                weeklyLimit: rateLimits.weekly,
                resetAt,
                aiProvider,
            });
        }

        // Attach increment function to request
        req.incrementSmritiUsage = async () => {
            const newDailyCount = dailyCount + 1;
            const newWeeklyCount = weeklyCount + 1;
            await setDoc(usageRef, {
                dailyCount: newDailyCount,
                weeklyCount: newWeeklyCount,
                lastDailyReset: Timestamp.fromDate(startOfDay),
                lastWeeklyReset: Timestamp.fromDate(startOfWeek),
                aiProvider,
                updatedAt: Timestamp.now(),
            }, { merge: true });
        };

        // Attach usage info for downstream controllers
        req.smritiUsage = {
            dailyRemaining: dailyRemaining - 1,
            weeklyRemaining: weeklyRemaining - 1,
            dailyLimit: rateLimits.daily,
            weeklyLimit: rateLimits.weekly,
            rateLimited: false,
            aiProvider,
        };

        next();
    } catch (error) {
        console.error('Smriti rate limit middleware error:', error.message);
        // On error, allow the request through rather than blocking the user
        next();
    }
}

/**
 * Controller: returns current usage info for a user.
 * GET /api/smriti/usage/:userIdentifier
 */
export async function getSmritiUsage(req, res) {
    try {
        const { userIdentifier } = req.params;
        const { aiProvider, rateLimits, firestoreCollection } = config.smriti;

        if (!userIdentifier) {
            return res.status(400).json({ error: 'userIdentifier is required' });
        }

        // If not using Gemini, return unlimited
        if (aiProvider !== 'gemini') {
            return res.status(200).json({
                dailyRemaining: rateLimits.daily,
                weeklyRemaining: rateLimits.weekly,
                dailyLimit: rateLimits.daily,
                weeklyLimit: rateLimits.weekly,
                nextDailyReset: null,
                nextWeeklyReset: null,
                aiProvider,
            });
        }

        const compositeId = `${userIdentifier}_${aiProvider}`;
        const usageRef = doc(firestore, firestoreCollection, compositeId);
        const usageSnap = await getDoc(usageRef);

        const startOfDay = getStartOfDay();
        const startOfWeek = getStartOfWeek();

        let dailyCount = 0;
        let weeklyCount = 0;

        if (usageSnap.exists()) {
            const data = usageSnap.data();

            const lastDailyReset = data.lastDailyReset?.toDate?.() || new Date(0);
            dailyCount = lastDailyReset < startOfDay ? 0 : (data.dailyCount || 0);

            const lastWeeklyReset = data.lastWeeklyReset?.toDate?.() || new Date(0);
            weeklyCount = lastWeeklyReset < startOfWeek ? 0 : (data.weeklyCount || 0);
        }

        return res.status(200).json({
            dailyRemaining: Math.max(0, rateLimits.daily - dailyCount),
            weeklyRemaining: Math.max(0, rateLimits.weekly - weeklyCount),
            dailyLimit: rateLimits.daily,
            weeklyLimit: rateLimits.weekly,
            nextDailyReset: getNextDailyReset().toISOString(),
            nextWeeklyReset: getNextWeeklyReset().toISOString(),
            aiProvider,
        });
    } catch (error) {
        console.error('Get Smriti usage error:', error.message);
        return res.status(500).json({ error: 'Failed to fetch usage info' });
    }
}
