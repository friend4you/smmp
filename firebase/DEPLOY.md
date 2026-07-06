# Firebase rules deployment

Phase 3+ rules live in [`firestore.rules`](./firestore.rules) and [`storage.rules`](./storage.rules). Project: **smmp-b0138** (from `GoogleService-Info.plist`).

## Option A — Firebase Console (no CLI)

### Firestore

1. Open [Firebase Console](https://console.firebase.google.com/) → project **smmp-b0138**
2. **Firestore Database** → **Rules**
3. Replace the editor contents with the full contents of `firebase/firestore.rules`
4. Click **Publish**

### Storage

1. **Storage** → **Rules**
2. Replace the editor contents with the full contents of `firebase/storage.rules`
3. Click **Publish**

## Option B — Firebase CLI

```bash
npm install -g firebase-tools   # or: npx firebase-tools
firebase login
cd /path/to/smmp
firebase deploy --only firestore:rules,storage
```

## Verify on device — Phase 3

After publishing, run the app signed in and confirm:

| Action | Expected |
|--------|----------|
| Read `users/{anyUid}` | Allowed |
| Query `posts` collection | Allowed |
| Create post with `authorId == your uid` | Allowed |
| Create post with another user's `authorId` | Denied |
| Like / unlike a post | Allowed |
| Add / delete own comment | Allowed |
| Read feed while logged out | Denied |

## Verify on device — Phase 4

After Phase 4 rules are published, additionally confirm:

| Action | Expected |
|--------|----------|
| Create `users/{yourUid}/following/{otherUid}` | Allowed |
| Create `users/{otherUid}/following/{thirdUid}` | Denied |
| Read `users/{anyUid}/following/{fid}` | Allowed |
| Update only `followerCount` on another user's document | Allowed |
| Update `displayName` on another user's document | Denied |
| Upload `users/{yourUid}/avatar.jpg` | Allowed |
| Upload `users/{otherUid}/avatar.jpg` | Denied |
| Read any user's avatar URL | Allowed |

If any operation fails with `permission-denied`, compare the deployed rules in the console with `firebase/firestore.rules` and `firebase/storage.rules` — they must match exactly.
