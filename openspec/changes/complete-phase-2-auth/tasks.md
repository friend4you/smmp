## 1. Auth service layer

- [ ] 1.1 Refactor `AuthServiceProtocol` to async/await: `login`, `register`, `signOut`, `sendPasswordReset`, `updateDisplayName`, `deleteCurrentUser` (for rollback)
- [ ] 1.2 Implement methods in `AuthService` with Firebase callback wrapping
- [ ] 1.3 Add `AuthErrorMapper` for user-readable Firebase error messages
- [ ] 1.4 Refactor `AuthRepository` to use `AuthServiceProtocol`, pure async API, and `register(displayName:email:password:)` signature

## 2. Firestore user bootstrap

- [ ] 2.1 Add `UserBootstrapService` (or `ProfileRepository.createProfile`) to write `users/{uid}` with displayName, email, bio, counts, createdAt
- [ ] 2.2 Wire bootstrap into `AuthRepository.register` after Auth account + displayName update
- [ ] 2.3 On Firestore failure: call `deleteCurrentUser` and throw mapped error
- [ ] 2.4 Add `email` field to `User` model if needed for local cache mapping

## 3. Login screen

- [x] 3.1 Replace password `TextField` with `SecureField`; add keyboard/content-type modifiers
- [x] 3.2 Implement email/password validation in `LoginViewModel` (compute flags on submit or on change)
- [x] 3.3 Add `isSubmitting` loading state; disable Login button while in flight
- [x] 3.4 Show error alert bound to `shouldShowErrorMessage` / `errorMessage`
- [x] 3.5 Add NavigationLink to Forgot Password screen
- [x] 3.6 Remove or hide Google/Apple decorative icons

## 4. Register screen

- [ ] 4.1 Add display name field
- [ ] 4.2 Use `SecureField` for password fields
- [ ] 4.3 Validate display name non-empty, email format, password min length, repeat-password match
- [ ] 4.4 Add password strength indicator (weak / ok / strong)
- [ ] 4.5 Add `isSubmitting`, error alert, and mapped error messages in `RegistrationViewModel`

## 5. Forgot password

- [ ] 5.1 Create `ForgotPasswordViewModel` with email validation and `sendPasswordReset`
- [ ] 5.2 Create `ForgotPasswordView` with email field, submit, success/error feedback
- [ ] 5.3 Wire navigation from `LoginView`

## 6. Session, splash, and sign-out

- [ ] 6.1 Create `SplashView` (logo) and use in `RootView` during `isResolvingSession`
- [ ] 6.2 Add `AuthRepository.signOut()` and wire `ProfileView` logout through it (remove direct Firebase call)
- [ ] 6.3 Verify session persistence on cold start still routes correctly

## 7. Unit tests

- [ ] 7.1 Add `MockAuthService` conforming to `AuthServiceProtocol`
- [ ] 7.2 Tests: `LoginViewModel` — invalid email blocks auth call; auth failure sets error
- [ ] 7.3 Tests: `RegistrationViewModel` — password mismatch blocks auth call; success path calls register with displayName
- [ ] 7.4 Tests: `SessionService` or auth-state transition (optional lightweight test)

## 8. README progress tracker

- [ ] 8.1 Update Phase 2 checklist in README.md to reflect completed items after implementation
