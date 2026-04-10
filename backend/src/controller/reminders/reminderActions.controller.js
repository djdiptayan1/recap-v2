import {
    updateDoc,
    serverTimestamp,
    getDoc,
} from 'firebase/firestore';
import { validationResult } from 'express-validator';
import {
    getReminderRef,
    normalizeDate,
    createHistoryEvent,
} from './reminder.shared.js';

export async function markReminderCompleted(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const {
            patientId,
            reminderId,
            completedVia = 'in_app',
            completedAt,
        } = req.body;

        const reminderRef = getReminderRef(patientId, reminderId);
        const reminderSnap = await getDoc(reminderRef);

        if (!reminderSnap.exists()) {
            return res.status(404).json({ success: false, error: 'Reminder not found' });
        }

        const reminder = reminderSnap.data();
        const actedAt = normalizeDate(completedAt) || new Date();
        const history = Array.isArray(reminder.completionHistory) ? reminder.completionHistory : [];

        const event = createHistoryEvent('completed', completedVia, actedAt);

        const updateData = {
            isCompleted: reminder.frequency === 'once',
            lastCompletedAt: actedAt,
            lastAction: 'completed',
            lastActionAt: actedAt,
            completionHistory: [...history, event],
            updatedAt: serverTimestamp(),
        };

        await updateDoc(reminderRef, updateData);
        const updatedSnap = await getDoc(reminderRef);

        return res.status(200).json({ success: true, data: { id: updatedSnap.id, ...updatedSnap.data() } });
    } catch (err) {
        next(err);
    }
}

export async function snoozeReminder(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const {
            patientId,
            reminderId,
            snoozeMinutes = 15,
            snoozedVia = 'notification_action',
        } = req.body;

        const reminderRef = getReminderRef(patientId, reminderId);
        const reminderSnap = await getDoc(reminderRef);

        if (!reminderSnap.exists()) {
            return res.status(404).json({ success: false, error: 'Reminder not found' });
        }

        const reminder = reminderSnap.data();
        const actedAt = new Date();
        const resolvedSnoozeMinutes = Number(snoozeMinutes) || 15;
        const snoozedUntil = new Date(actedAt.getTime() + resolvedSnoozeMinutes * 60 * 1000);
        const history = Array.isArray(reminder.completionHistory) ? reminder.completionHistory : [];

        const event = createHistoryEvent('snoozed', snoozedVia, actedAt, {
            snoozedUntil: snoozedUntil.toISOString(),
            snoozeMinutes: resolvedSnoozeMinutes,
        });

        const updateData = {
            isCompleted: false,
            lastSnoozedUntil: snoozedUntil,
            lastAction: 'snoozed',
            lastActionAt: actedAt,
            completionHistory: [...history, event],
            updatedAt: serverTimestamp(),
        };

        await updateDoc(reminderRef, updateData);
        const updatedSnap = await getDoc(reminderRef);

        return res.status(200).json({ success: true, data: { id: updatedSnap.id, ...updatedSnap.data() } });
    } catch (err) {
        next(err);
    }
}

export default {
    markReminderCompleted,
    snoozeReminder,
};
