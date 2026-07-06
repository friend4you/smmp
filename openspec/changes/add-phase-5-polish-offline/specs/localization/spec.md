## ADDED Requirements

### Requirement: Offline and polish strings are localized

The system SHALL add semantic localization keys for Phase 5 offline and polish copy, including at minimum: search requires-connection message, following list offline placeholder (if distinct from existing follow list offline key), and any new shared offline banner text if `feedOfflineBanner` is generalized.

#### Scenario: Search offline message

- **WHEN** the Search tab is shown while offline
- **THEN** the requires-connection message uses a catalog key such as `search.offline.requiresConnection`

#### Scenario: Offline banner key

- **WHEN** any screen shows the shared offline banner
- **THEN** the banner text uses a catalog key (existing `feedOfflineBanner` or a shared `common.offline.banner`)
