# Hel Lo Messaging App - Architecture Guide

**Hel Lo** is structured following **Clean Architecture** and a **Feature-First modular approach**, combined with **Riverpod** for reactive state management and **GoRouter** for robust declarative navigation.

## Folder Structure

```
lib/
├── core/
│   ├── constants/
│   ├── router/          # GoRouter configuration & route guards
│   ├── services/        # Connectivity, notifications, permissions
│   ├── theme/           # AppColors, AppTheme, AppTextStyles
│   └── utils/           # Conversation ID & formatting utilities
└── features/
    ├── auth/            # Authentication & session management
    ├── chat/            # Real-time messaging, media, chat list & details
    ├── contacts/        # User discovery & contact sync
    ├── status/          # 24h status stories
    ├── calls/           # Call history & architecture
    ├── settings/        # Privacy, security, notifications, storage
    └── search/          # Chat & message search
```

## Architectural Principles
1. **Separation of Concerns**: UI components (Widgets/Screens) do not contain business logic. Data access is encapsulated within repositories and data sources.
2. **Reactive State (Riverpod)**: Uses `StreamProvider`, `Notifier`, and `AsyncNotifier` to cleanly expose state reactively.
3. **Declarative Navigation (GoRouter)**: Centralized routing with authentication state observation.
```json
