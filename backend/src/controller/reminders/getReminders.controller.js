import {
    collection,
    getDocs,
    query,
} from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import config from '../../../config.js';
import { validationResult } from 'express-validator';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const REMINDERS_SUBCOLLECTION = config.firestoreNames.reminders_SubCollection;

export async function getReminders(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patientId } = req.query; // Usually GET uses query params

        const remindersRef = collection(firestore, USERS_COLLECTION, patientId, REMINDERS_SUBCOLLECTION);
        const q = query(remindersRef);
        const snap = await getDocs(q);

        const data = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        return res.status(200).json({ success: true, data });
    } catch (err) {
        next(err);
    }
}

export default {
    getReminders
};