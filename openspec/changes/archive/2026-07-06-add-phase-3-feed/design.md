## Context

Phase 2 completed auth, session routing, and Firestore `users/{uid}` bootstrap. The feed tab (`FeedView`) and new-post tab (`NewPostView`) are placeholders. `PostRepository`, `CommentRepository`, and `MediaService` are empty shells. CoreData entities (`CDPost`, `CDComment`, `CDUser`) and Swift models exist but have no Firestore mapping or repository logic.

Stack: SwiftUI, Firebase Auth + Firestore, CoreData, MVVM + Repository, `AppDependencies` DI, `NetworkMonitor` for connectivity, localization via `Localizable.xcstrings`.

Firestore security rules in the Firebase console are currently deny-all and must be updated before device testing.

## Goals / Non-Goals

**Goals:**

- Deliver README Phase 3: global feed, create/delete post (text with optional image), like/unlike, post detail with comments, offline read of cached feed
- Follow established architecture: Repository listeners → CoreData cache → `CurrentValueSubject` → ViewModel → View
- Fetch author profiles from `users/{authorId}` with CoreData caching for consistency
- Cascade delete post plus `likes` and `comments` subcollections
- Update `likeCount` and `commentCount` on the post document via client batch writes
- Deploy Firestore security rules that allow authenticated access with field-scoped count updates
- Deploy Firebase Storage security rules and implement `MediaService` image upload with cascade Storage delete on post delete
- Unit tests for document parsing; integration test for offline feed fallback

**Non-Goals:**

- Follow-scoped feed query (Phase 4 — swap global query for following + self)
- Image-only posts (text is always required; image is optional attachment)
- Camera capture (photo library via `PhotosPicker` only)
- SDWebImageSwiftUI (use SwiftUI `AsyncImage` for post images)
- Real-time comment listeners (load on open only)
- Denormalizing author fields onto post documents
- Profile editing, search, follow graph (Phase 4)
- Full offline write-disable UX polish (Phase 5 — basic offline banner in this change)
- Cloud Functions for count maintenance
- Account deletion, notifications

## Decisions

### 1. Global feed query (temporary until Phase 4)

**Decision:** Query `posts` collection ordered by `createdAt` descending with cursor pagination.

```
Phase 3                          Phase 4 (future)
────────                         ────────────────
posts                            posts WHERE authorId IN (following + self)
  .orderBy(createdAt, desc)        OR composite index + fan-out
  .limit(pageSize)
  + snapshot listener for new items at top
```

**Rationale:** Unblocks social UX demo without `FollowRepository`. Phase 4 replaces only the query/filter layer in `PostRepository`.

**Alternative considered:** Own-posts-only feed. Rejected — too empty for portfolio demo.

### 2. Author display via user fetch + cache

**Decision:** Resolve `authorId` → `User` by reading `users/{authorId}` from Firestore, caching via `LocalRepository.saveUser`. Feed and detail screens use cached user when available; fetch on miss.

```
PostCard appears
      │
      ├─ CDUser hit? → use displayName, photoURL
      │
      └─ miss → Firestore users/{authorId} → saveUser → render
```

**Rationale:** User chose consistent profile data over denormalized post fields.

**Alternative considered:** Denormalize `authorDisplayName` on post create. Rejected per user decision.

### 3. FeedPostItem view model

**Decision:** Introduce `FeedPostItem` (or equivalent) combining `Post`, resolved `User` author, and `isLikedByCurrentUser` for card rendering. Keeps `Post` model aligned with Firestore schema.

### 4. Real-time feed listener + pagination

**Decision:**

- Attach one Firestore `addSnapshotListener` on the global feed query (first page / recent window) for real-time inserts and updates.
- Use `getDocuments` with `startAfter` cursor for older pages (infinite scroll).
- When listener delivers posts newer than the user's scroll position, buffer them and show a "New posts" banner; tap scrolls to top and merges.

**Rationale:** Matches README §2.3 and architecture §3.6 without over-fetching entire history.

### 5. Offline read path

**Decision:** When `NetworkMonitor.isConnected == false`, skip Firestore calls; load posts from CoreData `CDPost` sorted by `createdAt` desc. Show offline banner on `FeedScreen`.

**Rationale:** README offline requirement; CoreData entities already exist.

### 6. Like/unlike with optimistic UI

**Decision:**

```
User taps like
    │
    ├─ ViewModel: optimistic isLiked + likeCount locally
    │
    └─ PostRepository: Firestore batch
           ├─ set/delete posts/{pid}/likes/{currentUid}
           └─ update posts/{pid}.likeCount (FieldValue.increment ±1)
```

On failure: ViewModel rolls back optimistic state and shows error.

**Check liked state:** On feed load, query whether `posts/{pid}/likes/{currentUid}` exists (batch get or include in repository merge logic).

### 7. Comment load-on-open

**Decision:** `PostDetailViewModel` calls `CommentRepository.fetchComments(postId:)` once on appear (and on pull-to-refresh). No snapshot listener. Add/delete triggers re-fetch or local list update plus count batch on post doc.

### 8. Cascade delete post

**Decision:** `PostRepository.deletePost` runs:

1. Delete Firebase Storage object at `posts/{pid}/image.jpg` if present
2. Query and delete all documents in `posts/{pid}/likes`
3. Query and delete all documents in `posts/{pid}/comments`
4. Delete `posts/{pid}`

Use batched writes (max 500 ops); paginate subcollection deletes if needed. Storage delete is best-effort before Firestore delete; continue if object missing.

**Rationale:** No orphaned subcollections or Storage files.

### 9. Create post (text required, image optional)

**Decision:** `CreatePostViewModel` validates non-empty trimmed text, max 280 characters. Image is optional (text + image allowed; image-only rejected). Writes `posts/{autoId}` with `authorId`, `text`, `imageURL` (download URL or `null`), `likeCount` 0, `commentCount` 0, `createdAt` serverTimestamp.

**Upload flow:**

```
Generate postId
      │
      ├─ image selected? → MediaService.resize + upload → download URL
      │
      └─ PostRepository.createPost(text, imageURL, postId, authorId)
```

On upload failure: do not write Firestore doc. On Firestore failure after upload: delete uploaded Storage object (compensating action).

### 10. Firestore security rules

**Decision:** Deploy rules (documented in `firestore-security-rules` spec) allowing:

- Authenticated read on `users`, `posts`, `likes`, `comments`
- User write own `users/{uid}`
- Create post only with `authorId == auth.uid`
- Update/delete own posts
- Write own like doc; update post `likeCount` / `commentCount` only when those are the changed fields
- Create/delete own comments

Store a reference copy at `firebase/firestore.rules` in the repo for version control; deploy manually to Firebase console.

### 11. Listener lifecycle

**Decision:** `PostRepository` holds `ListenerRegistration` keyed by `"feed"`. Remove on sign-out — extend `SessionService` sign-out path or `AuthRepository.signOut` to call `postRepository.removeAllListeners()`.

### 12. Localization

**Decision:** Add `feed.*`, `post.*`, `comment.*` keys to `Localizable.xcstrings`; use generated symbols in views/ViewModels per existing convention.

### 13. DI wiring

**Decision:** Inject `postRepository`, `commentRepository`, `sessionService`, `networkMonitor`, `localRepository` into ViewModels via `FeedView` / `NewPostView` / `PostDetailView` using `@EnvironmentObject AppDependencies` or explicit init from `ContentView`.

### 14. Post image upload and display

**Decision:**

- **Source:** `PhotosPicker` (photo library only; no camera).
- **Resize:** Client-side resize to max 1080px on long edge; encode as JPEG quality 0.8 before upload.
- **Storage path:** `posts/{postId}/image.jpg`.
- **Display:** SwiftUI `AsyncImage` in `PostCardView` and `PostDetailView` when `imageURL` is non-null (no SDWebImage dependency).
- **Progress:** Linear upload progress bar on Create Post screen while `MediaService` uploads.
- **Field convention:** `imageURL` is `null` when no image; HTTPS download URL when present (not empty string).

**Orchestration:** `CreatePostViewModel` coordinates `MediaService.uploadPostImage` then `PostRepository.createPost`. `MediaService` exposes upload progress for the UI.

**Alternative considered:** SDWebImageSwiftUI per README §3.5. Rejected for this slice — `AsyncImage` avoids an extra dependency; revisit in Phase 5 if scroll/cache performance needs work.

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Global feed shows all users' posts until Phase 4 | Documented temporary query; single swap point in `PostRepository` |
| N+1 user fetches on feed scroll | Cache in `CDUser`; dedupe in-flight fetches per `authorId` |
| Count drift if batch partially fails | Use Firestore batch atomicity; rollback optimistic UI on error |
| Cascade delete exceeds 500-op batch | Paginate subcollection deletes in loops |
| Deny-all rules block testing | Deploy rules as first implementation task |
| Stale CoreData from previous user | Accept for portfolio; scope queries by cached feed only |
| Listener + pagination overlap duplicates | Deduplicate by post `id` in repository merge |
| Orphan Storage file if Firestore write fails | Compensating delete in `CreatePostViewModel` / `MediaService` on post-create failure |
| `AsyncImage` re-fetch on fast scroll | Accept for portfolio; Phase 5 may add disk cache layer |
| Upload fails mid-create | Disable submit during upload; show error; no Firestore doc written |

## Migration Plan

1. Deploy Firestore and Storage security rules to Firebase console before integration testing on device.
2. Implement repositories and UI behind existing tab shell — no navigation structure change.
3. Phase 4 replaces feed query only; no data migration required.

## Open Questions

None — all product decisions resolved in explore session.
