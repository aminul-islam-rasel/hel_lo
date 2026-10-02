# Hel Lo - Firebase Setup Guide

Follow these steps to connect Hel Lo to your Firebase project:

1. **Create Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/).
   - Create a project named **Hel Lo**.

2. **Enable Services**:
   - **Authentication**: Enable Email/Password and Phone providers.
   - **Cloud Firestore**: Create database in production mode.
   - **Firebase Storage**: Set up storage bucket.
   - **Cloud Messaging (FCM)**: Enable for push notifications.

3. **Configure Platforms**:
   - Run FlutterFire CLI or download configuration files:
     - Android: Place `google-services.json` in `android/app/`.
     - iOS: Place `GoogleService-Info.plist` in `ios/Runner/`.

4. **Deploy Security Rules**:
   - Install Firebase CLI and deploy rules and indexes:
     ```bash
     firebase deploy --only firestore:rules,storage,firestore:indexes
     ```
