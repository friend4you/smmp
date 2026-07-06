## ADDED Requirements

### Requirement: Feed and Search routes include user profile

The system SHALL extend `FeedRoute` and `SearchRoute` with a `userProfile(userId: String)` case. Coordinators SHALL push `UserProfileView` within their tab stack when this route is navigated.

#### Scenario: Feed pushes user profile

- **WHEN** `FeedViewModel` calls `onNavigate(.userProfile(userId))`
- **THEN** the feed router pushes the route and `FeedViewBuilder` builds `UserProfileView`

#### Scenario: Search pushes user profile

- **WHEN** `SearchViewModel` calls `onNavigate(.userProfile(userId))`
- **THEN** the search router pushes the route and `SearchViewBuilder` builds `UserProfileView`

### Requirement: Profile route includes following list

The system SHALL extend `ProfileRoute` with a `following` case. The profile coordinator SHALL push `FollowingScreen` when the user taps the following count.

#### Scenario: Profile tab pushes following list

- **WHEN** the user taps following count on `ProfileView`
- **THEN** the profile router pushes `.following` and the builder returns `FollowingView`

### Requirement: Author avatar tap uses coordinator navigation

The system SHALL route author avatar taps in `PostCardView` and `CommentRowView` through view model `onNavigate` closures to the owning tab coordinator, not via inline `NavigationLink`.

#### Scenario: Post card author tap

- **WHEN** the user taps the author avatar on a feed post card
- **THEN** `FeedViewModel` receives the author id and calls `onNavigate(.userProfile(authorId))`

#### Scenario: Comment author tap

- **WHEN** the user taps the author avatar on a comment row in post detail
- **THEN** `PostDetailViewModel` calls `onNavigate(.userProfile(authorId))` on the feed coordinator stack
