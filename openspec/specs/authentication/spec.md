## Purpose

Email/password authentication, session routing, forgot-password flow, and a testable auth service layer for the smmp iOS app.

## Requirements

### Requirement: User can log in with email and password

The system SHALL allow an authenticated user to sign in using a valid email and password. Invalid input MUST be rejected before any network call. Firebase errors MUST be shown as user-readable messages.

#### Scenario: Successful login

- **WHEN** the user enters a valid email and password and taps Login
- **THEN** the system authenticates via Firebase Auth, caches the user in CoreData, and routes to the main app

#### Scenario: Invalid email format

- **WHEN** the user enters a malformed email and taps Login
- **THEN** the system shows an inline validation error and does not call Firebase

#### Scenario: Wrong credentials

- **WHEN** Firebase Auth returns an invalid-credential error
- **THEN** the system shows a user-readable error alert (not raw Firebase text)

### Requirement: User can register with display name, email, and password

The system SHALL allow a new user to register with display name, email, password, and password confirmation. Password strength MUST be indicated visually. Mismatched passwords MUST be rejected before any network call.

#### Scenario: Successful registration

- **WHEN** the user provides a valid display name, email, matching strong-enough passwords, and taps Register
- **THEN** the system calls `AuthService.register(displayName:email:password:)` (which creates the Auth account and sets `displayName` internally), bootstraps the Firestore user document via `ProfileRepository.createProfile`, caches locally including `email`, and routes to the main app

#### Scenario: Password mismatch

- **WHEN** password and repeat-password fields differ
- **THEN** the system shows a validation error and does not call Firebase

#### Scenario: Email already in use

- **WHEN** Firebase Auth returns an email-already-in-use error
- **THEN** the system shows a user-readable error alert

### Requirement: User can reset password via email

The system SHALL allow a user to request a password-reset email from the Login screen.

#### Scenario: Reset email sent

- **WHEN** the user enters a registered email on the Forgot Password screen and submits
- **THEN** the system calls Firebase `sendPasswordReset` and shows a success confirmation

#### Scenario: Invalid reset email

- **WHEN** the user enters a malformed email on the Forgot Password screen
- **THEN** the system shows a validation error and does not call Firebase

### Requirement: User can sign out

The system SHALL allow the authenticated user to sign out through the auth repository layer, not by calling Firebase directly from a view.

#### Scenario: Sign out from profile

- **WHEN** the user taps Logout on the Profile screen
- **THEN** the system signs out via `AuthRepository`, clears the session, and routes to Login
- **AND** CoreData cached content from the previous session remains on disk for offline reuse

### Requirement: Session persists across app launches

The system SHALL restore an authenticated session on cold start when a valid Firebase Auth token exists, and show a splash screen while resolving.

#### Scenario: Returning authenticated user

- **WHEN** the app launches and Firebase Auth has a valid session
- **THEN** the system shows a splash screen during resolution, then routes directly to the main app

#### Scenario: No session

- **WHEN** the app launches with no Firebase Auth session
- **THEN** the system routes to Login after session resolution completes

### Requirement: Auth service exposes a testable protocol

The system SHALL define `AuthServiceProtocol` with `async throws` methods: `login(email:password:)`, `register(displayName:email:password:)`, `signOut()`, and `sendPasswordReset(email:)`. Compensating `deleteCurrentUser()` and profile editing (`updateProfile`) are out of scope for the protocol — rollback uses concrete `AuthService`; profile edits are Phase 4 `ProfileRepository`.

### Requirement: Auth layer is unit tested

The system SHALL include unit tests for login and registration ViewModels and session state transitions using a mock `AuthServiceProtocol` (four methods only).

#### Scenario: LoginViewModel validation test

- **WHEN** login is attempted with an invalid email
- **THEN** the test verifies no auth call is made and an error state is published

#### Scenario: RegistrationViewModel mismatch test

- **WHEN** register is attempted with mismatched passwords
- **THEN** the test verifies no auth call is made
