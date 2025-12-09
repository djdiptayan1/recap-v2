import { doc, setDoc, getDoc, Timestamp } from 'firebase/firestore';
import { firestore } from '../utils/db.js';
import config from '../../config.js';
import generateUniquePatientID from '../utils/generateUniquePatientID.js';
import { uploadOnCloudinary, getOptimizedUrl, deleteFromCloudinary } from '../utils/cloudinary.js';

export const patientSignup = async (req, res, next) => {
    try {
        const { uid,
            email,
            firstName,
            lastName,
            dateOfBirth,
            bloodGroup,
            sex,
            stage,
            profileImageBase64 } = req.body;

        let profileImageURL = "";

        if (!uid || !email) {
            return res.status(400).json({ message: 'Missing required fields: uid or email' });
        }

        const userRef = doc(firestore, config.firestoreNames.usersCollection, uid);
        const userSnap = await getDoc(userRef);

        if (userSnap.exists()) {
            return res.status(409).json({ message: 'User already exists' });
        }

        if (profileImageBase64) {
            try {
                const base64Data = profileImageBase64.replace(/^data:image\/\w+;base64,/, "");
                const buffer = Buffer.from(base64Data, 'base64');

                const uploadResult = await uploadOnCloudinary(buffer, "recap/patients/profiles", uid); // using uid as filename for consistency
                if (uploadResult && uploadResult.public_id) {
                    profileImageURL = getOptimizedUrl(uploadResult.public_id);
                }
            } catch (uploadError) {
                console.error("Failed to upload profile image:", uploadError);
                return res.status(500).json({
                    error: uploadError,
                    message: 'Failed to upload profile image'
                });
            }
        }

        // Generate Unique ID
        const patientUID = await generateUniquePatientID();
        const userData = {
            email,
            patientUID,
            firstName: firstName || "",
            lastName: lastName || "",
            dateOfBirth: dateOfBirth || "",
            bloodGroup: bloodGroup || "",
            sex: sex || "",
            stage: stage || "",
            profileImageURL: profileImageURL || "https://i0.wp.com/christopherscottedwards.com/wp-content/uploads/2018/07/Generic-Profile.jpg?ssl=1", // Use variable or default
            type: 'patient',
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now()
        };

        await setDoc(userRef, userData);

        return res.status(201).json({
            message: 'Patient profile created successfully',
            user: userData
        });

    } catch (error) {
        next(error);
    }
};
