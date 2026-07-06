## Context

Phase 3 delivered a global feed, post CRUD, likes, comments, and `ProfileRepository.fetchUser` for author resolution. The Profile tab (`ProfileView`) shows a minimal own-profile stub; `EditProfileView` and `SearchView` are placeholders; `FollowRepository` is an empty shell. `createProfile` still lives in `AuthService` despite the Phase 2 spec placing it on `ProfileRepository`. The feed queries all posts globally; Phase 3 design deferred follow-scoped feed to Phase 4.

Stack: SwiftUI, coordinator–router–builder navigation, Firebase Auth + Firestore + Storage, CoreData cache, MVVM + Repository, `AppDependencies` DI, `NetworkMonitor`, localization via `Localizable.xcstrings`.

Firestore rules deny `users/{uid}/following` paths today. Storage rules cover post images only.

## Goals / Non-Goals

**Goals:**

- Deliver README Phase 4: own profile, other-user profile, edit profile, search, follow/unfollow, following list, follow-scoped feed
- Two-screen model: `ProfileView` (Profile tab) and `UserProfileView` (pushed from Feed/Search)
- Follow graph via `users/{me}/following/{theirId}` subcollection; max 30 following per user
- Follow-scoped feed: `authorId IN (self + following IDs)` — fits Firestore `in` limit of 30
- Move `createProfile` to `ProfileRepository`; add `updateProfile`, `searchUsers`
- Profile posts list reuses `PostCardView` (no grid toggle)
- Tapping author avatar pushes `UserProfileView` on the same tab stack
- When viewing own profile via `UserProfileView`, hide Follow and show Edit
- Follower count displayed but not tappable; full `FollowingScreen` only
- Search by `displayNameLower` prefix only (case-insensitive)
- Disable edit profile and follow/unfollow when offline
- Deploy Firestore + Storage rule updates; unit tests for key ViewModels and `FollowRepository`

**Non-Goals:**

- Account deletion
- Followers list screen (count only)
- Email or username search
- Offline queued writes for follow or profile edit
- Grid layout for profile posts
- Cross-tab navigation (e.g. switch to Profile tab from Feed)
- Cloud Functions for count maintenance
- Real-time profile or following listeners (load on appear / refresh)
- Camera capture for profile photo (photo library via `PhotosPicker`, same as posts)

## Decisions

### 1. Follow graph: following subcollection as source of truth

**Decision:** Store follows at `users/{followerId}/following/{followedId}` with `followedAt` timestamp. `isFollowing` checks document existence at `users/{me}/following/{theirId}`.

```
follow batch:
  users/me/following/theirId          create { followedAt }
  users/me                            followingCount += 1  (owner write)
  users/them                          followerCount += 1   (count-only rule)

unfollow: reverse
```

**Rationale:** Matches README schema; single write path; powers feed `in` query by listing following doc IDs.

**Alternative considered:** Bidirectional `followers` subcollection. Rejected for portfolio scope — follower count via denormalized field only.

### 2. User count updates via permissive security rules

**Decision:** Mirror Phase 3 post `likeCount` pattern — any authenticated user may update `followerCount` or `followingCount` on a user document when those are the only changed fields.

**Rationale:** Avoids Cloud Functions; consistent with existing count maintenance pattern.

### 3. Max 30 following per user

**Decision:** `FollowRepository.follow` rejects when `followingCount >= 30`. Feed query uses `whereField("authorId", in: [self] + followingIds)` (max 31 IDs).

**Rationale:** Firestore `in` queries support at most 30 disjunction values; capping following keeps feed query valid without chunking.

### 4. Follow-scoped feed (replaces global)

**Decision:** Change `PostRepository.feedQuery()` to filter by `authorId in followingSet`. Load following IDs from `users/{me}/following` before attaching listener and pagination. Offline feed filters cached `CDPost` by the same ID set.

```
PostRepository.feedQuery(followingIds: [String], selfId: String)
  → posts.whereField("authorId", in: [selfId] + followingIds)
           .orderBy("createdAt", descending: true)
```

**Rationale:** Phase 3 global query was explicitly temporary; single swap point in `PostRepository`.

### 5. Two profile screens

**Decision:**

| Screen | Entry | Actions |
|--------|-------|---------|
| `ProfileView` | Profile tab | Edit (sheet), Logout, Following list |
| `UserProfileView(userId)` | Feed/Search push | Follow/Unfollow (others), Edit (self), posts list |

Shared `ProfileHeaderView` component for avatar, name, bio, counts.

**Rationale:** User chose two screens over a single parameterized view with divergent toolbar/routing.

### 6. Own profile from feed: Option C

**Decision:** Tapping own avatar on a post pushes `UserProfileView(currentUserId)` with Follow hidden and Edit shown (sheet).

**Rationale:** Consistent push navigation; Edit available without switching tabs.

### 7. Search: `displayNameLower` prefix query

**Decision:** Store `displayNameLower = displayName.lowercased()` on create and update. Search queries Firestore with range filter on `displayNameLower` (prefix match). Debounce 300ms, minimum 2 characters. Hide Follow button for self in results.

**Rationale:** Firestore prefix search is case-sensitive on raw `displayName`; normalized field is the standard portfolio pattern.

**Alternative considered:** Client-side filter on bounded fetch. Rejected — does not scale and is less instructive for Firestore.

### 8. Move `createProfile` to `ProfileRepository`

**Decision:** `ProfileRepository.createProfile(uid:displayName:email:)` writes `users/{uid}` including `displayNameLower`. `AuthService.register` calls `ProfileRepository` via `AuthRepository` after Auth account creation.

**Rationale:** Aligns implementation with Phase 2 spec; single home for user document writes.

### 9. Profile photo upload

**Decision:** `MediaPaths.profileImage(userId:)` → `users/{uid}/avatar.jpg`. `ProfileRepository.updateProfile` orchestrates resize, upload, Firestore `photoURL` update, and Firebase Auth `photoURL` sync. Delete old avatar on replace.

**Rationale:** Parallel to post image flow; Storage rules extended for `users/{uid}/` path.

### 10. Repository boundaries

**Decision:**

| Repository | Responsibility |
|------------|----------------|
| `ProfileRepository` | `createProfile`, `fetchUser`, `updateProfile`, `searchUsers(prefix:)` |
| `FollowRepository` | `follow`, `unfollow`, `isFollowing`, `fetchFollowing`, `followingIds` |
| `PostRepository` | Follow-scoped feed query, `fetchPosts(authorId:)` |

**Rationale:** User confirmed split; avoids bloating profile repo with graph ops.

### 11. Navigation routes

**Decision:**

- `FeedRoute.userProfile(userId: String)`
- `SearchRoute.userProfile(userId: String)`
- `ProfileRoute.following` (push)
- `FeedRoute` / `ProfileRoute` / `UserProfileRoute` may also push `postDetail` from profile post list

Author avatar tap in `PostCardView` and `CommentRowView` calls `onAuthorTap(userId)` → coordinator pushes `userProfile`.

### 12. Offline behavior

**Decision:** When `NetworkMonitor.isConnected == false`, disable Follow/Unfollow buttons and Edit Profile entry with informative state (same pattern as offline write actions in Phase 3). Read cached profile and posts still allowed.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Count drift if batch partially fails | Use Firestore batch writes; surface error and do not optimistically update counts |
| User follows 30 people — cannot follow more | Clear error message; following count visible on profile |
| Feed empty for new users with no follows | Expected; own posts still appear via self ID in `in` query |
| `displayNameLower` out of sync if edited outside app | Always set in `updateProfile` repository path |
| Denormalized `followerCount` inaccurate under race | Acceptable for portfolio; same trade-off as `likeCount` |
| Two profile screens duplicate post-list wiring | Extract shared post-list section or builder helper |

## Migration Plan

1. Deploy updated Firestore rules (following subcollection + user count fields) before device testing follow flows
2. Deploy updated Storage rules (profile avatars)
3. Existing `users/{uid}` documents without `displayNameLower` — backfill on next `updateProfile` or lazy migration in `fetchUser` write-back (implementation choice: set on fetch if missing)
4. No data migration for posts; feed query change is read-path only
5. Rollback: revert rules and app build; global feed returns if `feedQuery` reverted

## Open Questions

None — exploration decisions captured above.
