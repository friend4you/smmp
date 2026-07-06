## MODIFIED Requirements

### Requirement: Feed shows offline cached content

The system SHALL display previously cached posts from CoreData when the device has no network connectivity.

#### Scenario: Offline feed read

- **WHEN** the user opens the Feed tab while offline and cached posts exist
- **THEN** the system displays cached posts sorted by `createdAt` descending without calling Firestore

#### Scenario: Offline banner

- **WHEN** `NetworkMonitor` reports no connectivity
- **THEN** the Feed screen shows the shared `OfflineBanner` at the top immediately, including on cold start offline

## ADDED Requirements

### Requirement: Feed disables like while offline

The system SHALL disable the like button on feed post cards when offline.

#### Scenario: Like button disabled offline

- **WHEN** the user views the feed while offline
- **THEN** like buttons are disabled and do not trigger repository writes

### Requirement: Feed shows skeleton while initial load is in progress

The system SHALL show redacted post card placeholders when the feed is loading and no posts are displayed yet.

#### Scenario: Initial feed skeleton

- **WHEN** the feed is loading for the first time with an empty `items` array
- **THEN** the system displays skeleton post card placeholders
