## Why

Phase 2 delivered authentication and Firestore user bootstrap, but the main app tabs are still placeholders. Users cannot view, create, interact with, or cache posts. Phase 3 delivers the first content vertical slice — a working global feed with text posts, likes, comments, and offline read — so the app behaves like a social platform before Phase 4 adds follow-scoped feeds and profiles.

## What Changes

- Deploy Firestore security rules for `users`, `posts`, `likes`, and `comments` (replacing deny-all)
- Implement `PostRepository` with global feed query, real-time listener, CoreData cache, offline fallback, create/delete post, and like/unlike with count updates
- Implement `CommentRepository` with load-on-open fetch, add/delete comment, and `commentCount` updates
- Fetch `users/{authorId}` for post and comment author display; cache in CoreData via `LocalRepository`
- Build `FeedViewModel`, `PostCardView`, and `FeedScreen` (pagination, pull-to-refresh, offline banner, new-posts banner)
- Build `CreatePostScreen` for text-only posts (280-character limit); image upload deferred
- Build `PostDetailScreen` with comments list and inline composer (push navigation from feed card)
- Optimistic like toggle with rollback on error
- Cascade delete: post document plus `likes` and `comments` subcollections on delete
- Add localization keys for feed, post, and comment UI
- Add unit tests for Firestore → model parsing and integration tests for offline feed path
- **Deferred to follow-up:** Firebase Storage, `MediaService` image upload, SDWebImageSwiftUI on cards

## Capabilities

### New Capabilities

- `feed`: Global chronological feed, pagination, real-time updates, offline read, author resolution
- `posts`: Create, delete, like/unlike text posts; `PostRepository`; create-post UI
- `comments`: Load-on-open comments on post detail; add and delete own comments
- `firestore-security-rules`: Authenticated read/write rules for Phase 3 collections including count-field updates

### Modified Capabilities

<!-- No existing main specs change requirements at the spec level -->

## Impact

- **Dependencies:** Firestore only for this change (Storage + SDWebImage deferred)
- **Repositories:** `PostRepository`, `CommentRepository`; extend `LocalRepository` for posts, comments, and user cache
- **Services:** `ProfileRepository` or shared user-fetch helper for author lookup (minimal read API)
- **ViewModels:** `FeedViewModel`, `CreatePostViewModel`, `PostDetailViewModel`
- **Views:** `FeedView`, `NewPostView`, new `PostCardView`, `PostDetailView`
- **Models:** Firestore mapping extensions for `Post`, `Comment`, `User`; optional `FeedPostItem` view model
- **Persistence:** `CDPost`, `CDComment`, `CDUser` read/write paths
- **Firebase console:** Security rules deployment (manual step documented in tasks)
- **Tests:** `smmpTests/` parsing and offline integration tests
- **Out of scope:** Follow-scoped feed (Phase 4), image posts, real-time comment listeners, profile editing, search
