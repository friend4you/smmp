# Social Media Mini-Platform (SMMP)

iOS application — a miniature social network with authentication, a real-time feed, profiles, user search, a follow graph, and offline support.

Built to demonstrate production-style mobile engineering: layered MVVM architecture, coordinator-based navigation, Firebase backend integration, CoreData offline caching, reactive connectivity handling, localization, and broad unit test coverage.

**Stack:** Swift 6 · SwiftUI · Firebase (Auth, Firestore, Storage) · CoreData · async/await

---

## Features

- **Authentication** — Email/password sign-in and registration, password reset, session persistence
- **Feed** — Follow-scoped chronological feed with real-time updates, pull-to-refresh, pagination, like/unlike
- **Posts** — Create posts with text and images (client-side resize before upload); view post detail with comments
- **Profiles** — View and edit profile (display name, bio, photo); follower/following counts
- **Discovery** — Debounced user search with inline follow/unfollow
- **Offline mode** — Browse cached feed and profiles without connectivity

---

## Screenshots

<p align="center">
  <img src="docs/screenshots/feed.png" width="240" alt="Feed screen" />
  <img src="docs/screenshots/create-post.png" width="240" alt="Create post screen" />
  <img src="docs/screenshots/post-detail.png" width="240" alt="Post detail screen" />
  <img src="docs/screenshots/profile.png" width="240" alt="Profile screen" />
  <img src="docs/screenshots/search.png" width="240" alt="Search screen" />
</p>

---

## Architecture

The app follows **MVVM** with clean layers: Views → ViewModels → Repositories → Services / Persistence.

**Navigation** uses a coordinator–router–builder pattern: session-driven root flow (`AppCoordinator`), per-tab navigation stacks, and protocol-based routing for testability.

**Data flow:** Repositories own Firestore listeners and CoreData writes. Reads serve from the network when online and fall back to cache offline. Writes go to Firestore; the real-time listener keeps the local cache in sync.

**Dependency injection:** `AppDependencies` is created at app launch and passed into coordinators and view builders. ViewModels receive services through initializers, making mocks straightforward in tests.

---
