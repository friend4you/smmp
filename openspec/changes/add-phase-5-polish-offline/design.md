## Context

Phases 3–4 built feed, posts, comments, profiles, search, and follow graph with partial offline support: `PostRepository` and `CommentRepository` read from CoreData when offline; profile screens load cached users/posts; Search and Following disable remote queries offline. Gaps remain:

- `NetworkMonitor.isConnected` defaults to `true`; first `NWPathMonitor` callback is async, so banners miss the initial offline state
- ViewModels using `NetworkMonitorProtocol` with computed `isOffline` (PostDetail, CreatePost, EditProfile) do not re-render when connectivity changes; only ViewModels binding `networkMonitor.$isConnected` update correctly
- `FeedViewModel` and `PostDetailViewModel` allow like toggles offline (optimistic update then error rollback)
- Post/comment delete controls remain enabled offline on Post Detail
- ~8 screens duplicate identical `offlineBanner` SwiftUI blocks
- `FollowingViewModel` clears rows offline (accepted exception); Search shows offline UI but messaging can be clearer
- `UserProfileViewModel` returns `nil` user offline when `CDUser` was never saved — no partial display from feed author context
- README Phase 5 polish items (skeletons, heart animation, haptics, splash) are unimplemented; scroll-to-top on new-posts banner is already done

Stack unchanged: SwiftUI, coordinator navigation, Firebase, CoreData, MVVM + Repository, `AppDependencies` DI, `AsyncImage` (no SDWebImage).

## Goals / Non-Goals

**Goals:**

- Deliver README Phase 5 subset aligned with engineer-review audience: correct offline behavior, consistent UX, expanded automated tests
- Fix `NetworkMonitor` so offline banners appear immediately and update reactively on every screen
- Full offline browsing for cached content on Feed, Post Detail, own/other profile (with partial state when only author stub exists)
- Disable all connectivity-required writes offline with UI affordances (disabled buttons, no optimistic rollback loops)
- Shared `OfflineBanner`; reconnect refresh on Feed and profile loads
- Skeleton placeholders on Feed, profile, Search initial load
- Heart bounce on like; haptics on like, follow, post submit; simple splash logo animation
- Unit/integration tests for connectivity, offline guards, reconnect

**Non-Goals:**

- `matchedGeometryEffect` / hero transitions (replaced by skeletons)
- SDWebImage or image cache memory audit / Instruments profiling
- UI tests (XCUITest)
- Followers screen
- Offline cache for Following list or Search results
- Offline queued writes
- Reachability probing beyond `NWPathMonitor` (no custom HTTP ping to Firebase)
- App-wide global offline overlay (per-screen banner remains)

## Decisions

### 1. Seed NetworkMonitor from currentPath on init

**Decision:** In `NetworkMonitor.init()`, set `isConnected = (monitor.currentPath.status == .satisfied)` before starting the monitor. Continue updating via `pathUpdateHandler`.

**Rationale:** Eliminates the false-online window on cold start offline. Matches user-reported banner bug.

**Alternative considered:** Default `isConnected = false`. Rejected — causes brief offline flash on normal online launch.

### 2. Connectivity publisher on the protocol

**Decision:** Extend `NetworkConnectivityProviding` (or `NetworkMonitorProtocol`) with `var connectivityPublisher: AnyPublisher<Bool, Never>`. `NetworkMonitor` implements from `$isConnected`. Test mocks use `CurrentValueSubject`.

All ViewModels that display offline state bind to this publisher and set `@Published var isOffline`.

**Rationale:** Fixes PostDetail/CreatePost/EditProfile non-reactive computed `isOffline`. Single pattern for engineer reviewers.

**Alternative considered:** Inject concrete `NetworkMonitor` everywhere and drop protocol for connectivity. Rejected — breaks existing test mocks and DI boundaries.

### 3. Shared OfflineBanner component

**Decision:** `OfflineBanner` SwiftUI view in `UI/Views/Components/`, using existing `feedOfflineBanner` localization key (or a generic `commonOfflineBanner` alias). Replace duplicated private banners.

**Rationale:** DRY; one place to adjust styling.

### 4. Offline write-disable at ViewModel layer

**Decision:** Guard all write paths (`toggleLike`, `addComment`, `deleteComment`, `deletePost`, `toggleFollow`, `submitPost`, `saveProfile`) with `guard !isOffline` (or `canSubmit` computed properties). Disable corresponding buttons in Views. Do not fire optimistic updates offline.

Profile and UserProfile ViewModels already guard likes; extend same pattern to Feed and PostDetail.

**Rationale:** Prevents confusing rollback alerts; matches README §1.5.

### 5. Offline exceptions (documented)

**Decision:**

| Screen | Offline behavior |
|--------|------------------|
| Search | Banner + "Search requires an internet connection"; no Firestore query; no cached results |
| Following | Banner + empty placeholder; no list cache |
| All other main screens | Serve CoreData/cache where available |

**Rationale:** User chose pragmatic exceptions for Search and Following while targeting full offline elsewhere.

### 6. Partial profile offline for never-visited users

**Decision:** When pushing `UserProfileView`, pass optional `User` stub from navigation context (feed author, search result, comment author). `UserProfileViewModel` uses stub fields when `ProfileRepository.fetchUser` returns nil offline. Show available `displayName` / `photoURL`; posts from `LocalRepository.fetchPosts()` filtered by `authorId`; empty posts section if none cached.

**Rationale:** Meets "show what info we have" without new persistence.

**Alternative considered:** Always require full `CDUser` cache. Rejected — first offline visit to a profile seen only via feed author row would be blank.

### 7. Reconnect refresh

**Decision:** On `connectivityPublisher` transition `false → true`, reload active screen data:

- `FeedViewModel`: re-call `observeFeed` / `reloadFeed` (existing behavior)
- `ProfileViewModel` / `UserProfileViewModel`: call `load()` if view appeared
- `PostDetailViewModel`: refresh comments if on screen

Do not auto-reload Search (user must type again).

**Rationale:** Stale offline data updates without manual pull-to-refresh.

### 8. Skeleton loading via redacted modifier

**Decision:** While `isLoading && items.isEmpty`, render placeholder `PostCardView` / profile header shapes with `.redacted(reason: .placeholder)` and `.shimmering()` optional (skip custom shimmer — redacted only). Search shows redacted result rows during in-flight query.

**Rationale:** Native SwiftUI; no third-party skeleton library.

### 9. Heart animation and haptics

**Decision:**

- Extract like button into `LikeButton` (or animate inline) with `withAnimation(.spring)` scale on `heart.fill` toggle
- `HapticService` protocol + implementation using `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator`; inject via `AppDependencies`
- Triggers: like (light), follow/unfollow (medium), post submit success (success)

**Rationale:** Small focused service; testable via protocol mock.

### 10. Splash animation

**Decision:** `SplashView` logo uses `.opacity` + `.scaleEffect` animation on appear (0.9 → 1.0, 0 → 1 opacity over ~0.4s). Keep `ProgressView` below.

**Rationale:** Simple; matches user preference.

### 11. Testing strategy (no UI tests)

**Decision:** Add `NetworkMonitorTests` (test initializer path). Extend `FeedViewModelTests` and new `PostDetailViewModelTests` for offline like/delete guards. Integration test: mock monitor flip offline→online triggers feed reload.

**Rationale:** Engineer audience; replaces skipped XCUITest with targeted unit/integration coverage.

## Risks / Trade-offs

- **[NWPathMonitor satisfied ≠ internet]** WiFi with captive portal may still show online → Mitigation: acceptable for portfolio; document limitation; Firestore errors still surface on write
- **[Partial profile stub stale]** Stub from feed may lack bio/counts offline → Mitigation: show only available fields; full profile loads on reconnect
- **[Publisher binding duplication]** Every ViewModel binds connectivity → Mitigation: optional small `ConnectivityObserving` helper if repetition grows; start explicit per-VM for clarity
- **[Reconnect storm]** Multiple VMs reloading on reconnect → Mitigation: only VMs with active `onAppear` / started state reload

## Migration Plan

1. Ship `NetworkMonitor` + protocol publisher change first (unblocks banners)
2. Replace banners and wire ViewModel bindings
3. Add write guards and UI disables
4. Partial profile stub wiring in coordinators
5. Polish (skeletons, animation, haptics, splash)
6. Tests last

No Firebase migration. No CoreData model changes.

## Open Questions

None — exploration decisions locked:

- Search offline: requires-connection message only
- Never-visited profile: partial stub display
- Tests: expand unit/integration
- Instruments, SDWebImage, UI tests, matchedGeometryEffect: out of scope
