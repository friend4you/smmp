## Why

All user-facing strings are hardcoded inline across SwiftUI views, ViewModels, and utilities (~40 strings today). The Xcode project already enables String Catalogs and generated symbols, but no catalog file exists. Establishing localization now—before completing Phase 2 auth—prevents more inline strings from landing and gives `complete-phase-2-auth` a clear convention to follow.

## What Changes

- Add `smmp/Resources/Localizable.xcstrings` (English only; structure ready for future locales)
- Migrate all existing user-facing strings to semantic keys with Xcode generated symbols (e.g. `auth.login.submit` → `.authLoginSubmit`)
- Replace inline literals in views with `Text(.symbol)`, `String(localized: .symbol)`, and related generated-symbol APIs
- Consolidate duplicate copy (e.g. email validation shared by `LoginView`, `LoginViewModel`, `AuthErrorMapper`) into single catalog keys
- Document and scaffold pluralization in the catalog (e.g. `feed.comment.count`) for upcoming feed/profile features
- Add SwiftLint with a custom rule flagging hardcoded UI strings; exclude `#Preview` blocks, tests, and developer-only messages
- Keep previews on the default `en` locale; preview bodies remain lint-exempt
- Unit tests continue to assert validation **state** only, not localized message text

## Capabilities

### New Capabilities

- `localization`: String Catalog, semantic keys, generated symbols, SwiftLint enforcement, pluralization pattern, and migration of existing UI copy

### Modified Capabilities

<!-- No existing main specs yet — README is the prior source of truth -->

## Impact

- **Resources:** New `Localizable.xcstrings` in `smmp/Resources/`
- **Views:** `LoginView`, `ForgotPasswordView`, `RegistrationView`, `ContentView`, `FeedView`, `SearchView`, `NewPostView`, `ProfileView`, `RootView`
- **ViewModels:** `LoginViewModel` (localized error messages assigned via `String(localized:)`)
- **Utilities:** `AuthErrorMapper`
- **Tooling:** New `.swiftlint.yml` and SwiftLint integration (SPM plugin or build-phase script)
- **Tests:** No message-text assertions; existing validation-state tests unchanged in intent
- **Out of scope:** Translating to non-English locales, `L10n` wrapper enum, localizing CoreData entity names / NSPredicate / `fatalError` / test fixtures, Firebase `error.localizedDescription` fallbacks for unmapped errors
- **Sequencing:** This change MUST complete before `complete-phase-2-auth` so new auth strings follow the established convention from day one
