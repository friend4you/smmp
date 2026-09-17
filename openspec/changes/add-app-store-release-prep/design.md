## Context

SMMP is a SwiftUI social app with email/password auth, Firestore, Storage, and CoreData. Feature work through Phase 5 is done. App Store review for a UGC social network still fails: no filter/report/block/contact (Guideline 1.2), no in-app account deletion (5.1.1(v)), no in-app privacy policy (5.1.1(i)), emails on publicly readable `users/{uid}` docs, and post-image Storage writes allowed for any signed-in user.

Constraints: keep MVVM + repositories + `AppDependencies`, no Cloud Functions, no new third-party SDKs, String Catalog localization, client-side Firestore/Storage like the rest of the app.

## Goals / Non-Goals

**Goals:**

- Close App Store guideline gaps that require code: UGC safety, account deletion, legal links, email privacy, Storage owner writes, plist/privacy manifest
- Stay consistent with existing client-side cascade patterns (post delete already removes likes, comments, and Storage)
- Keep URLs and support email in one replaceable configuration type

**Non-Goals:**

- Writing or hosting the legal document text (only in-app links + config)
- App Store Connect listing, screenshots, demo account, age rating
- Crashlytics, TestFlight, Sign in with Apple
- Server-side moderation queue, admin dashboard, or ML/NSFW image scanning
- Lowering `IPHONEOS_DEPLOYMENT_TARGET`
- iPad-specific layouts (ship iPhone-only instead)
- Queued offline writes for report/block/delete (those actions require connectivity)

## Decisions

### 1. Client-side profanity denylist for text filter

**Decision:** Add `ContentFiltering` with a bundled case-insensitive word-boundary denylist. Run it before register display name, edit profile (display name + bio), create post, and add comment. Reject the write and show a localized error. Images are not scanned.

**Rationale:** Guideline 1.2 requires a method for filtering objectionable material. A local list is testable, has no new dependency, and matches portfolio scope.

**Alternative considered:** Third-party moderation API or on-device ML. Rejected — extra cost/privacy surface and not needed to satisfy the guideline.

### 2. Reports as a top-level Firestore collection

**Decision:** `reports/{reportId}` with `reporterId`, `targetType` (`post` | `comment` | `user`), `targetId`, optional `parentPostId` for comments, `reason` (`spam` | `harassment` | `hateSpeech` | `sexualContent` | `other`), `createdAt`. Authenticated users create only their own reports. Clients do not list other users’ reports. Developer triages in Firebase Console.

**Rationale:** Satisfies “mechanism to report” without Cloud Functions. Console is the timely-response workflow for a single-developer app.

**Alternative considered:** Subcollection under the target document. Rejected — mixing user content with moderation metadata complicates rules and deletion.

### 3. Blocks as `users/{uid}/blocked/{blockedUid}`

**Decision:** Same ownership pattern as `following`. The blocker no longer sees the blocked user’s posts in feed/profile lists, comments, or search rows; opening that profile shows a blocked state with Unblock. Cannot block self. Block does not delete the other user’s account.

**Rationale:** Guideline 1.2 requires blocking abusive users. Persisting in Firestore keeps blocks across devices/reinstalls.

**Alternative considered:** Local-only block list. Rejected — clears on reinstall and is easy to miss in review.

### 4. In-app contact via configured support email

**Decision:** Profile overflow (and legal footer) includes Contact, opening `mailto:` from `LegalConfiguration.supportEmail`.

**Rationale:** Guideline 1.2 / 1.5 published contact information. Mailto is native and does not need a website.

### 5. Legal URLs in `LegalConfiguration`, Safari view in-app

**Decision:** `LegalConfiguration` holds `privacyPolicyURL`, `termsOfUseURL`, and `supportEmail`. Login footer and Profile menu open URLs in `SafariView` (or `SFSafariViewController` wrapper). Register requires an explicit checkbox (“I agree to the Terms and Privacy Policy”) before submit; links on the checkbox line open the same URLs.

**Rationale:** 5.1.1(i) requires the policy inside the app, not only App Store Connect. Checkbox is the consent record at account creation.

**Alternative considered:** In-app markdown copies of the policies. Rejected — legal text will live on a hosted page so it can be updated without an app release.

### 6. Delete Account is a Profile menu action with password reauth

**Decision:** Profile secondary menu: Logout, Privacy Policy, Terms, Contact, Delete Account. Delete shows a destructive confirmation, then asks for current password and reauthenticates (`EmailAuthProvider`) because Firebase requires a recent login for `user.delete()`. Then `AccountDeleting` runs the cascade and signs the session out.

**Rationale:** Easy to find (5.1.1(v)). Reauth avoids a cryptic Firebase “requires-recent-login” failure during review.

**Alternative considered:** Settings screen. Rejected — Profile already owns Logout; extra navigation is unnecessary.

### 7. Client-side deletion cascade, Auth last

**Decision:** `AccountDeletionService` (injected via `AppDependencies`), online-only:

1. Delete each of the user’s posts via existing `PostRepository` cascade (Storage image, likes, comments, post doc)
2. Collection-group query `comments` where `authorId == uid`; delete remaining comments and decrement those posts’ `commentCount`
3. Collection-group query `likes` where the document id is `uid`; delete remaining likes and decrement `likeCount` when practical
4. Unfollow all (`following` docs + count maintenance)
5. Delete `blocked` subcollection docs
6. Delete `users/{uid}/avatar.jpg` and `users/{uid}`
7. `AuthAccountDeleting.deleteCurrentUser()`
8. Clear session (existing logout path)

If any step before Auth fails, stop and show an error so the user can retry. Do not delete Auth first.

**Rationale:** Apple requires associated UGC deleted, not only the login. Matches existing client-side post delete. No Cloud Functions.

**Alternative considered:** Callable Cloud Function. Rejected — out of current architecture and ops scope.

### 8. Email stays in Auth and local current-user cache only

**Decision:** `createProfile` / `firestoreWriteData` MUST NOT write `email` to `users/{uid}`. Other users’ profiles and search results have `email == nil`. The signed-in user’s email MAY remain on the CoreData `CDUser` from Firebase Auth at login/register. Do not query Firestore by email.

**Rationale:** Any signed-in user can read `users/{uid}`. Field-level hiding is not possible; omitting the field is the only client-safe option.

**Alternative considered:** `users/{uid}/private` owner-only subcollection. Rejected — nothing in the product reads other users’ emails (search is `displayNameLower`).

### 9. Post image Storage path includes author uid

**Decision:** Change `MediaPaths.postImage` from `posts/{postId}/image.jpg` to `posts/{authorId}/{postId}/image.jpg`. Storage rules: write only when `authorId == request.auth.uid`, image content type, size &lt; 5 MB. Read: any authenticated user. Keep avatar rules owner-only as they are.

**Rationale:** Current rules allow any signed-in user to overwrite any `posts/{postId}/` object. Uid in the path enforces owner writes without `firestore.get` and without changing upload-before-document order.

**Alternative considered:** Create the Firestore post first, then `firestore.get` author in Storage rules. Rejected — extra create/update round-trip and Storage–Firestore rules coupling.

### 10. App Store build settings and privacy manifest

**Decision:**

- `INFOPLIST_KEY_CFBundleDisplayName` = `SMMP`
- `INFOPLIST_KEY_NSPhotoLibraryUsageDescription` covers **posts and profile photo**
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` = `NO`
- `TARGETED_DEVICE_FAMILY` = `1` (iPhone); keep iPhone orientations as they are unless layout breaks in landscape
- Add `PrivacyInfo.xcprivacy` with `NSPrivacyTracking` false and collected types: Email Address, Name, User ID, Photos or Videos, User Content — all for App Functionality, not used for tracking, linked to user identity where true
- Do not declare required-reason APIs the app does not call; Firebase ships its own manifests

**Rationale:** Home-screen name, accurate purpose string, export compliance, avoid iPad 2.4.1, and privacy labels that match runtime behavior.

### 11. Firestore rules additions

**Decision:**

- `reports`: create if `request.auth.uid == request.resource.data.reporterId`; read own reports only; no client update/delete
- `users/{userId}/blocked/{blockedId}`: owner create/delete; authenticated read (needed to filter feed/search)
- Existing user/post/comment/like/follow rules unchanged except email is simply no longer written

**Rationale:** Least change to Phase 3–4 rules while enabling new collections.

## Risks / Trade-offs

- **[Denylist is English and incomplete]** → Mitigation: document as minimum viable filter; extend the list later; still satisfies “a method for filtering”
- **[No image/NSFW scanning]** → Mitigation: users can report posts with images; age rating 17+ in Connect if UGC is unmoderated visually
- **[Collection-group deletes need indexes]** → Mitigation: add `firestore.indexes.json` (or console index) for `comments.authorId`; deploy documented in `DEPLOY.md`
- **[Partial cascade if app is killed mid-delete]** → Mitigation: Auth is last; retry is safe; leftover docs without an Auth user are unreachable for that login
- **[Existing Storage objects at old path]** → Mitigation: portfolio data can be discarded; new uploads use the new path
- **[Placeholder legal URLs fail review]** → Mitigation: `LegalConfiguration` is the single replace-before-submit point; tasks include a reminder, not hosted copywriting
- **[Firebase reauth friction]** → Mitigation: password prompt in the delete flow; disable delete offline

## Migration Plan

1. Rules + indexes + Storage path + MediaService (backend contract)
2. Stop writing email; filter + legal + report/block UI
3. Account deletion cascade
4. Plist + privacy manifest
5. Localization and tests

Rollback: revert the change branch. No production user migration expected.

## Open Questions

None — exploration locked:

- Filter: local denylist, not a vendor API
- Moderation console: Firebase Console, not an in-app admin
- Device family: iPhone-only
- Display name: `SMMP`
- Legal documents: hosted URLs via `LegalConfiguration`, not in-bundle markdown
