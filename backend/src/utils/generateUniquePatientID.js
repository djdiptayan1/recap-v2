import {
    collection,
    getDocs,
    limit,
    query,
    where,
} from 'firebase/firestore';
import config from '../../config.js';
import { firestore } from './db.js';

const CHARSET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
const usersRef = () => collection(firestore, config.firestoreNames.usersCollection);

const randomId = (length = 6) => {
    let out = '';
    for (let i = 0; i < length; i++) {
        out += CHARSET.charAt(Math.floor(Math.random() * CHARSET.length));
    }
    return out;
};

const patientIdExists = async (id) => {
    // Check against patientUID to match Swift model
    const q = query(usersRef(), where('patientUID', '==', id), limit(1));
    const snap = await getDocs(q);
    return !snap.empty;
};

const generateUniquePatientID = async (length = 6, maxAttempts = 10) => {
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
        const candidate = randomId(length);
        const exists = await patientIdExists(candidate);
        if (!exists) return candidate;
    }

    throw new Error('Unable to generate unique patientUID after maxAttempts');
};

export default generateUniquePatientID;