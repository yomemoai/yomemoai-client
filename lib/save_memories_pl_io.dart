import 'dart:convert';
import 'package:share_plus/share_plus.dart';

/// Save memories.pl via share sheet (user can save to Files / export).
Future<void> saveMemoriesPl(String content) async {
  final bytes = utf8.encode(content);
  final xfile = XFile.fromData(
    bytes,
    name: 'memories.pl',
    mimeType: 'text/plain',
  );
  await Share.shareXFiles(
    [xfile],
    text: 'memories.pl (Prolog facts + rules for debug)',
  );
}
