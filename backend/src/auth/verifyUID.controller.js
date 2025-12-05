import { collection, query, where, getDocs } from 'firebase/firestore';
import { validationResult } from 'express-validator';
import { firestore } from '../utils/db.js';
import config from '../../config.js';

const USERS_COLLECTION = config.firestoreNames.usersCollection;

export const verifyUID = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }
        const { patientUID } = req.body;

        if (!patientUID) {
            return res.status(400).json({ success: false, error: 'patientUID is required' });
        }

        const usersRef = collection(firestore, USERS_COLLECTION);
        const q = query(usersRef, where('patientUID', '==', patientUID));
        const querySnapshot = await getDocs(q);

        if (!querySnapshot.empty) {
            return res.status(200).json({
                success: true,
                exists: true,
                documentId: querySnapshot.docs[0].id,
                patientUID: querySnapshot.docs[0].data().patientUID,
                message: 'Patient UID found'
            });
        } else {
            return res.status(200).json({
                success: true,
                exists: false,
                message: 'Patient UID not found'
            });
        }
    } catch (error) {
        next(error);
    }
};
