## Why

Phase 3 delivered a working global feed with posts, likes, and comments, but profiles and the social graph are still stubs: the Profile tab shows minimal own-profile UI, Search is a placeholder, and the feed shows every user's posts. Phase 4 completes the social platform vertical slice — follow-scoped feed, full own/other profile screens, edit profile, user search, and follow/unfollow — so the app matches README §1.2 and §1.3 before Phase 5 polish.

## What Changes

- Move `createProfile` from `AuthService` to `ProfileRepository`; extend `ProfileRepository` with `updateProfile` and `searchUsers(prefix:)`
- Implement `FollowRepository` with follow/unfollow batch writes on `users/{uid}/following/{fid}`, count maintenance, and `fetchFollowing`
- Enforce max **30 following** per user (aligns with Firestore `in` query limit for feed)
- Replace global feed query with follow-scoped query: posts where `authorId` is self or in following set (up to 30 IDs)
- Extend `User` / `CDUser` with `followerCount`, `followingCount`, and `displayNameLower` for search
- Deploy Firestore rules for `users/{uid}/following/{fid}` and count-only `followerCount` / `followingCount` updates
- Deploy Storage rules and `MediaService` path for profile avatars (`users/{uid}/avatar.jpg`)
- Build **two profile screens**: `ProfileView` (own, Profile tab) and `UserProfileView` (pushed from Feed/Search; when `userId == self`, hide Follow and show Edit)
- Build `EditProfileView` (display name, bio, profile photo; save/discard; disabled offline)
- Build `SearchView` with debounced prefix search on `displayNameLower` only
- Build `FollowingScreen` (full list with unfollow); show follower count on profile but no Followers screen (portfolio shortcut)
- Wire author avatar taps in `PostCardView` / `CommentRowView` to push `UserProfileView` within the tab stack
- Add `PostRepository.fetchPosts(authorId:)` for profile post lists (reuse `PostCardView`)
- Disable follow/unfollow and edit profile when offline
- Add localization keys for profile, search, and follow UI
- Add unit tests for `ProfileViewModel`, `SearchViewModel`, and `FollowRepository`

## Capabilities

### New Capabilities

- `profiles`: Own and other-user profile screens, edit profile, `ProfileRepository` CRUD, profile photo upload, posts-by-author on profile
- `follow-graph`: `FollowRepository`, following subcollection, follow/unfollow, following list, follower/following counts, 30-following cap
- `user-search`: Debounced display-name prefix search with inline follow

### Modified Capabilities

- `feed`: Replace global feed query with follow-scoped feed (self + following, max 30 following IDs)
- `firestore-security-rules`: Rules for `following` subcollection and user count-field updates
- `storage-security-rules`: Profile avatar upload path and rules
- `user-profile-bootstrap`: `createProfile` owned by `ProfileRepository`; add `displayNameLower` on bootstrap
- `navigation`: Feed/Search routes for `UserProfileView`; Profile routes for `FollowingScreen`; author avatar navigation

## Impact

- **Repositories:** `ProfileRepository` (create, fetch, update, search), `FollowRepository` (follow, unfollow, isFollowing, fetchFollowing), `PostRepository` (follow-scoped feed query, `fetchPosts(authorId:)`)
- **Services:** `AuthService` loses `createProfile`; `MediaService` gains `uploadProfileImage` / `deleteProfileImage`
- **Models:** `User`, `CDUser`, `User+Firestore` — counts and `displayNameLower`
- **ViewModels:** `ProfileViewModel`, `UserProfileViewModel`, `EditProfileViewModel`, `SearchViewModel`, `FollowingViewModel`; extend `FeedViewModel` for author navigation
- **Views:** `ProfileView`, `UserProfileView`, `EditProfileView`, `SearchView`, `FollowingView`, shared `ProfileHeaderView`
- **Firebase:** `firebase/firestore.rules`, `firebase/storage.rules` — deploy manually
- **Tests:** `ProfileViewModelTests`, `SearchViewModelTests`, `FollowRepositoryTests`
- **Out of scope:** Account deletion, Followers list screen, email search, offline follow/edit, grid post layout, cross-tab navigation
