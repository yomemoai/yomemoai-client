import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../memory_provider.dart';
import '../utils/handle_display.dart';
import '../l10n/app_localizations.dart';
import 'editor_screen.dart';

class MemoryDetailScreen extends StatelessWidget {
  final MemoryItem item;
  const MemoryDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memoryDetail),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: item.content));
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.copied)));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditorScreen(item: item),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizedSectionTitle(context, item.handle),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (item.handle != localizedSectionTitle(context, item.handle))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.handle,
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey[500]),
                ),
              ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description,
                style: TextStyle(
                  color: Colors.blueGrey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(item.content, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
