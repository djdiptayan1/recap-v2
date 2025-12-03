import { db } from '../utils/db.js';
import { ref, get } from 'firebase/database';

export async function checkFirebaseConnection() {
    try {
        console.log('Checking Firebase connection...');

        const dbRef = ref(db);
        const timeoutPromise = new Promise((_, reject) =>
            setTimeout(() => reject(new Error('Firebase connection timeout')), 10000)
        );

        const checkPromise = get(dbRef).then(() => {
            console.log('Firebase Realtime Database connected successfully');
            return true;
        });

        await Promise.race([checkPromise, timeoutPromise]);
        return true;

    } catch (error) {
        console.error('Firebase connection failed:', error.message);
        throw new Error(`Firebase DB connection failed: ${error.message}`);
    }
}

export function dbCheckMiddleware(req, res, next) {
    if (!db) {
        return res.status(503).json({
            error: 'Database not available',
            message: 'Firebase connection not established'
        });
    }
    next();
}
