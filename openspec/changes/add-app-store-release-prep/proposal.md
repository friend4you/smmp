## Why

The product (auth, feed, posts, profiles, search, offline) is complete, but the app cannot pass App Store review as a social network: there is no UGC safety (filter, report, block, contact), no in-app account deletion, no privacy policy/terms in the UI, and publicly readable user documents store emails. Release prep in code must close those guideline gaps before TestFlight or App Store submission.

## What Changes

- Add client-side filtering of objectionable text on post, comment, display name, and bio writes
- Add report flows for posts, comments, and user profiles; persist reports in Firestore
- Add block/unblock of other users; hide blocked users' content from the blocker
- Add in-app contact / support entry (mailto or support URL)
- Add Privacy Policy and Terms links on Login, Register, and Profile; require terms acceptance before registration
- Add an easy-to-find **Delete Account** action that removes Auth, Firestore, and Storage data associated with the user (**BREAKING** for retained UGC — deletion is permanent)
- Stop writing `email` onto publicly readable `users/{uid}` documents (**BREAKING** vs current bootstrap spec; search remains display-name-only)
- Restrict Firebase Storage post-image writes to the post owner
- Set App Store–facing Info.plist values: display name, photo-library purpose string (posts and profile), encryption exemption, iPhone-only device family
- Add `PrivacyInfo.xcprivacy` declaring collected data types (no tracking)
- Add localization keys for all new user-facing copy

## Capabilities

### New Capabilities

- `ugc-safety`: Content filter, report, block, and in-app contact required by App Store Guideline 1.2
- `account-deletion`: In-app account deletion with cascade of Auth, Firestore, and Storage data (Guideline 5.1.1(v))
- `legal-disclosures`: Privacy Policy and Terms URLs in-app, plus required acceptance at registration (Guideline 5.1.1(i))
- `app-store-configuration`: Display name, usage strings, encryption flag, iPhone-only family, privacy manifest

### Modified Capabilities

- `authentication`: Registration requires terms acceptance; login surfaces privacy/terms links
- `user-profile-bootstrap`: Public `users/{uid}` document MUST NOT include email
- `firestore-security-rules`: Rules for reports and blocked-user subcollections
- `storage-security-rules`: Post image writes restricted to the owning user
- `posts`: Create post rejects filtered text; post owners/viewers can report others' posts
- `comments`: Add comment rejects filtered text; comments can be reported
- `feed`: Posts from users the current user has blocked are not shown
- `localization`: Keys for safety, legal, deletion, and filter/report/block copy

## Impact

- **Domain:** `ContentFilter` (or equivalent), report/block models and repository protocols
- **Data:** Firestore `reports` collection and `users/{uid}/blocked/{blockedUid}`; Storage post-image write rules and likely uid-scoped object path; `ProfileRepository.createProfile` stops writing `email`; account-deletion cascade in a dedicated service/repository
- **Auth:** Surface `deleteCurrentUser` for the user-facing flow (reauth if Firebase requires recent login); keep rollback delete for failed registration
- **UI:** Report sheets on post/comment/profile; block on other-user profile; Profile menu for legal links, contact, delete account; Register checkbox; Login footer links
- **Project:** `project.pbxproj` Info.plist keys, `PrivacyInfo.xcprivacy`, `LegalConfiguration` (replaceable hosted URLs)
- **Rules:** `firebase/firestore.rules`, `firebase/storage.rules`, `firebase/DEPLOY.md`
- **Tests:** Filter, report, block, deletion cascade, bootstrap without email, ViewModel guards
- **Out of scope:** Hosted legal document copywriting, App Store Connect metadata/screenshots/demo account, Crashlytics, TestFlight, Sign in with Apple, Cloud Functions / admin dashboard, lowering `IPHONEOS_DEPLOYMENT_TARGET`, iPad layout (iPhone-only instead)
