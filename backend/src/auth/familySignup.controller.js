import { collection, getDocs, query, where, addDoc, serverTimestamp, doc, getDoc } from 'firebase/firestore';
import { firestore } from '../utils/db.js';
import { validationResult } from 'express-validator';
import config from '../../config.js';

export const familySignup = async (req, res, next) => {
    try {
        const {
            patient_documentId,
            name,
            email,
            imageURL,
            phone,
            relation
        } = req.body;

        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const USERS_COLLECTION = config.firestoreNames.usersCollection;
        const FAMILY_MEMBERS_COLLECTION = config.firestoreNames.familyMembers_SubCollection;
        const patientRef = doc(firestore, USERS_COLLECTION, patient_documentId);
        const patientSnap = await getDoc(patientRef);

        if (!patientSnap.exists()) {
            return res.status(404).json({ success: false, message: 'Patient not found.' });
        }

        const familyMembersRef = collection(firestore, USERS_COLLECTION, patient_documentId, FAMILY_MEMBERS_COLLECTION);
        const q = query(familyMembersRef, where('email', '==', email));
        const querySnapshot = await getDocs(q);

        if (!querySnapshot.empty) {
            return res.status(409).json({
                success: false,
                message: 'Family member profile already exists.',
                existingMemberId: querySnapshot.docs[0].id
            });
        }

        const newFamilyMember = {
            name,
            email,
            imageURL: imageURL || '',
            phone: phone || '',
            relation: relation || '',
            createdAt: serverTimestamp(),
        };

        const docRef = await addDoc(familyMembersRef, newFamilyMember);

        return res.status(201).json({
            success: true,
            message: 'Family member added successfully.',
            data: {
                id: docRef.id,
                ...newFamilyMember,
                createdAt: newFamilyMember.createdAt
            }
        });

    } catch (error) {
        next(error);
    }
}