import { doc, setDoc, updateDoc, serverTimestamp, getDoc } from 'firebase/firestore';
import { firestore } from '../../utils/db.js';
import config from '../../../config.js';
import { validationResult } from 'express-validator';

const USERS_COLLECTION = config.firestoreNames.usersCollection;
const REPORTS_COLLECTION = config.firestoreNames.memoryCheckReports_SubCollection;

export async function submitQuiz(req, res, next) {
    try {
        const { documentId, score } = req.body;

        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                errors: errors.array(),
            });
        }

        if (!documentId) {
            return res.status(400).json({
                success: false,
                message: 'Document ID is required (in body, params, or query)',
            });
        }

        if (score === undefined || score === null || typeof score !== 'number') {
            return res.status(400).json({
                success: false,
                message: 'Score is required and must be a number.',
            });
        }

        // Check if user exists
        const userRef = doc(firestore, USERS_COLLECTION, documentId);
        const userSnap = await getDoc(userRef);

        if (!userSnap.exists()) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        // Calculate Result
        let result = {};
        if (score <= 8) {
            result = {
                status: "Functioning Okay",
                description: "Your brain is functioning okay. By learning to relax and maintain a healthy diet, your brain can function at even higher levels.",
                color: "green",
                icon: "brain.head.profile"
            };
        } else if (score <= 11) {
            result = {
                status: "Brain in Danger",
                description: "Your brain is in danger. Check your diet today. You can reduce brain drain and memory loss with vitamins, brain foods, herbs, yoga and meditation techniques, and appropriate medications.",
                color: "orange",
                icon: "exclamationmark.triangle.fill"
            };
        } else {
            result = {
                status: "Running on Empty",
                description: "Your brain is running on empty. You should see your doctor. You can refuel your brain and prevent further memory loss with food, vitamins, herbs, exercises, and medications.",
                color: "red",
                icon: "battery.0percent"
            };
        }

        const now = new Date();
        const dateString = now.toISOString().split('T')[0]; // YYYY-MM-DD

        const reportData = {
            date: serverTimestamp(),
            createdAt: serverTimestamp(),
            totalScore: score,
            totalQuestions: 15,
            overallPercentage: (score / 15) * 100,
            status: result.status,
            recommendations: [result.description],
            color: result.color,
            icon: result.icon,
            // typeScores: [],
        };

        // Path: users/{uid}/memoryCheckReports/{YYYY-MM-DD}
        const reportRef = doc(firestore, USERS_COLLECTION, documentId, REPORTS_COLLECTION, dateString);

        // Save Report
        await setDoc(reportRef, reportData);

        await updateDoc(userRef, {
            lastMemoryQuizDate: serverTimestamp()
        });

        return res.status(200).json({
            success: true,
            message: 'Quiz submitted successfully',
            data: {
                reportId: dateString,
                ...reportData,
                result
            }
        });

    } catch (error) {
        console.error("Error submitting quiz:", error);
        return res.status(500).json({
            success: false,
            message: error.message,
        });
    }
}