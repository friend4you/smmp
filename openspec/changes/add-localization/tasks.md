## 1. String Catalog setup

- [ ] 1.1 Create `smmp/Resources/` and add `Localizable.xcstrings` to the Xcode target
- [ ] 1.2 Add all semantic keys from design.md with English (`en`) values
- [ ] 1.3 Add plural scaffold `feed.comment.count` with `one` / `other` variants
- [ ] 1.4 Build the project and verify Xcode generates symbols (jump-to-definition on `.authLoginSubmit` etc.)

## 2. Utilities and ViewModels

- [ ] 2.1 Migrate `AuthErrorMapper` to `String(localized: .symbol)` for all mapped Firebase errors; share keys with validation copy where applicable
- [ ] 2.2 Migrate `LoginViewModel` validation/error messages to generated symbols (`auth.validation.*`)

## 3. Auth views

- [ ] 3.1 Migrate `LoginView` — fields, validation text, buttons, links, alert title/button
- [ ] 3.2 Migrate `ForgotPasswordView` — instructions and navigation title
- [ ] 3.3 Migrate `RegistrationView` — field prompts and register button

## 4. Shell and profile views

- [ ] 4.1 Migrate `ContentView` tab labels (`tab.*`)
- [ ] 4.2 Migrate `FeedView`, `SearchView`, `NewPostView` titles
- [ ] 4.3 Migrate `ProfileView` — user fallback, Edit, Logout
- [ ] 4.4 Migrate `RootView` session-resolving text

## 5. SwiftLint

- [ ] 5.1 Add SwiftLint to the project (SPM plugin or Run Script build phase)
- [ ] 5.2 Add `.swiftlint.yml` with standard rules and exclusions for tests
- [ ] 5.3 Add custom `hardcoded_ui_string` rule for SwiftUI/UI literals; exclude `#Preview` blocks and developer-only patterns
- [ ] 5.4 Run SwiftLint and fix any remaining violations in production sources

## 6. Verification

- [ ] 6.1 Confirm no duplicate English copy for shared messages (email validation, password required)
- [ ] 6.2 Run unit tests — validation tests assert state only, not message text
- [ ] 6.3 Build and smoke-test Login, tabs, Profile, and session splash in Simulator
- [ ] 6.4 Document in README or code comment that `complete-phase-2-auth` must use `auth.*` / `common.*` keys for new strings
