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

**Decision:** Sequential steps with compensating delete on failure.

```
Register tap
    │
    ▼
① Firebase Auth createUser(email, password)
    │
    ▼
② Auth profile update: displayName
    │
    ▼
③ Firestore setData users/{uid}
    │
    ├── success → ④ LocalRepository.saveUser → done
    │
    └── failure → delete Firebase Auth user → show error
```

Implement in `AuthRepository.register(displayName:email:password:)` coordinating `AuthService` + a new `UserBootstrapService` (or minimal method on `ProfileRepository`).

### 3. Auth API shape: async/await only

**Decision:** `AuthServiceProtocol` methods return `async throws -> User` (or `Void` for signOut/reset). Wrap Firebase callbacks once inside `AuthService`. Remove completion-handler hybrid from `AuthRepository`.

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

**Decision:** Change `AuthRepository` to depend on `AuthServiceProtocol`, not concrete `AuthService`. Inject mock in tests.

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

- None blocking implementation. Search by display name + email is deferred to Phase 4 per user decision.
