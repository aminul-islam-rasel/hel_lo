# Hel Lo - Firestore Database Structure

## Collections

### 1. `users/{uid}`
Stores user profile and status information.
- `uid` (String): Unique Firebase Auth user ID.
- `phoneNumber` (String): Normalized phone number (primary identifier).
- `displayName` (String): User's full name.
- `username` (String): Unique username handle.
- `profilePhoto` (String?): URL to profile photo in Firebase Storage.
- `about` (String): Bio / status text.
- `status` (String): Availability status (e.g. "Available").
- `createdAt` (Timestamp): Account creation timestamp.
- `lastSeen` (Timestamp): Last active timestamp.
- `isOnline` (Boolean): Real-time presence flag.
- `isVerified` (Boolean): Verification badge flag.
- `pushToken` (String?): FCM registration token.
- `privacySettings` (Map): Privacy configurations (profile photo, last seen, read receipts).
- `notificationSettings` (Map): Push notification preferences.

### 2. `conversations/{conversationId}`
Stores conversation metadata. `conversationId` is deterministically generated from sorted member UIDs (`conv_uid1_uid2`).
- `memberIds` (Array of Strings): [uid1, uid2].
- `lastMessage` (String): Preview of the latest message.
- `lastMessageTime` (Timestamp): Timestamp of the latest message.
- `updatedAt` (Timestamp): Last modification timestamp.

#### Subcollection: `conversations/{conversationId}/messages/{messageId}`
Stores individual chat messages.
- `messageId` (String): Unique message ID.
- `senderId` (String): UID of the sender.
- `type` (String): Message type ('text', 'image', 'video', 'document', 'audio').
- `text` (String): Message content or caption.
- `mediaUrl` (String?): URL to media in Firebase Storage.
- `createdAt` (Timestamp): Server timestamp when message was created.
- `isDeleted` (Boolean): Soft deletion flag.
- `isEdited` (Boolean): Edit flag.
- `readBy` (Array of Strings): UIDs of users who read the message.
- `deliveredTo` (Array of Strings): UIDs of users who received the message.

### 3. `statuses/{statusId}`
Stores 24-hour status stories.
- `statusId` (String): Unique status ID.
- `userId` (String): Author's UID.
- `type` (String): 'text', 'image', 'video'.
- `content` (String): Text content or media URL.
- `createdAt` (Timestamp): Creation timestamp.
- `expiresAt` (Timestamp): Expiration timestamp (+24 hours).
- `viewers` (Array of Strings): UIDs of users who viewed the status.

### 4. `calls/{callId}`
Stores voice/video call history logs.
