import {
    addDoc,
    updateDoc,
    deleteDoc,
    serverTimestamp,
    getDoc,
} from 'firebase/firestore';
import { validationResult } from 'express-validator';
import {
    getRemindersCollection,
    getReminderRef,
} from './reminder.shared.js';

export async function addReminder(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patientId, title, category, frequency, time, notes, categoryDetails } = req.body;

        const reminderData = {
            title,
            category,
            frequency,
            time,
            ...(notes && { notes }),
            ...(categoryDetails
                && typeof categoryDetails === 'object'
                && !Array.isArray(categoryDetails)
                && Object.keys(categoryDetails).length > 0
                && { categoryDetails }),
            isCompleted: false,
            lastCompletedAt: null,
            lastSnoozedUntil: null,
            lastAction: null,
            lastActionAt: null,
            completionHistory: [],
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp(),
        };

        const docRef = await addDoc(getRemindersCollection(patientId), reminderData);
        const snap = await getDoc(docRef);

        return res.status(201).json({ success: true, data: { id: snap.id, ...snap.data() } });
    } catch (err) {
        next(err);
    }
}

export async function editReminder(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patientId, reminderId, ...updates } = req.body;

        const allowedUpdates = ['title', 'category', 'frequency', 'time', 'notes', 'categoryDetails'];
        const updateData = {};

        allowedUpdates.forEach(field => {
            if (updates[field] !== undefined) {
                updateData[field] = updates[field];
            }
        });

        if (Object.keys(updateData).length === 0) {
            return res.status(400).json({ success: false, error: 'No updatable fields provided' });
        }

        const reminderRef = getReminderRef(patientId, reminderId);

        const checkSnap = await getDoc(reminderRef);
        if (!checkSnap.exists()) {
            return res.status(404).json({ success: false, error: 'Reminder not found' });
        }

        await updateDoc(reminderRef, { ...updateData, updatedAt: serverTimestamp() });
        const snap = await getDoc(reminderRef);

        return res.status(200).json({ success: true, data: { id: snap.id, ...snap.data() } });
    } catch (err) {
        next(err);
    }
}

export async function deleteReminder(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patientId, reminderId } = req.body;

        const reminderRef = getReminderRef(patientId, reminderId);
        
        const checkSnap = await getDoc(reminderRef);
        if (!checkSnap.exists()) {
            return res.status(404).json({ success: false, error: 'Reminder not found' });
        }

        await deleteDoc(reminderRef);

        return res.status(200).json({ success: true, message: 'Reminder deleted successfully' });
    } catch (err) {
        next(err);
    }
}

export default {
    addReminder,
    editReminder,
    deleteReminder,
};
