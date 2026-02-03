import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../memory_provider.dart';
import 'settings_screen.dart';
import 'editor_screen.dart';
import 'memory_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _expandedHandles = {};
  Offset? _lastTapPosition;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _logo(size: 20),
            const SizedBox(width: 8),
            _brandTitle(),
            const SizedBox(width: 8),
            const Text("Encrypted"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.refreshMemories(),
          ),
          IconButton(
            icon: const Icon(Icons.lock),
            tooltip: "Lock",
            onPressed: () => provider.lockNow(),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.items.isEmpty
          ? _buildEmptyState()
          : _buildGroupedList(context, provider.items),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditorScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _logo(size: 60),
          const SizedBox(height: 16),
          const Text("No memories found. Tap + to create one."),
        ],
      ),
    );
  }

  Widget _logo({double size = 24}) {
    return SvgPicture.asset(
      "assets/logo/yomemo-logo.svg",
      width: size,
      height: size,
    );
  }

  Widget _brandTitle() {
    final memoStyle = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.2,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Yo",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [Color(0xFF22D3EE), Color(0xFF3B82F6)],
            ).createShader(bounds);
          },
          child: Text("Memo", style: memoStyle.copyWith(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildGroupedList(BuildContext context, List<MemoryItem> items) {
    final grouped = <String, List<MemoryItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.handle, () => []).add(item);
    }
    final handles = grouped.keys.toList()..sort();

    final List<Widget> rows = [];
    rows.add(_buildSummary(context, items.length, handles.length));
    for (final handle in handles) {
      final isExpanded = _expandedHandles.contains(handle);
      rows.add(
        _buildHandleSectionHeader(handle, grouped[handle]!.length, isExpanded),
      );
      if (isExpanded) {
        for (final item in grouped[handle]!) {
          rows.add(_buildMemoryCard(context, item, showHandle: false));
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: rows,
    );
  }

  Widget _buildSummary(BuildContext context, int total, int handleCount) {
    final provider = context.watch<MemoryProvider>();
    final lastSync = provider.lastSyncAt;
    final lastAttempt = provider.lastSyncAttemptAt;
    final error = provider.lastSyncError;

    String timeText(DateTime? t) {
      if (t == null) return "—";
      final local = t.toLocal();
      return "${local.year}-${_two(local.month)}-${_two(local.day)} ${_two(local.hour)}:${_two(local.minute)}";
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Overview",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              "Immutable, zero-trust memory for every LLM session.",
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            const SizedBox(height: 6),
            const Text(
              "YoMemo protects memory at rest and in retrieval.",
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _metric("Memories", total.toString()),
                const SizedBox(width: 12),
                _metric("Handles", handleCount.toString()),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Last sync: ${timeText(lastSync)}",
              style: TextStyle(color: Colors.blueGrey[700], fontSize: 12),
            ),
            Text(
              "Last attempt: ${timeText(lastAttempt)}",
              style: TextStyle(color: Colors.blueGrey[700], fontSize: 12),
            ),
            if (error != null && error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Last error: $error",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.blueGrey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _two(int v) => v < 10 ? "0$v" : "$v";

  Future<void> _showHelp(BuildContext context) async {
    const docsUrl = "https://doc.yomemo.ai";
    const githubUrl = "https://github.com/yomemoai";

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const ListTile(
                title: Text("Help"),
                subtitle: Text("Docs and GitHub"),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text("Docs"),
                subtitle: const Text(docsUrl),
                onTap: () async {
                  await Clipboard.setData(const ClipboardData(text: docsUrl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Docs link copied")),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text("GitHub"),
                subtitle: const Text(githubUrl),
                onTap: () async {
                  await Clipboard.setData(const ClipboardData(text: githubUrl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("GitHub link copied")),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandleSectionHeader(String handle, int count, bool isExpanded) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedHandles.remove(handle);
          } else {
            _expandedHandles.add(handle);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.folder_open : Icons.folder_outlined,
              size: 20,
              color: Colors.blueGrey[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                handle,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.blueGrey[800],
                ),
              ),
            ),
            if (count > 1)
              Text(
                "($count)",
                style: TextStyle(fontSize: 13, color: Colors.blueGrey[600]),
              ),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: Colors.blueGrey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryCard(
    BuildContext context,
    MemoryItem item, {
    bool showHandle = true,
  }) {
    return GestureDetector(
      onTap: () => _openDetail(context, item),
      onLongPressStart: (details) {
        _lastTapPosition = details.globalPosition;
      },
      onLongPress: () => _showMemoryMenuAt(context, item),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: showHandle
              ? Text(
                  item.handle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 0, bottom: 6),
                  child: Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.blueGrey[600],
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
              Text(
                item.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Edit",
            onPressed: () => _openEditor(context, item),
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, MemoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MemoryDetailScreen(item: item)),
    );
  }

  void _openEditor(BuildContext context, MemoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditorScreen(item: item)),
    );
  }

  Future<void> _showMemoryMenuAt(BuildContext context, MemoryItem item) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = _lastTapPosition ?? const Offset(0, 0);
    final rect = RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & overlay.size,
    );

    final action = await showMenu<String>(
      context: context,
      position: rect,
      items: const [PopupMenuItem(value: 'edit', child: Text('Edit'))],
    );

    if (!mounted) return;
    if (action == 'edit') {
      _openEditor(context, item);
    }
  }
}
