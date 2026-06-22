## 1. Auth service layer

- [x] 1.1 Refactor `AuthServiceProtocol` to async/await: `login`, `register(displayName:email:password:)`, `signOut`, `sendPasswordReset` — no `updateDisplayName`, `deleteCurrentUser`, or `updateProfile` on protocol
- [x] 1.2 Implement protocol methods in `AuthService` with Firebase callback wrapping; `register` sets Auth `displayName` internally after `createUser`; add concrete-only `deleteCurrentUser()` for rollback
- [x] 1.3 Add `AuthErrorMapper` for user-readable Firebase error messages
- [x] 1.4 Refactor `AuthRepository` to use `AuthServiceProtocol` for auth ops, pure async API, and `register(displayName:email:password:)` signature; use concrete `AuthService` for rollback delete

## 2. Firestore user bootstrap

- [x] 2.1 Add `ProfileRepository.createProfile` to write `users/{uid}` with displayName, email, bio, counts, createdAt
- [x] 2.2 Wire bootstrap into `AuthRepository.register` after `authService.register` succeeds (displayName is set inside that call)
- [x] 2.3 On Firestore failure: call concrete `AuthService.deleteCurrentUser()` and throw mapped error
- [x] 2.4 Add `email` field to `User` model and `CDUser` for local cache at registration

## 3. Login screen

- [x] 3.1 Replace password `TextField` with `SecureField`; add keyboard/content-type modifiers
- [x] 3.2 Implement email/password validation in `LoginViewModel` (compute flags on submit or on change)
- [x] 3.3 Add `isSubmitting` loading state; disable Login button while in flight
- [x] 3.4 Show error alert bound to `shouldShowErrorMessage` / `errorMessage`
- [x] 3.5 Add NavigationLink to Forgot Password screen
- [x] 3.6 Remove or hide Google/Apple decorative icons

## 4. Register screen

- [x] 4.1 Add display name field
- [x] 4.2 Use `SecureField` for password fields
- [x] 4.3 Validate display name non-empty, email format, password min length, repeat-password match
- [x] 4.4 Add password strength indicator (weak / ok / strong)
- [x] 4.5 Add `isSubmitting`, error alert, and mapped error messages in `RegistrationViewModel`

## 5. Forgot password

- [x] 5.1 Create `ForgotPasswordViewModel` with email validation and `sendPasswordReset`
- [x] 5.2 Create `ForgotPasswordView` with email field, submit, success/error feedback
- [x] 5.3 Wire navigation from `LoginView`

## 6. Session, splash, and sign-out

- [x] 6.1 Create `SplashView` (logo) and use in `RootView` during `isResolvingSession`
- [x] 6.2 Add `AuthRepository.signOut()` and wire `ProfileView` logout through it (remove direct Firebase call)
- [x] 6.3 Verify session persistence on cold start still routes correctly

## 7. Unit tests

- [x] 7.1 Add `MockAuthService` conforming to `AuthServiceProtocol`
- [x] 7.2 Tests: `LoginViewModel` — invalid email blocks auth call; auth failure sets error
- [x] 7.3 Tests: `RegistrationViewModel` — password mismatch blocks auth call; success path calls register with displayName
- [x] 7.4 Tests: `SessionService` or auth-state transition (optional lightweight test)

## 8. README progress tracker

- [x] 8.1 Update Phase 2 checklist in README.md to reflect completed items after implementation
