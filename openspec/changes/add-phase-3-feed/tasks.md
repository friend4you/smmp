## 1. Firestore security rules

- [x] 1.1 Add `firebase/firestore.rules` with Phase 3 rules (users read, post CRUD, likes, comments, count-field updates)
- [x] 1.2 Deploy rules to Firebase console and verify authenticated read/write on device

## 2. Models and mapping

- [x] 2.1 Add Firestore document mappers for `Post` and `Comment` (`Timestamp` → `Date`, null-safe fields)
- [x] 2.2 Add `FeedPostItem` (or equivalent) combining `Post`, author `User`, and `isLikedByCurrentUser`
- [x] 2.3 Add unit tests for Post and Comment Firestore parsing (valid doc, null text, missing optional fields)

## 3. Local persistence extensions

- [x] 3.1 Extend `LocalRepository` with `savePost`, `fetchPosts` (sorted by `createdAt` desc), and upsert helpers for feed cache
- [x] 3.2 Extend `LocalRepository` with `saveComment`, `fetchComments(postId:)` for comment cache
- [x] 3.3 Add `fetchUser(id:)` read-from-cache helper; reuse existing `saveUser` for author cache

## 4. User fetch for authors

- [x] 4.1 Add `ProfileRepository.fetchUser(id:)` (or dedicated `UserRepository`) — Firestore read `users/{id}` → `User`, cache via `LocalRepository`
- [x] 4.2 Deduplicate in-flight fetches per `authorId` to avoid N+1 on fast scroll

## 5. PostRepository

- [x] 5.1 Define `PostRepositoryProtocol` with feed publisher, pagination, create, delete, like/unlike APIs
- [x] 5.2 Implement global feed query: `orderBy createdAt desc`, cursor pagination, dedupe by post id
- [x] 5.3 Attach Firestore snapshot listener keyed `"feed"`; write snapshots to CoreData; publish via `CurrentValueSubject`
- [x] 5.4 Implement offline path: skip listener, load from CoreData when `NetworkMonitor.isConnected == false`
- [x] 5.5 Implement `createPost(text:)` — text-only, 280 char max, `authorId == currentUid`, server timestamp
- [x] 5.6 Implement cascade `deletePost(id:)` — delete likes subcollection, comments subcollection, then post doc (paginate if >500 ops)
- [x] 5.7 Implement `likePost` / `unlikePost` — batch like doc write/delete + `FieldValue.increment` on `likeCount`
- [x] 5.8 Implement liked-state resolution for current user (`likes/{uid}` existence check on feed load)
- [x] 5.9 Implement `removeAllListeners()` and wire to sign-out path

## 6. CommentRepository

- [ ] 6.1 Define `CommentRepositoryProtocol` with fetch, add, delete APIs
- [ ] 6.2 Implement `fetchComments(postId:)` — one-time Firestore query, order by `createdAt` asc, cache to CoreData
- [ ] 6.3 Implement `addComment(postId:text:)` — batch comment create + `commentCount` increment
- [ ] 6.4 Implement `deleteComment(postId:commentId:)` — batch comment delete + `commentCount` decrement (author guard)

## 7. Feed ViewModel and UI

- [ ] 7.1 Create `FeedViewModel` — subscribe to `PostRepository`, pagination, pull-to-refresh, new-posts banner state
- [ ] 7.2 Resolve authors per feed page via `ProfileRepository` + `LocalRepository` cache
- [ ] 7.3 Build `PostCardView` — avatar, name, timestamp, text, like button, counts (text-only, no image yet)
- [ ] 7.4 Replace `FeedView` placeholder — `LazyVStack`, offline banner from `NetworkMonitor`, pull-to-refresh, empty state
- [ ] 7.5 Wire optimistic like toggle with rollback on error in `FeedViewModel`
- [ ] 7.6 Wire navigation: post card tap → `PostDetailView` push
- [ ] 7.7 Inject dependencies via `AppDependencies` / environment into `FeedView`

## 8. Create Post

- [ ] 8.1 Create `CreatePostViewModel` — text validation (non-empty, 280 max), `isSubmitting`, error handling
- [ ] 8.2 Flesh out `NewPostView` — multiline text, character counter, submit disabled when invalid or submitting
- [ ] 8.3 Wire `CreatePostViewModel` to `PostRepository.createPost` and dismiss/refresh feed on success

## 9. Post Detail and comments

- [ ] 9.1 Create `PostDetailViewModel` — load post, fetch comments on appear, pull-to-refresh comments
- [ ] 9.2 Build `PostDetailView` — full post, comments list, inline comment composer, delete own comment
- [ ] 9.3 Resolve comment authors via user fetch + cache
- [ ] 9.4 Add delete-post action for post author (with confirmation alert)

## 10. Localization

- [ ] 10.1 Add `feed.*`, `post.*`, `comment.*` keys to `Localizable.xcstrings` (empty state, banners, validation, errors, delete confirm)
- [ ] 10.2 Use generated localization symbols in all new views and ViewModels

## 11. Tests

- [ ] 11.1 Unit tests: Post and Comment Firestore mapping (from task 2.3)
- [ ] 11.2 Integration test: `PostRepository` offline fallback returns CoreData-cached posts when network is unavailable
- [ ] 11.3 Unit tests: `FeedViewModel` optimistic like rollback on repository error (optional if timeboxed)

## 12. README progress tracker

- [ ] 12.1 Update Phase 3 checklist in README.md as tasks complete (text-only items; leave image/Storage items unchecked)
