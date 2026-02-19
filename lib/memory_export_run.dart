import 'memory_provider.dart';
import 'memory_export_run_io.dart'
    if (dart.library.html) 'memory_export_stub.dart' as impl;

/// Picks a folder (when supported) and exports memories into it.
/// Returns number of handle folders written, or null if cancelled / unsupported (e.g. on web).
Future<int?> runExportMemoriesToFolder(List<MemoryItem> items) =>
    impl.runExportMemoriesToFolder(items);
