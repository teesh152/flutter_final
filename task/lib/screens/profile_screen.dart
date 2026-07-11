import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../services/sync_service.dart';
import 'login_screen.dart';

/// Screen 6: Profile - shows the logged-in user and task statistics.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, int> _counts = {'total': 0, 'done': 0, 'pending': 0};

  User get _user => FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final counts = await DatabaseHelper.instance.counts(_user.uid);
    if (mounted) setState(() => _counts = counts);
  }

  Future<void> _logout() async {
    SyncService.instance.stopAutoSync();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false);
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text('$value',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 44,
              backgroundColor: Color(0xFF3F51B5),
              child: Icon(Icons.person, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(_user.email ?? '',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            Text('User ID: ${_user.uid.substring(0, 8)}...',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            Row(
              children: [
                _statCard('Total', _counts['total']!, Icons.list_alt,
                    Colors.indigo),
                _statCard('Done', _counts['done']!, Icons.check_circle,
                    Colors.green),
                _statCard('Pending', _counts['pending']!,
                    Icons.pending_actions, Colors.orange),
              ],
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label:
                  const Text('Logout', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}
