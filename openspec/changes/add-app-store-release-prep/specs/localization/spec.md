## ADDED Requirements

### Requirement: Safety, legal, and deletion copy lives in the String Catalog

The system SHALL add semantic keys in `Localizable.xcstrings` for content-filter errors, report reasons and confirmation, block/unblock, contact, privacy/terms links, registration legal checkbox, delete-account confirmation and errors, and related accessibility labels. English (`en`) remains the required locale. Call sites MUST use generated symbols.

#### Scenario: Filter error uses a catalog key

- **WHEN** the content filter rejects a write
- **THEN** the user-visible message comes from a String Catalog symbol, not a string literal

#### Scenario: Delete account confirmation uses catalog keys

- **WHEN** the delete-account confirmation alert is shown
- **THEN** title, message, and actions use generated localization symbols
