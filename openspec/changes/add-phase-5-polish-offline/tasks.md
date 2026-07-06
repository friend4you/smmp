## 1. NetworkMonitor and connectivity protocol

- [ ] 1.1 Seed `isConnected` from `monitor.currentPath.status` in `NetworkMonitor.init()` before starting the handler
- [ ] 1.2 Add `connectivityPublisher: AnyPublisher<Bool, Never>` to `NetworkConnectivityProviding` / `NetworkMonitorProtocol`
- [ ] 1.3 Implement publisher on `NetworkMonitor` from `$isConnected`; update test mocks with `CurrentValueSubject`
- [ ] 1.4 Add `NetworkMonitorTests` — cold start offline, online→offline→online transitions

## 2. Shared offline UI

- [ ] 2.1 Create `OfflineBanner` component in `UI/Views/Components/`
- [ ] 2.2 Replace duplicated offline banners in Feed, PostDetail, Profile, UserProfile, Search, Following, NewPost, EditProfile
- [ ] 2.3 Remove `// TODO: Fix network service` from `FeedView` once banner is verified

## 3. ViewModel connectivity binding

- [ ] 3.1 Add connectivity binding helper or consistent `bindConnectivity()` pattern using `connectivityPublisher`
- [ ] 3.2 Update `FeedViewModel` — ensure `isOffline` reacts immediately (verify with tests)
- [ ] 3.3 Update `PostDetailViewModel` — `@Published isOffline` from publisher (replace computed-only)
- [ ] 3.4 Update `CreatePostViewModel` and `EditProfileViewModel` — reactive `isOffline`
- [ ] 3.5 Verify Profile, UserProfile, Search, Following ViewModels bind correctly (adjust if needed)

## 4. Offline write-disable audit

- [ ] 4.1 `FeedViewModel.toggleLike` — guard offline; disable like button in `PostCardView` when offline prop passed
- [ ] 4.2 `PostDetailViewModel` — guard `toggleLike`, `deletePost`, `addComment`, `deleteComment` offline
- [ ] 4.3 `PostDetailView` — disable trash, comment composer, delete comment when offline
- [ ] 4.4 Verify Profile/UserProfile like guards remain; CreatePost/EditProfile submit guards remain
- [ ] 4.5 Add `FeedViewModelTests` — offline like does not call repository
- [ ] 4.6 Add `PostDetailViewModelTests` — offline like/delete/comment guards

## 5. Reconnect refresh

- [ ] 5.1 `FeedViewModel` — verify reconnect reload (extend test if needed)
- [ ] 5.2 `ProfileViewModel` / `UserProfileViewModel` — reload on `false → true` when screen active
- [ ] 5.3 `PostDetailViewModel` — refresh comments on reconnect
- [ ] 5.4 Integration test: mock connectivity flip triggers feed reload

## 6. Partial profile offline

- [ ] 6.1 Extend `FeedRoute` / navigation to pass optional `User` stub to `UserProfileView`
- [ ] 6.2 Wire author stub from Feed post tap, Search result, and comment author navigation
- [ ] 6.3 `UserProfileViewModel` — merge stub with cached user; show partial header when `fetchUser` nil offline
- [ ] 6.4 `UserProfileViewModelTests` — partial offline profile from stub, cached posts only

## 7. Search and Following offline messaging

- [ ] 7.1 `SearchView` — requires-connection message when offline (localization key)
- [ ] 7.2 `FollowingView` — verify offline banner + empty placeholder copy
- [ ] 7.3 Add localization keys in `Localizable.xcstrings`

## 8. UI polish — skeletons

- [ ] 8.1 Feed skeleton — redacted `PostCardView` placeholders when loading and empty
- [ ] 8.2 Profile skeleton — redacted header + post rows on initial load
- [ ] 8.3 Search skeleton — redacted result rows during in-flight query

## 9. UI polish — animations and haptics

- [ ] 9.1 Add `HapticServiceProtocol` and `HapticService`; register in `AppDependencies`
- [ ] 9.2 Heart spring animation on like toggle in `PostCardView` (or extracted `LikeButton`)
- [ ] 9.3 Wire haptics: like (light), follow/unfollow (medium), post submit (success)
- [ ] 9.4 `SplashView` — simple logo fade + scale on appear

## 10. README progress tracker

- [ ] 10.1 Update README Phase 5 checklist — mark scroll-to-top done; reflect scoped items (no SDWebImage, UI tests, Instruments, matchedGeometry)
