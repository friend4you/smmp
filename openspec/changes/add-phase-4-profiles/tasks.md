## 1. Firestore and Storage security rules

- [x] 1.1 Extend `firebase/firestore.rules` — `users/{uid}/following/{fid}` read (authenticated) and create/delete (owner only)
- [x] 1.2 Extend `firebase/firestore.rules` — count-only updates for `followerCount` and `followingCount` on user documents
- [x] 1.3 Extend `firebase/storage.rules` — authenticated read for `users/{userId}/`; write for `users/{userId}/` when `userId == auth.uid`, image type, size cap
- [x] 1.4 Deploy Firestore and Storage rules to Firebase console and verify on device

## 2. Models and mapping

- [x] 2.1 Extend `User` with `followerCount`, `followingCount`, and `displayNameLower`
- [x] 2.2 Extend `CDUser` entity and `LocalRepository` save/fetch mapping for new fields
- [x] 2.3 Update `User+Firestore` parser and writer for counts and `displayNameLower`
- [x] 2.4 Add unit tests for User Firestore parsing including new fields

## 3. Move createProfile to ProfileRepository

- [x] 3.1 Add `createProfile(uid:displayName:email:)` to `ProfileRepositoryProtocol` and `ProfileRepository` (include `displayNameLower`)
- [x] 3.2 Remove `createProfile` from `AuthService`; wire `AuthRepository.register` through `ProfileRepository`
- [x] 3.3 Update registration tests and any mocks referencing `AuthService.createProfile`

## 4. ProfileRepository extensions

- [x] 4.1 Add `updateProfile` to `ProfileRepositoryProtocol` — Firestore write, Auth `displayName`/`photoURL` sync, CoreData cache update, `displayNameLower` maintenance
- [x] 4.2 Add `searchUsers(prefix:)` — prefix query on `displayNameLower`, min 2 chars, limit results
- [x] 4.3 Backfill `displayNameLower` on `fetchUser` when missing (lazy migration)
- [x] 4.4 Add `ProfileRepositoryTests` for `updateProfile` and `searchUsers` with mocks

## 5. MediaService profile photos

- [x] 5.1 Add `MediaPaths.profileImage(userId:)` → `users/{uid}/avatar.jpg`
- [x] 5.2 Add `uploadProfileImage` and `deleteProfileImage` to `MediaServiceProtocol` and `MediaService`
- [x] 5.3 Wire `ProfileRepository.updateProfile` to upload/delete avatar via `MediaService`

## 6. FollowRepository

- [x] 6.1 Define `FollowRepositoryProtocol` — `follow`, `unfollow`, `isFollowing`, `fetchFollowing`, `followingIds(for:)`
- [x] 6.2 Implement follow batch — create `users/me/following/theirId`, increment counts; enforce 30-following cap
- [x] 6.3 Implement unfollow batch — delete following doc, decrement counts
- [x] 6.4 Implement `fetchFollowing` and `followingIds` for feed query
- [x] 6.5 Add `FollowRepositoryTests` for batch logic, cap enforcement, and error paths

## 7. PostRepository follow-scoped feed

- [x] 7.1 Add `fetchPosts(authorId:)` — query posts by author, cache to CoreData, return sorted list
- [x] 7.2 Replace `feedQuery()` with follow-scoped query using `authorId in [self + followingIds]` (max 30 following)
- [x] 7.3 Update offline feed path to filter cached posts by follow graph
- [x] 7.4 Update feed listener and pagination to load following IDs before query setup
- [x] 7.5 Add/update integration tests for follow-scoped feed filtering

## 8. Shared profile UI components

- [x] 8.1 Build `ProfileHeaderView` — avatar (`AsyncImage`), display name, bio, follower/following counts (following tappable on own profile only)
- [x] 8.2 Build reusable profile posts list section using `PostCardView` + navigation to post detail

## 9. ProfileView (own profile tab)

- [x] 9.1 Extend `ProfileViewModel` — load profile, posts, following count tap navigation, edit sheet, logout, offline state
- [x] 9.2 Replace `ProfileView` placeholder UI with `ProfileHeaderView`, posts list, toolbar (Edit, Logout)
- [x] 9.3 Wire `ProfileRoute.following` in `ProfileCoordinator` and `ProfileViewBuilder`

## 10. UserProfileView (other users + self from feed)

- [x] 10.1 Create `UserProfileViewModel` — load user, posts, `isFollowing`, follow/unfollow, edit when self, offline disable for writes
- [x] 10.2 Build `UserProfileView` — header, Follow/Unfollow or Edit, posts list
- [x] 10.3 Add `FeedRoute.userProfile(userId)` and `SearchRoute.userProfile(userId)`; wire builders and coordinators

## 11. EditProfileView

- [x] 11.1 Create `EditProfileViewModel` — display name, bio, photo picker, validation, save/discard, upload progress, offline guard
- [x] 11.2 Replace `EditProfileView` placeholder — form fields, `PhotosPicker`, save/cancel with discard confirmation
- [x] 11.3 Present edit sheet from `ProfileView` and `UserProfileView` (self mode)

## 12. FollowingScreen

- [x] 12.1 Create `FollowingViewModel` — load following list, resolve users, unfollow per row
- [x] 12.2 Build `FollowingView` — user rows with avatar, name, Unfollow button
- [x] 12.3 Wire `ProfileRoute.following` push from profile header following count tap

## 13. SearchScreen

- [ ] 13.1 Create `SearchViewModel` — debounced query (300ms), min 2 chars, `searchUsers`, inline follow/unfollow, offline guard
- [ ] 13.2 Replace `SearchView` placeholder — search bar, results list, empty/no-results states, tap → user profile
- [ ] 13.3 Wire `SearchCoordinator` with `SearchRoute.userProfile` and inject dependencies via `SearchViewBuilder`

## 14. Feed and comment author navigation

- [ ] 14.1 Add `onAuthorTap` to `PostCardView`; wire `FeedViewModel` → `onNavigate(.userProfile(id))`
- [ ] 14.2 Add author tap to `CommentRowView`; wire `PostDetailViewModel` → feed coordinator `userProfile` route
- [ ] 14.3 Ensure post detail push from profile post lists works within each tab stack

## 15. Localization

- [ ] 15.1 Add `profile.*`, `search.*`, `follow.*` keys to `Localizable.xcstrings`
- [ ] 15.2 Use generated localization symbols in all new views and ViewModels

## 16. Tests

- [ ] 16.1 Unit tests: `ProfileViewModel` (load profile, edit navigation, offline)
- [ ] 16.2 Unit tests: `SearchViewModel` (debounce, min length, follow toggle)
- [ ] 16.3 Unit tests: `FollowRepository` (from task 6.5)
- [ ] 16.4 Unit tests: `UserProfileViewModel` (follow state, self vs other mode)

## 17. README progress tracker

- [ ] 17.1 Update Phase 4 checklist in README.md as tasks complete
