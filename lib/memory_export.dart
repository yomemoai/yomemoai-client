import 'memory_provider.dart';

/// Export format: one folder per handle; inside each folder:
/// - metadata.json: array of memory metadata (id, idempotent_key, description, metadata, created_at, updated_at)
/// - {idempotent_key}.txt: one file per memory with plain content.
/// Import can read metadata.json then for each entry read the corresponding .txt file.

/// Sanitizes a string for use as folder or file name (removes / \ : * ? " < > | and collapses spaces).
String sanitizeForFilename(String s) {
  if (s.isEmpty) return '_';
  final t = s.replaceAll(RegExp(r'[/\\:*?"<>|\s]+'), '_').trim();
  return t.isEmpty ? '_' : t;
}

/// Builds the export payload for [items]: grouped by handle, each group has metadata list and content map.
Map<String, Map<String, dynamic>> exportMemoriesByHandle(List<MemoryItem> items) {
  final byHandle = <String, Map<String, dynamic>>{};
  for (final item in items) {
    final handle = item.handle.trim().isEmpty ? '_' : item.handle;
    byHandle.putIfAbsent(handle, () => {
      'metadata_list': <Map<String, dynamic>>[],
      'contents': <String, String>{},
    });
    final data = byHandle[handle]!;
    (data['metadata_list'] as List<Map<String, dynamic>>).add({
      'id': item.id,
      'idempotent_key': item.idempotentKey,
      'description': item.description,
      'metadata': item.metadata,
      'created_at': item.createdAt?.toIso8601String(),
      'updated_at': item.updatedAt?.toIso8601String(),
    });
    (data['contents'] as Map<String, String>)[item.idempotentKey] = item.content;
  }
  return byHandle;
}
