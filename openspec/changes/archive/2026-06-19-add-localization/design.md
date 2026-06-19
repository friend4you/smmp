## Context

The smmp iOS app is SwiftUI + MVVM with ~40 inline English strings across views, ViewModels, and `AuthErrorMapper`. Xcode build settings already enable String Catalogs (`LOCALIZATION_PREFERS_STRING_CATALOGS`, `SWIFT_EMIT_LOC_STRINGS`, `STRING_CATALOG_GENERATE_SYMBOLS`), but no `.xcstrings` file exists. Phase 2 auth (`complete-phase-2-auth`) will add many more strings; localization must land first so that work follows one convention.

## Goals / Non-Goals

**Goals:**

- Single `Localizable.xcstrings` with semantic keys and generated symbols
- Migrate all existing user-facing strings; deduplicate shared copy
- Scaffold pluralization pattern for upcoming feed/profile features
- Add SwiftLint enforcement with preview exemption
- Keep `en` as the only locale; structure ready for `uk`, `de`, etc. later

**Non-Goals:**

- Translating to non-English locales
- Custom `L10n` wrapper type
- Localizing CoreData names, NSPredicate, queue labels, `fatalError`, test fixtures
- Pseudo-locale previews (e.g. `de` for layout stress) — `en` only for now
- Asserting localized message text in unit tests

## Decisions

### 1. Semantic keys + generated symbols (no string literals in production UI)

**Decision:** Catalog keys use dot-notation (`auth.login.submit`). Code uses Xcode-generated symbols (`.authLoginSubmit`), not `String(localized: "auth.login.submit")` string literals.

**Examples:**

```swift
// Views
Text(.authLoginSubmit)
Button { await login() } label: { Text(.authLoginSubmit) }
.navigationTitle(.authForgotPasswordTitle)
.alert(String(localized: .commonErrorTitle), ...) {
    Button(String(localized: .commonOk), role: .cancel) { }
}

// ViewModels / utilities
errorMessage = String(localized: .authValidationEmailInvalid)
return String(localized: .authErrorWrongPassword)
```

**Rationale:** Compile-time checking, refactor-safe renames in catalog, aligns with `STRING_CATALOG_GENERATE_SYMBOLS = YES`.

**Alternative considered:** English literals auto-extracted by `SWIFT_EMIT_LOC_STRINGS`. Rejected — duplicates are invisible, SwiftLint cannot distinguish intentional literals, keys drift when copy edits.

### 2. Single catalog at `smmp/Resources/Localizable.xcstrings`

**Decision:** One catalog file; keys grouped by feature prefix.

**Key map (migration inventory):**

| Key | English value | Used in |
|-----|---------------|---------|
| `auth.login.email` | Email | LoginView, RegistrationView |
| `auth.login.password` | Password | LoginView |
| `auth.login.repeatPassword` | Repeat password | RegistrationView |
| `auth.login.submit` | Login | LoginView |
| `auth.login.forgotPassword` | Forgot password? | LoginView |
| `auth.register.submit` | Register | LoginView, RegistrationView |
| `auth.forgotPassword.title` | Forgot Password | ForgotPasswordView |
| `auth.forgotPassword.instructions` | Enter your email… | ForgotPasswordView |
| `auth.validation.emailInvalid` | Please enter a valid email address. | LoginView, LoginViewModel, AuthErrorMapper |
| `auth.validation.passwordRequired` | Please enter your password. | LoginView, LoginViewModel |
| `auth.error.wrongPassword` | Incorrect email or password. | AuthErrorMapper |
| `auth.error.userNotFound` | No account found with this email. | AuthErrorMapper |
| `auth.error.network` | Network error… | AuthErrorMapper |
| `auth.error.tooManyRequests` | Too many attempts… | AuthErrorMapper |
| `common.error.title` | Error | LoginView alert |
| `common.ok` | OK | LoginView alert |
| `common.user` | User | ProfileView fallback display name |
| `tab.home` | Home | ContentView |
| `tab.search` | Search | ContentView |
| `tab.post` | Post | ContentView |
| `tab.profile` | Profile | ContentView |
| `feed.title` | Feed | FeedView |
| `search.title` | Search | SearchView |
| `post.new.title` | New Post | NewPostView |
| `profile.edit` | Edit | ProfileView |
| `profile.logout` | Logout | ProfileView |
| `session.resolving` | Resolving authentication… | RootView |
| `feed.comment.count` | plural scaffold | future feed UI |

### 3. Pluralization via catalog variants + generated symbol

**Decision:** Plural strings use String Catalog `variations.plural` with `one` / `other` for English. Code passes the count to the generated symbol.

**Catalog (en):**

```
feed.comment.count
  one:   "%lld comment"
  other: "%lld comments"
```

**Usage (when feed UI needs it):**

```swift
Text(.feedCommentCount(commentCount))
// or
String(localized: .feedCommentCount(commentCount))
```

Xcode generates a symbol that accepts `Int`/`Int64` because the key is plural-aware. Same symbol works in SwiftUI and non-UI code — no wrapper enum.

**This change:** Add the plural entry to the catalog as scaffold; wire UI only if a screen already displays a count (none today).

### 4. SwiftLint custom rule

**Decision:** Add `.swiftlint.yml` and SwiftLint via SPM build-tool plugin (preferred) or a Run Script build phase calling `swiftlint`.

**Custom rule concept (`hardcoded_ui_string`):** Flag string literals in:

- `Text("…")`, `Button("…")`, `Label("…", …)`, `SecureField("…", …)`, `TextField(…, prompt: Text("…"), …)`
- `.navigationTitle("…")`, `.alert("…", …)`, `NavigationLink("…")`

**Exclusions:**

- `*Tests.swift`, `*UITests.swift`
- `#Preview` blocks (regex/visitor scoped to preview, or `excluded` by `preview` custom rule config)
- Lines containing `fatalError`, `precondition`, `NSPredicate`, `entityName`, `DispatchQueue(label:`

**Allowed patterns:**

- `String(localized: .symbol)`
- `Text(.symbol)`, `Button` with `Text(.symbol)` label
- `error.localizedDescription` fallbacks

### 5. Previews

**Decision:** Previews use default `en` locale. `#Preview` bodies are SwiftLint-exempt so fixture/setup strings need not be cataloged.

### 6. Sequencing before Phase 2 auth

**Decision:** Complete this change before `complete-phase-2-auth`. New auth strings in phase 2 MUST use the same key-prefix convention (`auth.*`, `common.*`).

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Generated symbols not appearing until catalog + build | Add keys to catalog first; clean build; verify symbols in derived data / jump to definition |
| SwiftLint false positives on non-UI strings | Narrow rule matchers; maintain exclusion list |
| Symbol rename when key changes | Treat catalog keys as stable API; review key names before merge |
| Plural scaffold unused until Phase 3 | Low cost; documents pattern in design + spec |

## Migration Plan

```
1. Add smmp/Resources/Localizable.xcstrings with all keys (en)
2. Add plural scaffold for feed.comment.count
3. Build once to generate symbols
4. Migrate AuthErrorMapper → ViewModels → Views (auth first, then shell tabs)
5. Add SwiftLint + custom rule; fix any stragglers
6. Verify unit tests still pass (state-only assertions)
7. Merge → then start / continue complete-phase-2-auth using convention
```

**Rollback:** Revert PR; inline strings restored from git. No runtime migration or data impact.

## Open Questions

None — all decisions locked in explore session.
