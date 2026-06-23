## Why

Phase 2 delivered authentication and Firestore user bootstrap, but the main app tabs are still placeholders. Users cannot view, create, interact with, or cache posts. Phase 3 delivers the first content vertical slice — a working global feed with text posts (optional image attachment), likes, comments, and offline read — so the app behaves like a social platform before Phase 4 adds follow-scoped feeds and profiles.

## What Changes

- Deploy Firestore security rules for `users`, `posts`, `likes`, and `comments` (replacing deny-all)
- Deploy Firebase Storage security rules for post images
- Implement `PostRepository` with global feed query, real-time listener, CoreData cache, offline fallback, create/delete post, and like/unlike with count updates
- Implement `CommentRepository` with load-on-open fetch, add/delete comment, and `commentCount` updates
- Implement `MediaService` for client-side image resize (1080px JPEG 0.8), upload with progress, and Storage delete on post delete
- Fetch `users/{authorId}` for post and comment author display; cache in CoreData via `LocalRepository`
- Build `FeedViewModel`, `PostCardView`, and `FeedScreen` (pagination, pull-to-refresh, offline banner, new-posts banner, optional post image via `AsyncImage`)
- Build `CreatePostScreen` with required text (280-character limit), optional photo-library image via `PhotosPicker`, and linear upload progress
- Build `PostDetailScreen` with comments list, inline composer, and larger post image when present
- Optimistic like toggle with rollback on error
- Cascade delete: Storage image, post document, plus `likes` and `comments` subcollections on delete
- Add localization keys for feed, post, comment, and image UI
- Add unit tests for Firestore → model parsing and integration tests for offline feed path

## Capabilities

### New Capabilities

- `feed`: Global chronological feed, pagination, real-time updates, offline read, author resolution, optional post images
- `posts`: Create, delete, like/unlike posts (text required, optional image); `PostRepository`; create-post UI with image picker
- `comments`: Load-on-open comments on post detail; add and delete own comments
- `firestore-security-rules`: Authenticated read/write rules for Phase 3 collections including count-field updates
- `storage-security-rules`: Authenticated read/write rules for post images under `posts/{postId}/`

### Modified Capabilities

<!-- No existing main specs change requirements at the spec level -->

## Impact

- **Dependencies:** Firebase Firestore, Firebase Storage (no SDWebImage — `AsyncImage` for display)
- **Repositories:** `PostRepository`, `CommentRepository`; extend `LocalRepository` for posts, comments, and user cache
- **Services:** `MediaService` (resize, upload, delete, progress); `ProfileRepository` for author lookup
- **ViewModels:** `FeedViewModel`, `CreatePostViewModel`, `PostDetailViewModel`
- **Views:** `FeedView`, `NewPostView`, `PostCardView`, `PostDetailView`
- **Models:** Firestore mapping extensions for `Post`, `Comment`, `User`; `FeedPostItem` view model
- **Persistence:** `CDPost`, `CDComment`, `CDUser` read/write paths (`imageURL` cached)
- **Firebase console:** Firestore and Storage rules deployment (manual steps in tasks)
- **Tests:** `smmpTests/` parsing, offline integration, and `MediaService` resize tests
- **Out of scope:** Follow-scoped feed (Phase 4), image-only posts, camera capture, real-time comment listeners, profile editing, search
