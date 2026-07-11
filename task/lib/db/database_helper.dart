import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task_model.dart';

/// Singleton SQLite helper - the app always reads from SQLite first
/// (offline-first architecture).
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'tasks.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            uid TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            isDone INTEGER NOT NULL DEFAULT 0,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            isSynced INTEGER NOT NULL DEFAULT 0,
            isDeleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // ---------------- CRUD ----------------

  Future<void> insertTask(TaskModel task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTask(TaskModel task) async {
    final db = await database;
    await db
        .update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  /// Soft delete if it was synced before (so we can delete it remotely later),
  /// hard delete if it only ever existed locally.
  Future<void> deleteTask(TaskModel task) async {
    final db = await database;
    if (task.isSynced) {
      task.isDeleted = true;
      task.isSynced = false;
      task.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await updateTask(task);
    } else {
      await db.delete('tasks', where: 'id = ?', whereArgs: [task.id]);
    }
  }

  Future<void> hardDelete(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  /// Visible (non-deleted) tasks for a user, newest first.
  Future<List<TaskModel>> getTasks(String uid) async {
    final db = await database;
    final rows = await db.query('tasks',
        where: 'uid = ? AND isDeleted = 0',
        whereArgs: [uid],
        orderBy: 'createdAt DESC');
    return rows.map(TaskModel.fromMap).toList();
  }

  /// Rows waiting to be pushed to Firestore.
  Future<List<TaskModel>> getUnsynced(String uid) async {
    final db = await database;
    final rows = await db
        .query('tasks', where: 'uid = ? AND isSynced = 0', whereArgs: [uid]);
    return rows.map(TaskModel.fromMap).toList();
  }

  Future<void> markSynced(String id) async {
    final db = await database;
    await db.update('tasks', {'isSynced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<TaskModel?> getById(String id) async {
    final db = await database;
    final rows =
        await db.query('tasks', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return TaskModel.fromMap(rows.first);
  }

  Future<Map<String, int>> counts(String uid) async {
    final tasks = await getTasks(uid);
    final done = tasks.where((t) => t.isDone).length;
    return {'total': tasks.length, 'done': done, 'pending': tasks.length - done};
  }
}
