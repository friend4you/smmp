## ADDED Requirements

### Requirement: User can follow and unfollow another user

The system SHALL allow an authenticated user to follow or unfollow another user via `FollowRepository`, writing `users/{followerId}/following/{followedId}` with a `followedAt` timestamp.

#### Scenario: Follow user

- **WHEN** the user taps Follow on another user's profile while online and under the following limit
- **THEN** the system creates the following document and increments `followingCount` on the current user and `followerCount` on the target user in a batch write

#### Scenario: Unfollow user

- **WHEN** the user taps Unfollow while online
- **THEN** the system deletes the following document and decrements both count fields in a batch write

#### Scenario: Follow disabled offline

- **WHEN** the device is offline
- **THEN** Follow/Unfollow controls are disabled

### Requirement: Following is capped at 30 users

The system SHALL reject follow attempts when the current user's `followingCount` is already 30.

#### Scenario: Follow limit reached

- **WHEN** the user attempts to follow a 31st user
- **THEN** the system shows a user-readable error and does not write to Firestore

### Requirement: User can view their following list

The system SHALL display `FollowingScreen` as a list of users the current user follows, with avatar, display name, and Unfollow action per row.

#### Scenario: Following list loads

- **WHEN** the user opens `FollowingScreen` while online
- **THEN** the system queries `users/{currentUid}/following`, resolves each followed user's profile, and displays the list

#### Scenario: Unfollow from following list

- **WHEN** the user taps Unfollow on a row while online
- **THEN** the system unfollows the user and removes the row from the list

### Requirement: Follow state is resolved from following subcollection

The system SHALL determine `isFollowing` by checking existence of `users/{currentUid}/following/{targetUid}`.

#### Scenario: Follow button state on profile

- **WHEN** `UserProfileView` loads for another user
- **THEN** the system shows Follow or Unfollow based on following document existence

### Requirement: FollowRepository owns follow graph operations

The system SHALL implement `follow`, `unfollow`, `isFollowing`, `fetchFollowing`, and `followingIds(for:)` on `FollowRepository` (not `ProfileRepository`).

#### Scenario: Feed uses following IDs

- **WHEN** the feed loads for an authenticated user
- **THEN** `PostRepository` obtains following user IDs from `FollowRepository` to build the follow-scoped feed query
