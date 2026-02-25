import config from '../../config.js';

const TIMEZONE = config.timezone || 'Asia/Kolkata';

/**
 * Get today's date string (YYYY-MM-DD) in the configured timezone
 */
export function getLocalToday(date = new Date()) {
    return date.toLocaleDateString('en-CA', { timeZone: TIMEZONE });
}

/**
 * Get year-month string (YYYY-MM) in the configured timezone
 */
export function getLocalYearMonth(date = new Date()) {
    const year = date.toLocaleDateString('en-CA', { timeZone: TIMEZONE, year: 'numeric' });
    const month = date.toLocaleDateString('en-CA', { timeZone: TIMEZONE, month: '2-digit' });
    return `${year}-${month}`;
}

/**
 * Get formatted date strings in the configured timezone
 * Returns { full: 'YYYY-MM-DD', yearMonth: 'YYYY-MM' }
 */
export function getFormattedLocalDate(date = new Date()) {
    const full = getLocalToday(date);
    const yearMonth = full.substring(0, 7); // 'YYYY-MM' from 'YYYY-MM-DD'
    return { full, yearMonth };
}
