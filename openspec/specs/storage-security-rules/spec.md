## Purpose

Firebase Storage security rules for Phase 3 post image upload and read access.

## Requirements

### Requirement: Authenticated users can read post images

The system SHALL deploy Firebase Storage security rules allowing any authenticated user to read objects under `posts/{postId}/`.

#### Scenario: Read post image

- **WHEN** an authenticated user requests a download URL for `posts/{postId}/image.jpg`
- **THEN** Storage rules allow the read

#### Scenario: Unauthenticated read denied

- **WHEN** an unauthenticated client attempts to read a post image
- **THEN** Storage rules deny the operation

### Requirement: Authenticated users can upload post images with constraints

The system SHALL allow authenticated users to write objects under `posts/{postId}/` when the file is an image and does not exceed a size cap (e.g. 5 MB).

#### Scenario: Upload image

- **WHEN** an authenticated user uploads an image to `posts/{postId}/image.jpg` within size and content-type limits
- **THEN** Storage rules allow the write

#### Scenario: Oversized upload denied

- **WHEN** a user attempts to upload a file larger than the configured size cap
- **THEN** Storage rules deny the write

### Requirement: Storage rules are version-controlled in the repository

The project SHALL include a reference copy of Phase 3 Storage rules in the repository (e.g. `firebase/storage.rules`) and document manual deployment to the Firebase console as an implementation task.

#### Scenario: Rules file in repo

- **WHEN** a developer clones the repository
- **THEN** they can find the intended Storage rules in a tracked file matching the deployed rules
