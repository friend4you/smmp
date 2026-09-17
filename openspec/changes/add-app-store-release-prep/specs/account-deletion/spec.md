## ADDED Requirements

### Requirement: User can delete their account from Profile

The system SHALL offer a Delete Account action in the Profile overflow menu, separate from Logout. The action MUST be easy to find. Delete Account MUST be disabled while offline.

#### Scenario: Delete Account is visible on Profile

- **WHEN** the user opens the Profile overflow menu
- **THEN** Delete Account is listed in addition to Logout

#### Scenario: Delete disabled offline

- **WHEN** the device is offline
- **THEN** Delete Account is disabled or shows an offline message and does not start deletion

### Requirement: Account deletion requires confirmation and password reauthentication

The system SHALL require a destructive confirmation, then the current password, and SHALL reauthenticate with Firebase email/password before deleting data or the Auth user.

#### Scenario: User cancels confirmation

- **WHEN** the user taps Delete Account and then cancels the confirmation
- **THEN** the system does not delete data or the Auth user

#### Scenario: Wrong password

- **WHEN** reauthentication fails
- **THEN** the system shows a user-readable error and does not delete data or the Auth user

### Requirement: Account deletion removes associated data then the Auth user

The system SHALL delete the user's associated data while the Auth session is still valid, then delete the Firebase Auth user, then clear the session and route to Login. Associated data MUST include: the user's posts (existing post cascade), remaining comments authored by the user, remaining likes by the user, following documents and follow-count maintenance, blocked-user documents, profile avatar in Storage, and the `users/{uid}` document. The Auth user MUST be deleted last. If a data step fails, the system MUST stop, keep the Auth user, and show an error so the user can retry.

#### Scenario: Successful deletion

- **WHEN** the user confirms deletion, reauthenticates, and all cascade steps succeed
- **THEN** the Auth user no longer exists
- **AND** the app routes to Login
- **AND** the user's posts, comments, likes, follows, blocks, avatar, and profile document are gone

#### Scenario: Cascade failure before Auth delete

- **WHEN** a Firestore or Storage delete fails before Auth deletion
- **THEN** the Auth user still exists
- **AND** the system shows a user-readable error
