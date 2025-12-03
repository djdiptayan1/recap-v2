import 'dotenv/config';
import app from './src/app.js';
import { checkFirebaseConnection } from './src/middleware/dbCheck.js';

const PORT = process.env.PORT || 3000;

checkFirebaseConnection()
    .then(() => {
        app.listen(PORT, () => {
            console.log(`Server is running on port ${PORT}`);
        });
    })
    .catch((err) => {
        console.error('Failed to connect to Firebase:', err.message);
        process.exit(1);
    });