import express from 'express';
import { body, query } from 'express-validator';
import {
    addReminder,
    editReminder,
    deleteReminder,
} from '../controller/reminders/reminderCrud.controller.js';
import {
    markReminderCompleted,
    snoozeReminder,
} from '../controller/reminders/reminderActions.controller.js';
import { getReminders } from '../controller/reminders/getReminders.controller.js';

const router = express.Router();

router.get('/', [
    query('patientId').notEmpty().withMessage('Patient ID is required'),
], getReminders);

router.post('/', [
    body('patientId').notEmpty().withMessage('Patient ID is required'),
    body('title').notEmpty().withMessage('Title is required'),
    body('category').isIn(['Medicine', 'Daily Chore', 'Appointment', 'Exercise', 'Meal', 'Hydration', 'Other']).withMessage('Invalid category'),
    body('frequency').isIn(['once', 'hourly', 'daily', 'weekdays', 'weekends', 'weekly', 'biweekly', 'monthly', 'yearly']).withMessage('Invalid frequency'),
    body('time').notEmpty().withMessage('Time is required'),
    body('categoryDetails').optional().isObject().withMessage('Category details must be an object'),
], addReminder);

router.delete('/', [
    body('patientId').notEmpty().withMessage('Patient ID is required'),
    body('reminderId').notEmpty().withMessage('Reminder ID is required'),
], deleteReminder);

router.put('/', [
    body('patientId').notEmpty().withMessage('Patient ID is required'),
    body('reminderId').notEmpty().withMessage('Reminder ID is required'),
], editReminder);

router.post('/complete', [
    body('patientId').notEmpty().withMessage('Patient ID is required'),
    body('reminderId').notEmpty().withMessage('Reminder ID is required'),
    body('completedVia').optional().isString().withMessage('completedVia must be a string'),
    body('completedAt').optional().isISO8601().withMessage('completedAt must be an ISO8601 date'),
], markReminderCompleted);

router.post('/snooze', [
    body('patientId').notEmpty().withMessage('Patient ID is required'),
    body('reminderId').notEmpty().withMessage('Reminder ID is required'),
    body('snoozeMinutes').optional().isInt({ min: 1, max: 1440 }).withMessage('snoozeMinutes must be between 1 and 1440'),
    body('snoozedVia').optional().isString().withMessage('snoozedVia must be a string'),
], snoozeReminder);

export default router;
