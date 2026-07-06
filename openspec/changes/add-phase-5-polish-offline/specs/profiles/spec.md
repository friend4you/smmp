## ADDED Requirements

### Requirement: Other-user profile shows partial offline state from navigation context

When the full user document is not cached in CoreData and the device is offline, the system SHALL display available fields from the navigation author stub (at minimum display name and photo URL when present) and cached posts for that user.

#### Scenario: Partial profile from feed navigation

- **WHEN** the user opens `UserProfileView` from a feed post author tap while offline and no `CDUser` exists
- **THEN** the system shows the feed author's display name and avatar from the navigation context

#### Scenario: Cached posts shown with partial profile

- **WHEN** the user opens an other-user profile offline with a stub and cached posts exist for that `authorId`
- **THEN** the system lists cached posts in the profile posts section

### Requirement: Profile screens show skeleton while loading

The system SHALL show redacted profile header and post placeholders during initial profile load when no content is yet displayed.

#### Scenario: Profile skeleton

- **WHEN** `ProfileView` or `UserProfileView` is loading with no profile data shown
- **THEN** the system displays skeleton placeholders until data or partial stub is available
