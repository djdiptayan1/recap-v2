<div align="center">

# RECAP: Every Memory Matters

### Compassionate Memory Care, Now with On-Device Intelligence

<p align="center">
  <em>Recap supports people living with dementia and their families through cognitive engagement, reminiscence, and safe AI assistance.</em>
</p>

<br/>

![Swift](https://img.shields.io/badge/Swift-5-orange)
![Node](https://img.shields.io/badge/Node.js-22+-green)
![Docker](https://img.shields.io/badge/Docker-Ready-blue)
![Firebase](https://img.shields.io/badge/Firebase-Cloud-yellow)
![AI](https://img.shields.io/badge/AI-Apple%20Foundation%20Models%20%2B%20Gemini-black)

<br/>

</div>

---

## What is Recap?

**Recap** is a dementia-care platform for:

- People living with Alzheimer's and related memory conditions
- Families and caregivers
- Daily cognitive, emotional, and routine support

It combines:

- Cognitive exercises and progress tracking
- Family collaboration and reminders
- Smriti AI companion with provider-aware routing

---

## What Is New: Foundation Models Integration

Recap now runs a **dual-provider AI system**:

- **Primary provider:** Apple Foundation Models (on-device), when available and ready
- **Fallback provider:** Existing Gemini path, when Foundation Models is unavailable, disabled, or not ready
- **No forced switching:** routing is automatic and state-aware

### Provider Behavior

- Supported + enabled + ready device: Foundation Models is used
- Supported but disabled/not-ready: user sees enable/preparing UI and can continue with fallback
- Unsupported device: Gemini is used automatically

### Availability UX

Smriti now explicitly communicates AI state:

- Apple Intelligence active
- Enable Apple Intelligence in Settings
- Apple Intelligence is preparing
- Apple Intelligence is not supported on this device

When Foundation Models is unavailable at runtime, fallback reason is shown without breaking chat continuity.

---

## Smriti AI: Capability Upgrades

### Structured Foundation Output

Foundation path now uses strongly typed structured generation (Generable-first contract), including:

- Core answer
- Warm memory-oriented follow-up prompt
- Optional care strategies when relevant
- Optional medical disclaimer only for medical-care guidance
- Optional supportive note in emotional contexts
- Optional source references for factual claims

### Streaming + Reliability

- Snapshot streaming support for structured UI updates
- Graceful retry/degrade path when stream generation fails
- Single active request per session is enforced to align with Foundation Models constraints

### Mode-Aware Prompting

Smriti preserves two behaviorally distinct modes:

- **Caregiver mode:** concise dementia-care guidance, emotional acknowledgement-first behavior
- **Reminiscence mode (memoryLane):** warm past-memory conversation and supportive prompts

Both modes preserve domain boundaries and always end successful turns with a warm follow-up.

---

## Tool Calling (Foundation Path)

Foundation Models tool calling is now integrated with live app data (API-backed tools), not static memory.

Current tool coverage includes:

- Family context
- Reminders read/create/edit/delete
- Daily question performance
- Streak statistics
- Journal summaries

Implementation principles:

- Tools call backend endpoints as source of truth
- Writes require explicit user confirmation/consent
- Invalid identity or authorization state throws typed tool errors
- Tool output is compact and model-facing

### Reminder Workflow Enhancements

- Full reminder CRUD tool support with backend-aligned contracts
- Category-aware field validation
- Follow-up questions when required details are missing
- Pull-to-refresh and force refresh support in reminders UI

---

## Identity, Authorization, and Safety

### Identity Resolution

Tool execution follows role-aware identifier resolution using existing app keys (`documentID`, `patientDocumentID`, `familyDocumentID`, `userType`) to avoid mixed patient/family context.

### Consent and Side Effects

- Side-effecting actions are consent-gated
- Destructive/high-impact actions require explicit confirmation
- Cancel path performs no side effects

### Safety Guardrails

- Off-topic and disallowed requests are declined
- Medical diagnosis/prescription is not provided
- Guardrail violations/refusals are mapped to user-safe responses
- Apple acceptable-use constraints are enforced in product behavior

---

## Architecture Summary

- **iOS:** SwiftUI + MVVM + FoundationModels framework integration
- **AI Router:** runtime provider selection and fallback handling
- **Engine:** prompt contracts, streaming/non-stream generation, tool orchestration
- **Tools:** modular Foundation tool set under `services/foundationModel/tools/`
- **Backend:** Express APIs for grounded reads/writes and server-side authorization hardening

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

Requires `.env` values for Firebase and Gemini fallback integration.

### Firebase Service Account Key

A service account key is required for Firebase Admin operations (example: account deletion in Firebase Auth).

1. Go to [Firebase Console](https://console.firebase.google.com) -> **Project Settings** -> **Service accounts**
2. Click **Generate new private key** and download the JSON
3. Save as `serviceAccountKey.json` inside `backend/`

Never commit this file to git.

### Quick Start (Docker)

```bash
# Generate base64 from your Firebase service account key
base64 -i backend/serviceAccountKey.json

# Run the container with encoded key and env file
docker run -d \
  --name recappp \
  --env-file recapEnv.env \
  -e FIREBASE_SERVICE_ACCOUNT="<paste_base64_string_here>" \
  -p 3000:3000 \
  djdiptayan/hackrecap-backend:latest
```

### Quick Start (Local)

```bash
cd backend
npm install
# Place serviceAccountKey.json in backend/
npm run dev
```

### Dev Auto-Restart

```bash
cd backend
chmod +x restart-recap.sh
./restart-recap.sh
```

---

## Apple Intelligence Enablement (User Flow)

If device support exists but Foundation Models is not enabled/ready:

1. Open Settings
2. Go to Apple Intelligence
3. Turn Apple Intelligence on
4. Return to Recap and tap Retry

Recap provides app settings navigation and an in-app enablement guide for this flow.

---

## Tech Stack

### Mobile (iOS)

- Swift 5
- SwiftUI
- MVVM
- FoundationModels framework (Apple on-device AI)

### Backend

- Node.js 22+
- Express 5
- Docker

### Cloud and Services

- Firebase Firestore
- Firebase Auth
- Cloudinary
- Gemini (fallback provider)

---

<div align="center">

### Built to preserve memories and strengthen families.

Open an issue, PR, or discussion to contribute.

</div>