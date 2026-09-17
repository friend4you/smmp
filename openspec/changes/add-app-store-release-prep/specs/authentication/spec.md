## ADDED Requirements

### Requirement: Registration requires legal acceptance

The system SHALL require the Register screen legal checkbox from `legal-disclosures` before calling `AuthService.register`. Invalid legal acceptance MUST be rejected before any network call.

#### Scenario: Unchecked terms blocks register

- **WHEN** register is attempted with valid fields and the legal checkbox off
- **THEN** the system does not call Firebase
- **AND** shows a validation error or keeps submit disabled
