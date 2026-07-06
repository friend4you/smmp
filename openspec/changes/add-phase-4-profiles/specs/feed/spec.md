## MODIFIED Requirements

### Requirement: User can view a global chronological feed

The system SHALL display a scrollable list of posts from the `posts` collection ordered by `createdAt` descending, filtered to posts whose `authorId` is the current user or a user the current user follows (up to 30 following IDs). The feed query SHALL NOT return posts from users outside the follow graph.

#### Scenario: Feed loads on app open

- **WHEN** an authenticated user opens the Feed tab and the device is online
- **THEN** the system loads following IDs, fetches posts where `authorId` is in (self + following), displays them newest-first, and caches them in CoreData

#### Scenario: Empty feed

- **WHEN** no posts exist from followed users or self
- **THEN** the system shows an empty-state message on the Feed screen

#### Scenario: Own posts always visible

- **WHEN** the user follows no one but has created posts
- **THEN** the feed shows the user's own posts

## ADDED Requirements

### Requirement: Feed author avatar navigates to user profile

The system SHALL push `UserProfileView` when the user taps the author avatar or display name on a feed post card.

#### Scenario: Tap other user avatar

- **WHEN** the user taps another author's avatar on a post card
- **THEN** the system pushes `UserProfileView(authorId)` on the feed coordinator stack

### Requirement: Offline feed respects follow graph cache

The system SHALL filter cached CoreData posts by the same follow graph (self + cached following IDs) when serving the offline feed.

#### Scenario: Offline follow-scoped feed

- **WHEN** the user opens the Feed tab while offline
- **THEN** the system displays cached posts whose `authorId` is self or in the locally known following set
