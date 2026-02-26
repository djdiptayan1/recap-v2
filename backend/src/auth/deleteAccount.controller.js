import { collection, query, where, getDocs, deleteDoc, doc } from 'firebase/firestore';
import { firestore } from '../utils/db.js';
import config from '../../config.js';

const deleteSubcollection = async (docRef, subcollectionName) => {
    const subColRef = collection(docRef, subcollectionName);
    const snapshot = await getDocs(subColRef);
    const deletePromises = snapshot.docs.map(d => deleteDoc(d.ref));
    await Promise.all(deletePromises);
};

export const deleteAccount = async (req, res) => {
    try {
        const { uid } = req.body;
        const userRef = collection(firestore, config.firestoreNames.usersCollection);
        const q = query(userRef, where('uid', '==', uid));
        const querySnapshot = await getDocs(q);
        if (querySnapshot.empty) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }
        const userDoc = querySnapshot.docs[0];

        // Delete known subcollections
        const subcollections = [
            config.firestoreNames.streaks_SubCollection,
            config.firestoreNames.familyMembers_SubCollection,
            config.firestoreNames.memoryCheckReports_SubCollection,
            config.firestoreNames.personalQuestions_SubCollection,
            config.firestoreNames.reminders_SubCollection,
            config.firestoreNames.journalEntries_SubCollection,
            config.firestoreNames.analyticsCache_SubCollection,
        ];

        await Promise.all(subcollections.map(sub => deleteSubcollection(userDoc.ref, sub)));

        await deleteDoc(userDoc.ref);
        res.status(200).json({ success: true, message: 'Account deleted successfully' });
    } catch (error) {
        console.error('Error deleting user:', error);
        res.status(500).json({ success: false, message: 'Error deleting account' });
    }
};  