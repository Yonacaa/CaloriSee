import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DevDbScreen extends StatefulWidget {
  const DevDbScreen({super.key});

  @override
  State<DevDbScreen> createState() => _DevDbScreenState();
}

class _DevDbScreenState extends State<DevDbScreen> {
  String _dbPath = '';
  String _status = '';

  @override
  void initState() {
    super.initState();
    _initPath();
  }

  Future<void> _initPath() async {
    final dbFolder = await getDatabasesPath();
    final dbFile = p.join(dbFolder, 'calorisee.db');
    setState(() {
      _dbPath = dbFile;
    });
  }

  Future<void> _exportDb() async {
    setState(() {
      _status = 'Exporting...';
    });

    try {
      // Try to open and close the DB to release any locks before copying
      try {
        final dbTmp = await openDatabase(_dbPath);
        await dbTmp.close();
      } catch (_) {}

      final dbFile = File(_dbPath);
      if (!await dbFile.exists()) {
        setState(() {
          _status = 'DB file not found at $_dbPath';
        });
        return;
      }

      final docs = await getApplicationDocumentsDirectory();
      final dest = File(p.join(docs.path, 'calorisee_export.db'));
      await dbFile.copy(dest.path);

      setState(() {
        _status = 'Exported to ${dest.path}';
      });
    } catch (e) {
      setState(() {
        _status = 'Export failed: $e';
      });
    }
  }

  Future<void> _showDbContents() async {
    try {
      final db = await openDatabase(_dbPath, readOnly: true);
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      String summary = 'Tables:\n${tables.map((e) => e['name']).join(', ')}\n';
      // Optionally list rows of key tables (users, food_history)
      if ((tables.any((t) => t['name'] == 'users'))) {
        final users = await db.query('users', limit: 10);
        summary += '\nUsers (up to 10):\n${users.map((u) => u.toString()).join('\n')}';
      }
      await db.close();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('DB Preview'),
          content: SingleChildScrollView(child: Text(summary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Failed to open DB: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev: Database'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Database Path:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SelectableText(_dbPath.isNotEmpty ? _dbPath : 'loading...'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _exportDb,
              icon: const Icon(Icons.upload_file),
              label: const Text('Export DB to app documents'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showDbContents,
              icon: const Icon(Icons.visibility),
              label: const Text('Preview DB (tables + sample rows)'),
            ),
            const SizedBox(height: 16),
            Text('Status: $_status'),
            const Spacer(),
            const Text('Notes:' , style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• Exported file is named `calorisee_export.db` in app documents folder.'),
            const SizedBox(height: 4),
            const Text('• Use Device File Explorer (Android Studio) or adb to pull it.'),
          ],
        ),
      ),
    );
  }
}
