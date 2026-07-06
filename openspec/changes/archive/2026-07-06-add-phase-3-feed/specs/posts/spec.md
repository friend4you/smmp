## ADDED Requirements

### Requirement: User can create a post with required text and optional image

The system SHALL allow an authenticated user to create a post with non-empty trimmed text (max 280 characters). An optional image MAY be attached from the photo library. Image-only posts (no text) SHALL NOT be allowed.

#### Scenario: Successful text-only post

- **WHEN** the user enters valid text with no image on the Create Post screen and submits while online
- **THEN** the system writes a `posts/{pid}` document with `authorId`, `text`, `imageURL` null, `likeCount` 0, `commentCount` 0, and `createdAt` server timestamp

#### Scenario: Successful text and image post

- **WHEN** the user enters valid text, selects an image from the photo library, and submits while online
- **THEN** the system resizes the image (max 1080px long edge, JPEG quality 0.8), uploads to `posts/{pid}/image.jpg` in Firebase Storage, writes the download URL to `imageURL`, and creates the Firestore post document

#### Scenario: Empty post rejected

- **WHEN** the user submits with empty or whitespace-only text
- **THEN** the system disables or rejects submission and does not write to Firestore or Storage

#### Scenario: Text over limit rejected

- **WHEN** the user enters more than 280 characters
- **THEN** the system prevents submission and shows validation feedback

#### Scenario: Upload progress shown

- **WHEN** the user submits a post with an image while online
- **THEN** the Create Post screen shows a linear upload progress indicator until upload completes or fails

#### Scenario: Upload failure does not create post

- **WHEN** image upload fails before the Firestore write
- **THEN** the system does not create a `posts/{pid}` document and shows a user-readable error

### Requirement: User can delete their own post

The system SHALL allow the post author to delete their post, including the Firebase Storage image (if any) and all documents in the `likes` and `comments` subcollections.

#### Scenario: Successful cascade delete

- **WHEN** the post author deletes their post
- **THEN** the system deletes the Storage object at `posts/{pid}/image.jpg` (if present), all `posts/{pid}/likes/*` documents, all `posts/{pid}/comments/*` documents, and the `posts/{pid}` document

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

Each post card in the feed SHALL show author avatar, display name, timestamp, post text, optional image when `imageURL` is present, like count, comment count, and a like toggle reflecting whether the current user has liked the post.

#### Scenario: Post card content

- **WHEN** a post is displayed in the feed
- **THEN** the card shows text, optional image via `AsyncImage`, relative or formatted timestamp, like count, comment count, and filled/unfilled like state for the current user

#### Scenario: Post detail shows larger image

- **WHEN** the user opens Post Detail for a post with an `imageURL`
- **THEN** the system displays the image larger than on the feed card, scaled to fit

### Requirement: Firestore documents map to Post model

The system SHALL map Firestore `posts/{pid}` documents to the `Post` Swift struct including `Timestamp` to `Date` conversion. Mapping logic MUST be covered by unit tests.

#### Scenario: Parse valid post document

- **WHEN** a Firestore document contains all required post fields
- **THEN** the mapper produces a `Post` with matching `id`, `authorId`, `text`, counts, and `createdAt`

#### Scenario: Parse post with null imageURL

- **WHEN** a Firestore document has null or missing `imageURL`
- **THEN** the mapper produces a `Post` with `imageURL` nil without crashing

### Requirement: Post repository supports offline read fallback

`PostRepository` SHALL write incoming Firestore snapshots to CoreData and serve cached posts when offline.

#### Scenario: Cache on snapshot

- **WHEN** a Firestore feed snapshot arrives while online
- **THEN** the repository upserts posts into `CDPost` with a `cachedAt` timestamp

#### Scenario: Offline fetch

- **WHEN** the repository is asked for the feed while offline
- **THEN** it returns posts from CoreData without opening a Firestore listener
