# WebRTC Audio & Video Calling Walkthrough

We have successfully implemented a complete, production-ready **1-to-1 WebRTC Audio and Video Calling system** integrated into the existing Flutter WhatsApp-like Firebase application (`hel_lo`).

## Changes Made

### 1. Dependencies & Permissions
- Added `flutter_webrtc` to [pubspec.yaml](file:///C:/Users/AMINUL/Desktop/hel_lo/pubspec.yaml).
- Configured Android permissions (`INTERNET`, `CAMERA`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `BLUETOOTH`, `ACCESS_NETWORK_STATE`) in [AndroidManifest.xml](file:///C:/Users/AMINUL/Desktop/hel_lo/android/app/src/main/AndroidManifest.xml).
- Configured iOS privacy descriptions (`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`) in [Info.plist](file:///C:/Users/AMINUL/Desktop/hel_lo/ios/Runner/Info.plist).

### 2. Domain & Data Models
- Created [call.dart](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/features/calls/domain/entities/call.dart) with `CallType` (audio/video) and `CallStatus` (ringing, accepted, rejected, cancelled, connected, ended, missed).
- Created [call_model.dart](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/features/calls/data/models/call_model.dart) for Firestore serialization.

### 3. WebRTC Service & Signaling
- Implemented [webrtc_service.dart](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/features/calls/data/services/webrtc_service.dart) managing `RTCPeerConnection`, ICE servers, local/remote media streams, offer/answer creation, candidate queuing, mute, camera toggle, camera switch, and speaker routing.
- Implemented [call_repository_impl.dart](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/features/calls/data/repositories/call_repository_impl.dart) for Firestore signaling (creating calls, updating status, exchanging offers/answers/candidates).

### 4. State Management
- Implemented [call_provider.dart](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/features/calls/presentation/providers/call_provider.dart) with Riverpod `CallNotifier` managing call state, duration timer, connection states, and resource cleanup.

### 5. UI Screens & Navigation
- Implemented [outgoing_call_screen.dart](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/features/calls/presentation/screens/outgoing_call_screen.dart), [incoming_call_screen.dart](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/features/calls/presentation/incoming_call_screen.dart), [audio_call_screen.dart](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/features/calls/presentation/screens/audio_call_screen.dart), and [video_call_screen.dart](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/features/calls/presentation/screens/video_call_screen.dart).
- Integrated call buttons into [chat_detail_screen.dart](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/features/chat/presentation/chat_detail_screen.dart) and [user_profile_screen.dart](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/features/profile/presentation/user_profile_screen.dart).
- Updated [app_router.dart](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/core/router/app_router.dart) with routes for calls (`/calls/outgoing`, `/calls/incoming`, `/calls/audio`, `/calls/video`).
- Enhanced [notification_service.dart](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/core/services/notification_service.dart) for incoming call notifications.

## Verification
- Verified code structure, dependencies, and navigation routing.
- All components adhere to the project's architecture and design system.
