## Why

Phase 4 delivered profiles, search, and the follow graph, but offline mode is inconsistent: `NetworkMonitor` defaults to online before the first path update (offline banners fail to appear), some ViewModels do not react to connectivity changes, and write actions (like, delete) are still allowed on Feed and Post Detail while offline. README §1.5 and Phase 5 promise full offline browsing, disabled writes, and polish (skeletons, micro-interactions) before release prep.

## What Changes

- Fix `NetworkMonitor` — seed initial state from `currentPath`; expose a connectivity publisher so all ViewModels react to online/offline transitions
- Add shared `OfflineBanner` component; replace per-screen copy-pasted banners
- Harden offline write-disable across Feed, Post Detail, Profile, and Create Post (like, comment, delete post/comment)
- Document explicit offline exceptions: Search (requires connection message, no cached results) and Following list (empty with banner, no cache)
- Other-user profile offline when never fully cached: show partial state from any available author data (e.g. display name from feed navigation context)
- Reconnect auto-refresh for Feed and profile screens that were loaded while offline
- Add skeleton loading placeholders (`.redacted`) on Feed, profile, and Search while initial load runs
- Add heart bounce animation on like; haptics on like, follow, and post submit
- Add simple splash logo fade/scale animation
- Expand unit and integration tests for connectivity, offline guards, and reconnect behavior
- Add localization keys for new offline and polish strings

## Capabilities

### New Capabilities

- `offline-mode`: Reliable connectivity detection, shared offline banner, full offline browsing policy, write-disable audit, reconnect refresh, partial profile offline state
- `ui-polish`: Skeleton loading, heart animation, haptics, splash animation

### Modified Capabilities

- `feed`: Offline banner driven by reactive connectivity; like disabled offline; skeleton on initial load
- `posts`: Like animation; like and delete disabled offline on Feed and Post Detail
- `comments`: Add/delete comment disabled offline on Post Detail
- `profiles`: Partial offline display for never-visited users; skeleton on profile load
- `user-search`: Explicit offline requires-connection messaging (no cached search results)
- `follow-graph`: Following list shows offline empty state (no list cache)
- `localization`: Keys for offline search message, partial profile state, haptics-adjacent copy if needed

## Impact

- **Utilities:** `NetworkMonitor`, `NetworkMonitorProtocol` / `NetworkConnectivityProviding` — publisher API, initial path seeding
- **UI components:** `OfflineBanner`, `LikeButton` or animated heart in `PostCardView`, skeleton wrappers
- **Services:** `HapticService` (new, injected via `AppDependencies`)
- **ViewModels:** `FeedViewModel`, `PostDetailViewModel`, `CreatePostViewModel`, `EditProfileViewModel`, `ProfileViewModel`, `UserProfileViewModel`, `SearchViewModel`, `FollowingViewModel` — unified connectivity binding, offline guards
- **Views:** `SplashView`, `FeedView`, `PostDetailView`, `ProfileView`, `UserProfileView`, `SearchView`, `FollowingView`
- **Tests:** `NetworkMonitorTests`, expanded offline/write-disable tests for Feed and PostDetail ViewModels, reconnect integration test
- **Out of scope:** SDWebImage, `matchedGeometryEffect`, UI tests, Instruments profiling, Followers screen, Following list offline cache, Search result caching
