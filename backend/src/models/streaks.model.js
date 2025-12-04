export const StreakStatsSchema = {
    maxStreak: 'number',
    currentStreak: 'number',
    activeDays: 'number',
    answeredToday: 'boolean',
    lastAnsweredDate: 'timestamp',
    totalQuestionsAnswered: 'number',
    correctAnswers: 'number',
    longestBreak: 'number',
    initialized: 'boolean',
};

export const STREAK_STATS_FIELDS = [
    'maxStreak',
    'currentStreak',
    'activeDays',
    'answeredToday',
    'lastAnsweredDate',
    'totalQuestionsAnswered',
    'correctAnswers',
    'longestBreak',
    'initialized',
];
