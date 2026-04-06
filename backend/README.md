# Recap Backend API

A Node.js/Express backend API for a memory care application designed to help Alzheimer's patients and their families manage daily cognitive exercises, track progress, maintain health records, and interact with an AI care companion.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Environment Variables](#environment-variables)
- [Project Structure](#project-structure)
- [API Documentation](#api-documentation)
- [Running the Application](#running-the-application)
- [Docker Support](#docker-support)
- [Data Models](#data-models)
- [Configuration](#-configuration)
- [Security Features](#security-features)
- [Error Handling](#-error-handling)
- [Logging](#logging)
- [Additional Information](#-additional-information)

## Overview

Recap Backend is a RESTful API service that powers a memory care application for Alzheimer's patients. The system enables:

- Patient and family member registration and authentication
- Daily cognitive exercise questions tailored to memory types (immediate, recent, remote)
- Question answering with patient/family role distinction
- Family-managed personalized questions (add, edit, delete)
- Memory quiz assessments with historical reports
- Activity streak tracking to encourage consistent engagement
- AI-powered care companion (Smriti) with structured and real-time streaming responses
- Journal and memory entries with photo and audio support
- Reminder management (medicine, appointments, chores, etc.)
- Dashboard analytics with daily, weekly, and monthly statistics
- Educational articles and citations management
- Secure image and audio storage via Cloudinary

## Features

### Authentication & User Management

- Patient signup with unique 6-character patient ID generation
- Family member registration and verification
- Profile management with image upload support (Cloudinary)
- UID-based authentication system
- Account deletion

### Smriti AI Companion

- **Structured endpoint**: Returns JSON with answer, care strategies, sources, medical disclaimer, and follow-up prompts
- **Streaming endpoint**: Real-time Server-Sent Events (SSE) for live chat experience
- Powered by Google Gemini (`gemini-3-flash-preview`) via `@google/genai` SDK
- Patient context-aware: references name, family members, stage, activities, and reminders
- Reminiscence therapy mode for memory lane conversations
- Conversation history support (last 20 messages)

### Cognitive Assessment

- Daily question generation based on memory types:
  - **Immediate Memory**: 4 questions per day
  - **Recent Memory**: 2 questions per day
  - **Remote Memory**: 1 question per day
- Answer submission with patient/family role distinction
- Family-managed personalized questions (CRUD)
- Memory quiz with 15-point scoring system
- Memory quiz report history
- Automatic streak updates on patient answers

### Journal & Memory Entries

- Create, read, update, delete journal entries per patient
- Support for text, voice recordings (audio upload to Cloudinary), and photos (multiple per entry)
- Mood tagging: happy, sad, neutral, anxious, calm, grateful
- Entry types: journal (text/voice) and memory (photo-focused)
- People, place, and event tagging
- Pagination support

### Reminders

- CRUD operations for patient reminders
- Categories: Medicine, Daily Chore, Appointment, Exercise, Meal, Hydration, Other
- Frequencies: once, hourly, daily, weekdays, weekends, weekly, biweekly, monthly, yearly

### Dashboard Analytics

- Daily, weekly, and monthly question accuracy statistics
- Per-category breakdowns (immediate, recent, remote)
- Cognitive decline trend alerts
- Analytics caching with configurable TTL (default 5 minutes)

### Progress Tracking

- Daily activity streak calculation
- Monthly and yearly streak statistics
- Engagement metrics for patients
- Last activity date tracking

### Educational Resources

- Article management system
- Scientific citation database
- Support for multimedia content (images, links)
- Pagination support for large datasets

### Family Features

- Family member profiles
- Multi-user support per patient
- Relationship tracking
- Family member deletion
- Collaborative care management

## Tech Stack

- **Runtime**: Node.js (ES Modules)
- **Framework**: Express.js v5.1.0
- **Database**: Firebase Firestore
- **AI/ML**: Google Gemini via `@google/genai` v1.35.0
- **File Storage**: Cloudinary v2.8.0
- **Validation**: express-validator v7.3.0
- **MIME Detection**: mime v4.1.0
- **Logging**: Morgan
- **Environment**: dotenv

## Prerequisites

- Node.js (v18 or higher)
- npm
- Firebase project with Firestore enabled
- Cloudinary account for image/audio storage
- Google Gemini API key (for Smriti AI)

## Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/djdiptayan1/recap-v2.git
   cd recap/backend
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Set up environment variables**

   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Set up Firebase Service Account Key (required for Firebase Admin operations)**

   - Go to [Firebase Console](https://console.firebase.google.com) → **Project Settings** → **Service accounts**
   - Click **"Generate new private key"** → Download the JSON file
   - Save it as `serviceAccountKey.json` in the `backend/` root directory

   > ⚠️ **Never commit this file to git.** It is already in `.gitignore`.

5. **Verify Firebase connection**
   The application automatically checks Firebase connectivity on startup.

5. **Start the dev server**

   ```bash
   npm run dev
   ```

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Firebase Configuration
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_DATABASE_URL=https://your_project.firebaseio.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
FIREBASE_MEASUREMENT_ID=your_measurement_id

# Firebase Admin (Docker/Production only - base64-encoded service account JSON)
# FIREBASE_SERVICE_ACCOUNT=your_base64_encoded_service_account_key

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Gemini AI Configuration
GEMINI_API_KEY=your_gemini_api_key
```

## Running the Application

### Development Mode

```bash
npm run dev
```

Uses nodemon for automatic server restart on file changes.

### Production Mode

```bash
npm start
```

The server will start on the configured PORT (default: 3000).

### Verify Installation

```bash
curl http://localhost:3000/health
```

Expected response:

```json
{
  "status": "ok",
  "message": "Server is running and Firebase is connected",
  "timestamp": "2026-01-01T00:00:00.000Z"
}
```

## Docker Support

A Dockerfile and deployment script are included for containerized deployment.

### Build Docker Image and Push to Docker Hub

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t username/recap-backend:latest --push .
```

### Run Container

For Docker, pass the service account key as a **base64-encoded environment variable** instead of copying the file into the image:

```bash
# Step 1: Generate the base64 string (run once locally)
base64 -i serviceAccountKey.json

# Step 2: Run with the base64 key
docker run --platform linux/amd64 \
--name recappp \
--env-file recapEnv.env \
-e FIREBASE_SERVICE_ACCOUNT="<paste_base64_string_here>" \
-p 3000:3000 \
username/recap-backend
```

> 💡 Alternatively, add `FIREBASE_SERVICE_ACCOUNT=<base64_string>` to your `recapEnv.env` file.

### Auto-Restart Script

A convenience script `restart-recap.sh` is provided to pull the latest image and restart the container:

```bash
./restart-recap.sh
```

## Project Structure

```
backend/
├── config.js                 # Application configuration (Firebase, Gemini, Firestore collections, questions, timezone)
├── index.js                  # Application entry point
├── Dockerfile               # Docker configuration
├── restart-recap.sh         # Docker restart convenience script
├── package.json             # Dependencies and scripts
├── .env.example             # Environment variable template
├── src/
│   ├── app.js              # Express app setup (middleware, routes, error handling)
│   ├── auth/               # Authentication controllers
│   │   ├── deleteAccount.controller.js
│   │   ├── familySignup.controller.js
│   │   ├── patientSignup.controller.js
│   │   ├── verifyFamilyMember.controller.js
│   │   └── verifyUID.controller.js
│   ├── controller/         # Business logic controllers
│   │   ├── analytics/
│   │   │   └── dashboardAnalytics.controller.js
│   │   ├── articles.controler.js
│   │   ├── citations.controller.js
│   │   ├── family_member/
│   │   │   ├── deleteFamily.controller.js
│   │   │   └── fetchFamily.controller.js
│   │   ├── journal/
│   │   │   └── journal.controller.js
│   │   ├── memoryQuiz/
│   │   │   ├── getQuizQuestions.controller.js
│   │   │   ├── memoryReport.controller.js
│   │   │   └── submitQuiz.controller.js
│   │   ├── patient/
│   │   │   └── fetch.controller.js
│   │   ├── questions/
│   │   │   ├── answerDailyQuestion.controller.js
│   │   │   ├── fetch.controller.js
│   │   │   ├── getDailyQuestions.controller.js
│   │   │   ├── admin/
│   │   │   │   ├── addQuestion.controller.js
│   │   │   │   ├── deleteQuestion.controller.js
│   │   │   │   └── editQuestions.controller.js
│   │   │   └── family/
│   │   │       └── fetchFamilyQuestions.controller.js
│   │   ├── reminders/
│   │   │   ├── getReminders.controller.js
│   │   │   └── setReminders.controller.js
│   │   ├── smriti/
│   │   │   ├── smriti.controller.js
│   │   │   └── smriti.stream.controller.js
│   │   └── streaks/
│   │       ├── fetchStreak.controller.js
│   │       └── updateStreak.controller.js
│   ├── middleware/         # Custom middleware
│   │   └── dbCheck.js      # Firebase connection middleware
│   ├── models/             # Data models / schemas
│   │   ├── articles.model.js
│   │   ├── citations.model.js
│   │   ├── familyMember.model.js
│   │   ├── journal.model.js
│   │   ├── memoryQuiz.model.js
│   │   ├── patient.model.js
│   │   ├── questions.model.js
│   │   ├── reminder.model.js
│   │   └── streaks.model.js
│   ├── routes/             # API route definitions
│   │   ├── index.js        # Main router (mounts all sub-routers)
│   │   ├── analytics.routes.js
│   │   ├── articles.routes.js
│   │   ├── auth.route.js
│   │   ├── citations.routes.js
│   │   ├── familyMember.routes.js
│   │   ├── journal.routes.js
│   │   ├── memoryQuiz.routes.js
│   │   ├── patient.routes.js
│   │   ├── questions.routes.js
│   │   ├── reminders.route.js
│   │   ├── smriti.routes.js
│   │   └── streaks.routes.js
│   └── utils/              # Utility functions
│       ├── cloudinary.js   # Image/audio upload & deletion
│       ├── dateUtils.js    # Timezone-aware date formatting
│       ├── db.js           # Firebase client initialization
│       ├── firebaseAdmin.js # Firebase Admin SDK initialization
│       ├── generateUniquePatientID.js
│       └── streakCalculator.js
```

## 📚 API Documentation

### Base URL

```
http://localhost:3000/api
```

### Health Check

```
GET /health
GET /
```

---

### Authentication Endpoints

#### 1. Verify Patient UID

```http
POST /api/auth/verify-uid
Content-Type: application/json

{
  "patientUID": "ABC123"
}
```

#### 2. Patient Signup

```http
POST /api/auth/patientsignup
Content-Type: application/json

{
  "uid": "firebase_user_id",
  "email": "patient@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "dateOfBirth": "1950-01-01",
  "bloodGroup": "A+",
  "sex": "Male",
  "stage": "Early",
  "profileImageBase64": "data:image/jpeg;base64,..."
}
```

**Response:**

```json
{
  "message": "Patient profile created successfully",
  "user": {
    "email": "patient@example.com",
    "patientUID": "ABC123",
    "firstName": "John",
    "lastName": "Doe",
    "profileImageURL": "https://cloudinary.com/...",
    "type": "patient",
    "createdAt": "2026-01-01T00:00:00.000Z"
  }
}
```

#### 3. Family Member Signup

```http
POST /api/auth/familysignup
Content-Type: application/json

{
  "patient_documentId": "firebase_patient_doc_id",
  "email": "family@example.com",
  "name": "Jane Doe",
  "profileImageBase64": "data:image/jpeg;base64,...",
  "phone": "+1234567890",
  "relation": "Daughter"
}
```

#### 4. Verify Family Member

```http
POST /api/auth/verify-familymember
Content-Type: application/json

{
  "email": "family@example.com",
  "documentId": "firebase_patient_doc_id"
}
```

---

### Patient Endpoints

#### Get Patient Details

```http
GET /api/patient/:documentId
```

**Response:**

```json
{
  "success": true,
  "data": {
    "patientUID": "ABC123",
    "firstName": "John",
    "lastName": "Doe",
    "email": "patient@example.com",
    "profileImageURL": "https://...",
    "stage": "Early",
    "bloodGroup": "A+"
  }
}
```

---

### Questions Endpoints

#### 1. Get All Questions

```http
GET /api/questions
```

#### 2. Get Daily Questions

```http
GET /api/questions/dailyquestions
```

**Response:**

```json
{
  "success": true,
  "count": 7,
  "data": [
    {
      "id": "question_id",
      "text": "What did you eat for breakfast today?",
      "category": "immediateMemory",
      "answerOptions": ["Toast", "Cereal", "Eggs", "Fruit"],
      "correctAnswers": ["Toast"],
      "questionType": "multiple-choice"
    }
  ],
  "meta": {
    "immediate": 4,
    "recent": 2,
    "remote": 1
  }
}
```

#### 3. Answer a Daily Question

```http
POST /api/questions/answer
Content-Type: application/json

{
  "patientId": "firebase_doc_id",
  "questionId": "question_id",
  "answer": "Toast",
  "answeredBy": "patient",
  "date": "2026-01-01",
  "category": "immediateMemory"
}
```

- `answeredBy`: `"patient"` stores in `answers` field and updates streak; `"family"` stores in `correctAnswers` field.

#### 4. Get Family Questions

```http
GET /api/questions/family/:patient_documentId
```

#### 5. Add Family Question

```http
POST /api/questions/family/:patient_documentId/add
Content-Type: application/json

{
  "text": "What is your favorite childhood memory?",
  "category": "remoteMemory",
  "subcategory": "childhood",
  "questionType": "multiple-choice",
  "answerOptions": ["Playing outdoors", "Family dinners", "School trips", "Festivals"],
  "correctAnswers": ["Playing outdoors"],
  "askInterval": 7,
  "timeFrame": { "from": "1960-01-01", "to": "1975-12-31" },
  "tag": "childhood"
}
```

#### 6. Edit Family Question

```http
PUT /api/questions/family/:patient_documentId/edit/:questionId
Content-Type: application/json

{
  "text": "Updated question text",
  "answerOptions": ["Option A", "Option B"],
  "correctAnswers": ["Option A"]
}
```

#### 7. Delete Family Question

```http
DELETE /api/questions/family/:patient_documentId/delete/:questionId
```

---

### Memory Quiz Endpoints

#### 1. Get Quiz Questions

```http
GET /api/memoryquiz
```

#### 2. Submit Quiz Results

```http
POST /api/memoryquiz
Content-Type: application/json

{
  "score": 12
}
```

**Score Range**: 0-15

#### 3. Get Memory Quiz Reports

```http
GET /api/memoryquiz/reports/:patientId
```

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": "report_id",
      "score": 12,
      "date": "2026-01-01T00:00:00.000Z",
      "createdAt": "2026-01-01T00:00:00.000Z"
    }
  ]
}
```

---

### Smriti AI Endpoints

#### 1. Structured Response

```http
POST /api/smriti
Content-Type: application/json

{
  "query": "What activities help with memory?",
  "context": {
    "patientName": "John",
    "stage": "Early",
    "dob": "1950-01-01",
    "familyMembers": [
      { "name": "Jane", "relation": "Daughter" }
    ],
    "recentActivities": {
      "streakDays": 5,
      "reminders": ["Take medicine", "Morning walk"]
    },
    "mode": "memoryLane"
  },
  "history": [
    { "role": "user", "text": "Hi Smriti" },
    { "role": "model", "text": "Hello! How are you today?" }
  ]
}
```

**Response:**

```json
{
  "answer": "Memory-boosting activities include...",
  "followup_prompt": "Do you remember playing any games with Jane when she was little?",
  "care_strategies": ["Try daily crossword puzzles", "Take regular walks"],
  "medical_disclaimer": "Please consult your doctor for personalized advice.",
  "sources": [
    { "name": "Alzheimer's Association", "url": "https://alz.org" }
  ],
  "supportive_note": "You're doing great by staying engaged!"
}
```

#### 2. Streaming Response (SSE)

```http
POST /api/smriti/stream
Content-Type: application/json

{
  "query": "Tell me about managing sundowning",
  "context": { ... },
  "history": [ ... ]
}
```

**Response**: Server-Sent Events stream

```
data: {"text":"Sundowning is a common..."}
data: {"text":" pattern in Alzheimer's..."}
data: [DONE]
```

---

### Journal Endpoints

#### 1. List Journal Entries

```http
GET /api/journal?patientId=doc_id&limit=10&after=last_doc_id
```

#### 2. Get Journal Entry by ID

```http
GET /api/journal/:id?patientId=doc_id
```

#### 3. Create Journal Entry

```http
POST /api/journal
Content-Type: application/json

{
  "patientId": "firebase_doc_id",
  "title": "A beautiful morning",
  "content": "Today I remembered...",
  "mood": "happy",
  "createdBy": "patient",
  "entryType": "journal",
  "people": "Jane, Ravi",
  "place": "Home garden",
  "eventTag": "daily",
  "audioBase64": "data:audio/m4a;base64,...",
  "audioDuration": 45,
  "photoBase64s": [
    {
      "imageBase64": "data:image/jpeg;base64,...",
      "caption": "Morning flowers"
    }
  ]
}
```

For large uploads on Vercel, do not send many base64 images plus audio in one JSON body. Use direct Cloudinary uploads first:

```http
POST /api/journal/uploads/sign
Content-Type: application/json

{
  "patientId": "firebase_doc_id",
  "mediaType": "photo",
  "index": 0
}
```

Or fetch all upload signatures in one call:

```http
POST /api/journal/uploads/sign-batch
Content-Type: application/json

{
  "patientId": "firebase_doc_id",
  "photoCount": 10,
  "includeAudio": true
}
```

Then upload the file directly to the returned `uploadUrl`, and create the journal entry with media references instead of base64:

```http
POST /api/journal
Content-Type: application/json

{
  "patientId": "firebase_doc_id",
  "content": "Today I remembered...",
  "audioUpload": {
    "url": "https://res.cloudinary.com/.../audio-file.m4a",
    "publicId": "recap/journal/audio/journal_patient_audio_..."
  },
  "photoUploads": [
    {
      "url": "https://res.cloudinary.com/.../photo-1.jpg",
      "publicId": "recap/journal/photos/journal_patient_photo_...",
      "caption": "Morning flowers"
    }
  ]
}
```

Rules:
- Use either `audioBase64` or `audioUpload`, never both
- Use either `photoBase64s` or `photoUploads`, never both
- Maximum 10 photos per journal entry
- `audioUpload.url` and `photoUploads[].url` must be Cloudinary URLs

**Mood values**: `happy`, `sad`, `neutral`, `anxious`, `calm`, `grateful`

**Entry types**: `journal`, `memory`

#### 4. Update Journal Entry

```http
PUT /api/journal/:id
Content-Type: application/json

{
  "patientId": "firebase_doc_id",
  "title": "Updated title",
  "content": "Updated content",
  "mood": "calm"
}
```

#### 5. Delete Journal Entry

```http
DELETE /api/journal/:id?patientId=doc_id
```

---

### Reminders Endpoints

#### 1. Get Reminders

```http
GET /api/reminders?patientId=doc_id
```

#### 2. Add Reminder

```http
POST /api/reminders
Content-Type: application/json

{
  "patientId": "firebase_doc_id",
  "title": "Take morning medicine",
  "category": "Medicine",
  "frequency": "daily",
  "time": "2026-01-01T08:00:00.000Z",
  "notes": "With breakfast"
}
```

**Categories**: `Medicine`, `Daily Chore`, `Appointment`, `Exercise`, `Meal`, `Hydration`, `Other`

**Frequencies**: `once`, `hourly`, `daily`, `weekdays`, `weekends`, `weekly`, `biweekly`, `monthly`, `yearly`

#### 3. Edit Reminder

```http
PUT /api/reminders
Content-Type: application/json

{
  "patientId": "firebase_doc_id",
  "reminderId": "reminder_doc_id",
  "title": "Take evening medicine",
  "time": "2026-01-01T20:00:00.000Z"
}
```

#### 4. Delete Reminder

```http
DELETE /api/reminders
Content-Type: application/json

{
  "patientId": "firebase_doc_id",
  "reminderId": "reminder_doc_id"
}
```

---

### Analytics Endpoints

#### Get Dashboard Analytics

```http
GET /api/analytics/dashboard/:patientId
```

**Response:**

```json
{
  "success": true,
  "data": {
    "today": {
      "total": 7,
      "answered": 5,
      "correct": 4,
      "accuracyPercent": 80,
      "categories": {
        "immediate": { "total": 4, "correct": 3 },
        "recent": { "total": 2, "correct": 1 },
        "remote": { "total": 1, "correct": 0 }
      }
    },
    "weekly": [ ... ],
    "monthly": [ ... ],
    "declineAlerts": [ ... ]
  }
}
```

---

### Streaks Endpoints

#### 1. Update Activity Streak

```http
POST /api/streaks/activity
Content-Type: application/json

{
  "documentId": "firebase_user_doc_id"
}
```

#### 2. Get Streak Statistics

```http
GET /api/streaks/stats/:documentId
```

**Response:**

```json
{
  "success": true,
  "data": {
    "currentStreak": 5,
    "maxStreak": 12,
    "activeDays": 45,
    "lastAnsweredDate": "2026-01-01"
  }
}
```

#### 3. Get Monthly Streak Data

```http
GET /api/streaks/month/:documentId?yearMonth=2026-01
```

#### 4. Get Yearly Streak Data

```http
GET /api/streaks/year/:documentId?year=2026
```

---

### Family Members Endpoints

#### 1. Get Family Members

```http
GET /api/familymembers/:documentId
```

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": "member_doc_id",
      "email": "family@example.com",
      "name": "Jane Doe",
      "relation": "Daughter",
      "phone": "+1234567890",
      "profileImageURL": "https://..."
    }
  ]
}
```

#### 2. Delete Family Member

```http
DELETE /api/familymembers/:documentId/:memberId
```

---

### Articles Endpoints

#### 1. List All Articles

```http
GET /api/articles?limit=10&after=doc_id
```

#### 2. Get Article by ID

```http
GET /api/articles/:id
```

#### 3. Create Article

```http
POST /api/articles
Content-Type: application/json

{
  "title": "Understanding Alzheimer's Disease",
  "content": "Article content here...",
  "author": "Dr. Smith",
  "citation": "optional_citation_id",
  "image": "https://image-url.com/image.jpg",
  "link": "https://source-url.com",
  "source": "https://original-source.com"
}
```

#### 4. Update Article

```http
PUT /api/articles/:id
```

#### 5. Delete Article

```http
DELETE /api/articles/:id
```

---

### Citations Endpoints

#### 1. List All Citations

```http
GET /api/citations?limit=10&after=doc_id
```

#### 2. Get Citation by ID

```http
GET /api/citations/:id
```

#### 3. Create Citation

```http
POST /api/citations
Content-Type: application/json

{
  "title": "Research Paper Title",
  "authors": "Smith, J., Doe, A.",
  "journal": "Journal of Neuroscience",
  "year": "2025",
  "doi": "10.1234/example",
  "url": "https://doi.org/10.1234/example"
}
```

#### 4. Update Citation

```http
PUT /api/citations/:id
```

#### 5. Delete Citation

```http
DELETE /api/citations/:id
```

---

## Data Models

### Patient Schema

```javascript
{
  patientUID: "ABC123",          // Unique 6-character ID
  firstName: "John",
  lastName: "Doe",
  email: "patient@example.com",
  sex: "Male",
  dateOfBirth: "1950-01-01",
  bloodGroup: "A+",
  stage: "Early",                // Alzheimer's stage
  profileImageURL: "https://...",
  type: "patient",
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Question Schema

```javascript
{
  text: "Question text",
  category: "immediateMemory",   // immediateMemory, recentMemory, remoteMemory
  subcategory: "optional",
  questionType: "multiple-choice",
  answerOptions: ["Option 1", "Option 2"],
  correctAnswers: ["Option 1"],  // Multiple correct answers supported
  answers: ["Patient Answer"],   // Patient-submitted answers
  patientAnswer: "Latest answer",
  hint: "Optional hint",
  image: "https://...",
  audio: "https://...",
  priority: 1,
  hardness: "easy",
  confidence: 0.85,
  askInterval: 7,                // Days between asks
  timeFrame: { from: "date", to: "date" },
  tag: "daily-routine",
  isActive: true,
  isAnswered: false,
  timesAsked: 0,
  timesAnsweredCorrectly: 0,
  lastAsked: Timestamp,
  lastAnsweredDate: "ISO string",
  lastAnsweredCorrectly: Timestamp,
  addedAt: Timestamp,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Journal Entry Schema

```javascript
{
  patientId: "firebase_doc_id",
  title: "Entry title",
  content: "Text content",
  mood: "happy",                 // happy, sad, neutral, anxious, calm, grateful
  audioURL: "https://...",       // Cloudinary URL for voice recording
  audioPublicId: "public_id",   // For Cloudinary deletion
  audioDuration: 45,             // Seconds
  createdBy: "patient",          // patient or family
  entryType: "journal",          // journal or memory
  people: "Jane, Ravi",          // Comma-separated names
  place: "Home garden",
  eventTag: "birthday",          // birthday, holiday, family, daily, etc.
  photos: [                      // Built from photoBase64s during upload
    { url: "https://...", publicId: "id", caption: "Description" }
  ],
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Reminder Schema

```javascript
{
  title: "Take medicine",
  category: "Medicine",          // Medicine, Daily Chore, Appointment, Exercise, Meal, Hydration, Other
  frequency: "daily",            // once, hourly, daily, weekdays, weekends, weekly, biweekly, monthly, yearly
  time: "2026-01-01T08:00:00Z",
  notes: "Optional notes",
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Streak Schema

```javascript
{
  currentStreak: 5,              // Consecutive days
  maxStreak: 12,                 // Longest streak
  activeDays: 45,                // Total active days
  lastAnsweredDate: "2026-01-01",
  streakData: {
    "2026-01-01": true,
    "2026-01-02": true
    // ... date-boolean map
  }
}
```

### Family Member Schema

```javascript
{
  email: "family@example.com",
  name: "Jane Doe",
  relation: "Daughter",
  phone: "+1234567890",
  profileImageURL: "https://...",
  patient_documentId: "firebase_doc_id",
  createdAt: Timestamp
}
```

### Memory Quiz Report Schema

```javascript
{
  score: 12,                     // 0-15
  date: Timestamp,
  createdAt: Timestamp
}
```

### Article Schema

```javascript
{
  title: "Article Title",
  content: "Full article content",
  author: "Dr. Smith",
  citation: "citation_doc_id",   // Optional reference
  image: "https://...",
  link: "https://...",
  source: "https://...",
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Citation Schema

```javascript
{
  title: "Research Paper Title",
  authors: "Smith, J., Doe, A.",
  journal: "Journal of Neuroscience",
  year: "2025",
  doi: "10.1234/example",
  url: "https://doi.org/...",
  source: "PubMed",
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

## 🔧 Configuration

The application uses a centralized configuration file (`config.js`):

### Firebase & Gemini

```javascript
firebase: { /* Firebase config from env vars */ },
gemini: { apiKey: process.env.GEMINI_API_KEY }
```

### Question Configuration

```javascript
questions: {
  maxQuestions_perDay: 7,
  number_of_immediate_questions: 4,
  number_of_recent_questions: 2,
  number_of_remote_questions: 1
}
```

### Firestore Collection Names

All Firestore collection and subcollection names are defined in `config.js` under `firestoreNames`:

| Key | Collection Name | Type |
|-----|----------------|------|
| `usersCollection` | `users` | Collection |
| `articlesCollection` | `Articles` | Collection |
| `citationsCollection` | `Citations` | Collection |
| `memoryQuizCollection` | `MemoryQuiz` | Collection |
| `questionsCollection` | `Questions` | Collection |
| `streaks_SubCollection` | `streaks` | Subcollection |
| `familyMembers_SubCollection` | `family_members` | Subcollection |
| `memoryCheckReports_SubCollection` | `memoryCheckReports` | Subcollection |
| `personalQuestions_SubCollection` | `questions` | Subcollection |
| `reminders_SubCollection` | `reminders` | Subcollection |
| `journalEntries_SubCollection` | `journal_entries` | Subcollection |
| `analyticsCache_SubCollection` | `analyticsCache` | Subcollection |

### Additional Config

```javascript
timezone: 'Asia/Kolkata',
analyticsCacheTTL: 300,  // seconds (default 5 minutes)
question_category: {
  immediate: 'immediateMemory',
  recent: 'recentMemory',
  remote: 'remoteMemory'
}
```

## Security Features

- Input validation using express-validator on all endpoints
- Firebase authentication integration
- Environment variable protection
- CORS support (configurable)
- Request size limiting (50MB max for base64 payloads)
- Error handling middleware
- Database connection verification on startup
- 404 handler for undefined routes

## 🚨 Error Handling

All endpoints follow a consistent error response format:

```json
{
  "error": "Error message",
  "message": "Detailed description"
}
```

HTTP Status Codes:

- `200`: Success
- `201`: Created
- `400`: Bad Request (validation errors)
- `404`: Not Found
- `409`: Conflict (duplicate resource)
- `500`: Internal Server Error

Development mode includes stack traces in error responses.

## Logging

The application uses Morgan for HTTP request logging in development mode:

```
GET /api/patient/abc123 200 45.123 ms
POST /api/auth/patientsignup 201 234.567 ms
```

## 🎓 Additional Information

### Memory Categories Explained

- **Immediate Memory**: Events from minutes to hours ago (e.g., "What did you eat for breakfast?")
- **Recent Memory**: Events from days to weeks ago (e.g., "Who visited you last week?")
- **Remote Memory**: Long-term memories from years ago (e.g., "Where did you grow up?")

### Streak Calculation Algorithm

The streak calculator tracks daily engagement and calculates:

1. **Current Streak**: Consecutive days from today going backward
2. **Max Streak**: Longest consecutive streak in history
3. **Active Days**: Total number of days with activity
4. **Last Activity**: Most recent engagement date

Gaps of more than 24 hours reset the current streak but are recorded for max streak calculation.

### Unique Patient ID Generation

- Format: 6 alphanumeric characters (A-Z, 0-9)
- Collision-resistant with retry mechanism
- Checked against existing IDs in Firestore
- Max 10 generation attempts before failure

---

**Version**: 2.0.0
**Last Updated**: February 26, 2026
**Maintainer**: Recap Development Team
