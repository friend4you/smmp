## Context

The smmp iOS app uses SwiftUI with MVVM + Repository pattern and `AppDependencies` for DI. Navigation today is decentralized:

- `RootView` gates splash / login / main via `SessionService`
- `ContentView` owns a `TabView` with `@State selectedTab`
- Each tab embeds its own `NavigationStack` (`FeedView`, `SearchView`, `NewPostView`, `ProfileView`)
- Login uses inline `NavigationLink` destinations for Register and Forgot Password
- Feed uses typed `NavigationLink(value:)` + `navigationDestination` for post detail
- Tab switching after post creation uses a `@Binding` passed into `NewPostView`

There is no shared navigation API, no testable routing layer, and no single owner for auth ↔ main transitions. Phase 3 feed flows are in place; this change introduces a coordinator–router–builder architecture and migrates screens incrementally.

Stack constraints: SwiftUI, `ObservableObject` / `@MainActor` ViewModels, existing `SessionService` and `AppDependencies`.

## Goals / Non-Goals

**Goals:**

- Centralize navigation in coordinators with typed per-flow route enums
- Provide a reusable `Router<Route>` with `NavigationPath`, push/pop/popToRoot, and separate sheet/fullScreenCover slots
- Wire ViewModels via `onNavigate: (Route) -> Void` closures created in builders (no router reference inside ViewModels)
- `AppCoordinator` owns splash / auth / main lifecycle; recreate child coordinators on auth transitions
- `MainCoordinator` owns tab selection via `selectTab(_:)` and per-tab child coordinators
- Per-tab navigation stays within the tab stack (no cross-tab orchestration in v1)
- Incremental migration: infrastructure → Auth → Feed → Search → NewPost → Profile
- Protocols for routes, routers, and coordinators to enable unit testing

**Non-Goals:**

- Deep linking / universal links
- Path persistence across app launches (state restoration)
- Cross-tab navigation (e.g. feed avatar → profile tab)
- Replacing `SessionService` or auth product behavior
- UIKit coordinators or custom transition animations

## Decisions

### 1. Coordinator hierarchy (App → Auth/Main → per-tab)

**Decision:**

```
AppCoordinator
├── splash (inline, not AuthCoordinator)
├── AuthCoordinator + AuthRouter + AuthViewBuilder
└── MainCoordinator
    ├── selectedTab: Tab
    ├── FeedCoordinator + FeedRouter + FeedViewBuilder
    ├── SearchCoordinator + ...
    ├── NewPostCoordinator + ...
    └── ProfileCoordinator + ...
```

**Rationale:** Matches feature boundaries; each tab preserves its own navigation stack while session and tab selection live higher up.

**Alternative considered:** Single `MainCoordinator` owning all routes. Rejected — route enums and stacks would grow unbounded.

### 2. Per-coordinator route enums (not global)

**Decision:** Each coordinator defines its own `Hashable` route enum (e.g. `AuthRoute`, `FeedRoute`, `ProfileRoute`).

**Rationale:** Type-safe destinations, isolated migration, smaller API surface per flow.

**Alternative considered:** One `AppRoute` enum. Rejected per exploration — poor separation and coupling across tabs.

### 3. Generic `Router<Route>` with protocol `Routing`

**Decision:** Shared concrete `Router<Route: AppRoute>` class implementing:

| API | Behavior |
|-----|----------|
| `path: NavigationPath` | Push stack binding for `NavigationStack` |
| `push(_ route: Route)` | Append to path |
| `pop()` | Remove last path element |
| `popToRoot()` | Clear path only |
| `sheet: Route?` | Modal sheet presentation |
| `fullScreenCover: Route?` | Full-screen modal |
| `presentSheet(_:)` / `dismissSheet()` | Sheet lifecycle |
| `presentFullScreenCover(_:)` / `dismissFullScreenCover()` | Cover lifecycle |
| `reset()` | Clear path + dismiss all modals (used on logout) |

**Rationale:** DRY across Auth, Feed, Profile, etc.; testable via `Routing` protocol mock.

**Alternative considered:** Copy-paste router per flow. Rejected — identical push/pop/sheet logic.

### 4. Modal presentation: separate slots (not presentation metadata on route)

**Decision:** Same route enum for stack and modal destinations; coordinator root view binds `.sheet(item: $router.sheet)` and `navigationDestination(for:)` separately. Builder maps each route case to the correct presentation context.

**Rationale:** Aligns with SwiftUI's distinct presentation APIs; simpler than encoding presentation style on every route case.

### 5. Builder owns ViewModel + View construction

**Decision:** Each flow has a `*ViewBuilder` that receives `Routing` (protocol) + `AppDependencies` (or subset). Builder:

1. Instantiates ViewModel with repos/services + `onNavigate: { route in router.push(route) }` (or `presentSheet` for modal routes)
2. Returns the SwiftUI view

Views do not construct child destinations via `NavigationLink { Destination() }`.

**Rationale:** Single composition root per flow; ViewModels stay testable with a stub closure.

### 6. ViewModel navigation via closure only

**Decision:**

```swift
init(..., onNavigate: @escaping (AuthRoute) -> Void)
// usage: onNavigate(.register)
```

No router reference stored in ViewModel.

**Rationale:** Decouples VM from navigation infrastructure; matches user preference and eases testing.

### 7. Tab selection on MainCoordinator, not in router path

**Decision:** `MainCoordinator.selectTab(_ tab: Tab)` updates `@Published var selectedTab`. Tab coordinators are created eagerly when MainCoordinator is created (session authenticated).

**Rationale:** Simpler v1; avoids encoding tab state in `NavigationPath`. Cross-tab nav explicitly deferred.

### 8. Auth transitions recreate coordinators

**Decision:** When `SessionService.isAuthenticated` flips:

- **Login success:** discard `AuthCoordinator`, create fresh `MainCoordinator` (new routers, empty paths)
- **Logout:** call `router.reset()` on active coordinators, discard `MainCoordinator`, create fresh `AuthCoordinator`

**Rationale:** Prevents stale navigation state and ViewModels from prior session.

### 9. Coordinator root view owns navigation chrome

**Decision:** Each coordinator exposes `var body: some View` (or `rootView`) that wraps:

- `NavigationStack(path: $router.path) { root builder output }`
- `.navigationDestination(for: Route.self) { route in builder.build(route) }`
- `.sheet(item: $router.sheet) { ... }`
- `.fullScreenCover(item: $router.fullScreenCover) { ... }`

Individual feature views do not declare their own `NavigationStack` after migration.

**Rationale:** One stack per tab/auth flow; destinations registered in one place.

### 10. AppCoordinator replaces RootView branching logic

**Decision:** `AppCoordinator` observes `SessionService` and renders splash | `authCoordinator.rootView` | `mainCoordinator.rootView`. `smmpApp` injects `AppCoordinator` (or factory from `AppDependencies`).

**Rationale:** Single owner for session-driven navigation tree.

### 11. Protocol surface

**Decision:**

```swift
protocol AppRoute: Hashable {}

protocol Routing: AnyObject, ObservableObject {
    associatedtype Route: AppRoute
    var path: NavigationPath { get set }
    var sheet: Route? { get set }
    var fullScreenCover: Route? { get set }
    func push(_ route: Route)
    func pop()
    func popToRoot()
    func presentSheet(_ route: Route)
    func dismissSheet()
    func presentFullScreenCover(_ route: Route)
    func dismissFullScreenCover()
    func reset()
}

protocol Coordinating: AnyObject, ObservableObject {
    associatedtype Route: AppRoute
    var router: any Routing { get }
    @ViewBuilder var rootView: some View { get }
}
```

Per-flow type aliases or constrained protocols (e.g. `AuthRouting: Routing where Route == AuthRoute`) optional for ergonomics.

**Rationale:** Enables mock routers in tests and keeps coordinators swappable.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Double abstraction (Coordinator + Router + SwiftUI stack) | Keep coordinators thin — mostly compose builder + bind router; no business logic |
| `NavigationPath` is type-erased | Use `navigationDestination(for: ConcreteRoute.self)` per coordinator; one route enum per stack |
| Migration leaves hybrid NavigationLink usage | Migrate one flow at a time; lint/review checklist per PR |
| Generic `Router` + protocol associated types add complexity | Start with concrete routers conforming to protocol; generic base is shared infra |
| Eager tab coordinator creation uses memory for 4 stacks | Acceptable for 4 tabs; lazy creation deferred unless profiling shows issue |
| Modal and push share route enum — wrong presentation if miswired | Builder + coordinator tests; document which routes use sheet vs push |

## Migration Plan

1. **Infrastructure** — protocols, generic `Router`, folder structure (`Coordinators/`, `Routers/`, `Builders/`, `Routes/`)
2. **AppCoordinator shell** — wire into app entry alongside existing `RootView` (feature flag or parallel path optional; prefer direct replacement once Auth migrates)
3. **Auth flow** — `AuthRoute`, `AuthRouter`, `AuthCoordinator`, `AuthViewBuilder`; migrate Login, Register, ForgotPassword; remove login `NavigationLink`s
4. **MainCoordinator shell** — tab host replacing `ContentView`; tab selection via coordinator
5. **Feed flow** — `FeedRoute` (feed root, post detail, future in-tab destinations); migrate `FeedView` / post detail push
6. **Search, NewPost, Profile** — one flow per task group; Profile logout triggers AppCoordinator recreation
7. **Cleanup** — remove dead `NavigationStack` wrappers from migrated views, delete unused bindings (`selectedTab` in NewPost → coordinator callback)

Rollback: each migration step is independently revertable; keep git commits per flow.

## Open Questions

- None blocking implementation. Future: cross-tab navigation API on `MainCoordinator`, deep link parser mapping URL → coordinator routes.
