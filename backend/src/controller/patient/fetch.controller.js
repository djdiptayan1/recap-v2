import { doc, getDoc } from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import config from '../../../config.js';
import { getOptimizedImageUrl } from '../../utils/cloudinary.js';

const USERS_COLLECTION = config.firestoreNames.usersCollection;

/**
 * Fetches patient data by document ID.
 * @param {string} documentId - The Firestore document ID of the patient.
 * @returns {Promise<Object|null>} - The patient data or null if not found.
 */
export async function getPatientData(documentId) {
    try {
        if (!documentId) return null;

        const patientRef = doc(firestore, USERS_COLLECTION, documentId);
        const patientSnap = await getDoc(patientRef);

        if (patientSnap.exists()) {
            const data = patientSnap.data();
            return {
                ...data,
                profileImageURL: getOptimizedImageUrl(data.profileImageURL, 'avatar'),
            };
        }
        return null;
    } catch (error) {
        console.error('Error fetching patient data:', error);
        throw error;
    }
}

export async function getPatient(req, res, next) {
    try {
        const { documentId } = req.params;
        const data = await getPatientData(documentId);

        if (!data) {
            return res.status(404).json({ success: false, message: 'Patient not found' });
        }

        return res.status(200).json({ success: true, data });
    } catch (err) {
        next(err);
    }
}

export default {
    getPatient,
    getPatientData,
};
