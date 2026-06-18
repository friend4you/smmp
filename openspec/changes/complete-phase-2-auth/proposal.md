## Why

Phase 2 authentication is partially implemented: login and register work, but validation, error UX, forgot password, sign-out through the auth layer, Firestore user bootstrap, and tests are missing or thin. Without a Firestore `users/{uid}` document at registration, Phase 3 (feed) and Phase 4 (profiles/search) cannot function correctly. This change completes Phase 2 to a portfolio-ready, testable vertical slice before moving to the feed.

## What Changes

- Harden Login and Register screens: `SecureField`, inline validation, loading state, user-friendly error alerts
- Add Register display name field, password strength indicator, and repeat-password check
- Add Forgot Password screen and flow
- Extend `AuthService` / `AuthRepository` with `signOut`, `sendPasswordReset`, and pure `async throws` API (remove completion-handler hybrid)
- Bootstrap Firestore `users/{uid}` on successful registration; **delete the Firebase Auth user** if the Firestore write fails
- Set Firebase Auth `displayName` on registration
- Route sign-out through `AuthRepository` (remove direct `Auth.auth().signOut()` from views)
- Add minimal Splash screen while `SessionService` resolves session
- Remove or hide decorative social-login icons (Google/Apple) until implemented
- Add `AuthErrorMapper` for readable Firebase error messages
- Add unit tests for `LoginViewModel`, `RegistrationViewModel`, and `SessionService`
- Keep CoreData cache on sign-out (see design.md) — data remains for offline reuse on next login

## Capabilities

### New Capabilities

- `authentication`: Login, register, sign-out, forgot password, form validation, session routing, and auth-layer tests
- `user-profile-bootstrap`: Firestore user document creation on registration with Auth rollback on failure

### Modified Capabilities

<!-- No existing main specs yet — README is the prior source of truth -->

## Impact

- **Services:** `AuthService`, `AuthServiceProtocol`, new `AuthErrorMapper`
- **Repositories:** `AuthRepository`, `AuthRepositoryProtocol`; minimal Firestore write in registration path (via `ProfileRepository` or dedicated bootstrap helper)
- **ViewModels:** `LoginViewModel`, `RegistrationViewModel`, new `ForgotPasswordViewModel`
- **Views:** `LoginView`, `RegistrationView`, new `ForgotPasswordView`, `SplashView`, `RootView`, `ProfileView`
- **Tests:** New unit tests in `smmpTests/`
- **Out of scope:** Social sign-in, account deletion, search (Phase 4 — search by display name and email noted for future)
