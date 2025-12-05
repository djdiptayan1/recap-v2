import {
    collection,
    getDocs,
    query,
    where,
} from 'firebase/firestore';
import { firestore } from '../utils/db.js';
import config from '../../config.js';
import { validationResult } from 'express-validator';
import { getPatientData } from '../controller/patient/fetch.controller.js';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const FAMILY_MEMBERS_COLLECTION = config.firestoreNames.familyMembers_SubCollection;

export async function verifyFamilyMember(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { email, documentId } = req.body;

        if (!email || !documentId) {
            return res.status(400).json({ success: false, error: 'Email and documentId are required' });
        }

        const familyRef = collection(firestore, USERS_COLLECTION, documentId, FAMILY_MEMBERS_COLLECTION);
        const q = query(familyRef, where('email', '==', email));
        const snap = await getDocs(q);

        if (snap.empty) {
            return res.status(200).json({
                success: false,
                message: 'User is not a family member'
            });
        }

        // Fetch patient data
        const patientData = await getPatientData(documentId) || {};

        return res.status(200).json({
            success: true,
            message: 'User is a family member',
            familymember_documentId: snap.docs[0].id,
            name: snap.docs[0].data().name,
            imageURL: snap.docs[0].data().imageURL,
            email: snap.docs[0].data().email,
            phone: snap.docs[0].data().phone,
            relation: snap.docs[0].data().relation,

            patientdata: patientData
        });

    } catch (err) {
        next(err);
    }
}
