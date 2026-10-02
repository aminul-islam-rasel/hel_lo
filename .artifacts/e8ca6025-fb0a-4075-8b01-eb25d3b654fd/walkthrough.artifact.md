# Walkthrough - Device Contacts Syncing and Matching in Select Contact

## Changes Made

### Contacts Feature
- Added `flutter_contacts` dependency to [pubspec.yaml](file:///C:/Users/AMINUL/Desktop/hel_lo/pubspec.yaml).
- Updated [ContactsScreen](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/features/contacts/presentation/contacts_screen.dart) to:
  - Request device contacts permission on load.
  - Sync device contacts and extract/normalize phone numbers.
  - Filter registered Firestore users (`users` collection) so that only users whose phone numbers match a contact in the user's phone address book are displayed in the "Select Contact" list.
  - Added empty and permission denied states for smooth UX.

## Validation Results
- Verified compilation and static analysis with `flutter analyze`.
