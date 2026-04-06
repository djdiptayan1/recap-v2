/**
 * Firestore schema for per-user Smriti AI usage tracking.
 *
 * Collection: smritiUsage (configurable via config.smriti.firestoreCollection)
 * Document ID: {userIdentifier}_{aiProvider} (composite ID to support both Gemini and Apple Intelligence)
 */

export const SmritiUsageSchema = {
    dailyCount: 'number',
    weeklyCount: 'number',
    lastDailyReset: 'timestamp',   // Firestore Timestamp — start of the current day (IST)
    lastWeeklyReset: 'timestamp',  // Firestore Timestamp — start of the current week (Monday IST)
    aiProvider: 'string',          // Which AI provider was active when usage was recorded
    updatedAt: 'timestamp',
};

export const SMRITI_USAGE_FIELDS = [
    'dailyCount',
    'weeklyCount',
    'lastDailyReset',
    'lastWeeklyReset',
    'aiProvider',
    'updatedAt',
];
