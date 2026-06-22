## Purpose

User-facing copy is centralized in a String Catalog with semantic keys and Xcode-generated symbols. SwiftLint enforces the convention in production sources.

## Requirements

### Requirement: User-facing strings live in a String Catalog

The system SHALL store all user-facing copy in a single `Localizable.xcstrings` file under `smmp/Resources/`. Keys MUST use semantic dot-notation grouped by feature (e.g. `auth.login.submit`, `tab.home`, `common.ok`). English (`en`) is the only required locale for this change; the catalog structure MUST support adding locales later without code changes.

#### Scenario: New UI string added

- **WHEN** a developer adds user-facing copy to the app
- **THEN** the copy is defined in `Localizable.xcstrings` under a semantic key
- **AND** code references the generated symbol, not a string literal

#### Scenario: Duplicate copy consolidated

- **WHEN** the same message appears in multiple layers (e.g. view, ViewModel, error mapper)
- **THEN** all call sites reference a single catalog key

### Requirement: Code uses generated localization symbols

The system SHALL use Xcode generated symbols (`STRING_CATALOG_GENERATE_SYMBOLS = YES`) for all localized strings. SwiftUI views MUST use generated symbols (e.g. `Text(.authLoginSubmit)`). Non-SwiftUI code MUST use `String(localized: .authValidationEmailInvalid)`. The system MUST NOT introduce a custom `L10n` wrapper enum.

#### Scenario: SwiftUI label

- **WHEN** a view displays a static label such as a tab title or button
- **THEN** the view uses a generated symbol (e.g. `Label(.tabHome, systemImage: "house")`)

#### Scenario: ViewModel error message

- **WHEN** a ViewModel sets an error message shown in an alert
- **THEN** it assigns `String(localized: .<symbol>)` using the same catalog key as related UI validation copy

#### Scenario: Auth error mapping

- **WHEN** `AuthErrorMapper` maps a known Firebase Auth error code
- **THEN** it returns `String(localized: .<symbol>)` for the corresponding catalog key
- **AND** unmapped errors MAY fall back to `error.localizedDescription`

### Requirement: Pluralization is supported via String Catalog variants

The system SHALL support plural strings using String Catalog plural variants and generated symbols that accept a numeric argument. At minimum, the catalog MUST include a scaffolded plural key for future feed use (e.g. `feed.comment.count` with `one` / `other` English variants).

#### Scenario: Comment count display

- **WHEN** UI needs to show a comment count of `n`
- **THEN** it uses the plural generated symbol (e.g. `Text(.feedCommentCount(n))` or `String(localized: .feedCommentCount(n))`)
- **AND** `n == 1` resolves to the `one` variant and any other `n` resolves to `other`

### Requirement: Hardcoded UI strings are prevented by SwiftLint

The project MUST include SwiftLint with a custom rule that flags hardcoded user-facing string literals in SwiftUI and UI-related APIs (e.g. `Text("...")`, `Button("...")`, `.navigationTitle("...")`, `.alert("...")`). `#Preview` blocks, test targets, developer-only messages (`fatalError`, `precondition`), CoreData entity names, NSPredicate format strings, and dispatch queue labels MUST be excluded from the rule.

#### Scenario: Hardcoded string in production view

- **WHEN** a developer adds `Text("Hello")` in a non-preview Swift file
- **THEN** SwiftLint reports a violation

#### Scenario: String in preview block

- **WHEN** a developer uses a literal string inside a `#Preview` block
- **THEN** SwiftLint does not report a violation

### Requirement: Localization tests assert behavior not copy

Unit tests MUST assert validation and error **state** (e.g. `isEmailValid == false`, `shouldShowErrorMessage == true`) and MUST NOT assert the English text of localized messages.

#### Scenario: Login validation test

- **WHEN** a unit test verifies invalid email handling
- **THEN** it checks `isEmailValid` or that auth was not called
- **AND** does not compare `errorMessage` to a hardcoded English string

### Requirement: Existing screens are fully migrated

All current user-facing strings in production Swift sources MUST be migrated to the catalog before this change is considered complete, including: Login, Registration, Forgot Password, tab bar labels, Feed, Search, New Post, Profile, Root session-resolving text, and `AuthErrorMapper` messages.

#### Scenario: Build with no inline UI literals

- **WHEN** the migration is complete and SwiftLint runs on production sources
- **THEN** no hardcoded UI string violations remain outside excluded paths
