## MODIFIED Requirements

### Requirement: User can like and unlike a post

The system SHALL allow an authenticated user to like and unlike any post while online. Like state SHALL be stored in `posts/{pid}/likes/{uid}` and `likeCount` on the post document SHALL be updated atomically via batch write. Like and unlike SHALL be disabled when offline.

#### Scenario: Like a post

- **WHEN** the user taps like on a post they have not liked while online
- **THEN** the system creates `posts/{pid}/likes/{currentUid}` and increments `likeCount` on the post document in a single batch

#### Scenario: Unlike a post

- **WHEN** the user taps unlike on a post they have liked while online
- **THEN** the system deletes `posts/{pid}/likes/{currentUid}` and decrements `likeCount` on the post document in a single batch

#### Scenario: Optimistic like with rollback

- **WHEN** the user taps like while online and the Firestore batch fails
- **THEN** the system reverts the optimistic UI state and shows a user-readable error

#### Scenario: Like disabled offline

- **WHEN** the user views a post on Feed or Post Detail while offline
- **THEN** the like control is disabled and no Firestore write is attempted

### Requirement: User can delete their own post

The system SHALL allow the post author to delete their post while online, including the Firebase Storage image (if any) and all documents in the `likes` and `comments` subcollections. Post delete SHALL be disabled when offline.

#### Scenario: Successful cascade delete

- **WHEN** the post author deletes their post while online
- **THEN** the system deletes the Storage object at `posts/{pid}/image.jpg` (if present), all `posts/{pid}/likes/*` documents, all `posts/{pid}/comments/*` documents, and the `posts/{pid}` document

#### Scenario: Non-author cannot delete

- **WHEN** a user attempts to delete a post they did not author
- **THEN** the system does not delete the post (enforced by Firestore rules and repository guard)

#### Scenario: Delete disabled offline

- **WHEN** the post author views Post Detail while offline
- **THEN** the delete post control is disabled

## ADDED Requirements

### Requirement: Like button provides animated feedback

The system SHALL animate the heart icon with a spring scale effect when the user toggles like state on Feed and Post Detail while online.

#### Scenario: Animated like on post card

- **WHEN** the user likes a post while online
- **THEN** the heart icon animates with a brief scale bounce
