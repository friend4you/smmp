## ADDED Requirements

### Requirement: Create post rejects filtered text

The system SHALL apply `ContentFiltering` to post text before upload or Firestore write. Denylisted text MUST be rejected with a user-readable error.

#### Scenario: Filtered post is not created

- **WHEN** the user submits post text that fails the content filter while online
- **THEN** the system does not upload an image or create a `posts/{pid}` document

### Requirement: User can report another author's post

The system SHALL offer Report on posts the current user did not author (post card menu and/or Post Detail). Submitting a report SHALL create a `reports` document as specified by `ugc-safety`.

#### Scenario: Report from Post Detail

- **WHEN** the user reports another author's post while online
- **THEN** a report document is created for that post id
- **AND** the post remains visible (report does not delete it)

## MODIFIED Requirements

### Requirement: User can create a post with required text and optional image

The system SHALL allow an authenticated user to create a post with non-empty trimmed text (max 280 characters). An optional image MAY be attached from the photo library. Image-only posts (no text) SHALL NOT be allowed.

#### Scenario: Successful text-only post

- **WHEN** the user enters valid text with no image on the Create Post screen and submits while online
- **THEN** the system writes a `posts/{pid}` document with `authorId`, `text`, `imageURL` null, `likeCount` 0, `commentCount` 0, and `createdAt` server timestamp

#### Scenario: Successful text and image post

- **WHEN** the user enters valid text, selects an image from the photo library, and submits while online
- **THEN** the system resizes the image (max 1080px long edge, JPEG quality 0.8), uploads to `posts/{authorId}/{pid}/image.jpg` in Firebase Storage, writes the download URL to `imageURL`, and creates the Firestore post document

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
- **THEN** the system deletes the Storage object at `posts/{authorId}/{pid}/image.jpg` (if present), all `posts/{pid}/likes/*` documents, all `posts/{pid}/comments/*` documents, and the `posts/{pid}` document

#### Scenario: Non-author cannot delete

- **WHEN** a user attempts to delete a post they did not author
- **THEN** the system does not delete the post (enforced by Firestore rules and repository guard)
