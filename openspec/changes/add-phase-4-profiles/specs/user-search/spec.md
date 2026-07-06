## ADDED Requirements

### Requirement: User can search for other users by display name

The system SHALL provide a Search tab with a debounced search bar that queries users by prefix match on `displayNameLower`. Search SHALL NOT query email or username fields.

#### Scenario: Search with valid query

- **WHEN** the user types at least 2 characters and the device is online
- **THEN** the system queries Firestore for users whose `displayNameLower` starts with the lowercased query and displays results with avatar and display name

#### Scenario: Debounced search

- **WHEN** the user types rapidly in the search field
- **THEN** the system waits approximately 300ms after the last keystroke before issuing a query

#### Scenario: Empty and no-results states

- **WHEN** the query is empty or no users match
- **THEN** the system shows an appropriate empty or no-results state

### Requirement: Search results support inline follow

The system SHALL show a Follow/Unfollow button on each search result row for users other than the current user.

#### Scenario: Follow from search results

- **WHEN** the user taps Follow on a search result while online
- **THEN** the system follows the user via `FollowRepository` and updates the button state

#### Scenario: Hide follow for self in results

- **WHEN** the current user appears in search results
- **THEN** the system does not show a Follow button for that row

### Requirement: Search result navigates to user profile

The system SHALL push `UserProfileView` when the user taps a search result row.

#### Scenario: Tap search result

- **WHEN** the user taps a user in search results
- **THEN** the system pushes `UserProfileView(userId)` on the search coordinator stack

### Requirement: Search is disabled offline

The system SHALL not issue Firestore search queries when the device is offline.

#### Scenario: Offline search

- **WHEN** the user is on the Search tab while offline
- **THEN** the system shows an offline indicator and does not query Firestore
