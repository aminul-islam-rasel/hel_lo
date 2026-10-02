# Implement Device Contacts Syncing and Matching in Select Contact

## Overview
Currently, `ContactsScreen` displays all users registered in Firestore. We will update it to sync device contacts using `flutter_contacts`, normalize phone numbers, and filter Firestore users so that only registered users whose phone numbers exist in the user's local address book are shown.

## Proposed Changes

### [pubspec.yaml](file:///C:/Users/AMINUL/Desktop/hel_lo/pubspec.yaml)
- Add `flutter_contacts` dependency.

### [ContactsScreen](file:///C:/Users/AMINUL/Desktop/hel_lo/lib/features/contacts/presentation/contacts_screen.dart)
- Request contacts permission.
- Fetch device contacts on load.
- Normalize phone numbers (strip non-digit characters).
- Query Firestore `users` collection and filter users to only include those whose `phoneNumber` matches a device contact's phone number (excluding current user).
- Add UI states for permission denied, loading, and no matching contacts found.

## Verification Plan
- Build the app and open "Select Contact".
- Verify that permission prompt appears.
- Verify that only contacts whose phone numbers are registered in Firestore AND exist in device contacts are shown.
