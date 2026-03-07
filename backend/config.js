import 'dotenv/config';

export default {
    firebase: {
        apiKey: process.env.FIREBASE_API_KEY,
        authDomain: process.env.FIREBASE_AUTH_DOMAIN,
        databaseURL: process.env.FIREBASE_DATABASE_URL,
        projectId: process.env.FIREBASE_PROJECT_ID,
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
        messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
        appId: process.env.FIREBASE_APP_ID,
        measurementId: process.env.FIREBASE_MEASUREMENT_ID,
    },

    gemini: {
        apiKey: process.env.GEMINI_API_KEY,
    },

    firestoreNames: {
        articlesCollection: 'Articles',
        citationsCollection: 'Citations',
        memoryQuizCollection: 'MemoryQuiz',
        usersCollection: 'users',
        questionsCollection: 'Questions',

        streaks_SubCollection: 'streaks',
        // streaksCore_SubCollection: 'streaksCore',
        familyMembers_SubCollection: 'family_members',
        memoryCheckReports_SubCollection: 'memoryCheckReports',

        // QUESTIONS
        personalQuestions_SubCollection: 'questions',

        //reminders
        reminders_SubCollection: 'reminders',

        //journal
        journalEntries_SubCollection: 'journal_entries',

        //analytics cache
        analyticsCache_SubCollection: 'analyticsCache',
    },

    questions: {
        maxQuestions_perDay: 7,
        number_of_immediate_questions: 4,
        number_of_recent_questions: 2,
        number_of_remote_questions: 1,

    },

    timezone: 'Asia/Kolkata',

    analyticsCacheTTL: 300, // seconds (default 5 minutes)

    smriti: {
        aiProvider: 'gemini',  // 'gemini' | 'appleIntelligence'
        rateLimits: {
            daily: 2,
            weekly: 8,
        },
        firestoreCollection: 'smritiUsage',
    },

    question_category: {
        immediate: 'immediateMemory',
        recent: 'recentMemory',
        remote: 'remoteMemory'
    }
};