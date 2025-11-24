// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/models/note.dart';

class NotesExporter {
  /// Verilen notları JSON'a çevirip geçici dosyaya yazar ve sistem paylaşım sayfasını açar.
  static Future<void> shareAsJson(List<Note> notes) async {
    // Domain modelini basit Map'e çeviriyoruz (gizli/sistem alanı yok):
    final payload = notes.map((n) => {
      'id': n.id,
      'title': n.title,
      'content': n.content,
      'pinned': n.pinned,
      'created_at': n.createdAt.toIso8601String(),
      'updated_at': n.updatedAt.toIso8601String(),
      'deleted_at': n.deletedAt?.toIso8601String(),
    }).toList();

    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);

    final dir = await getTemporaryDirectory();
    final filename = 'notes_${DateTime.now().toIso8601String().replaceAll(':','-')}.json';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(jsonStr);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json', name: filename)],
      text: 'My Notes export',
      subject: 'Notes export',
    );
  }
}
