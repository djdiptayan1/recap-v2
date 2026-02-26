import {
    collection,
    doc,
    addDoc,
    updateDoc,
    deleteDoc,
    serverTimestamp,
    getDoc
} from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import config from '../../../config.js';
import { validationResult } from 'express-validator';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const REMINDERS_SUBCOLLECTION = config.firestoreNames.reminders_SubCollection;

const getRemindersCollection = (patientId) =>
    collection(firestore, USERS_COLLECTION, patientId, REMINDERS_SUBCOLLECTION);

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
            time, // assuming time comes as a valid format (e.g. ISO string or timestamp) desirable for Firestore
            // If time comes as string, Firestore might save it as string or map. If we want server timestamp, we use serverTimestamp().
            // Requirements said "time" (user provided).
            ...(notes && { notes }),
            ...(categoryDetails && typeof categoryDetails === 'object' && !Array.isArray(categoryDetails) && Object.keys(categoryDetails).length > 0 && { categoryDetails }),
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

        const { patientId, reminderId, ...updates } = req.body; // Assuming patientId and reminderId are in body or params? 
        // Plan said: "patientId, reminderId, updates". 
        // Usually IDs are better in params for PUT/DELETE, but I will check route plan.
        // Route plan: PUT /edit. If logic says body, I use body. 
        // Let's support body for now as per plan implies validation of inputs.

        // Allowed updates
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

        const reminderRef = doc(firestore, USERS_COLLECTION, patientId, REMINDERS_SUBCOLLECTION, reminderId);

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

        const { patientId, reminderId } = req.body; // Or query? Plan implied inputs. 

        const reminderRef = doc(firestore, USERS_COLLECTION, patientId, REMINDERS_SUBCOLLECTION, reminderId);
        await deleteDoc(reminderRef);

        return res.status(200).json({ success: true, message: 'Reminder deleted successfully' });
    } catch (err) {
        next(err);
    }
}

export default {
    addReminder,
    editReminder,
    deleteReminder
};