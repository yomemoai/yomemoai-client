import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'memory_provider.dart';
import 'memory_export_io.dart';

/// Picks a directory and exports [items] into it. Returns number of handle folders written, or null if cancelled / error.
Future<int?> runExportMemoriesToFolder(List<MemoryItem> items) async {
  final path = await FilePicker.platform.getDirectoryPath();
  if (path == null || path.isEmpty) return null;
  final rootDir = Directory(path);
  if (!await rootDir.exists()) return null;
  return exportMemoriesToDirectory(items, rootDir);
}
