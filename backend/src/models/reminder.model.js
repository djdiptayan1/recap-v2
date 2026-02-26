export const ReminderSchema = {
    title: 'string',           // Reminder title
    category: 'string',        // Medicine, Daily Chore, Appointment, Exercise, Meal, Hydration, Other
    frequency: 'string',       // Frequency: once, daily, weekly, monthly
    time: 'timestamp',         // Reminder time
    notes: 'string',           // Optional notes
    categoryDetails: 'map',    // Category-specific details (e.g. Medicine: medicineName, dosage, dosageUnit, mealRelation; Appointment: doctorName, location; Exercise: exerciseType, duration; Meal: mealType; Hydration: amount, unit)
    createdAt: 'timestamp',
    updatedAt: 'timestamp',
}