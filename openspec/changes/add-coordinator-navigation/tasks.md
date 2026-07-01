## 1. Navigation infrastructure

- [x] 1.1 Add `AppRoute` protocol (`Hashable` marker) in `smmp/Navigation/Protocols/`
- [x] 1.2 Add `Routing` protocol with `path`, `sheet`, `fullScreenCover`, push/pop/popToRoot, sheet/cover present/dismiss, and `reset`
- [x] 1.3 Add `Coordinating` protocol with associated route type, router, and `rootView`
- [x] 1.4 Implement generic `Router<Route: AppRoute>` as `@MainActor final class` conforming to `Routing` and `ObservableObject`
- [x] 1.5 Add router unit tests: push increments path, pop decrements, popToRoot clears path, sheet present/dismiss, reset clears all

## 2. AppCoordinator shell

- [x] 2.1 Create `AppCoordinator` observing `SessionService` (splash | auth | main)
- [x] 2.2 Wire `AppCoordinator` into app entry (`smmpApp` / replace `RootView` branching)
- [x] 2.3 Implement coordinator recreation on auth state change (discard old child, create fresh instance)
- [x] 2.4 Add `AppCoordinator` tests or test helper verifying auth ↔ main transition recreates children

## 3. Auth flow migration

- [x] 3.1 Define `AuthRoute` enum (login, register, forgotPassword)
- [x] 3.2 Create `AuthRouter` type alias or wrapper over `Router<AuthRoute>`
- [x] 3.3 Create `AuthViewBuilder` — builds Login, Registration, ForgotPassword with `onNavigate` closures
- [x] 3.4 Create `AuthCoordinator` root view: `NavigationStack` + `navigationDestination(for: AuthRoute.self)` + sheet bindings
- [x] 3.5 Add `onNavigate` to `LoginViewModel`, `RegistrationViewModel`, `ForgotPasswordViewModel`; remove navigation side effects from views
- [x] 3.6 Replace `LoginView` `NavigationLink`s with buttons calling view model navigate methods
- [x] 3.7 Remove `NavigationStack` wrapper from migrated auth views (stack owned by coordinator)

## 4. MainCoordinator shell

- [x] 4.1 Create `MainCoordinator` with `@Published selectedTab: Tab` and `selectTab(_:)`
- [x] 4.2 Create placeholder tab coordinator stubs (Feed, Search, NewPost, Profile) returning existing views temporarily
- [x] 4.3 Replace `ContentView` tab shell with `MainCoordinator.rootView` (`TabView` bound to coordinator)
- [x] 4.4 Eagerly instantiate all tab coordinators when `MainCoordinator` is created

## 5. Feed flow migration

- [x] 5.1 Define `FeedRoute` enum (feed root, postDetail with associated data)
- [x] 5.2 Create `FeedRouter` and `FeedViewBuilder`
- [x] 5.3 Create `FeedCoordinator` with `NavigationStack`, `navigationDestination`, and modal bindings
- [x] 5.4 Add `onNavigate` to `FeedViewModel` for post detail push; replace `NavigationLink(value:)` in `FeedView`
- [x] 5.5 Wire `PostDetailView` through builder; remove nested `NavigationStack` from feed views
- [x] 5.6 Register `FeedCoordinator` in `MainCoordinator` feed tab

## 6. Search flow migration

- [x] 6.1 Define `SearchRoute` enum (search root; extend for future destinations)
- [x] 6.2 Create `SearchRouter`, `SearchViewBuilder`, `SearchCoordinator`
- [x] 6.3 Remove `NavigationStack` from `SearchView`; register in `MainCoordinator` search tab

## 7. NewPost flow migration

- [x] 7.1 Define `NewPostRoute` enum (newPost root)
- [x] 7.2 Create `NewPostRouter`, `NewPostViewBuilder`, `NewPostCoordinator`
- [x] 7.3 Replace `selectedTab` `@Binding` with `onNavigate` / coordinator callback to `MainCoordinator.selectTab(.feed)` after successful post
- [x] 7.4 Remove `NavigationStack` from `NewPostView`; register in `MainCoordinator` newPost tab

## 8. Profile flow migration

- [x] 8.1 Define `ProfileRoute` enum (profile root, editProfile as sheet case)
- [x] 8.2 Create `ProfileRouter`, `ProfileViewBuilder`, `ProfileCoordinator`
- [x] 8.3 Wire edit profile (when implemented) via `presentSheet`; wire logout through existing auth repository (AppCoordinator handles tree swap)
- [x] 8.4 Remove `NavigationStack` from `ProfileView`; register in `MainCoordinator` profile tab

## 9. Cleanup and verification

- [x] 9.1 Delete or reduce `RootView` / `ContentView` to thin wrappers if no longer needed
- [x] 9.2 Audit migrated views for remaining `NavigationLink { Destination() }` patterns
- [ ] 9.3 Manual test: login → register → back → forgot password → login → feed → post detail → pop → logout → login
- [ ] 9.4 Manual test: tab switching preserves feed stack; new post switches to feed tab
