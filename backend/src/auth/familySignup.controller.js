import { collection, getDocs, query, where, serverTimestamp, doc, getDoc, setDoc } from 'firebase/firestore';
import { firestore } from '../utils/db.js';
import { validationResult } from 'express-validator';
import config from '../../config.js';
import { uploadOnCloudinary, getOptimizedImageUrl, deleteFromCloudinary } from '../utils/cloudinary.js';

export const familySignup = async (req, res, next) => {
    try {
        const {
            patient_documentId,
            name,
            email,
            profileImageBase64,
            profileImageURL: socialProfileImageURL,
            phone,
            relation
        } = req.body;

        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const USERS_COLLECTION = config.firestoreNames.usersCollection;
        const FAMILY_MEMBERS_COLLECTION = config.firestoreNames.familyMembers_SubCollection;
        const patientRef = doc(firestore, USERS_COLLECTION, patient_documentId);
        const patientSnap = await getDoc(patientRef);

        if (!patientSnap.exists()) {
            return res.status(404).json({ success: false, message: 'Patient not found.' });
        }

        const familyMembersRef = collection(firestore, USERS_COLLECTION, patient_documentId, FAMILY_MEMBERS_COLLECTION);
        const q = query(familyMembersRef, where('email', '==', email));
        const querySnapshot = await getDocs(q);

        if (!querySnapshot.empty) {
            return res.status(409).json({
                success: false,
                message: 'Family member profile already exists.',
                existingMemberId: querySnapshot.docs[0].id
            });
        }

        // Generate new document reference to get ID beforehand
        const newFamilyMemberRef = doc(familyMembersRef);
        const familyMemberId = newFamilyMemberRef.id;
        let imageURL = "";

        if (profileImageBase64) {
            try {
                const base64Data = profileImageBase64.replace(/^data:image\/\w+;base64,/, "");
                const buffer = Buffer.from(base64Data, 'base64');

                // Upload to Cloudinary using the generated familyMemberId
                // Using a specific folder for family members if desired, or general profiles
                // Mirroring patientSignup but putting it in recap/family_members/profiles to distinguish
                const uploadResult = await uploadOnCloudinary(buffer, "recap/family_members/profiles", familyMemberId);

                if (uploadResult && uploadResult.public_id) {
                    imageURL = getOptimizedImageUrl(uploadResult.public_id);
                }
            } catch (uploadError) {
                console.error("Failed to upload profile image:", uploadError);
                // Proceed without image or return error? patientSignup returns 500.
                // Ideally we should probably fail if image upload was requested but failed, 
                // or just log it and proceed with empty image. 
                // patientSignup returns 500, so I will do the same for consistency.
                return res.status(500).json({
                    success: false,
                    error: uploadError,
                    message: 'Failed to upload profile image'
                });
            }
        } else if (socialProfileImageURL) {
            // Use the profile image URL from social login (Google/Apple) as fallback
            imageURL = socialProfileImageURL;
        }

        const newFamilyMember = {
            id: familyMemberId, // Store ID inside document as well if needed, though it's the doc ID
            name,
            email,
            imageURL: imageURL || "https://i0.wp.com/christopherscottedwards.com/wp-content/uploads/2018/07/Generic-Profile.jpg?ssl=1",
            phone: phone || '',
            relation: relation || '',
            createdAt: serverTimestamp(),
        };

        await setDoc(newFamilyMemberRef, newFamilyMember);

        return res.status(201).json({
            success: true,
            message: 'Family member added successfully.',
            data: {
                id: familyMemberId,
                ...newFamilyMember,
                // createdAt will be serverTimestamp object, might need processing for response 
                // but usually fine or returns null in simple JSON. 
                // For immediate response, serverTimestamp is not resolved.
                // We can just return the object.
            }
        });

    } catch (error) {
        next(error);
    }
}
