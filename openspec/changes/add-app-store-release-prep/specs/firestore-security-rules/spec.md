## ADDED Requirements

### Requirement: Users can create reports about others' content

The system SHALL deploy Firestore rules for `reports/{reportId}` allowing an authenticated user to create a document only when `reporterId == request.auth.uid`. The creator MAY read their own reports. Clients MUST NOT update or delete reports. Unauthenticated access MUST be denied.

#### Scenario: Create own report

- **WHEN** an authenticated user creates `reports/{id}` with `reporterId` equal to their uid
- **THEN** Firestore rules allow the create

#### Scenario: Create report as another user denied

- **WHEN** a user creates a report with a different `reporterId`
- **THEN** Firestore rules deny the create

### Requirement: Users can manage their own blocked subcollection

The system SHALL deploy rules for `users/{userId}/blocked/{blockedId}` allowing the owner to create and delete their own blocked documents, and allowing any authenticated user to read blocked documents (so clients can filter feed, search, and comments).

#### Scenario: Block another user

- **WHEN** user A creates `users/A/blocked/B` where `A == request.auth.uid`
- **THEN** Firestore rules allow the create

#### Scenario: Write another user's blocked list denied

- **WHEN** user A attempts to create `users/B/blocked/C` where `B != request.auth.uid`
- **THEN** Firestore rules deny the write
