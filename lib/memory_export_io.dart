import 'dart:convert';
import 'dart:io';

import 'memory_provider.dart';
import 'memory_export.dart';

/// Exports [items] into [rootDir]: one subfolder per handle (name = sanitized handle),
/// each with metadata.json and one .txt file per memory (filename = sanitized idempotent_key).
/// Returns the number of handle folders written.
Future<int> exportMemoriesToDirectory(List<MemoryItem> items, Directory rootDir) async {
  if (items.isEmpty) return 0;
  final byHandle = exportMemoriesByHandle(items);
  int count = 0;
  for (final entry in byHandle.entries) {
    final handle = entry.key;
    final data = entry.value;
    final metadataList = data['metadata_list'] as List<Map<String, dynamic>>;
    final contents = data['contents'] as Map<String, String>;

    final dirName = sanitizeForFilename(handle);
    final handleDir = Directory('${rootDir.path}/$dirName');
    await handleDir.create(recursive: true);

    await File('${handleDir.path}/metadata.json').writeAsString(
      JsonEncoder.withIndent('  ').convert({'memories': metadataList}),
      encoding: utf8,
    );

    for (final meta in metadataList) {
      final key = meta['idempotent_key'] as String? ?? '';
      final content = contents[key] ?? '';
      final fileName = '${sanitizeForFilename(key)}.txt';
      await File('${handleDir.path}/$fileName').writeAsString(content, encoding: utf8);
    }
    count++;
  }
  return count;
}
