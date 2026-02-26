import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import 'dotenv/config';

let serviceAccount;

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    // Production / Docker: load from base64-encoded env variable
    serviceAccount = JSON.parse(
        Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString('utf8')
    );
} else {
    // Local development: load from file
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = dirname(__filename);
    serviceAccount = JSON.parse(
        readFileSync(join(__dirname, '../../serviceAccountKey.json'), 'utf8')
    );
}

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
    });
}

export const authAdmin = admin.auth();
export default admin;
