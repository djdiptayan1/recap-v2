import {
    collection,
    getDocs,
    doc,
    getDoc,
} from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import config from '../../../config.js';
import { validationResult } from 'express-validator';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const FAMILY_MEMBERS_COLLECTION = config.firestoreNames.familyMembers_SubCollection;

async function getFamilyMembers(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }
        const { documentId } = req.params;

        if (!documentId) {
            return res.status(400).json({ success: false, error: 'documentId is required' });
        }

        // Check if user exists
        const userRef = doc(firestore, USERS_COLLECTION, documentId);
        const userSnap = await getDoc(userRef);

        if (!userSnap.exists()) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        const familyRef = collection(firestore, USERS_COLLECTION, documentId, FAMILY_MEMBERS_COLLECTION);
        const snap = await getDocs(familyRef);

        const data = snap.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        return res.status(200).json({ success: true, data, count: data.length });
    } catch (err) {
        next(err);
    }
}

export default {
    getFamilyMembers,
};
