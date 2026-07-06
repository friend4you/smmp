## ADDED Requirements

### Requirement: NetworkMonitor reports connectivity reliably on launch

The system SHALL initialize `NetworkMonitor.isConnected` from `NWPathMonitor.currentPath.status` synchronously in `init()` before the async path handler runs. The monitor SHALL continue updating `isConnected` on subsequent path changes.

#### Scenario: Cold start offline

- **WHEN** the app launches with no satisfied network path
- **THEN** `NetworkMonitor.isConnected` is `false` before any screen renders

#### Scenario: Connectivity transitions

- **WHEN** the network path changes from satisfied to unsatisfied or the reverse
- **THEN** `NetworkMonitor` updates `isConnected` and publishes the new value to subscribers

### Requirement: Connectivity changes are observable by ViewModels

The system SHALL expose a `connectivityPublisher` (or equivalent) on the network connectivity protocol so ViewModels can bind `@Published isOffline` and trigger SwiftUI updates on every screen that shows offline state.

#### Scenario: Post Detail banner updates on disconnect

- **WHEN** the user is viewing Post Detail and connectivity is lost
- **THEN** the offline banner appears and write controls disable without leaving the screen

### Requirement: Offline banner is a shared component

The system SHALL render offline state using a shared `OfflineBanner` component with consistent styling across Feed, Post Detail, Profile, Search, Following, Create Post, and Edit Profile screens.

#### Scenario: Consistent offline banner

- **WHEN** any supported screen is visible while offline
- **THEN** the system shows the shared `OfflineBanner` at the top of the screen content

### Requirement: Connectivity-required writes are disabled offline

The system SHALL prevent like, unlike, comment add/delete, post delete, follow/unfollow, post create, and profile save operations when offline. The UI SHALL disable or hide the corresponding controls. The system SHALL NOT apply optimistic UI updates for writes while offline.

#### Scenario: Like disabled on feed offline

- **WHEN** the user is on the Feed tab while offline
- **THEN** the like button is disabled and tapping it does not change like state or show a rollback error

#### Scenario: Like disabled on post detail offline

- **WHEN** the user views Post Detail while offline
- **THEN** the like button is disabled

#### Scenario: Delete post disabled offline

- **WHEN** the post author views Post Detail while offline
- **THEN** the delete post control is disabled

#### Scenario: Comment composer disabled offline

- **WHEN** the user views Post Detail while offline
- **THEN** the comment text field and submit control are disabled

### Requirement: Screens reload on reconnect

The system SHALL refresh cached screen data when connectivity transitions from offline to online for Feed, Profile, User Profile, and Post Detail (comments).

#### Scenario: Feed reloads on reconnect

- **WHEN** the Feed tab is active and connectivity is restored
- **THEN** the system re-attaches the Firestore feed listener and updates posts

#### Scenario: Profile reloads on reconnect

- **WHEN** a profile screen is visible and connectivity is restored
- **THEN** the system reloads profile and posts from Firestore

### Requirement: Other-user profile shows partial data offline when never cached

When `ProfileRepository.fetchUser` returns no cached user offline, the system SHALL display any available author stub passed from navigation context (display name, photo URL) and cached posts for that `authorId` from CoreData.

#### Scenario: Profile opened from feed author offline

- **WHEN** the user taps an author avatar on a feed post while offline and no `CDUser` exists for that author
- **THEN** the system shows the author's display name and photo from the feed item, lists cached posts for that author if any, and shows the offline banner

#### Scenario: No cached posts for uncached author

- **WHEN** the user opens an other-user profile offline with only a stub and no cached posts
- **THEN** the system shows the stub header fields and an empty posts state

### Requirement: Search offline shows requires-connection message

The system SHALL NOT cache or display search results offline. The Search tab SHALL show the offline banner and a message that search requires an internet connection.

#### Scenario: Search tab offline

- **WHEN** the user opens the Search tab while offline
- **THEN** the system shows the offline banner and a requires-connection message; no Firestore query runs

### Requirement: Following list offline shows empty state with banner

The system SHALL NOT cache the following list for offline display. When offline, `FollowingScreen` SHALL show the offline banner and an empty or placeholder state.

#### Scenario: Following screen offline

- **WHEN** the user opens Following while offline
- **THEN** the system shows the offline banner and does not display a following list
