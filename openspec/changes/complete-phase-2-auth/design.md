## Context

Phase 2 has a working auth spine (`AuthService` → `AuthRepository` → ViewModels → `SessionService` → `RootView`), but UI validation, error handling, forgot password, architectural sign-out, Firestore user bootstrap, and tests are incomplete. The README Firestore schema defines `users/{uid}` but registration only creates a Firebase Auth account today. Phase 3 feed work depends on author profiles existing in Firestore.

Stack: SwiftUI, Firebase Auth + Firestore, CoreData local cache, MVVM + Repository layers, `AppDependencies` DI.

## Goals / Non-Goals

**Goals:**

- Complete Phase 2 to match README sections 1.1 (auth subset) and 2.2 (login/register/forgot password)
- Bootstrap `users/{uid}` on registration with `email` field for future search (display name + email, Phase 4)
- Roll back Firebase Auth user if Firestore bootstrap fails (user decision)
- Pure `async throws` auth API; user-friendly errors; unit tests
- Minimal splash during session resolution

**Non-Goals:**

- Social sign-in (Google/Apple) — hide decorative icons
- Account deletion — Settings / Phase 6
- Search implementation — Phase 4 (email uniqueness noted in spec only)
- Feed, posts, offline banners — Phase 3+

## Decisions

### 1. Keep CoreData cache on sign-out

**Decision:** Do not wipe CoreData when the user signs out.

**How it works:**

```
┌──────────────────────────────────────────────────────────────┐
│                    SIGN-OUT DATA LAYERS                       │
└──────────────────────────────────────────────────────────────┘

  Firebase Auth          SessionService           CoreData
  ─────────────          ──────────────           ────────
  Token cleared    →     currentUser = nil   →    CDUser, CDPost
  (no session)           routes to Login          STILL ON DISK

  Next login (same user):
  ─────────────────────
  Auth token restored → SessionService sets currentUser
                     → Repositories can show cached data immediately
                     → Firestore listeners refresh in background (Phase 3+)

  Next login (different user — edge case):
  ───────────────────────────────────────
  New uid → LocalRepository writes new CDUser
         → Phase 3 should scope feed cache by authorId / following
         → For Phase 2, only CDUser from auth is written; low risk
```

**Rationale:** Supports Phase 5 offline mode — previously loaded content stays available after re-login without re-download. iOS apps are typically single-user devices.

**Alternative considered:** Clear all CoreData on sign-out. Rejected for now because it defeats offline reuse and adds complexity before Phase 3 defines cache invalidation rules.

### 2. Registration flow with rollback

**Decision:** Sequential steps with compensating delete on failure. Orchestrated by `AuthRepository.register(displayName:email:password:)`.

```
Register tap
    │
    ▼
AuthRepository.register(displayName:email:password:)
    │
    ├─① authService.register(displayName, email, password)
    │     └── createUser + set Auth displayName internally (not a separate protocol method)
    │
    ├─② profileRepository.createProfile(uid, displayName, email, ...)
    │
    ├── success → ③ LocalRepository.saveUser (includes email) → done
    │
    └── failure → authService.deleteCurrentUser() [concrete AuthService only] → show error
```

Firestore profile writes live on `ProfileRepository.createProfile` — the single home for `users/{uid}` document writes (registration bootstrap now; profile edits in Phase 4).

### 3. Auth API shape: async/await only

**Decision:** `AuthServiceProtocol` exposes only user-facing Firebase Auth operations. Methods return `async throws -> User` (or `Void` for signOut/reset). Wrap Firebase callbacks once inside `AuthService`. Remove completion-handler hybrid from `AuthRepository`.

**Protocol surface (Phase 2):**

| Method | Returns | Notes |
|---|---|---|
| `login(email:password:)` | `User` | |
| `register(displayName:email:password:)` | `User` | Sets Auth `displayName` inside implementation after `createUser` |
| `signOut()` | `Void` | |
| `sendPasswordReset(email:)` | `Void` | |

**Not on protocol:**

| Method | Where | Why |
|---|---|---|
| `deleteCurrentUser()` | Concrete `AuthService` only | Compensating rollback for failed Firestore bootstrap — not a user-facing auth feature |
| `updateProfile(...)` | `ProfileRepository` (Phase 4) | Firestore profile fields; Auth `displayName`/`photoURL` synced from repository when editing |

`MockAuthService` conforms to the four protocol methods only. ViewModel unit tests do not need rollback behavior.

### 4. Firestore user document fields

**Decision:** Extend README schema with `email` (string, from registration input):

| Field | Value at registration |
|---|---|
| `displayName` | From form |
| `email` | From form (unique via Firebase Auth) |
| `bio` | `""` |
| `photoURL` | `null` |
| `followerCount` | `0` |
| `followingCount` | `0` |
| `createdAt` | `FieldValue.serverTimestamp()` |

Update README Firestore table when archiving this change.

### 5. Error mapping

**Decision:** Add `AuthErrorMapper` mapping common `AuthErrorCode` values to short user-facing strings. ViewModels consume mapped messages via `@Published errorMessage`.

### 6. Splash screen

**Decision:** Replace `RootView` placeholder text with a minimal `SplashView` (logo + optional progress). Shown while `SessionService.isResolvingSession == true`.

### 7. Dependency injection for testability

**Decision:** `AuthRepository` calls `AuthServiceProtocol` for `login`, `register`, `signOut`, and `sendPasswordReset`. Inject `MockAuthService` in ViewModel tests.

For registration rollback, `AuthRepository` calls `deleteCurrentUser()` on the concrete `AuthService` instance passed at init (production DI wires `AuthService`; rollback is not part of the mockable protocol contract).

### 8. Local `User` model includes `email`

**Decision:** Add `email` to the `User` struct and `CDUser` CoreData entity. Populated at registration and cached locally alongside `displayName`, `bio`, and `photoURL`.

**Rationale:** Firestore bootstrap stores `email` for Phase 4 search; caching it locally avoids an extra fetch for profile display and keeps the local model aligned with the remote document.

### 9. Profile editing deferred to Phase 4

**Decision:** `updateProfile` is **not** part of `AuthServiceProtocol` or Phase 2 scope. Phase 4 adds `ProfileRepository.updateProfile(...) -> User` for Edit Profile (README 2.7).

**Future shape (Phase 4, not implemented now):**

- Firestore fields (`bio`, etc.) written via `ProfileRepository`
- `displayName` and `photoURL` updates sync to **both** Firebase Auth and Firestore to keep data consistent
- Additional fields (gender, birth date, etc.) and a `UserProfilePatch` struct are deferred until Edit Profile is scoped

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Orphaned Auth user if delete-after-Firestore-failure also fails | Log error; rare; user can retry register (email still in use would indicate orphan — manual cleanup) |
| Stale CoreData from previous user on shared device | Accept for portfolio; Phase 3+ can scope queries by current uid |
| Firestore write requires network at registration | Show clear error; registration cannot complete offline (acceptable) |
| README schema missing `email` field | Update README in same change or at archive |

## Migration Plan

No production migration. Existing Auth-only users (if any test accounts exist) lack Firestore docs — manually create or re-register. No data migration needed for CoreData.

## Open Questions

- None blocking Phase 2 implementation.
- Phase 4: `ProfileRepository.updateProfile` API shape (`UserProfilePatch` vs optional parameters) and additional Firestore fields (gender, birth date) to be decided when Edit Profile is scoped.
