## 1. Localization and legal configuration

- [ ] 1.1 Add `LegalConfiguration` with replaceable `privacyPolicyURL`, `termsOfUseURL`, and `supportEmail`
- [ ] 1.2 Add String Catalog keys for filter errors, report reasons/confirmation, block/unblock, contact, privacy/terms, register legal checkbox, delete-account confirmation and errors
- [ ] 1.3 Add a reusable in-app Safari view wrapper for legal URLs

## 2. Content filter

- [ ] 2.1 Add `ContentFiltering` protocol and denylist implementation (`ContentFilter`)
- [ ] 2.2 Register the filter in `AppDependencies` and inject into create-post, comment, registration, and edit-profile ViewModels
- [ ] 2.3 Guard create post, add comment, register display name, and edit display name/bio; show catalog error on reject
- [ ] 2.4 Add `ContentFilterTests` — match, miss, case/word-boundary behavior

## 3. Stop writing email on public profiles

- [ ] 3.1 Stop passing `includeEmail: true` from `ProfileRepository.createProfile`; ensure `firestoreWriteData` does not write `email`
- [ ] 3.2 Keep current-user email from Firebase Auth in local cache only; other users' `email` remains nil
- [ ] 3.3 Update bootstrap/mapping tests so Firestore user docs are asserted without `email`

## 4. Storage owner-only post images

- [ ] 4.1 Change `MediaPaths.postImage` to `posts/{authorId}/{postId}/image.jpg`; update `MediaService` / protocol call sites
- [ ] 4.2 Update `firebase/storage.rules` — authenticated read; write only when `authorId == request.auth.uid` plus size/content-type
- [ ] 4.3 Update `MediaServiceTests` and post delete/upload paths for the new Storage path

## 5. Firestore rules for reports and blocks

- [ ] 5.1 Add `reports/{reportId}` rules (create own, read own, no client update/delete)
- [ ] 5.2 Add `users/{userId}/blocked/{blockedId}` rules (owner write, authenticated read)
- [ ] 5.3 Add collection-group index notes for `comments.authorId` (and likes if needed) in `firebase/DEPLOY.md`
- [ ] 5.4 Document deploying updated Firestore + Storage rules in `firebase/DEPLOY.md`

## 6. Reports

- [ ] 6.1 Add report model, `ReportRepository` (create-only), and reason enum
- [ ] 6.2 Add report UI on Post Detail / post menu, comment row, and other-user profile (not own content)
- [ ] 6.3 Disable report offline; show confirmation after successful create
- [ ] 6.4 Add `ReportRepository` / ViewModel tests — own content not reportable; create payload fields

## 7. Blocks

- [ ] 7.1 Add block repository (create/delete `users/{uid}/blocked/{blockedUid}`, fetch blocked ids)
- [ ] 7.2 Filter feed, search results, and comments by blocked ids; blocked profile shows Unblock
- [ ] 7.3 Add Block on other-user profile; prevent self-block; disable offline
- [ ] 7.4 Add tests — block hides feed posts; unblock restores; self-block rejected

## 8. Legal disclosures in auth and profile

- [ ] 8.1 Login footer: Privacy Policy and Terms of Use opening Safari view
- [ ] 8.2 Register checkbox required before submit; inline links to the same URLs
- [ ] 8.3 Profile overflow: Privacy Policy, Terms of Use, Contact (`mailto:` support email)
- [ ] 8.4 `RegistrationViewModelTests` — unchecked legal box does not call register

## 9. Account deletion

- [ ] 9.1 Add reauthenticate-with-password on `AuthService` (needed for `user.delete()`)
- [ ] 9.2 Add `AccountDeletionService` cascade: own posts (existing delete), remaining comments/likes via collection group, unfollow all, delete blocks, avatar + user doc, Auth last, then session clear
- [ ] 9.3 Profile Delete Account: confirmation, password prompt, offline disable, error if cascade fails before Auth
- [ ] 9.4 Tests — cascade order (Auth last); confirmation cancel does nothing; offline does not start delete

## 10. App Store build settings

- [ ] 10.1 Set `INFOPLIST_KEY_CFBundleDisplayName` = `SMMP`
- [ ] 10.2 Update `NSPhotoLibraryUsageDescription` to cover post attachment and profile photo
- [ ] 10.3 Set `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` = `NO`
- [ ] 10.4 Set `TARGETED_DEVICE_FAMILY` = `1` (iPhone only)
- [ ] 10.5 Add `PrivacyInfo.xcprivacy` (no tracking; Email, Name, User ID, Photos, User Content for App Functionality)

## 11. Cleanup

- [ ] 11.1 Remove commented `EnvironmentObject` leftover in `NewPostView`
- [ ] 11.2 Update README status: App Store code prep in progress / items covered; Connect listing still out of scope
