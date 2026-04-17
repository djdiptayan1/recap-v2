import {
    getDocs,
    query,
} from 'firebase/firestore';
import { validationResult } from 'express-validator';
import { getRemindersCollection } from './reminder.shared.js';

export async function getReminders(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patientId } = req.query;

        const remindersRef = getRemindersCollection(patientId);
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