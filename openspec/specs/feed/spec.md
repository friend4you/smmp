## Purpose

Global chronological feed: real-time updates, pagination, offline cache, and author resolution for the smmp iOS app.

## Requirements

### Requirement: User can view a global chronological feed

The system SHALL display a scrollable list of posts from the global `posts` collection ordered by `createdAt` descending. The feed query SHALL NOT filter by follow graph in Phase 3 (Phase 4 will replace this with following-scoped feed).

#### Scenario: Feed loads on app open

- **WHEN** an authenticated user opens the Feed tab and the device is online
- **THEN** the system fetches posts from Firestore, displays them newest-first, and caches them in CoreData

#### Scenario: Empty feed

- **WHEN** no posts exist in Firestore
- **THEN** the system shows an empty-state message on the Feed screen

### Requirement: Feed supports pagination

The system SHALL load additional older posts when the user scrolls near the end of the list using cursor-based pagination.

#### Scenario: Load more posts

- **WHEN** the user scrolls to the bottom of the loaded feed and more posts exist
- **THEN** the system fetches the next page and appends posts without duplicates

### Requirement: Feed supports pull-to-refresh

The system SHALL allow the user to manually refresh the feed.

#### Scenario: Pull to refresh

- **WHEN** the user pulls down on the Feed screen while online
- **THEN** the system reloads the latest posts from Firestore and updates the list

### Requirement: Feed updates in real time

The system SHALL attach a Firestore snapshot listener on the feed query to receive new and updated posts while the Feed screen is active.

#### Scenario: New post appears while browsing

- **WHEN** another user creates a post while the current user is viewing the feed
- **THEN** the system receives the update via the listener and updates the cached feed data

#### Scenario: New posts banner while scrolled down

- **WHEN** new posts arrive via the listener and the user is not at the top of the feed
- **THEN** the system shows a "New posts" banner; tapping it scrolls to the top and reveals the new posts

### Requirement: Feed shows offline cached content

The system SHALL display previously cached posts from CoreData when the device has no network connectivity.

#### Scenario: Offline feed read

- **WHEN** the user opens the Feed tab while offline and cached posts exist
- **THEN** the system displays cached posts sorted by `createdAt` descending without calling Firestore

#### Scenario: Offline banner

- **WHEN** `NetworkMonitor` reports no connectivity
- **THEN** the Feed screen shows a visible offline banner at the top

### Requirement: Feed resolves post authors from user profiles

The system SHALL fetch author display data from `users/{authorId}` for each post and cache users in CoreData via `LocalRepository`.

#### Scenario: Author display on card

- **WHEN** a post card is rendered
- **THEN** the system shows the author's `displayName` and `photoURL` from the cached or fetched user document

#### Scenario: Author cache hit

- **WHEN** a post author's user document is already in CoreData
- **THEN** the system uses the cached user without a redundant Firestore read

### Requirement: Feed card navigates to post detail

The system SHALL navigate to `PostDetailScreen` when the user taps a post card.

#### Scenario: Tap post card

- **WHEN** the user taps a post card in the feed
- **THEN** the system pushes the Post Detail screen for that post
