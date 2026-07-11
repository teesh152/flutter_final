# Task Manager - Flutter Final Project

Offline & Online Data Management System (Firebase + SQLite).

## Features
- Firebase Authentication (Login / Register)
- SQLite local database (offline-first)
- Firebase Firestore cloud database
- Automatic + manual two-way sync (online/offline)
- 6 screens: Splash, Login, Register, Home, Add/Edit Task, Profile
- English UI, Material 3 design

## How to build the APK on GitHub (no PC tools needed)
1. Create a **new GitHub repository** (public or private).
2. Upload **all files and folders** of this project to the repo root
   (make sure `.github/workflows/build.yml`, `lib/`, `pubspec.yaml`, `test/` are included).
3. Go to the **Actions** tab → the workflow **"Build Android APK"** runs automatically
   (or press **Run workflow** manually).
4. When it finishes (about 5-8 minutes), open the run → **Artifacts** section →
   download **task-app-release-apk** → extract the ZIP → install `app-release.apk`.

## How to run locally in Android Studio (optional)
1. Extract the project and open the folder.
2. Run: `flutter create . --project-name task --org com --platforms android`
3. In `android/app/build.gradle(.kts)` change `flutter.minSdkVersion` to `23`.
4. Run: `flutter pub get` then `flutter run`.

## Firebase setup (one time, from the Firebase Console website)
- Project: `salehflutter-808f2` (already configured in `lib/firebase_options.dart`)
- Enable **Authentication → Sign-in method → Email/Password**.
- Create a **Firestore Database** (start in *test mode* for the course demo).

## Data structure
- SQLite table: `tasks(id, uid, title, description, isDone, createdAt, updatedAt, isSynced, isDeleted)`
- Firestore: `users/{uid}/tasks/{taskId}`

## Sync strategy (offline-first)
- Every change is saved to SQLite immediately with `isSynced = 0`.
- When online, pending changes are pushed to Firestore automatically
  (connectivity listener) or via the sync button / pull-to-refresh.
- On login, cloud tasks are pulled into SQLite.
- Local unsynced changes always win until they are pushed.
