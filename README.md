# WhatsApp-Like Real-Time Messaging App (Flutter + Firebase)

A complete, production-ready, modern WhatsApp-like real-time messaging application built using **Flutter** and **Firebase**.

## Core Features
- **Authentication**: Secure phone number + password registration, sign-in, session persistence, and profile creation.
- **Real-Time Messaging**: Instant 1-to-1 messaging via Cloud Firestore with pagination and real-time streams.
- **Media Messaging**: Images, videos, documents, and voice message recording/playback via Firebase Storage.
- **Message Status & Indicators**: Sent, delivered, read indicators and real-time typing status.
- **User Discovery & Contacts**: Phone number and username search, contact synchronization.
- **Status / Stories**: 24-hour disappearing photo/video/text statuses with viewer tracking.
- **Calls Architecture**: Voice and video call history and navigation model.
- **Settings & Privacy**: Privacy controls, notification settings, dark/light theme support.
- **Security & Performance**: Strict Firestore & Storage security rules, Riverpod state management, GoRouter navigation.

---

## Firebase Setup Instructions

1. **Create a Firebase Project**:
   - Go to the [Firebase Console](https://console.firebase.google.com/).
   - Create a new project.
   - Enable **Authentication** (Email/Password & Phone providers).
   - Enable **Cloud Firestore** in production mode.
   - Enable **Firebase Storage**.
   - Enable **Cloud Messaging (FCM)**.

2. **Add Platforms**:
   - **Android**: Register your Android app with package name `com.example.hel_lo`. Download `google-services.json` and place it in `android/app/`.
   - **iOS**: Register your iOS app with bundle ID. Download `GoogleService-Info.plist` and place it in `ios/Runner/`.

3. **Deploy Security Rules & Indexes**:
   - Use Firebase CLI to deploy `firestore.rules`, `storage.rules`, and `firestore.indexes.json`:
     ```bash
     firebase deploy --only firestore:rules,storage,firestore:indexes
     ```

---

## Running the Application

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run code generation (if using riverpod generator):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. Run the app on connected device or emulator:
   ```bash
   flutter run
   ```
