## MODIFIED Requirements

### Requirement: Search is disabled offline

The system SHALL not issue Firestore search queries when the device is offline. The Search tab SHALL show the shared offline banner and a message that search requires an internet connection. The system SHALL NOT display cached search results.

#### Scenario: Offline search

- **WHEN** the user is on the Search tab while offline
- **THEN** the system shows the offline banner and a requires-connection message; no Firestore query runs

## ADDED Requirements

### Requirement: Search shows skeleton during in-flight query

The system SHALL display redacted result row placeholders while a search query is loading and no results are yet shown.

#### Scenario: Search loading skeleton

- **WHEN** the user submits a valid search query and results have not arrived
- **THEN** the system shows skeleton search result rows
