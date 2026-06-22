## ADDED Requirements

### Requirement: User can create a text-only post

The system SHALL allow an authenticated user to create a post with text only (no image in this phase). Text MUST be non-empty after trimming and MUST NOT exceed 280 characters.

#### Scenario: Successful text post

- **WHEN** the user enters valid text on the Create Post screen and submits while online
- **THEN** the system writes a `posts/{pid}` document with `authorId`, `text`, `imageURL` null, `likeCount` 0, `commentCount` 0, and `createdAt` server timestamp

#### Scenario: Empty post rejected

- **WHEN** the user submits with empty or whitespace-only text
- **THEN** the system disables or rejects submission and does not write to Firestore

#### Scenario: Text over limit rejected

- **WHEN** the user enters more than 280 characters
- **THEN** the system prevents submission and shows validation feedback

### Requirement: User can delete their own post

The system SHALL allow the post author to delete their post, including all documents in the `likes` and `comments` subcollections.

#### Scenario: Successful cascade delete

- **WHEN** the post author deletes their post
- **THEN** the system deletes all `posts/{pid}/likes/*` documents, all `posts/{pid}/comments/*` documents, and the `posts/{pid}` document

#### Scenario: Non-author cannot delete

- **WHEN** a user attempts to delete a post they did not author
- **THEN** the system does not delete the post (enforced by Firestore rules and repository guard)

### Requirement: User can like and unlike a post

The system SHALL allow an authenticated user to like and unlike any post. Like state SHALL be stored in `posts/{pid}/likes/{uid}` and `likeCount` on the post document SHALL be updated atomically via batch write.

#### Scenario: Like a post

- **WHEN** the user taps like on a post they have not liked
- **THEN** the system creates `posts/{pid}/likes/{currentUid}` and increments `likeCount` on the post document in a single batch

#### Scenario: Unlike a post

- **WHEN** the user taps unlike on a post they have liked
- **THEN** the system deletes `posts/{pid}/likes/{currentUid}` and decrements `likeCount` on the post document in a single batch

#### Scenario: Optimistic like with rollback

- **WHEN** the user taps like and the Firestore batch fails
- **THEN** the system reverts the optimistic UI state and shows a user-readable error

### Requirement: Post card displays post content

Each post card in the feed SHALL show author avatar, display name, timestamp, post text, like count, comment count, and a like toggle reflecting whether the current user has liked the post.

#### Scenario: Post card content

- **WHEN** a post is displayed in the feed
- **THEN** the card shows text, relative or formatted timestamp, like count, comment count, and filled/unfilled like state for the current user

### Requirement: Firestore documents map to Post model

The system SHALL map Firestore `posts/{pid}` documents to the `Post` Swift struct including `Timestamp` to `Date` conversion. Mapping logic MUST be covered by unit tests.

#### Scenario: Parse valid post document

- **WHEN** a Firestore document contains all required post fields
- **THEN** the mapper produces a `Post` with matching `id`, `authorId`, `text`, counts, and `createdAt`

#### Scenario: Parse post with null text

- **WHEN** a Firestore document has null or missing `text` (image-only future case)
- **THEN** the mapper produces a `Post` with `text` nil without crashing

### Requirement: Post repository supports offline read fallback

`PostRepository` SHALL write incoming Firestore snapshots to CoreData and serve cached posts when offline.

#### Scenario: Cache on snapshot

- **WHEN** a Firestore feed snapshot arrives while online
- **THEN** the repository upserts posts into `CDPost` with a `cachedAt` timestamp

#### Scenario: Offline fetch

- **WHEN** the repository is asked for the feed while offline
- **THEN** it returns posts from CoreData without opening a Firestore listener
