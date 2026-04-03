# 📱 Social Media Mini-Platform — iOS

> A portfolio-grade iOS application demonstrating real-time social interactions, media handling, offline caching, and fluid animations — built with Swift, SwiftUI, CoreData, and Firebase.

---

## Table of Contents

1. [User Requirements](#1-user-requirements)
2. [Screens & Functionality](#2-screens--functionality)
3. [Architecture](#3-architecture)
4. [Development Plan](#4-development-plan)
5. [Progress Tracker](#5-progress-tracker)

---

## 1. User Requirements

This section describes the platform from the user's perspective — what a person can do when they open the app.

### 1.1 Account & Identity

- A user can **register** a new account using email and password.
- A user can **log in** and **log out** securely.
- A user can **view and edit** their profile: display name, bio, and profile photo.
- A user can **delete** their account and all associated data.

### 1.2 Feed & Content

- A user can **view a chronological feed** of posts from people they follow, as well as their own posts.
- A user can **create a new post** containing text and/or an image.
- A user can **delete their own post**.
- A user can **like** and **unlike** any post in the feed.
- A user can **comment** on a post and **delete their own comments**.
- The feed **updates in real time** when people they follow publish new content.

### 1.3 Discovery & Social Graph

- A user can **search for other users** by display name or username.
- A user can **visit any public profile** to see that person's posts, follower count, and following count.
- A user can **follow** or **unfollow** another user.
- A user can **view their own followers list** and **following list**.

### 1.4 Media

- A user can **upload a photo** from the device camera roll when creating a post or updating their profile picture.
- Images are displayed with **efficient cached loading** — no repeated downloads on revisit.

### 1.5 Offline Mode

- A user can **browse previously loaded content** (feed, profiles, posts) without an active internet connection.
- A user receives a **clear visual indicator** when the app is running in offline mode.
- Actions that require connectivity (posting, liking, commenting) are **gracefully disabled** offline, with an informative prompt.

---

## 2. Screens & Functionality

### 2.1 Splash / Launch Screen

- App logo animation on startup.
- Automatically routes to **Login** if no session exists, or **Feed** if the user is already authenticated.

### 2.2 Authentication Screens

**Login Screen**
- Email and password fields with inline validation.
- "Forgot password" flow (email reset link).
- Navigation to Register.

**Register Screen**
- Display name, email, and password fields.
- Password strength indicator.
- Account creation triggers profile setup.

### 2.3 Main Feed Screen

- Vertical scrolling list of post cards (infinite scroll / pagination).
- Each post card shows: author avatar, display name, timestamp, post text, optional image, like count, comment count, and a like toggle button.
- Pull-to-refresh for manual update.
- Real-time listener appends new posts at the top with an animated "New posts" banner.
- Offline banner displayed at the top when connectivity is lost.

### 2.4 Create Post Screen

- Multi-line text input (character counter, 280-character limit).
- Image picker integration (photo library and camera).
- Image preview with remove option.
- Post button disabled while empty or uploading.
- Upload progress indicator for images.

### 2.5 Post Detail Screen

- Full post view with larger image.
- Comments section with chronological list.
- Inline comment composer pinned to the keyboard.
- Like button with animated heart icon.

### 2.6 User Profile Screen

- Header: profile photo, display name, bio, follower/following counts.
- Follow / Unfollow button (hidden on own profile).
- Grid or list toggle for the user's posts.
- Tapping a post navigates to Post Detail.

### 2.7 Edit Profile Screen

- Change display name, bio, and profile photo.
- Save/discard confirmation flow.

### 2.8 Search / Discovery Screen

- Search bar with debounced query.
- Results list showing avatar, name, and a quick Follow button.
- Empty state and no-results illustrations.

### 2.9 Followers / Following Screen

- Flat list of user cards.
- Follow/Unfollow toggle on each row (for the following list).

### 2.10 Notifications Screen *(stretch goal)*

- Activity feed: new followers, likes, and comments on the user's posts.
- Push notification deep-links to the relevant post or profile.

### 2.11 Settings Screen

- Log out.
- Delete account (confirmation alert).
- Toggle for push notifications *(stretch goal)*.

---

## 3. Architecture

### 3.1 Why MVVM + Clean Layers?

The project follows **MVVM (Model–View–ViewModel)** with a clear separation into three additional layers: **Repository**, **Service**, and **Persistence**. This choice is justified by several factors specific to this project:

- **SwiftUI is binding-native.** SwiftUI's `@StateObject`, `@ObservedObject`, and `@Published` map directly onto the ViewModel pattern. Fighting this with a different pattern (e.g., pure MVC) produces boilerplate and loses reactivity benefits.
- **Testability.** Business logic lives in ViewModels and Repositories — both plain Swift classes with no UIKit or SwiftUI imports — making them trivially unit-testable with mock services.
- **Multi-source data.** The app reads from three places simultaneously: Firebase Firestore (remote, real-time), Firebase Storage (media), and CoreData (local cache). A Repository layer acts as the single source of truth, deciding whether to serve cached or remote data and merging results transparently.
- **Scalability.** New features (e.g., Stories, DMs) slot in as new Repository + ViewModel pairs without touching existing code.

### 3.2 Layer Responsibilities

```
┌────────────────────────────────────────────────────────┐
│                      SwiftUI Views                      │  ← Render state, emit user actions
├────────────────────────────────────────────────────────┤
│                      ViewModels                         │  ← Transform data, drive UI state
├────────────────────────────────────────────────────────┤
│                      Repositories                       │  ← Coordinate remote + local data
├──────────────────────┬─────────────────────────────────┤
│   Firebase Services  │      CoreData Persistence        │  ← External / local data sources
│  (Auth, Firestore,   │  (FeedCache, UserCache,          │
│   Storage)           │   PostCache)                     │
└──────────────────────┴─────────────────────────────────┘
```

### 3.3 Data Models

#### Remote (Firestore Schema)

| Collection | Document Fields |
|---|---|
| `users/{uid}` | `displayName`, `bio`, `photoURL`, `followerCount`, `followingCount`, `createdAt` |
| `users/{uid}/following/{fid}` | `followedAt` |
| `posts/{pid}` | `authorId`, `text`, `imageURL`, `likeCount`, `commentCount`, `createdAt` |
| `posts/{pid}/likes/{uid}` | `likedAt` |
| `posts/{pid}/comments/{cid}` | `authorId`, `text`, `createdAt` |

#### Local (CoreData Entities)

| Entity | Attributes | Purpose |
|---|---|---|
| `CDUser` | `uid`, `displayName`, `bio`, `photoURL`, `cachedAt` | Profile offline cache |
| `CDPost` | `pid`, `authorId`, `text`, `imageURL`, `likeCount`, `createdAt`, `cachedAt` | Feed offline cache |
| `CDComment` | `cid`, `postId`, `authorId`, `text`, `createdAt` | Comment offline cache |

CoreData entities mirror the Firestore schema fields that the UI actually renders. Fields used only for server-side logic (e.g., sub-collection counts managed by Cloud Functions) are not persisted locally.

### 3.4 Data Flow

**Online path (read):**
1. ViewModel calls Repository method (e.g., `fetchFeed()`).
2. Repository opens a Firestore real-time listener.
3. On snapshot arrival, Repository maps Firestore documents → Swift model structs.
4. Repository writes/updates CoreData cache in a background context.
5. Repository publishes updated array via a `CurrentValueSubject`.
6. ViewModel receives the published value and updates `@Published` properties.
7. SwiftUI View re-renders automatically.

**Offline path (read):**
1. `NetworkMonitor` (wrapping `NWPathMonitor`) publishes `isConnected = false`.
2. Repository skips Firestore listener; fetches from CoreData using an `NSFetchRequest`.
3. Remainder of the flow is identical from step 5 onwards.

**Write path:**
1. ViewModel calls Repository write method (e.g., `likePost(pid:)`).
2. Repository writes to Firestore directly.
3. On success, the existing real-time listener fires and updates the local cache automatically (no manual cache invalidation needed).
4. On failure, ViewModel surfaces an error alert.

### 3.5 Image Strategy

- **Upload:** Images are resized client-side to a maximum of 1080px on the long edge before upload, using `UIGraphicsImageRenderer`. This keeps Storage costs low and upload speeds fast.
- **Download & Caching:** `SDWebImageSwiftUI` (or `Kingfisher`) handles async image loading with a two-tier cache (in-memory LRU + disk). URLs stored in Firestore are CDN-backed Firebase Storage links with long-lived tokens.

### 3.6 Real-Time Strategy

Firestore `addSnapshotListener` is attached at the Repository level, not in Views. Listeners are stored in a `ListenerRegistration` dictionary keyed by scope (e.g., `"feed"`, `"post-\(pid)"`). On sign-out all listeners are removed to prevent data leaks.

### 3.7 Dependency Injection

A lightweight `AppDependencies` container is instantiated at app entry and injected into the root View via SwiftUI's `.environmentObject`. ViewModels receive concrete service instances through their initializers, making them swappable with mocks during testing.

---

## 4. Development Plan

The plan is broken into **6 phases**, each delivering a working vertical slice. Each phase ends with a testable build.

### Phase 1 — Project Foundation

1. Create Xcode project with SwiftUI lifecycle.
2. Add Swift Package dependencies: Firebase SDK, SDWebImageSwiftUI.
3. Configure Firebase project (Authentication, Firestore, Storage).
4. Set up folder structure: `Models/`, `ViewModels/`, `Views/`, `Repositories/`, `Services/`, `Persistence/`, `Utilities/`.
5. Define all Swift model structs (`User`, `Post`, `Comment`).
6. Implement `AppDependencies` container and root environment injection.
7. Configure `CoreData` model (`.xcdatamodeld`) with all entities and attributes.
8. Implement `PersistenceController` (singleton with background context for writes).
9. Implement `NetworkMonitor` using `NWPathMonitor`.
10. Write unit tests for model parsing.

### Phase 2 — Authentication

1. Build Login screen (email/password fields, validation, error alerts).
2. Build Register screen (display name, email, password, strength indicator).
3. Implement `AuthService` wrapping `Firebase Auth` (sign-in, register, sign-out, password reset).
4. Implement `AuthRepository` publishing `currentUser` state.
5. Implement `AuthViewModel` driving both screens.
6. Add session persistence: app re-opens to Feed if already logged in.
7. Write unit tests for `AuthViewModel` with a mock `AuthService`.

### Phase 3 — Feed & Posts

1. Implement `PostRepository` with Firestore listener, CoreData write, and offline fallback.
2. Build `FeedViewModel` (pagination, refresh, real-time append).
3. Build `PostCardView` (avatar, name, text, image, like button, comment count).
4. Build `FeedScreen` with `LazyVStack`, pull-to-refresh, offline banner, and "New posts" banner.
5. Implement like/unlike toggle (optimistic UI update with rollback on error).
6. Build `CreatePostScreen` (text input, image picker, upload progress, character counter).
7. Implement image upload to Firebase Storage via `MediaService`.
8. Build `PostDetailScreen` with comments list and inline comment composer.
9. Implement `CommentRepository` (fetch, add, delete).
10. Write integration tests for `PostRepository` offline path.

### Phase 4 — Profiles & Social Graph

1. Build `UserProfileScreen` (header, follow button, post grid/list toggle).
2. Implement `ProfileRepository` (fetch user, update user, follow, unfollow).
3. Build `EditProfileScreen` (fields, profile photo picker, save/discard).
4. Build `SearchScreen` (debounced search bar, results list, inline follow button).
5. Build `FollowersScreen` and `FollowingScreen`.
6. Implement `FollowRepository` (fetch lists, follow/unfollow with Firestore batch write).
7. Write unit tests for `ProfileViewModel` and `SearchViewModel`.

### Phase 5 — Polish, Animations & Offline

1. Add `matchedGeometryEffect` transitions for post card → post detail navigation.
2. Animate heart icon on like (scale + color bounce using `withAnimation`).
3. Add skeleton loading placeholders using redacted SwiftUI modifier.
4. Add smooth scroll-to-top on new-posts banner tap.
5. Add haptic feedback (like, follow, post submit).
6. Implement full offline mode: CoreData-backed all screens, disabled write actions, offline banner.
7. Audit and cap memory usage for image cache.
8. Profile app with Instruments (Time Profiler, Allocations) and fix hotspots.
9. Write UI tests for critical flows (login, post, like).

### Phase 6 — Release Prep

1. App icon and launch screen assets.
2. Add `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription` permission strings.
3. Enable Firebase Crashlytics and Analytics.
4. App Store metadata: screenshots, description, keywords.
5. Submit to TestFlight for external review.
6. Address TestFlight feedback.
7. (Optional) Submit to App Store public release.

---

## 5. Progress Tracker

Use this checklist to track implementation status. Items map 1-to-1 with the Development Plan above.

### Phase 1 — Project Foundation
- [ ] Xcode project created with SwiftUI lifecycle
- [ ] Swift Package dependencies added (Firebase, SDWebImageSwiftUI)
- [ ] Firebase project configured (Auth, Firestore, Storage)
- [ ] Folder structure set up
- [ ] Swift model structs defined (`User`, `Post`, `Comment`)
- [ ] `AppDependencies` container implemented
- [ ] CoreData model defined (all entities and attributes)
- [ ] `PersistenceController` implemented
- [ ] `NetworkMonitor` implemented
- [ ] Unit tests for model parsing written

### Phase 2 — Authentication
- [ ] Login screen built
- [ ] Register screen built
- [ ] `AuthService` implemented
- [ ] `AuthRepository` implemented
- [ ] `AuthViewModel` implemented
- [ ] Session persistence working
- [ ] Unit tests for `AuthViewModel` written

### Phase 3 — Feed & Posts
- [ ] `PostRepository` implemented (Firestore + CoreData + offline)
- [ ] `FeedViewModel` implemented
- [ ] `PostCardView` built
- [ ] `FeedScreen` built (pull-to-refresh, offline banner, new-posts banner)
- [ ] Like/unlike with optimistic UI implemented
- [ ] `CreatePostScreen` built
- [ ] Image upload via `MediaService` implemented
- [ ] `PostDetailScreen` built
- [ ] `CommentRepository` implemented
- [ ] Integration tests for offline path written

### Phase 4 — Profiles & Social Graph
- [ ] `UserProfileScreen` built
- [ ] `ProfileRepository` implemented
- [ ] `EditProfileScreen` built
- [ ] `SearchScreen` built
- [ ] `FollowersScreen` and `FollowingScreen` built
- [ ] `FollowRepository` implemented
- [ ] Unit tests for `ProfileViewModel` and `SearchViewModel` written

### Phase 5 — Polish, Animations & Offline
- [ ] `matchedGeometryEffect` transitions added
- [ ] Heart animation on like implemented
- [ ] Skeleton loading placeholders added
- [ ] Scroll-to-top on new-posts banner implemented
- [ ] Haptic feedback added
- [ ] Full offline mode implemented and verified
- [ ] Image cache memory audit done
- [ ] Instruments profiling completed and hotspots fixed
- [ ] UI tests for critical flows written

### Phase 6 — Release Prep
- [ ] App icon and launch screen assets added
- [ ] Permission usage description strings added
- [ ] Firebase Crashlytics and Analytics enabled
- [ ] App Store metadata prepared
- [ ] TestFlight build submitted
- [ ] TestFlight feedback addressed
- [ ] App Store submission (optional)

---

> **Last updated:** April 2026
