import 'save_memories_pl_web.dart'
    if (dart.library.io) 'save_memories_pl_io.dart' as impl;

/// Saves the given Prolog program as memories.pl (for debug).
/// On web: triggers browser download. On mobile/desktop: opens share sheet so user can save.
Future<void> saveMemoriesPl(String content) => impl.saveMemoriesPl(content);
