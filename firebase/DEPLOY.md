# Firestore rules deployment

Phase 3 rules live in [`firestore.rules`](./firestore.rules). Project: **smmp-b0138** (from `GoogleService-Info.plist`).

## Option A — Firebase Console (no CLI)

1. Open [Firebase Console](https://console.firebase.google.com/) → project **smmp-b0138**
2. **Firestore Database** → **Rules**
3. Replace the editor contents with the full contents of `firebase/firestore.rules`
4. Click **Publish**

## Option B — Firebase CLI

```bash
npm install -g firebase-tools   # or: npx firebase-tools
firebase login
cd /path/to/smmp
firebase deploy --only firestore:rules
```

## Verify on device (task 1.2)

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

If any operation fails with `permission-denied`, compare the deployed rules in the console with `firebase/firestore.rules` — they must match exactly.
