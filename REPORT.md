# Project Report - Task Manager (Offline & Online Data Management System)

## 1. Introduction
This project is a Flutter mobile application (Task & To-Do App, idea #2) that manages
tasks both offline and online. It stores data locally in SQLite so the app is fully
usable without internet, and synchronizes with Firebase Cloud Firestore whenever a
connection is available. User accounts are handled by Firebase Authentication.

## 2. Objectives Achieved
- Practiced Flutter development with a clean, layered architecture (models, db, services, screens).
- Used SQLite (sqflite) for local data storage with full CRUD operations.
- Integrated Firebase Authentication (email/password login and registration).
- Synced data between SQLite and Firestore in both directions.
- Built 6 English-language screens with Material 3 design.

## 3. Architecture
The app follows an offline-first design:
1. **UI layer (screens/)** - Splash, Login, Register, Home, Add/Edit Task, Profile.
2. **Service layer (services/)** - `AuthService` (Firebase Auth) and `SyncService`
   (two-way SQLite ↔ Firestore synchronization with a connectivity listener).
3. **Data layer (db/, models/)** - `DatabaseHelper` (SQLite singleton) and `TaskModel`
   (converts between SQLite rows and Firestore documents).

Every create, update, delete, or "mark done" action is written to SQLite immediately
with a flag `isSynced = 0`. The sync service pushes pending rows to Firestore when the
device is online (automatically via `connectivity_plus`, or manually with the sync
button / pull-to-refresh). Deletes are "soft" locally until the remote document is
removed, guaranteeing no change is ever lost while offline. On login, the user's cloud
tasks are pulled into SQLite so data follows the account across devices.

## 4. CRUD Operations
- **Create:** Add Task screen → `INSERT` into SQLite → push to Firestore.
- **Read:** Home screen lists tasks from SQLite (works fully offline).
- **Update:** Edit screen and the done-checkbox → `UPDATE` in SQLite → push.
- **Delete:** Swipe-to-delete → soft delete locally → remote delete when online.

## 5. Technologies
Flutter & Dart, firebase_core, firebase_auth, cloud_firestore, sqflite, path,
connectivity_plus. The APK is built automatically with a GitHub Actions CI workflow.

## 6. Conclusion
The application fulfills all mandatory requirements: Firebase Authentication, a SQLite
local database, a Firebase cloud database, more than five screens, and an English-only
UI. The offline/online sync indicator on each task (cloud icon) and the connectivity
banner are extra features that make the sync state visible to the user.
