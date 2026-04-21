export const DAILY_MOODS = [
    { key: 'very_unpleasant', label: 'Very Unpleasant', score: 0 },
    { key: 'unpleasant', label: 'Unpleasant', score: 1 },
    { key: 'neutral', label: 'Neutral', score: 2 },
    { key: 'pleasant', label: 'Pleasant', score: 3 },
    { key: 'very_pleasant', label: 'Very Pleasant', score: 4 },
];

export const DAILY_MOOD_KEYS = DAILY_MOODS.map(mood => mood.key);

export const DAILY_MOOD_LOOKUP = Object.fromEntries(
    DAILY_MOODS.map(mood => [mood.key, mood])
);
