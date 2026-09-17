## ADDED Requirements

### Requirement: Add comment rejects filtered text

The system SHALL apply `ContentFiltering` to comment text before the Firestore write. Denylisted text MUST be rejected with a user-readable error.

#### Scenario: Filtered comment is not created

- **WHEN** the user submits a comment that fails the content filter while online
- **THEN** the system does not create a comment document or change `commentCount`

### Requirement: User can report another author's comment

The system SHALL offer Report on comments the current user did not author. Submitting a report SHALL create a `reports` document with `targetType` comment, `targetId` the comment id, and `parentPostId` the post id.

#### Scenario: Report a comment

- **WHEN** the user reports another author's comment while online
- **THEN** a report document is created
- **AND** the comment remains visible
