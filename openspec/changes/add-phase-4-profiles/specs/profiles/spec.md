## ADDED Requirements

### Requirement: User can view their own profile on the Profile tab

The system SHALL display the authenticated user's profile on the Profile tab via `ProfileView`, showing profile photo, display name, bio, follower count, following count, and a list of the user's posts using `PostCardView`.

#### Scenario: Own profile loads

- **WHEN** the user opens the Profile tab while online
- **THEN** the system fetches `users/{currentUid}`, displays profile fields, and loads the user's posts ordered by `createdAt` descending

#### Scenario: Own profile shows cached data offline

- **WHEN** the user opens the Profile tab while offline and cached user/posts exist
- **THEN** the system displays cached profile and posts without calling Firestore

### Requirement: User can view another user's profile

The system SHALL display another user's profile via `UserProfileView(userId)` pushed within the Feed or Search tab navigation stack, showing profile photo, display name, bio, follower count, following count, Follow/Unfollow button, and posts list.

#### Scenario: Other user profile from feed

- **WHEN** the user taps an author's avatar on a feed post card and the author is not the current user
- **THEN** the system pushes `UserProfileView` on the feed coordinator stack with Follow/Unfollow visible

#### Scenario: Own profile from feed shows Edit not Follow

- **WHEN** the user taps their own avatar on a feed post card
- **THEN** the system pushes `UserProfileView` for the current user with Follow hidden and Edit available

### Requirement: User can edit their profile

The system SHALL allow the authenticated user to edit display name, bio, and profile photo via `EditProfileView` presented as a sheet from `ProfileView` or `UserProfileView`.

#### Scenario: Save profile changes

- **WHEN** the user edits fields, picks a new photo, and taps Save while online
- **THEN** the system uploads the photo to Storage if changed, updates `users/{uid}` including `displayNameLower`, syncs Firebase Auth `displayName` and `photoURL`, updates CoreData cache, and dismisses the sheet

#### Scenario: Discard unsaved changes

- **WHEN** the user taps back or Cancel with unsaved edits
- **THEN** the system prompts to discard or continue editing

#### Scenario: Edit profile disabled offline

- **WHEN** the device is offline
- **THEN** the Edit Profile action is disabled or shows an offline message

### Requirement: Profile displays follower count without Followers screen

The system SHALL display `followerCount` on profile headers. The follower count SHALL NOT navigate to a Followers list screen in this phase.

#### Scenario: Follower count not tappable

- **WHEN** the user views any profile
- **THEN** follower count is displayed as read-only text

### Requirement: Profile navigates to Following list

The system SHALL navigate to `FollowingScreen` when the user taps the following count on their own profile or on `UserProfileView` when viewing their own profile.

#### Scenario: Tap following count on own profile

- **WHEN** the user taps the following count on `ProfileView`
- **THEN** the system pushes `FollowingScreen` listing users the current user follows

### Requirement: Profile post list reuses PostCardView

The system SHALL render a user's posts on profile screens as a vertical list of `PostCardView` rows, reusing the same card component as the feed.

#### Scenario: Tap profile post navigates to detail

- **WHEN** the user taps a post on a profile screen
- **THEN** the system pushes Post Detail within the same tab coordinator stack

### Requirement: ProfileRepository owns user document writes

The system SHALL implement `ProfileRepository.createProfile`, `ProfileRepository.fetchUser`, `ProfileRepository.updateProfile`, and `ProfileRepository.searchUsers(prefix:)` as the single coordination layer for `users/{uid}` document reads and writes (except follow count maintenance performed by `FollowRepository`).

#### Scenario: createProfile moved from AuthService

- **WHEN** registration succeeds
- **THEN** `AuthRepository` calls `ProfileRepository.createProfile` instead of `AuthService.createProfile`

#### Scenario: updateProfile writes displayNameLower

- **WHEN** the user saves a new display name
- **THEN** the Firestore document includes both `displayName` and `displayNameLower` (lowercased)

### Requirement: Profile photo uses dedicated Storage path

The system SHALL upload profile photos to `users/{uid}/avatar.jpg` via `MediaService`, store the download URL in `photoURL`, and delete the previous Storage object when replaced.

#### Scenario: Upload profile photo

- **WHEN** the user selects a photo and saves while online
- **THEN** the system resizes the image, uploads to `users/{uid}/avatar.jpg`, and persists the URL on the user document
