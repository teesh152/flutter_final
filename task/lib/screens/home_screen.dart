import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/task_model.dart';
import '../services/sync_service.dart';
import 'add_edit_task_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

/// Screen 4: Home - task list loaded from SQLite (offline-first),
/// with manual + automatic synchronization to Firestore.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper.instance;
  final _sync = SyncService.instance;
  List<TaskModel> _tasks = [];
  bool _online = true;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _load();
    _sync.startAutoSync(_uid, _load);
    _checkOnline();
  }

  Future<void> _checkOnline() async {
    final online = await _sync.isOnline();
    if (mounted) setState(() => _online = online);
  }

  Future<void> _load() async {
    final tasks = await _db.getTasks(_uid);
    if (mounted) setState(() => _tasks = tasks);
    _checkOnline();
  }

  Future<void> _manualSync() async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Syncing...'), duration: Duration(seconds: 1)));
    await _sync.fullSync(_uid);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Sync complete')));
  }

  Future<void> _toggleDone(TaskModel task) async {
    task.isDone = !task.isDone;
    task.isSynced = false;
    task.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _db.updateTask(task);
    await _load();
    _sync.pushLocalChanges(_uid).then((_) => _load());
  }

  Future<void> _delete(TaskModel task) async {
    await _db.deleteTask(task);
    await _load();
    _sync.pushLocalChanges(_uid).then((_) => _load());
  }

  Future<void> _logout() async {
    _sync.stopAutoSync();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final pending = _tasks.where((t) => !t.isDone).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync now',
              onPressed: _manualSync),
          IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Profile',
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => const ProfileScreen()))
                  .then((_) => _load())),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: _online ? Colors.green.shade50 : Colors.orange.shade50,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_online ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: _online ? Colors.green : Colors.orange),
                const SizedBox(width: 6),
                Text(
                  _online
                      ? 'Online - changes sync automatically'
                      : 'Offline - changes saved locally',
                  style: TextStyle(
                      fontSize: 12,
                      color: _online
                          ? Colors.green.shade800
                          : Colors.orange.shade800),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('$pending pending / ${_tasks.length} total',
                style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 72, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No tasks yet. Tap + to add one.',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _manualSync,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _tasks.length,
                      itemBuilder: (context, i) {
                        final task = _tasks[i];
                        return Dismissible(
                          key: ValueKey(task.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _delete(task),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: Checkbox(
                                value: task.isDone,
                                onChanged: (_) => _toggleDone(task),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: task.description.isEmpty
                                  ? null
                                  : Text(task.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                              trailing: Icon(
                                task.isSynced
                                    ? Icons.cloud_done
                                    : Icons.cloud_upload_outlined,
                                size: 18,
                                color: task.isSynced
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              onTap: () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                      builder: (_) =>
                                          AddEditTaskScreen(task: task)))
                                  .then((_) => _load()),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (_) => const AddEditTaskScreen()))
            .then((_) => _load()),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _sync.stopAutoSync();
    super.dispose();
  }
}
