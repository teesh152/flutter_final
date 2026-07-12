import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../db/database_helper.dart';
import '../models/task_model.dart';

/// Handles two-way synchronization between the local SQLite database
/// and Firebase Cloud Firestore.
///
/// Strategy (offline-first):
///  * All writes go to SQLite immediately with isSynced = 0.
///  * When online, unsynced rows are pushed to Firestore.
///  * On login / manual refresh, remote tasks are pulled into SQLite.
///  * Local unsynced changes always win until they are pushed.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _db = DatabaseHelper.instance;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('tasks');

  Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Start listening for connectivity changes; auto-push when back online.
  void startAutoSync(String uid, void Function() onSynced) {
    _sub?.cancel();
    _sub = Connectivity().onConnectivityChanged.listen((results) async {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        await pushLocalChanges(uid);
        onSynced();
      }
    });
  }

  void stopAutoSync() {
    _sub?.cancel();
    _sub = null;
  }

  /// Push all unsynced local rows (creates/updates/deletes) to Firestore.
  Future<void> pushLocalChanges(String uid) async {
    if (!await isOnline()) return;
    final unsynced = await _db.getUnsynced(uid);
    for (final task in unsynced) {
      try {
        if (task.isDeleted) {
          await _col(uid).doc(task.id).delete();
          await _db.hardDelete(task.id);
        } else {
          await _col(uid).doc(task.id).set(task.toFirestore());
          await _db.markSynced(task.id);
        }
      } catch (_) {
        // Keep the row unsynced; it will retry on the next sync.
      }
    }
  }

  /// Pull remote tasks into SQLite. Local unsynced rows are not overwritten.
  Future<void> pullRemote(String uid) async {
    if (!await isOnline()) return;
    try {
      final snapshot = await _col(uid).get();
      for (final doc in snapshot.docs) {
        final remote = TaskModel.fromFirestore(doc.id, uid, doc.data());
        final local = await _db.getById(remote.id);
        if (local == null) {
          await _db.insertTask(remote);
        } else if (local.isSynced) {
          // Only overwrite rows that have no pending local changes.
          await _db.insertTask(remote);
        }
      }
    } catch (_) {
      // Offline or Firestore error - local data remains the source of truth.
    }
  }

  /// Full sync: push local changes first, then pull the remote state.
  Future<void> fullSync(String uid) async {
    await pushLocalChanges(uid);
    await pullRemote(uid);
  }
}
