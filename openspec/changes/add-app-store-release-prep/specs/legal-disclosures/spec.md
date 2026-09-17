## ADDED Requirements

### Requirement: Privacy Policy and Terms are reachable inside the app

The system SHALL expose Privacy Policy and Terms of Use actions that open `LegalConfiguration.privacyPolicyURL` and `LegalConfiguration.termsOfUseURL` in an in-app Safari view. The links MUST appear on Login and in the Profile menu.

#### Scenario: Open Privacy Policy from Login

- **WHEN** the user taps Privacy Policy on the Login screen
- **THEN** the system presents the configured privacy URL in an in-app Safari view

#### Scenario: Open Terms from Profile

- **WHEN** the user taps Terms of Use in the Profile menu
- **THEN** the system presents the configured terms URL in an in-app Safari view

### Requirement: Registration requires acceptance of Terms and Privacy Policy

The system SHALL require an explicit checkbox on the Register screen acknowledging the Terms of Use and Privacy Policy before registration can be submitted. The checkbox label MUST link to the same legal URLs. Submit MUST remain disabled until the checkbox is on.

#### Scenario: Register disabled until accepted

- **WHEN** the user fills valid registration fields but has not checked the legal checkbox
- **THEN** the system does not call Firebase register

#### Scenario: Register proceeds after acceptance

- **WHEN** the user checks the legal checkbox and submits valid fields
- **THEN** the system proceeds with the existing registration flow
