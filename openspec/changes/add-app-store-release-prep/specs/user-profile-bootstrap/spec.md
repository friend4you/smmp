## MODIFIED Requirements

### Requirement: Firestore user document is created on registration

The system SHALL create a Firestore document at `users/{uid}` via `ProfileRepository.createProfile` immediately after `AuthService.register(displayName:email:password:)` succeeds, before routing the user to the main app. Firebase Auth `displayName` is set inside `register`; no separate profile-update step precedes the Firestore write.

The document MUST include: `displayName`, `bio` (empty string), `photoURL` (null or empty string), `followerCount` (0), `followingCount` (0), and `createdAt`. The document MUST NOT include `email`. Email MAY be cached locally for the signed-in user from Firebase Auth only.

#### Scenario: Successful bootstrap

- **WHEN** `AuthService.register` succeeds
- **THEN** the system writes `users/{uid}` to Firestore with the registration display name and without an `email` field
- **AND** caches the user locally
- **AND** the user is routed to the main app

## REMOVED Requirements

### Requirement: Email is stored for future search

**Reason:** Public `users/{uid}` documents are readable by any authenticated user. Storing email there exposes other users' email addresses (App Store Guidelines 1.6 / 5.1.1). Search already matches `displayNameLower` only.

**Migration:** Stop writing `email` in `ProfileRepository.createProfile` / `firestoreWriteData`. Keep email on Firebase Auth. Optionally cache email on the current user's CoreData record from Auth at login/register. Do not query Firestore by email.
