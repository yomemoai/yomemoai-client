import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import '../memory_provider.dart';
import '../save_memories_pl.dart';
import '../memory_export_run.dart';
import '../l10n/app_localizations.dart';

/// Dedicated screen for export options (folder, memories.pl, etc.).
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final list = provider.items;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportMemoriesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.chooseExportFormat,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ListTile(
            title: Text(l10n.exportToFolder),
            subtitle: Text(l10n.exportToFolderSubtitle),
            trailing: const Icon(Icons.folder_open),
            onTap: () async {
              if (list.isEmpty) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.noMemoriesToExport)),
                );
                return;
                }
              try {
                final count = await runExportMemoriesToFolder(list);
                if (!context.mounted) return;
                if (count == null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.exportCancelledOrNotSupported)),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.exportedHandlesCount(count))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.exportFailed('$e'))),
                  );
                }
              }
            },
          ),
          const Divider(height: 24),
          ListTile(
            title: Text(l10n.exportMemoriesPl),
            subtitle: Text(l10n.exportMemoriesPlSubtitle),
            trailing: const Icon(Icons.code),
            onTap: () async {
              final content = provider.getMemoriesPrologContent();
              try {
                await saveMemoriesPl(content);
                if (context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.memoriesPlReady)),
                  );
                }
              } catch (e) {
                try {
                  await Clipboard.setData(ClipboardData(text: content));
                  if (context.mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.shareFailedCopiedToClipboard),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.saveFailed('$e'))),
                    );
                  }
                }
              }
            },
          ),
          ListTile(
            title: Text(l10n.copyMemoriesPlToClipboard),
            subtitle: Text(l10n.copyMemoriesPlSubtitle),
            trailing: const Icon(Icons.copy),
            onTap: () async {
              final content = provider.getMemoriesPrologContent();
              try {
                await Clipboard.setData(ClipboardData(text: content));
                if (context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.copiedPasteSaveMemoriesPl)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.copyFailed('$e'))),
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
