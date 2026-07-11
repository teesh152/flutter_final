import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/task_model.dart';
import '../services/sync_service.dart';

/// Screen 5: Add or Edit a task.
/// Writes to SQLite first, then attempts to push to Firestore.
class AddEditTaskScreen extends StatefulWidget {
  final TaskModel? task;
  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  bool _saving = false;

  bool get isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task?.title ?? '');
    _description =
        TextEditingController(text: widget.task?.description ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = DatabaseHelper.instance;

    if (isEdit) {
      final task = widget.task!;
      task.title = _title.text.trim();
      task.description = _description.text.trim();
      task.updatedAt = now;
      task.isSynced = false;
      await db.updateTask(task);
    } else {
      final task = TaskModel(
        id: now.toString(),
        uid: uid,
        title: _title.text.trim(),
        description: _description.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await db.insertTask(task);
    }

    // Fire-and-forget push; if offline it stays queued in SQLite.
    SyncService.instance.pushLocalChanges(uid);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Task' : 'New Task')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                      labelText: 'Title', prefixIcon: Icon(Icons.title)),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  maxLines: 5,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      alignLabelWithHint: true),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  label: Text(isEdit ? 'Update Task' : 'Save Task',
                      style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }
}
