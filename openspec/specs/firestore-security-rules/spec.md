## Purpose

Firestore security rules for Phase 3: users, posts, likes, comments, and count-field updates.

## Requirements

### Requirement: Authenticated users can read user profiles

The system SHALL deploy Firestore security rules allowing any authenticated user to read `users/{userId}` documents. Users MAY write only their own `users/{userId}` document.

#### Scenario: Read another user's profile

- **WHEN** an authenticated user reads `users/{otherUid}`
- **THEN** Firestore rules allow the read

#### Scenario: Write own profile only

- **WHEN** an authenticated user writes `users/{uid}` where `uid` matches their auth uid
- **THEN** Firestore rules allow the write

#### Scenario: Unauthenticated access denied

- **WHEN** an unauthenticated client attempts any read or write
- **THEN** Firestore rules deny the operation

### Requirement: Authenticated users can read all posts

The system SHALL deploy rules allowing authenticated users to read any document in the `posts` collection.

#### Scenario: Read global feed

- **WHEN** an authenticated user queries the `posts` collection
- **THEN** Firestore rules allow the read

### Requirement: Users can create posts as themselves

The system SHALL allow post creation only when `request.resource.data.authorId == request.auth.uid`.

#### Scenario: Create own post

- **WHEN** an authenticated user creates a post with `authorId` equal to their uid
- **THEN** Firestore rules allow the create

#### Scenario: Create post as another user denied

- **WHEN** a user creates a post with a different `authorId`
- **THEN** Firestore rules deny the create

### Requirement: Post authors can update and delete their posts

The system SHALL allow update and delete on `posts/{postId}` only when `resource.data.authorId == request.auth.uid`, except for count-field updates defined in a separate requirement.

#### Scenario: Author deletes post

- **WHEN** the post author deletes `posts/{postId}`
- **THEN** Firestore rules allow the delete

#### Scenario: Non-author delete denied

- **WHEN** a non-author attempts to delete a post
- **THEN** Firestore rules deny the delete

### Requirement: Users can manage their own likes

The system SHALL allow authenticated users to read all like documents and create/delete only `posts/{postId}/likes/{likeUserId}` where `likeUserId == request.auth.uid`.

#### Scenario: Like a post

- **WHEN** an authenticated user creates `posts/{postId}/likes/{theirUid}`
- **THEN** Firestore rules allow the write

#### Scenario: Unlike a post

- **WHEN** an authenticated user deletes their own like document
- **THEN** Firestore rules allow the delete

### Requirement: Count fields can be updated by authenticated users

The system SHALL allow authenticated users to update `likeCount` and `commentCount` on a post document when those are the only fields changed, enabling client-side batch count maintenance without Cloud Functions.

#### Scenario: Increment like count

- **WHEN** an authenticated user updates only `likeCount` on a post document
- **THEN** Firestore rules allow the update

#### Scenario: Increment comment count

- **WHEN** an authenticated user updates only `commentCount` on a post document
- **THEN** Firestore rules allow the update

#### Scenario: Update post text by non-author denied

- **WHEN** a non-author attempts to update `text` or other non-count fields on a post
- **THEN** Firestore rules deny the update

### Requirement: Users can manage their own comments

The system SHALL allow authenticated users to read all comments, create comments with `authorId == request.auth.uid`, and delete comments they authored.

#### Scenario: Add comment

- **WHEN** an authenticated user creates a comment with their uid as `authorId`
- **THEN** Firestore rules allow the create

#### Scenario: Delete own comment

- **WHEN** the comment author deletes their comment document
- **THEN** Firestore rules allow the delete

### Requirement: Rules are version-controlled in the repository

The project SHALL include a reference copy of the Phase 3 Firestore rules in the repository (e.g. `firebase/firestore.rules`) and document manual deployment to the Firebase console as an implementation task.

#### Scenario: Rules file in repo

- **WHEN** a developer clones the repository
- **THEN** they can find the intended Firestore rules in a tracked file matching the deployed rules
