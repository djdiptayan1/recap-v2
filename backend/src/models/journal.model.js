export const JournalSchema = {
    patientId: 'string',        // The patient's Firestore document ID
    title: 'string',            // Optional title for the entry
    content: 'string',          // Text content of the journal entry
    mood: 'string',             // Optional mood tag: 'happy', 'sad', 'neutral', 'anxious', 'calm', 'grateful'
    audioURL: 'string',         // Cloudinary URL for voice recording (if any)
    audioPublicId: 'string',    // Cloudinary public_id for deletion
    audioDuration: 'number',    // Duration of audio in seconds
    createdBy: 'string',        // 'patient' or 'family'
    createdAt: 'Timestamp',     // Firestore server timestamp
    updatedAt: 'Timestamp',     // Firestore server timestamp
};

export const JOURNAL_FIELDS = [
    'patientId',
    'title',
    'content',
    'mood',
    'audioURL',
    'audioPublicId',
    'audioDuration',
    'createdBy',
];
