## ADDED Requirements

### Requirement: Firestore user document is created on registration

The system SHALL create a Firestore document at `users/{uid}` immediately after a successful Firebase Auth registration, before routing the user to the main app.

The document MUST include: `displayName`, `bio` (empty string), `photoURL` (null), `followerCount` (0), `followingCount` (0), `email`, and `createdAt`.

#### Scenario: Successful bootstrap

- **WHEN** Firebase Auth registration succeeds
- **THEN** the system writes `users/{uid}` to Firestore with the registration display name and email
- **AND** the user is routed to the main app

### Requirement: Auth user is deleted if Firestore bootstrap fails

The system SHALL roll back the Firebase Auth account if the Firestore user document write fails, so no orphaned Auth accounts exist without a profile document.

#### Scenario: Firestore write failure

- **WHEN** Firebase Auth registration succeeds but the Firestore write fails
- **THEN** the system deletes the newly created Firebase Auth user
- **AND** shows a user-readable error to the registrant
- **AND** the user remains on the Register screen

### Requirement: Email is stored for future search

The system SHALL persist the user's email on the Firestore user document. Email is unique (enforced by Firebase Auth). Phase 4 search will query by display name and email; no separate username field is required.

#### Scenario: Email stored at registration

- **WHEN** a user registers with email `user@example.com`
- **THEN** the Firestore `users/{uid}` document includes `email: "user@example.com"`
