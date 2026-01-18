export const ReminderSchema = {
    title: 'string',           // Reminder title
    category: 'string',        // Medicine, Daily Chore, Appointment, Exercise, Meal, Hydration, Other
    frequency: 'string',       // Frequency: once, daily, weekly, monthly
    time: 'timestamp',         // Reminder time
    notes: 'string',           // Optional notes
    createdAt: 'timestamp',
    updatedAt: 'timestamp',
}