## ADDED Requirements

### Requirement: Following list does not cache offline

The system SHALL NOT persist the following list for offline browsing. When offline, `FollowingScreen` SHALL show the shared offline banner and an empty or placeholder state without unfollow actions.

#### Scenario: Following screen offline empty

- **WHEN** the user opens `FollowingScreen` while offline
- **THEN** the system shows the offline banner and no following rows
