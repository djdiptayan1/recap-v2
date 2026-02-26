<div align="center">

# RECAP: Every Memory Matters

### The Future of Compassionate Memory Care

<p align="center">
  <em>Empowering Alzheimer's patients and caregivers through cognitive engagement, reminiscence therapy, and AI-driven assistance.</em>
</p>

<br/>

![Swift](https://img.shields.io/badge/Swift-5-orange)
![Node](https://img.shields.io/badge/Node.js-18+-green)
![Docker](https://img.shields.io/badge/Docker-Ready-blue)
![Firebase](https://img.shields.io/badge/Firebase-Cloud-yellow)
![AI](https://img.shields.io/badge/AI-Google%20Gemini-purple)

<br/>

</div>

---

## What is Recap?

**Recap** is a holistic digital memory-care ecosystem designed for:

• Alzheimer’s & dementia patients
• Families & caregivers
• Cognitive monitoring & emotional connection

Combining **AI companionship**, **daily cognitive exercises**, and **family collaboration** into one intuitive platform.

---

## Core Features

<div align="center">


| Cognitive Engagement | Smriti AI Companion | Family Synergy |
| ----------------------- | ---------------------- | ------------------------- |
| Daily memory exercises  | Real-time AI support   | Shared dashboards         |
| Cognitive assessments   | Reminiscence therapy   | Custom memories           |
| Gamified streaks        | Context-aware recall   | Smart reminders           |

</div>

---

### Cognitive Engagement

* Personalized daily memory questions
* Periodic cognitive health quizzes
* Streak-based motivation system

### Smriti AI Care Companion

* Powered by Google Gemini
* Memory-lane reminiscence mode
* Secure patient context awareness

### Family Synergy

* Real-time health insights
* Upload photos, voices, stories
* Medication & routine coordination

---

## Screenshots

### Patient App

<p align="center">
<img src="https://res.cloudinary.com/dbtijt1zq/image/upload/v1772048140/ufke6lkpp4oxsnjswwr8.png" width="18%" />
<img src="https://res.cloudinary.com/dbtijt1zq/image/upload/v1772048148/r9h7ej4mm8gt3bedt2dq.png" width="18%" />
<img src="https://res.cloudinary.com/dbtijt1zq/image/upload/v1772048146/jl1oweylvh6wr0yo13bs.png" width="18%" />
<img src="https://res.cloudinary.com/dbtijt1zq/image/upload/v1772048144/ifcqlc4g1lrbc0kpimbq.png" width="18%" />
<img src="https://res.cloudinary.com/dbtijt1zq/image/upload/v1772048144/uv8wmtmbgdp2qe1ag7yi.png" width="18%" />
</p>

---

### Caregiver Portal

<p align="center">
<img src="https://res.cloudinary.com/dbtijt1zq/image/upload/v1772048142/nmexrxae9dg4k8ccrlb6.png" width="18%" />
<img src="https://res.cloudinary.com/dbtijt1zq/image/upload/v1772048148/sid4k7p89esbm7vwncab.png" width="18%" />
<img src="https://res.cloudinary.com/dbtijt1zq/image/upload/v1772048141/l0u2uo3moubir9dcqlma.png" width="18%" />
<img src="https://res.cloudinary.com/dbtijt1zq/image/upload/v1772048141/ywycbazxwenr5jtxfbr4.png" width="18%" />
<img src="https://res.cloudinary.com/dbtijt1zq/image/upload/v1772048146/v9dxlusltvxy4rjnuuoo.png" width="18%" />
</p>

<p align="center">
<img src="https://res.cloudinary.com/dbtijt1zq/image/upload/v1772048140/vg2syphpkskizu1acwaz.png" width="18%" />
<img src="https://res.cloudinary.com/dbtijt1zq/image/upload/v1772048141/uqr02nylkp6ugcxrx27d.png" width="18%" />
</p>

---

## Backend Setup

> Requires `.env` file with Firebase + Gemini credentials

### 🔐 Firebase Service Account Key

A **service account key** is required for Firebase Admin operations (e.g., account deletion from Firebase Auth).

1. Go to [Firebase Console](https://console.firebase.google.com) → **Project Settings** → **Service accounts**
2. Click **"Generate new private key"** → Download the JSON file
3. Save it as `serviceAccountKey.json` in the `backend/` directory

> ⚠️ **Never commit this file to git.** It is already in `.gitignore`.

### ▶ Quick Start (Docker)

```bash
# Generate the base64 string from your service account key
base64 -i backend/serviceAccountKey.json

# Run the container with the base64-encoded key
docker run -d \
  --name recappp \
  --env-file recapEnv.env \
  -e FIREBASE_SERVICE_ACCOUNT="<paste_base64_string_here>" \
  -p 3000:3000 \
  djdiptayan/hackrecap-backend:latest
```

### ▶ Quick Start (Local)

```bash
cd backend
npm install
# Place your serviceAccountKey.json in the backend/ directory
npm run dev
```

### 🔁 Dev Auto-Restart

```bash
cd backend
chmod +x restart-recap.sh
./restart-recap.sh
```

---

## Tech Stack

### 📱 Mobile (iOS)

* Swift 5
* SwiftUI
* MVVM Architecture

### Backend

* Node.js 22+
* Express 5
* Docker

### Cloud & AI

* Firebase Firestore
* Firebase Auth
* Cloudinary
* Google Gemini 3 

---

<div align="center">

### Built to preserve memories and strengthen families.

*Open an issue, PR, or discussion — contributions welcome.*

</div>