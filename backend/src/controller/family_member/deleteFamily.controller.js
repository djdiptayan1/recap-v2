import {
    doc,
    getDoc,
    deleteDoc,
} from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import config from '../../../config.js';
import { validationResult } from 'express-validator';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const FAMILY_MEMBERS_COLLECTION = config.firestoreNames.familyMembers_SubCollection;

async function deleteFamilyMember(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }
        const { documentId, memberId } = req.params;

        if (!documentId || !memberId) {
            return res.status(400).json({ success: false, error: 'documentId and memberId are required' });
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

        // Check if family member exists
        const memberRef = doc(firestore, USERS_COLLECTION, documentId, FAMILY_MEMBERS_COLLECTION, memberId);
        const memberSnap = await getDoc(memberRef);

        if (!memberSnap.exists()) {
            return res.status(404).json({
                success: false,
                message: 'Family member not found',
            });
        }

        await deleteDoc(memberRef);

        return res.status(200).json({ success: true, message: 'Family member deleted successfully' });
    } catch (err) {
        next(err);
    }
}

export default {
    deleteFamilyMember,
};
