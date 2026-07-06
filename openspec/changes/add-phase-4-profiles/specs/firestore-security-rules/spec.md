## ADDED Requirements

### Requirement: Users can manage their own following subcollection

The system SHALL deploy Firestore security rules for `users/{userId}/following/{followedId}` allowing the owner to create and delete their own following documents, and allowing any authenticated user to read following documents.

#### Scenario: Create following document

- **WHEN** user A creates `users/A/following/B` where `A == request.auth.uid`
- **THEN** Firestore rules allow the create

#### Scenario: Delete own following document

- **WHEN** user A deletes `users/A/following/B`
- **THEN** Firestore rules allow the delete

#### Scenario: Read following for isFollowing check

- **WHEN** an authenticated user reads `users/{uid}/following/{fid}`
- **THEN** Firestore rules allow the read

#### Scenario: Write another user's following denied

- **WHEN** user A attempts to create `users/B/following/C` where `B != request.auth.uid`
- **THEN** Firestore rules deny the write

### Requirement: User follower and following counts can be updated by authenticated users

The system SHALL allow authenticated users to update `followerCount` and `followingCount` on a user document when those are the only fields changed, enabling client-side batch count maintenance without Cloud Functions.

#### Scenario: Increment follower count

- **WHEN** an authenticated user updates only `followerCount` on another user's document
- **THEN** Firestore rules allow the update

#### Scenario: Increment following count on own profile

- **WHEN** the owner updates only `followingCount` on their own user document
- **THEN** Firestore rules allow the update

#### Scenario: Update display name via count rule denied

- **WHEN** a non-owner attempts to update `displayName` on another user's document
- **THEN** Firestore rules deny the update
