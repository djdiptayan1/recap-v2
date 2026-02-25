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
import { uploadOnCloudinary, deleteFromCloudinary } from '../../utils/cloudinary.js';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const JOURNAL_SUBCOLLECTION = config.firestoreNames.journalEntries_SubCollection;

const journalRef = (patientId) =>
    collection(firestore, USERS_COLLECTION, patientId, JOURNAL_SUBCOLLECTION);

async function createEntry(req, res, next) {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ success: false, errors: errors.array() });
        }

        const { patientId, title, content, mood, audioBase64, audioDuration, createdBy } = req.body;

        if (!content && !audioBase64) {
            return res.status(400).json({
                success: false,
                error: 'At least one of content or audioBase64 must be provided',
            });
        }

        const payload = {};
        JOURNAL_FIELDS.forEach(k => {
            if (req.body[k] !== undefined) payload[k] = req.body[k];
        });
        // Remove audioBase64 from payload — it's processed separately
        delete payload.audioBase64;

        let audioURL = null;
        let audioPublicId = null;

        if (audioBase64) {
            // Strip the data URI prefix if present
            const base64Data = audioBase64.replace(/^data:audio\/\w+;base64,/, '');
            const buffer = Buffer.from(base64Data, 'base64');

            // Generate a temporary ID for naming the file
            const tempId = `journal_${patientId}_${Date.now()}`;
            const uploadResult = await uploadOnCloudinary(buffer, 'recap/journal/audio', tempId);

            if (uploadResult) {
                audioURL = uploadResult.secure_url || uploadResult.url;
                audioPublicId = uploadResult.public_id;
            }
        }

        const entryData = {
            ...payload,
            ...(audioURL && { audioURL }),
            ...(audioPublicId && { audioPublicId }),
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp(),
        };

        const docRef = await addDoc(journalRef(patientId), entryData);
        const snap = await getDoc(docRef);

        return res.status(201).json({ success: true, data: { id: snap.id, ...snap.data() } });
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
        const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));

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

        return res.status(200).json({ success: true, data: { id: snap.id, ...snap.data() } });
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
            // Delete old audio if exists
            const existingData = existingSnap.data();
            if (existingData.audioPublicId) {
                await deleteFromCloudinary(existingData.audioPublicId, 'video');
            }

            const base64Data = audioBase64.replace(/^data:audio\/\w+;base64,/, '');
            const buffer = Buffer.from(base64Data, 'base64');
            const tempId = `journal_${patientId}_${Date.now()}`;
            const uploadResult = await uploadOnCloudinary(buffer, 'recap/journal/audio', tempId);

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

        return res.status(200).json({ success: true, data: { id: snap.id, ...snap.data() } });
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

        const entryDocRef = doc(
            firestore, USERS_COLLECTION, patientId, JOURNAL_SUBCOLLECTION, entryId
        );
        const snap = await getDoc(entryDocRef);

        if (!snap.exists()) {
            return res.status(404).json({ success: false, error: 'Journal entry not found' });
        }

        const entryData = snap.data();
        if (entryData.audioPublicId) {
            await deleteFromCloudinary(entryData.audioPublicId, 'video');
        }

        await deleteDoc(entryDocRef);

        return res.status(200).json({ success: true, message: 'Journal entry deleted successfully' });
    } catch (err) {
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
