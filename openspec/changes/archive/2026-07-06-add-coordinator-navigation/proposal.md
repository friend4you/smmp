## Why

Navigation is scattered across the app: each tab owns its own `NavigationStack`, login uses ad-hoc `NavigationLink`s, tab switching is a raw `@Binding`, and there is no shared abstraction for push, pop, modals, or auth-to-main transitions. As flows grow (feed → post detail → profile, edit sheets, cross-feature navigation), this becomes hard to test, reason about, and extend. A coordinator + router + builder architecture centralizes navigation state and makes flows incremental to migrate.

## What Changes

- Introduce protocol layer: `AppRoute`, `Routing`, `Coordinating` (and per-flow conformances)
- Introduce generic `Router<Route>` with `NavigationPath`, `push` / `pop` / `popToRoot`, and separate `sheet` / `fullScreenCover` presentation slots
- Introduce `AppCoordinator` that observes `SessionService` and switches between splash, auth, and main flows (recreating child coordinators on auth transitions)
- Introduce `AuthCoordinator` + `AuthRouter` + `AuthViewBuilder` for login, registration, and forgot-password flows
- Introduce `MainCoordinator` with `selectTab(_:)` and per-tab coordinators: Feed, Search, NewPost, Profile
- Introduce per-tab routers, route enums, coordinators, and view builders; builders create ViewModels with `onNavigate: (Route) -> Void` closures wired to the router
- Replace `RootView` session routing and `ContentView` tab shell with coordinator-owned view trees
- Migrate existing screens incrementally: infrastructure → Auth → Feed → Search → NewPost → Profile
- Remove direct `NavigationLink` destination construction from views in migrated flows; navigation triggered via ViewModel `onNavigate`

## Capabilities

### New Capabilities

- `navigation`: Coordinator–router–builder navigation architecture, protocols, auth/main/tab flow ownership, modal presentation via router, and incremental migration of existing screens

### Modified Capabilities

<!-- Auth and session routing behavior stays the same at the product level; only the implementation layer changes. No delta specs required. -->

## Impact

- **New modules:** `Coordinators/`, `Routers/`, `Builders/`, route enums per flow
- **Protocols:** `AppRoute`, `Routing`, `Coordinating` (or equivalent names)
- **App entry:** `smmpApp.swift` / `RootView` wired through `AppCoordinator`
- **Views:** `LoginView`, `FeedView`, `ContentView`, `ProfileView`, and related screens refactored to receive navigation via builders/coordinators
- **ViewModels:** gain `onNavigate` closure parameter; remove direct navigation concerns
- **Tests:** router unit tests (push/pop/sheet), coordinator transition tests
- **Out of scope:** deep linking, path persistence across launches, cross-tab navigation orchestration
