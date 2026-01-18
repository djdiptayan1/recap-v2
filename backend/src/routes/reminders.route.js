import express from 'express';
import { body, query } from 'express-validator';
import { addReminder, editReminder, deleteReminder } from '../controller/reminders/setReminders.controller.js';
import { getReminders } from '../controller/reminders/getReminders.controller.js';

const router = express.Router();

router.get('/', [
    query('patientId').notEmpty().withMessage('Patient ID is required'),
], getReminders);

router.post('/', [
    body('patientId').notEmpty().withMessage('Patient ID is required'),
    body('title').notEmpty().withMessage('Title is required'),
    body('category').isIn(['Medicine', 'Daily Chore', 'Appointment', 'Exercise', 'Meal', 'Hydration', 'Other']).withMessage('Invalid category'),
    body('frequency').isIn(['once', 'daily', 'weekly', 'monthly']).withMessage('Frequency must be once, daily, weekly, or monthly'),
    body('time').notEmpty().withMessage('Time is required'),
], addReminder);

router.delete('/', [
    body('patientId').notEmpty().withMessage('Patient ID is required'),
    body('reminderId').notEmpty().withMessage('Reminder ID is required'),
], deleteReminder);

router.put('/', [
    body('patientId').notEmpty().withMessage('Patient ID is required'),
    body('reminderId').notEmpty().withMessage('Reminder ID is required'),
], editReminder);

export default router;
