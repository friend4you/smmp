## MODIFIED Requirements

### Requirement: User can add a comment

The system SHALL allow an authenticated user to add a text comment on a post while online. The comment MUST have non-empty trimmed text. `commentCount` on the post document SHALL be incremented in the same batch as the comment write. Comment submission SHALL be disabled when offline.

#### Scenario: Successful comment

- **WHEN** the user submits a non-empty comment on Post Detail while online
- **THEN** the system creates `posts/{pid}/comments/{cid}` with `authorId`, `text`, and `createdAt`, and increments `commentCount` on the post document atomically

#### Scenario: Empty comment rejected

- **WHEN** the user submits an empty or whitespace-only comment
- **THEN** the system does not write to Firestore

#### Scenario: Comment disabled offline

- **WHEN** the user views Post Detail while offline
- **THEN** the comment composer and submit control are disabled

### Requirement: User can delete their own comment

The system SHALL allow the comment author to delete their comment while online. `commentCount` on the post document SHALL be decremented in the same batch as the comment delete. Comment delete SHALL be disabled when offline.

#### Scenario: Delete own comment

- **WHEN** the comment author deletes their comment while online
- **THEN** the system deletes `posts/{pid}/comments/{cid}` and decrements `commentCount` on the post document atomically

#### Scenario: Non-author cannot delete

- **WHEN** a user attempts to delete another user's comment
- **THEN** the system does not delete the comment (enforced by Firestore rules)

#### Scenario: Delete comment disabled offline

- **WHEN** the user views Post Detail while offline
- **THEN** delete actions on comments are not available or are disabled
