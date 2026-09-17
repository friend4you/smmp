## MODIFIED Requirements

### Requirement: Authenticated users can read post images

The system SHALL deploy Firebase Storage security rules allowing any authenticated user to read objects under `posts/{authorId}/{postId}/`.

#### Scenario: Read post image

- **WHEN** an authenticated user requests a download URL for `posts/{authorId}/{postId}/image.jpg`
- **THEN** Storage rules allow the read

#### Scenario: Unauthenticated read denied

- **WHEN** an unauthenticated client attempts to read a post image
- **THEN** Storage rules deny the operation

### Requirement: Authenticated users can upload post images with constraints

The system SHALL allow an authenticated user to write objects under `posts/{authorId}/{postId}/` only when `authorId == request.auth.uid`, the file is an image, and it does not exceed the configured size cap (e.g. 5 MB).

#### Scenario: Upload own post image

- **WHEN** the authenticated user uploads an image to `posts/{theirUid}/{postId}/image.jpg` within size and content-type limits
- **THEN** Storage rules allow the write

#### Scenario: Upload another user's post image denied

- **WHEN** a user attempts to upload to `posts/{otherUid}/{postId}/image.jpg`
- **THEN** Storage rules deny the write

#### Scenario: Oversized upload denied

- **WHEN** a user attempts to upload a file larger than the configured size cap
- **THEN** Storage rules deny the write
