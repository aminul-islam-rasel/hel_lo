# Hel Lo - Security & Access Control

## Firestore Security Rules (`firestore.rules`)
- **Authentication Required**: All read/write operations require valid Firebase Authentication (`request.auth != null`).
- **User Profiles**: Users can read any user profile but can only write to their own user document (`request.auth.uid == userId`).
- **Conversations & Messages**: Users can only read and write conversations and messages if their UID is present in the conversation's `memberIds`.
- **Statuses**: Any authenticated user can read active statuses; only the status owner can create, update, or delete their statuses.

## Firebase Storage Rules (`storage.rules`)
- **User Media**: Profile photos and personal media are restricted to the owner (`request.auth.uid == userId`).
- **Chat Media**: Read and write access to chat attachments and voice notes is restricted to authenticated conversation members.
