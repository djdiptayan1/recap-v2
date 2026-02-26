import { collection, getDocs, deleteDoc, doc, getDoc } from 'firebase/firestore';
import { firestore } from '../utils/db.js';
import { authAdmin } from '../utils/firebaseAdmin.js';
import config from '../../config.js';

const deleteSubcollection = async (docRef, subcollectionName) => {
    const subColRef = collection(docRef, subcollectionName);
    const snapshot = await getDocs(subColRef);
    const deletePromises = snapshot.docs.map(d => deleteDoc(d.ref));
    await Promise.all(deletePromises);
};

export const deleteAccount = async (req, res) => {
    try {
        const { documentId } = req.body;
        console.log('Delete account request for documentId:', documentId);
        const userDocRef = doc(firestore, config.firestoreNames.usersCollection, documentId);
        const userDoc = await getDoc(userDocRef);
        if (!userDoc.exists()) {
            console.log('User not found for documentId:', documentId);
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        // Delete the user from Firebase Authentication first
        try {
            await authAdmin.deleteUser(documentId);
            console.log(`Successfully deleted user ${documentId} from Firebase Auth`);
        } catch (authError) {
            if (authError.code === 'auth/user-not-found') {
                console.log(`User ${documentId} not found in Firebase Auth, proceeding to clean up DB.`);
            } else {
                console.error(`Failed to delete user ${documentId} from Firebase Auth. Aborting DB cleanup:`, authError);
                return res.status(500).json({
                    success: false,
                    message: 'Failed to delete user authentication record. Please try again.'
                });
            }
        }

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

        await Promise.all(subcollections.map(sub => deleteSubcollection(userDocRef, sub)));

        // Delete from Firestore
        await deleteDoc(userDocRef);
        res.status(200).json({ success: true, message: 'Account deleted successfully' });
    } catch (error) {
        console.error('Error deleting user:', error);
        res.status(500).json({ success: false, message: 'Error deleting account' });
    }
};  