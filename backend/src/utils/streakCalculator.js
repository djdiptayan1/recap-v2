/**
 * Calculates streak metrics from a map of date usage.
 * @param {Object} streakData - Object where keys are 'YYYY-MM-DD' and values are booleans.
 * @returns {Object} { currentStreak, maxStreak, activeDays, lastAnsweredDate }
 */
export function calculateStreakMetrics(streakData) {
    // 1. Extract all active dates
    const activeDates = Object.entries(streakData)
        .filter(([_, isActive]) => isActive)
        .map(([dateStr]) => dateStr);

    if (activeDates.length === 0) {
        return {
            currentStreak: 0,
            maxStreak: 0,
            activeDays: 0,
            lastAnsweredDate: null
        };
    }

    // 2. Sort dates chronologically
    activeDates.sort();

    // 3. Calculate metrics
    let maxStreak = 0;
    let currentRun = 0;
    let prevDate = null;

    // For Max Streak
    for (const dateStr of activeDates) {
        const currentDate = new Date(dateStr);
        // Reset time to midnight for accurate day diff
        currentDate.setHours(0, 0, 0, 0);

        if (prevDate) {
            const diffTime = Math.abs(currentDate - prevDate);
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

            if (diffDays === 1) {
                currentRun++;
            } else {
                currentRun = 1; // Reset if gap > 1 day
            }
        } else {
            currentRun = 1;
        }

        if (currentRun > maxStreak) {
            maxStreak = currentRun;
        }
        prevDate = currentDate;
    }

    // 4. Calculate Current Streak (working backwards from today)
    // We re-sort descending for easier backward check
    const descDates = [...activeDates].sort().reverse();

    let currentStreak = 0;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Check if the most recent active date is Today or Yesterday
    // If the last activity was 2+ days ago, current streak is 0.
    const lastActiveStr = descDates[0];
    const lastActiveDate = new Date(lastActiveStr);
    lastActiveDate.setHours(0, 0, 0, 0);

    const timeSinceLastActive = Math.abs(today - lastActiveDate);
    const daysSinceLastActive = Math.ceil(timeSinceLastActive / (1000 * 60 * 60 * 24));

    // If last active day is today (0) or yesterday (1), we might have a streak.
    if (daysSinceLastActive <= 1) {
        currentStreak = 1;

        let previousChecker = lastActiveDate;

        for (let i = 1; i < descDates.length; i++) {
            const historicDate = new Date(descDates[i]);
            historicDate.setHours(0, 0, 0, 0);

            const gap = Math.abs(previousChecker - historicDate);
            const gapDays = Math.ceil(gap / (1000 * 60 * 60 * 24));

            if (gapDays === 1) {
                currentStreak++;
                previousChecker = historicDate;
            } else {
                break;
            }
        }
    }

    return {
        currentStreak,
        maxStreak,
        activeDays: activeDates.length,
        lastAnsweredDate: lastActiveStr
    };
}
