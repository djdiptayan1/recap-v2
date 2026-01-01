import { collection, query, where, getDocs } from 'firebase/firestore';
import { firestore } from '../utils/db.js';
import config from '../../config.js';

export const deleteAccount = async (req, res) => {
    try {
        const { uid } = req.body;
        const userRef = collection(firestore, config.firestoreNames.usersCollection);
        const q = query(userRef, where('uid', '==', uid));
        const querySnapshot = await getDocs(q);
        if (querySnapshot.empty) {
            return res.status(404).json({ message: 'User not found' });
        }
        const userDoc = querySnapshot.docs[0];
        await userDoc.ref.delete();
        res.status(200).json({ message: 'User deleted successfully' });
    } catch (error) {
        console.error('Error deleting user:', error);
        res.status(500).json({ message: 'Error deleting user' });
    }
};  