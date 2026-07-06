## ADDED Requirements

### Requirement: Feed and profile screens show skeleton placeholders while loading

The system SHALL display skeleton placeholder content using SwiftUI `.redacted(reason: .placeholder)` while initial data is loading and no content is yet available.

#### Scenario: Feed skeleton on first load

- **WHEN** the Feed tab is loading and `items` is empty
- **THEN** the system shows redacted post card placeholders instead of a bare spinner

#### Scenario: Profile skeleton on first load

- **WHEN** a profile screen is loading and profile data is not yet available
- **THEN** the system shows a redacted profile header and post row placeholders

#### Scenario: Search skeleton during query

- **WHEN** a search query is in flight and prior results are cleared
- **THEN** the system shows redacted search result row placeholders

### Requirement: Like button animates on toggle

The system SHALL animate the heart icon when the user likes or unlikes a post using a spring scale animation (`withAnimation`).

#### Scenario: Like animation on feed

- **WHEN** the user likes a post on the feed while online
- **THEN** the heart icon scales with a brief bounce and changes to filled red

#### Scenario: Unlike animation

- **WHEN** the user unlikes a post while online
- **THEN** the heart icon animates back to outline style

### Requirement: Haptic feedback on key actions

The system SHALL provide haptic feedback for like, follow/unfollow, and successful post submission via a `HapticService` injected through `AppDependencies`.

#### Scenario: Like haptic

- **WHEN** the user successfully toggles like while online
- **THEN** the system triggers a light impact haptic

#### Scenario: Follow haptic

- **WHEN** the user successfully follows or unfollows while online
- **THEN** the system triggers a medium impact haptic

#### Scenario: Post submit haptic

- **WHEN** the user successfully creates a post
- **THEN** the system triggers a success notification haptic

### Requirement: Splash screen animates logo on launch

The system SHALL animate the splash logo with a simple fade-in and scale-up on appear before routing to auth or the main app.

#### Scenario: Splash logo animation

- **WHEN** the splash screen appears during session resolution
- **THEN** the logo fades in and scales to full size with a short animation
