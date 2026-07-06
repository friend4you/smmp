## ADDED Requirements

### Requirement: Authenticated users can read profile avatars

The system SHALL deploy Firebase Storage security rules allowing any authenticated user to read objects under `users/{userId}/`.

#### Scenario: Read profile avatar

- **WHEN** an authenticated user requests a download URL for `users/{userId}/avatar.jpg`
- **THEN** Storage rules allow the read

### Requirement: Users can upload their own profile avatar with constraints

The system SHALL allow an authenticated user to write objects under `users/{userId}/` only when `userId == request.auth.uid`, the file is an image, and it does not exceed the configured size cap (e.g. 5 MB).

#### Scenario: Upload own avatar

- **WHEN** the authenticated user uploads an image to `users/{theirUid}/avatar.jpg` within size and content-type limits
- **THEN** Storage rules allow the write

#### Scenario: Upload another user's avatar denied

- **WHEN** a user attempts to upload to `users/{otherUid}/avatar.jpg`
- **THEN** Storage rules deny the write
