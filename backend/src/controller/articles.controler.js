import {
    collection,
    doc,
    getDoc,
    getDocs,
    addDoc,
    updateDoc,
    deleteDoc,
    query,
    limit as limitFn,
    startAfter,
    serverTimestamp,
} from 'firebase/firestore';
import { firestore } from '../utils/db.js';
import config from '../../config.js';
import { ARTICLE_FIELDS } from '../models/articles.model.js';

const COLLECTION_NAME = config.firestoreNames.articlesCollection;
const articlesRef = () => collection(firestore, COLLECTION_NAME);

async function createArticle(req, res, next) {
    try {
        const payload = {};
        ARTICLE_FIELDS.forEach(k => {
            if (req.body[k] !== undefined) payload[k] = req.body[k];
        });

        const docRef = await addDoc(articlesRef(), {
            ...payload,
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp(),
        });

        const snap = await getDoc(docRef);
        return res.status(201).json({ success: true, data: { id: snap.id, ...snap.data() } });
    } catch (err) {
        next(err);
    }
}

async function getArticleByID(req, res, next) {
    try {
        const snap = await getDoc(doc(firestore, COLLECTION_NAME, req.params.id));
        if (!snap.exists()) {
            return res.status(404).json({ success: false, error: 'Article not found' });
        }
        return res.status(200).json({ success: true, data: { id: snap.id, ...snap.data() } });
    } catch (err) {
        next(err);
    }
}

async function getAllArticles(req, res, next) {
    try {
        const { limit = 20, after } = req.query;
        let q = query(articlesRef(), limitFn(Math.min(100, Math.max(1, parseInt(limit, 10) || 20))));

        if (after) {
            const afterSnap = await getDoc(doc(firestore, COLLECTION_NAME, after));
            if (afterSnap.exists()) {
                q = query(articlesRef(), startAfter(afterSnap), limitFn(limit));
            }
        }

        const snap = await getDocs(q);
        const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));

        return res.status(200).json({ success: true, data, count: data.length });
    } catch (err) {
        next(err);
    }
}

async function updateArticle(req, res, next) {
    try {
        const { id } = req.params;
        const updates = {};
        ARTICLE_FIELDS.forEach(k => {
            if (req.body[k] !== undefined) updates[k] = req.body[k];
        });

        if (Object.keys(updates).length === 0) {
            return res.status(400).json({ success: false, error: 'No updatable fields provided' });
        }

        const docRef = doc(firestore, COLLECTION_NAME, id);
        await updateDoc(docRef, { ...updates, updatedAt: serverTimestamp() });
        const snap = await getDoc(docRef);

        return res.status(200).json({ success: true, data: { id: snap.id, ...snap.data() } });
    } catch (err) {
        next(err);
    }
}

async function deleteArticle(req, res, next) {
    try {
        const { id } = req.params;
        await deleteDoc(doc(firestore, COLLECTION_NAME, id));
        return res.status(204).send();
    } catch (err) {
        next(err);
    }
}

export default {
    getAllArticles,
    getArticleByID,
    createArticle,
    updateArticle,
    deleteArticle,
};
