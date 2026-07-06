## ADDED Requirements

### Requirement: User can view comments on post detail

The system SHALL load comments for a post when the Post Detail screen opens. Comments SHALL NOT use a real-time Firestore listener in Phase 3.

#### Scenario: Comments load on open

- **WHEN** the user navigates to Post Detail for a post
- **THEN** the system fetches `posts/{pid}/comments` ordered by `createdAt` ascending and displays them

#### Scenario: Pull to refresh comments

- **WHEN** the user pulls to refresh on the Post Detail screen while online
- **THEN** the system re-fetches comments from Firestore

### Requirement: User can add a comment

The system SHALL allow an authenticated user to add a text comment on a post. The comment MUST have non-empty trimmed text. `commentCount` on the post document SHALL be incremented in the same batch as the comment write.

#### Scenario: Successful comment

- **WHEN** the user submits a non-empty comment on Post Detail while online
- **THEN** the system creates `posts/{pid}/comments/{cid}` with `authorId`, `text`, and `createdAt`, and increments `commentCount` on the post document atomically

#### Scenario: Empty comment rejected

- **WHEN** the user submits an empty or whitespace-only comment
- **THEN** the system does not write to Firestore

### Requirement: User can delete their own comment

The system SHALL allow the comment author to delete their comment. `commentCount` on the post document SHALL be decremented in the same batch as the comment delete.

#### Scenario: Delete own comment

- **WHEN** the comment author deletes their comment
- **THEN** the system deletes `posts/{pid}/comments/{cid}` and decrements `commentCount` on the post document atomically

#### Scenario: Non-author cannot delete

- **WHEN** a user attempts to delete another user's comment
- **THEN** the system does not delete the comment (enforced by Firestore rules)

### Requirement: Comments resolve author display from user profiles

The system SHALL fetch comment author `displayName` and `photoURL` from `users/{authorId}` with CoreData caching, consistent with feed post author resolution.

#### Scenario: Comment author display

- **WHEN** a comment row is rendered on Post Detail
- **THEN** the system shows the comment author's display name from cached or fetched user data

### Requirement: Firestore documents map to Comment model

The system SHALL map Firestore `posts/{pid}/comments/{cid}` documents to the `Comment` Swift struct. Mapping logic MUST be covered by unit tests.

#### Scenario: Parse valid comment document

- **WHEN** a Firestore comment document contains required fields
- **THEN** the mapper produces a `Comment` with matching `id`, `postId`, `authorId`, `text`, and `createdAt`
