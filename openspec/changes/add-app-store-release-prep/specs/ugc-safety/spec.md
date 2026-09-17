## ADDED Requirements

### Requirement: User-generated text is filtered for objectionable material

The system SHALL run a client-side `ContentFiltering` check (bundled case-insensitive word-boundary denylist) before accepting display name, bio, post text, or comment text. Images SHALL NOT be scanned. A failing check MUST block the write and show a localized error.

#### Scenario: Post text contains a denylisted term

- **WHEN** the user submits a post whose trimmed text matches the denylist
- **THEN** the system does not write to Firestore or Storage
- **AND** shows a user-readable filter error

#### Scenario: Clean text is allowed

- **WHEN** the user submits post or comment text that does not match the denylist
- **THEN** the filter does not block the write

### Requirement: User can report a post, comment, or profile

The system SHALL allow an authenticated user to report another user's post, comment, or profile. The report MUST include a reason (`spam`, `harassment`, `hateSpeech`, `sexualContent`, or `other`). The system SHALL write `reports/{reportId}` with `reporterId` equal to the current uid, `targetType`, `targetId`, optional `parentPostId` for comments, `reason`, and `createdAt`. A user MUST NOT report their own content. Report is disabled offline.

#### Scenario: Report another user's post

- **WHEN** the user chooses Report on a post they did not author, picks a reason, and submits while online
- **THEN** the system creates a `reports` document for that post
- **AND** shows a confirmation that the report was sent

#### Scenario: Cannot report own profile

- **WHEN** the user views their own profile
- **THEN** Report is not offered

### Requirement: User can block and unblock another user

The system SHALL persist blocks at `users/{currentUid}/blocked/{blockedUid}`. The blocker MUST NOT see the blocked user's posts in the feed or profile post lists, comments on post detail, or rows in search. Opening a blocked user's profile SHALL show a blocked state and Unblock. A user MUST NOT block themselves. Block and unblock require connectivity.

#### Scenario: Block hides the user's posts

- **WHEN** the current user blocks user B
- **THEN** the system writes `users/{currentUid}/blocked/B`
- **AND** posts authored by B no longer appear in the current user's feed

#### Scenario: Unblock restores visibility

- **WHEN** the current user unblocks user B
- **THEN** the blocked document is deleted
- **AND** B's content is eligible to appear again

### Requirement: User can contact the developer from the app

The system SHALL provide a Contact action (Profile menu) that opens a mail composer or `mailto:` URL using `LegalConfiguration.supportEmail`.

#### Scenario: Contact from Profile

- **WHEN** the user taps Contact in the Profile menu
- **THEN** the system opens a mail message addressed to the configured support email
