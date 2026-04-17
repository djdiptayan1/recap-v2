import { collection, doc } from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import config from '../../../config.js';

export const USERS_COLLECTION = config.firestoreNames.usersCollection;
export const REMINDERS_SUBCOLLECTION = config.firestoreNames.reminders_SubCollection;

export const getRemindersCollection = patientId =>
    collection(firestore, USERS_COLLECTION, patientId, REMINDERS_SUBCOLLECTION);

export const getReminderRef = (patientId, reminderId) =>
    doc(firestore, USERS_COLLECTION, patientId, REMINDERS_SUBCOLLECTION, reminderId);

export function normalizeDate(value) {
    if (!value) return null;
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
}

export function createHistoryEvent(action, via, actedAt, extras = {}) {
    return {
        action,
        via,
        actedAt: actedAt.toISOString(),
        ...extras,
    };
}
