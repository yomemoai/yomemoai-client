import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import '../memory_provider.dart';
import '../save_memories_pl.dart';
import '../memory_export_run.dart';

/// Dedicated screen for export options (folder, memories.pl, etc.).
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final list = provider.items;

    return Scaffold(
      appBar: AppBar(title: const Text("Export memories")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Choose an export format. More options may be added later.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text("Export to folder"),
            subtitle: const Text(
              "One subfolder per handle; each has metadata.json and one .txt file per memory.",
            ),
            trailing: const Icon(Icons.folder_open),
            onTap: () async {
              if (list.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text("No memories to export")),
                );
                return;
                }
              try {
                final count = await runExportMemoriesToFolder(list);
                if (!context.mounted) return;
                if (count == null) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Export cancelled or not supported on this platform"),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text("Exported $count handle(s) to selected folder")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text("Export failed: $e")),
                  );
                }
              }
            },
          ),
          const Divider(height: 24),
          ListTile(
            title: const Text("Export memories.pl"),
            subtitle: const Text(
              "Prolog facts + rules for debug. Share/save file, or copy to clipboard if share fails.",
            ),
            trailing: const Icon(Icons.code),
            onTap: () async {
              final content = provider.getMemoriesPrologContent();
              try {
                await saveMemoriesPl(content);
                if (context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text("memories.pl ready (saved or shared)")),
                  );
                }
              } catch (e) {
                try {
                  await Clipboard.setData(ClipboardData(text: content));
                  if (context.mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Share failed; copied to clipboard. Paste and save as memories.pl",
                        ),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text("Save failed: $e")),
                    );
                  }
                }
              }
            },
          ),
          ListTile(
            title: const Text("Copy memories.pl to clipboard"),
            subtitle: const Text("Paste into a file and save as memories.pl."),
            trailing: const Icon(Icons.copy),
            onTap: () async {
              final content = provider.getMemoriesPrologContent();
              try {
                await Clipboard.setData(ClipboardData(text: content));
                if (context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Copied. Paste into a file and save as memories.pl")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text("Copy failed: $e")),
                );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
