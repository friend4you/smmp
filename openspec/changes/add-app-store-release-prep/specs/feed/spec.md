## ADDED Requirements

### Requirement: Feed hides posts from blocked users

The system SHALL exclude posts whose `authorId` is in the current user's blocked set when building the follow-scoped feed.

#### Scenario: Blocked author omitted from feed

- **WHEN** the feed includes a post by user B and the current user has blocked B
- **THEN** that post is not shown in the feed
