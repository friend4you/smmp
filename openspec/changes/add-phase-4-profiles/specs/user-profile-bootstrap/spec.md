## MODIFIED Requirements

### Requirement: Firestore user document is created on registration

The system SHALL create a Firestore document at `users/{uid}` via `ProfileRepository.createProfile` immediately after `AuthService.register(displayName:email:password:)` succeeds, before routing the user to the main app. Firebase Auth `displayName` is set inside `register`; no separate profile-update step precedes the Firestore write.

The document MUST include: `displayName`, `displayNameLower` (lowercased `displayName`), `bio` (empty string), `photoURL` (null or empty string), `followerCount` (0), `followingCount` (0), `email`, and `createdAt`.

#### Scenario: Successful bootstrap

- **WHEN** `AuthService.register` succeeds
- **THEN** `AuthRepository` calls `ProfileRepository.createProfile` to write `users/{uid}` with display name, `displayNameLower`, and email
- **AND** caches the user locally including `email`
- **AND** the user is routed to the main app

### Requirement: Email is stored for future search

The system SHALL persist the user's email on the Firestore user document. Email is unique (enforced by Firebase Auth). User search in Phase 4 queries by display name prefix on `displayNameLower` only; email is stored for account identity, not search.

#### Scenario: Email stored at registration

- **WHEN** a user registers with email `user@example.com`
- **THEN** the Firestore `users/{uid}` document includes `email: "user@example.com"`
