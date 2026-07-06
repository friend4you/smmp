## ADDED Requirements

### Requirement: Navigation uses coordinator–router–builder architecture

The app SHALL implement navigation using a hierarchy of coordinators, each owning a router and view builders. `AppCoordinator` SHALL be the root coordinator. Feature flows SHALL use dedicated child coordinators (Auth, Main, and per-tab coordinators). Routers SHALL manage navigation state; builders SHALL construct views and view models; views SHALL NOT embed ad-hoc `NavigationLink` destinations for flows owned by a coordinator.

#### Scenario: Coordinator hierarchy at runtime

- **WHEN** the app is running with an authenticated session
- **THEN** `AppCoordinator` owns `MainCoordinator`, which owns per-tab coordinators (Feed, Search, NewPost, Profile), each with its own router and route enum

#### Scenario: Unauthenticated session

- **WHEN** the app is running without an authenticated session
- **THEN** `AppCoordinator` owns `AuthCoordinator` with `AuthRouter` and auth view builders, and does not instantiate `MainCoordinator`

### Requirement: Routers expose push stack and modal presentation

Each flow router SHALL conform to a `Routing` protocol and store navigation state in a `NavigationPath` for push navigation. Routers SHALL additionally expose optional `sheet` and `fullScreenCover` route slots for modal presentation. Routers SHALL provide `push`, `pop`, `popToRoot`, sheet present/dismiss, fullScreenCover present/dismiss, and `reset` operations.

#### Scenario: Push and pop on stack

- **WHEN** a view model calls `onNavigate` with a push route and the builder wired it to `router.push`
- **THEN** the route is appended to the router's `NavigationPath` and the destination is shown in the coordinator's `NavigationStack`

#### Scenario: Pop to root

- **WHEN** `popToRoot()` is invoked on a router
- **THEN** the router's `NavigationPath` is cleared and the stack shows the root destination

#### Scenario: Sheet presentation

- **WHEN** a view model triggers navigation to a route presented as a sheet
- **THEN** the router sets its `sheet` route property and the coordinator presents the built view in a `.sheet`

#### Scenario: Reset on session end

- **WHEN** `reset()` is invoked on a router (e.g. during logout)
- **THEN** the router clears `NavigationPath`, dismisses any active sheet, and dismisses any active fullScreenCover

### Requirement: Each coordinator defines its own route enum

Each coordinator SHALL define a dedicated `Hashable` route enum conforming to an `AppRoute` protocol. Route enums SHALL NOT be shared globally across unrelated coordinators. Associated data required for destinations (e.g. post item, user id) SHALL be carried on route cases.

#### Scenario: Auth routes isolated from feed routes

- **WHEN** auth and feed flows are both implemented
- **THEN** `AuthRoute` and `FeedRoute` are separate enums, each used only by their respective coordinator and router

### Requirement: View builders construct view models and views with navigation closures

View builders SHALL receive a router (via `Routing` protocol) and dependencies. Each builder SHALL create the view model, passing an `onNavigate: (Route) -> Void` closure that forwards to the appropriate router method (`push`, `presentSheet`, etc.). Builders SHALL return the composed SwiftUI view for the requested route or root.

#### Scenario: Login navigates to register via closure

- **WHEN** the user taps Register on the login screen
- **THEN** `LoginViewModel` calls `onNavigate(.register)` and the auth router pushes or presents the registration destination without the view model holding a router reference

#### Scenario: Builder creates view model

- **WHEN** the auth coordinator builds the login screen
- **THEN** `AuthViewBuilder` instantiates `LoginViewModel` with repositories and `onNavigate`, and returns `LoginView(viewModel:)`

### Requirement: MainCoordinator owns tab selection

Tab selection SHALL be managed by `MainCoordinator` via `selectTab(_:)`, not stored in a tab router's `NavigationPath`. Each tab coordinator SHALL maintain its own independent navigation stack while the tab is part of an active session.

#### Scenario: Switch tabs preserves per-tab stacks

- **WHEN** the user switches from Feed to Profile and back to Feed during the same session
- **THEN** the feed coordinator's `NavigationPath` is preserved (unless explicitly reset)

#### Scenario: Post creation switches tab via coordinator

- **WHEN** post creation completes and the app navigates the user to the feed tab
- **THEN** `MainCoordinator.selectTab(.feed)` is used rather than a view-level `@Binding` on tab state

### Requirement: AppCoordinator owns session-driven flow transitions

`AppCoordinator` SHALL observe `SessionService` and render splash, auth, or main coordinator trees accordingly. On transition between authenticated and unauthenticated states, `AppCoordinator` SHALL recreate child coordinators (discard previous instances, fresh routers with empty paths).

#### Scenario: Successful login recreates main flow

- **WHEN** the user authenticates successfully
- **THEN** `AppCoordinator` discards `AuthCoordinator`, creates a new `MainCoordinator` with fresh tab coordinators, and shows the main app

#### Scenario: Logout recreates auth flow

- **WHEN** the user signs out
- **THEN** `AppCoordinator` resets and discards `MainCoordinator`, creates a new `AuthCoordinator`, and shows the login flow

#### Scenario: Splash during session resolution

- **WHEN** `SessionService.isResolvingSession` is true
- **THEN** `AppCoordinator` shows the splash screen and neither auth nor main coordinators

### Requirement: Navigation is in-tab only for initial release

Cross-tab navigation orchestration (e.g. opening Profile tab from Feed) SHALL NOT be implemented in this change. Destinations reachable from a tab SHALL be pushed or presented within that tab's coordinator stack or modals only.

#### Scenario: Post detail from feed stays in feed stack

- **WHEN** the user taps a post in the feed
- **THEN** post detail is pushed on the feed coordinator's router, not by switching tabs

### Requirement: Navigation protocols enable testing

The project SHALL define protocols for routes (`AppRoute`), routers (`Routing`), and coordinators (`Coordinating`). Unit tests SHALL be able to substitute mock routers to verify push, pop, and presentation behavior without SwiftUI hosting.

#### Scenario: Router push is unit testable

- **WHEN** a test calls `push` on a concrete router instance
- **THEN** the router's `NavigationPath` count increases by one and the test does not require a `NavigationStack` view hierarchy
