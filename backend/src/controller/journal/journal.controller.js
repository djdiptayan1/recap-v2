import {
    collection,
    doc,
    getDoc,
    getDocs,
    addDoc,
    updateDoc,
    deleteDoc,
    query,
    orderBy,
    limit as limitFn,
    startAfter,
    serverTimestamp,
} from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import config from '../../../config.js';
import { JOURNAL_FIELDS } from '../../models/journal.model.js';
import { validationResult } from 'express-validator';
import {
    uploadOnCloudinary,
    deleteFromCloudinary,
    buildResponsiveImageSet,
} from '../../utils/cloudinary.js';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const JOURNAL_SUBCOLLECTION = config.firestoreNames.journalEntries_SubCollection;

const journalRef = (patientId) =>
    collection(firestore, USERS_COLLECTION, patientId, JOURNAL_SUBCOLLECTION);

/**
 * Converts Firestore Timestamp objects to ISO date strings so the JSON
 * response contains plain strings that iOS Codable (String?) can decode.
 */
function serializeEntry(data) {
    const result = {};
    for (const [key, value] of Object.entries(data)) {
        if (value && typeof value.toDate === 'function') {
            result[key] = value.toDate().toISOString();
        } else {
            result[key] = value;
        }
    }

    if (Array.isArray(result.photos)) {
        result.photos = result.photos.map(photo => {
            const responsive = buildResponsiveImageSet(photo?.url);
            return {
                ...photo,
                url: responsive?.detailURL || photo?.url || '',
                detailURL: responsive?.detailURL || photo?.url || '',
                thumbnailURL: responsive?.thumbnailURL || photo?.url || '',
                originalURL: responsive?.originalURL || photo?.url || '',
            };
        });
    }

    return result;
}

async function createEntry(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patientId, title, content, mood, audioBase64, audioDuration, createdBy,
                entryType, people, place, eventTag, photoBase64s } = req.body;

        if (!content && !audioBase64 && (!photoBase64s || !photoBase64s.length)) {
            return res.status(400).json({
                success: false,
                error: 'At least one of content, audioBase64, or photoBase64s must be provided',
            });
        }

        const payload = {};
        JOURNAL_FIELDS.forEach(k => {
            if (req.body[k] !== undefined) payload[k] = req.body[k];
        });
        // Remove audioBase64 from payload — it's processed separately
        delete payload.audioBase64;

        // Prepare upload tasks for parallel execution
        const uploadPromises = [];
        
        // 1. Audio upload task
        let audioUploadPromise = null;
        if (audioBase64) {
            const base64Data = audioBase64.replace(/^data:audio\/\w+;base64,/, '');
            const buffer = Buffer.from(base64Data, 'base64');
            const tempId = `journal_${patientId}_audio_${Date.now()}`;
            audioUploadPromise = uploadOnCloudinary(buffer, 'recap/journal/audio', tempId);
            uploadPromises.push(audioUploadPromise);
        }

        // 2. Photo upload tasks
        const photoTasks = [];
        if (photoBase64s && Array.isArray(photoBase64s)) {
            photoBase64s.forEach((photo, i) => {
                if (photo.imageBase64) {
                    const base64Data = photo.imageBase64.replace(/^data:image\/\w+;base64,/, '');
                    const buffer = Buffer.from(base64Data, 'base64');
                    const photoId = `journal_${patientId}_photo_${Date.now()}_${i}`;
                    const task = uploadOnCloudinary(buffer, 'recap/journal/photos', photoId)
                        .then(result => ({ result, caption: photo.caption || '' }));
                    photoTasks.push(task);
                    uploadPromises.push(task);
                }
            });
        }

        // Execute all uploads in parallel
        await Promise.all(uploadPromises);

        // Process results
        let audioURL = null;
        let audioPublicId = null;
        if (audioUploadPromise) {
            const result = await audioUploadPromise;
            if (result) {
                audioURL = result.secure_url || result.url;
                audioPublicId = result.public_id;
            }
        }

        const photos = [];
        for (const task of photoTasks) {
            const { result, caption } = await task;
            if (result) {
                photos.push({
                    url: result.secure_url || result.url,
                    publicId: result.public_id,
                    caption: caption,
                });
            }
        }

        // Auto-derive entryType if not supplied
        const resolvedEntryType = entryType || (photos.length > 0 ? 'memory' : 'journal');

        const entryData = {
            ...payload,
            ...(audioURL && { audioURL }),
            ...(audioPublicId && { audioPublicId }),
            ...(photos.length && { photos }),
            entryType: resolvedEntryType,
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp(),
        };

        const docRef = await addDoc(journalRef(patientId), entryData);
        const snap = await getDoc(docRef);

        return res.status(201).json({ success: true, data: { id: snap.id, ...serializeEntry(snap.data()) } });
    } catch (err) {
        next(err);
    }
}

async function getEntries(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patientId, limit = 20, after } = req.query;
        const parsedLimit = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));

        let q = query(journalRef(patientId), orderBy('createdAt', 'desc'), limitFn(parsedLimit));

        if (after) {
            const afterSnap = await getDoc(
                doc(firestore, USERS_COLLECTION, patientId, JOURNAL_SUBCOLLECTION, after)
            );
            if (afterSnap.exists()) {
                q = query(
                    journalRef(patientId),
                    orderBy('createdAt', 'desc'),
                    startAfter(afterSnap),
                    limitFn(parsedLimit)
                );
            }
        }

        const snap = await getDocs(q);
        const data = snap.docs.map(d => ({ id: d.id, ...serializeEntry(d.data()) }));

        return res.status(200).json({ success: true, data, count: data.length });
    } catch (err) {
        next(err);
    }
}

async function getEntryById(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patientId } = req.query;
        const { id: entryId } = req.params;

        const snap = await getDoc(
            doc(firestore, USERS_COLLECTION, patientId, JOURNAL_SUBCOLLECTION, entryId)
        );

        if (!snap.exists()) {
            return res.status(404).json({ success: false, error: 'Journal entry not found' });
        }

        return res.status(200).json({ success: true, data: { id: snap.id, ...serializeEntry(snap.data()) } });
    } catch (err) {
        next(err);
    }
}

async function updateEntry(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { id: entryId } = req.params;
        const { patientId, title, content, mood, audioBase64, audioDuration } = req.body;

        const entryDocRef = doc(
            firestore, USERS_COLLECTION, patientId, JOURNAL_SUBCOLLECTION, entryId
        );
        const existingSnap = await getDoc(entryDocRef);

        if (!existingSnap.exists()) {
            return res.status(404).json({ success: false, error: 'Journal entry not found' });
        }

        const updates = {};
        if (title !== undefined) updates.title = title;
        if (content !== undefined) updates.content = content;
        if (mood !== undefined) updates.mood = mood;
        if (audioDuration !== undefined) updates.audioDuration = audioDuration;

        if (audioBase64) {
            const existingData = existingSnap.data();
            const uploadPromises = [];
            
            // Delete old audio if exists
            if (existingData.audioPublicId) {
                uploadPromises.push(deleteFromCloudinary(existingData.audioPublicId, 'video'));
            }

            const base64Data = audioBase64.replace(/^data:audio\/\w+;base64,/, '');
            const buffer = Buffer.from(base64Data, 'base64');
            const tempId = `journal_${patientId}_${Date.now()}`;
            const uploadNewTask = uploadOnCloudinary(buffer, 'recap/journal/audio', tempId);
            uploadPromises.push(uploadNewTask);

            // Execute in parallel
            await Promise.allSettled(uploadPromises);
            
            const uploadResult = await uploadNewTask;
            if (uploadResult) {
                updates.audioURL = uploadResult.secure_url || uploadResult.url;
                updates.audioPublicId = uploadResult.public_id;
            }
        }

        if (Object.keys(updates).length === 0) {
            return res.status(400).json({ success: false, error: 'No updatable fields provided' });
        }

        await updateDoc(entryDocRef, { ...updates, updatedAt: serverTimestamp() });
        const snap = await getDoc(entryDocRef);

        return res.status(200).json({ success: true, data: { id: snap.id, ...serializeEntry(snap.data()) } });
    } catch (err) {
        next(err);
    }
}

async function deleteEntry(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { id: entryId } = req.params;
        const { patientId } = req.query;

        console.log(`[Journal] Attempting to delete entry ${entryId} for patient ${patientId}`);

        const entryDocRef = doc(
            firestore, USERS_COLLECTION, patientId, JOURNAL_SUBCOLLECTION, entryId
        );
        const snap = await getDoc(entryDocRef);

        if (!snap.exists()) {
            console.warn(`[Journal] Delete failed: Entry ${entryId} not found`);
            return res.status(404).json({ success: false, error: 'Journal entry not found' });
        }

        const entryData = snap.data();
        
        // Asynchronously delete media assets in parallel
        const cleanupPromises = [];
        if (entryData.audioPublicId) {
            console.log(`[Journal] Queueing audio deletion: ${entryData.audioPublicId}`);
            cleanupPromises.push(deleteFromCloudinary(entryData.audioPublicId, 'video'));
        }
        if (entryData.photos && Array.isArray(entryData.photos)) {
            entryData.photos.forEach(photo => {
                if (photo.publicId) {
                    console.log(`[Journal] Queueing photo deletion: ${photo.publicId}`);
                    cleanupPromises.push(deleteFromCloudinary(photo.publicId, 'image'));
                }
            });
        }

        try {
            if (cleanupPromises.length > 0) {
                await Promise.allSettled(cleanupPromises);
            }
        } catch (mediaError) {
            console.error(`[Journal] Error during parallel media cleanup for entry ${entryId}:`, mediaError);
        }

        await deleteDoc(entryDocRef);
        console.log(`[Journal] Successfully deleted entry ${entryId}`);

        return res.status(200).json({ success: true, message: 'Journal entry deleted successfully' });
    } catch (err) {
        console.error(`[Journal] Unexpected error during deletion of entry ${req.params.id}:`, err);
        next(err);
    }
}

export default {
    createEntry,
    getEntries,
    getEntryById,
    updateEntry,
    deleteEntry,
};
