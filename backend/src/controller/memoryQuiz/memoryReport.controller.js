import { collection, getDocs, query, orderBy, doc, getDoc } from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import config from '../../../config.js';
import { validationResult } from 'express-validator';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const REPORTS_COLLECTION = config.firestoreNames.memoryCheckReports_SubCollection;

export const getMemoryReports = async (req, res, next) => {
    try {
        const { patientId } = req.params;

        if (!patientId) {
            return res.status(400).json({
                success: false,
                message: 'Patient ID is required'
            });
        }

        // Check if user exists
        const userRef = doc(firestore, USERS_COLLECTION, patientId);
        const userSnap = await getDoc(userRef);

        if (!userSnap.exists()) {
            return res.status(404).json({
                success: false,
                message: 'Patient not found'
            });
        }

        const reportsRef = collection(firestore, USERS_COLLECTION, patientId, REPORTS_COLLECTION);
        const q = query(reportsRef, orderBy('date', 'desc'));

        const snapshot = await getDocs(q);

        const reports = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            reports.push({
                id: doc.id,
                ...data,
                date: data.date && typeof data.date.toDate === 'function' ? data.date.toDate().toISOString() : data.date,
                createdAt: data.createdAt && typeof data.createdAt.toDate === 'function' ? data.createdAt.toDate().toISOString() : data.createdAt
            });
        });

        res.status(200).json({
            success: true,
            data: reports
        });

    } catch (error) {
        next(error);
    }
};