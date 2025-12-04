import {
    collection,
    getDocs,
    query,
    orderBy,
} from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import config from '../../../config.js';

const COLLECTION_NAME = config.firestoreNames.memoryQuizCollection;
const memoryQuizRef = () => collection(firestore, COLLECTION_NAME);

async function getQuizQuestions(req, res, next) {
    try {
        const q = query(memoryQuizRef(), orderBy('order', 'asc'));
        const snap = await getDocs(q);
        const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));

        return res.status(200).json({ success: true, data, count: data.length });
    } catch (err) {
        next(err);
    }
}

export default {
    getQuizQuestions,
};
