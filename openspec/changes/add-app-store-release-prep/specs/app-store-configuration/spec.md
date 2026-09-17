## ADDED Requirements

### Requirement: Home screen display name is SMMP

The generated Info.plist SHALL set `CFBundleDisplayName` to `SMMP` via `INFOPLIST_KEY_CFBundleDisplayName`.

#### Scenario: Display name on the home screen

- **WHEN** the app is installed on a device
- **THEN** the home-screen label is `SMMP`, not the target name `smmp`

### Requirement: Photo library purpose string covers posts and profile

The system SHALL set `NSPhotoLibraryUsageDescription` to a purpose string that names both attaching a photo to a post and setting a profile picture.

#### Scenario: Purpose string mentions both uses

- **WHEN** the generated Info.plist is inspected
- **THEN** `NSPhotoLibraryUsageDescription` describes post attachment and profile photo

### Requirement: Export compliance declares exempt encryption

The generated Info.plist SHALL set `ITSAppUsesNonExemptEncryption` to `NO`.

#### Scenario: Encryption flag is set

- **WHEN** the generated Info.plist is inspected
- **THEN** `ITSAppUsesNonExemptEncryption` is `false`

### Requirement: The app ships as iPhone-only

The smmp target SHALL set `TARGETED_DEVICE_FAMILY` to `1` (iPhone).

#### Scenario: iPad is not a native target

- **WHEN** the Release build settings are inspected
- **THEN** `TARGETED_DEVICE_FAMILY` is `1`

### Requirement: App privacy manifest declares collected data

The app target SHALL include `PrivacyInfo.xcprivacy` with `NSPrivacyTracking` set to false. Collected data types SHALL include Email Address, Name, User ID, Photos or Videos, and User Content, used for App Functionality and not for tracking. The app MUST NOT declare required-reason API types it does not call.

#### Scenario: Privacy manifest is bundled

- **WHEN** a developer archives the app
- **THEN** `PrivacyInfo.xcprivacy` is in the app bundle with tracking disabled and the listed data types
