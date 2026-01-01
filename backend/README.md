# Recap Backend API

A Node.js/Express backend API for a memory care application designed to help Alzheimer's patients and their families manage daily cognitive exercises, track progress, and maintain health records.

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
- [Contributing](#contributing)

## Overview

Recap Backend is a RESTful API service that powers a memory care application for Alzheimer's patients. The system enables:

- Patient and family member registration and authentication
- Daily cognitive exercise questions tailored to memory types (immediate, recent, remote)
- Memory quiz assessments
- Activity streak tracking to encourage consistent engagement
- Educational articles and citations management
- Secure image storage via Cloudinary

## Features

### Authentication & User Management

- Patient signup with unique 6-character patient ID generation
- Family member registration and verification
- Profile management with image upload support
- UID-based authentication system

### Cognitive Assessment

- Daily question generation based on memory types:
  - **Immediate Memory**: 4 questions per day
  - **Recent Memory**: 2 questions per day
  - **Remote Memory**: 1 question per day
- Memory quiz with 15-point scoring system
- Question categorization and difficulty tracking
- Adaptive question selection

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
- Collaborative care management

## Tech Stack

- **Runtime**: Node.js (ES Modules)
- **Framework**: Express.js v5.1.0
- **Database**: Firebase Firestore & Realtime Database
- **File Storage**: Cloudinary
- **Validation**: express-validator v7.3.0
- **Logging**: Morgan
- **Environment**: dotenv

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- Firebase project with Firestore and Realtime Database enabled
- Cloudinary account for image storage

## Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
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
4. **Verify Firebase connection**
   The application automatically checks Firebase connectivity on startup.

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

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

## Project Structure

```
backend/
├── config.js                 # Application configuration
├── index.js                  # Application entry point
├── Dockerfile               # Docker configuration
├── package.json             # Dependencies and scripts
├── src/
│   ├── app.js              # Express app setup
│   ├── auth/               # Authentication controllers
│   │   ├── deleteAccount.controller.js
│   │   ├── familySignup.controller.js
│   │   ├── patientSignup.controller.js
│   │   ├── verifyFamilyMember.controller.js
│   │   └── verifyUID.controller.js
│   ├── controller/         # Business logic controllers
│   │   ├── articles.controler.js
│   │   ├── citations.controller.js
│   │   ├── family_member/
│   │   │   └── fetchFamily.controller.js
│   │   ├── memoryQuiz/
│   │   │   ├── getQuizQuestions.controller.js
│   │   │   └── submitQuiz.controller.js
│   │   ├── patient/
│   │   │   └── fetch.controller.js
│   │   ├── questions/
│   │   │   ├── fetch.controller.js
│   │   │   ├── getDailyQuestions.controller.js
│   │   │   └── admin/
│   │   │       ├── addQuestions.controller.js
│   │   │       └── editQuestions.controller.js
│   │   └── streaks/
│   │       ├── fetchStreak.controller.js
│   │       └── updateStreak.controller.js
│   ├── middleware/         # Custom middleware
│   │   └── dbCheck.js      # Firebase connection middleware
│   ├── models/             # Data models
│   │   ├── articles.model.js
│   │   ├── citations.model.js
│   │   ├── familyMember.model.js
│   │   ├── memoryQuiz.model.js
│   │   ├── patient.model.js
│   │   ├── questions.model.js
│   │   └── streaks.model.js
│   ├── routes/             # API route definitions
│   │   ├── index.js        # Main router
│   │   ├── articles.routes.js
│   │   ├── auth.route.js
│   │   ├── citations.routes.js
│   │   ├── familyMember.routes.js
│   │   ├── memoryQuiz.routes.js
│   │   ├── patient.routes.js
│   │   ├── questions.routes.js
│   │   └── streaks.routes.js
│   └── utils/              # Utility functions
│       ├── cloudinary.js   # Image upload/management
│       ├── db.js           # Firebase initialization
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

#### Get Family Members

```http
GET /api/familymembers/:documentId
```

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "email": "family@example.com",
      "name": "Jane Doe",
      "relation": "Daughter",
      "phone": "+1234567890",
      "profileImageURL": "https://..."
    }
  ]
}
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

A Dockerfile is included in the project root for containerized deployment.

### Build Docker Image

```bash
docker build -t recap-backend .
```

### Run Container

```bash
docker run -p 3000:3000 --env-file .env recap-backend
```

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
  correctAnswers: ["Option 1"],
  hint: "Optional hint",
  image: "https://...",
  audio: "https://...",
  priority: 1,
  hardness: "easy",
  confidence: 0.85,
  askInterval: 7,                // Days between asks
  timeFrame: "immediate",
  tag: "daily-routine",
  isActive: true,
  isAnswered: false,
  timesAsked: 0,
  timesAnsweredCorrectly: 0,
  lastAsked: Timestamp,
  lastAnsweredCorrectly: Timestamp,
  addedAt: Timestamp,
  createdAt: Timestamp
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

### Question Configuration

```javascript
questions: {
  maxQuestions_perDay: 7,
  number_of_immediate_questions: 4,
  number_of_recent_questions: 2,
  number_of_remote_questions: 1
}
```

### Collection Names

All Firestore collection names are defined in `config.js` under `firestoreNames`.

## Security Features

- Input validation using express-validator on all endpoints
- Firebase authentication integration
- Environment variable protection
- CORS support (configurable)
- Request size limiting (50MB max)
- Error handling middleware
- Database connection verification

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

**Version**: 1.0.0
**Last Updated**: January 1, 2026
**Maintainer**: Recap Development Team
