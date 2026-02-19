import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../memory_provider.dart';
import '../utils/handle_display.dart';
import '../l10n/app_localizations.dart';
import 'settings_screen.dart';
import 'editor_screen.dart';
import 'memory_detail_screen.dart';
import 'insights_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const String _kExpandedPrefixesKey = 'home_expanded_prefixes';
const String _kDefaultExpandedPrefixesKey = 'default_expanded_prefixes';

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _expandedHandles = {};
  /// Prefix groups expanded (e.g. yomemo, voice). Persisted.
  Set<String> _expandedPrefixes = {};
  /// For each expanded prefix, which handle is selected (null = All).
  final Map<String, String?> _selectedHandleByPrefix = {};
  Offset? _lastTapPosition;
  final GlobalKey _helpKey = GlobalKey();
  final GlobalKey _avatarKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadExpandedPrefixes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MemoryProvider>().ensureMemoriesLoadedIfNeeded();
    });
  }

  Future<void> _loadExpandedPrefixes() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_kExpandedPrefixesKey);
    final Set<String> next = saved != null
        ? saved.toSet()
        : (prefs.getStringList(_kDefaultExpandedPrefixesKey) ?? []).toSet();
    if (mounted) setState(() => _expandedPrefixes = next);
  }

  Future<void> _saveExpandedPrefixes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kExpandedPrefixesKey, _expandedPrefixes.toList());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    context.read<MemoryProvider>().setHandleSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemoryProvider>();
    final l10n = AppLocalizations.of(context);
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final scaffold = Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _logo(size: 20),
            const SizedBox(width: 8),
            _brandTitle(),
            const SizedBox(width: 8),
            Text(l10n.encrypted),
          ],
        ),
        actions: isIOS
            // iOS: 默认展示 Lock / Settings / Avatar，其他菜单通过头像下拉展示。
            ? [
                IconButton(
                  icon: const Icon(Icons.lock),
                  tooltip: l10n.lock,
                  onPressed: () => provider.lockNow(),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                    if (mounted) {
                      await _loadExpandedPrefixes();
                      if (mounted) setState(() {});
                    }
                  },
                ),
                if (provider.userEmail.isNotEmpty ||
                    provider.userAvatarUrl.isNotEmpty)
                  _buildUserAvatar(provider, isIOS: true),
              ]
            : [
                _buildInsightsButton(provider),
                IconButton(
                  icon: const Icon(Icons.lock),
                  tooltip: l10n.lock,
                  onPressed: () => provider.lockNow(),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  key: _helpKey,
                  onPressed: () => _showHelp(context),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                    if (mounted) {
                      await _loadExpandedPrefixes();
                      if (mounted) setState(() {});
                    }
                  },
                ),
                if (provider.userEmail.isNotEmpty ||
                    provider.userAvatarUrl.isNotEmpty)
                  _buildUserAvatar(provider, isIOS: false),
              ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child:             Autocomplete<MapEntry<String, int>>(
              displayStringForOption: (MapEntry<String, int> option) => option.key,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<MapEntry<String, int>>.empty();
                }
                final provider = context.read<MemoryProvider>();
                return provider.handleCounts.entries.where((entry) {
                  return entry.key.toLowerCase().contains(textEditingValue.text.toLowerCase());
                }).toList()..sort((a,b) => b.value.compareTo(a.value)); // Sort by count descending
              },
              onSelected: (MapEntry<String, int> selection) {
                // When an option is selected, update our _searchController
                _searchController.text = selection.key;
                // _onSearchChanged will be triggered by _searchController's listener
              },
              fieldViewBuilder: (BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted) {
                // This ensures that the TextFormField's controller (textEditingController)
                // is always showing the same text as our _searchController.
                // This handles cases where _searchController might be updated programmatically.
                if (textEditingController.text != _searchController.text) {
                  textEditingController.text = _searchController.text;
                  // Optionally maintain cursor position
                  textEditingController.selection = _searchController.selection;
                }

                return TextFormField(
                  controller: textEditingController, // Use Autocomplete's controller for UI
                  focusNode: focusNode,
                  onChanged: (String value) {
                    // When user types, update our _searchController
                    _searchController.text = value;
                    // _onSearchChanged will be triggered by _searchController's listener
                  },
                  decoration: InputDecoration(
                    hintText: l10n.searchHandles,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: textEditingController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            // Clear both controllers
                            textEditingController.clear();
                            _searchController.clear();
                            // _onSearchChanged will be triggered by _searchController's listener
                          },
                        )
                      : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onFieldSubmitted: (String value) {
                    onFieldSubmitted();
                  },
                );
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<MapEntry<String, int>> onSelected, Iterable<MapEntry<String, int>> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 24, // Match padding
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);
                          final display = handleDisplay(option.key);
                          return ListTile(
                            leading: Icon(display.icon, size: 20, color: Colors.blueGrey[600]),
                            title: Text(localizedSectionTitle(context, option.key)),
                            subtitle: option.key != display.sectionTitle
                                ? Text(option.key, style: TextStyle(fontSize: 12, color: Colors.blueGrey[500]))
                                : null,
                            trailing: Text("(${option.value})"),
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: provider.items.isEmpty
                ? (provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildEmptyState())
                : _buildGroupedList(context, provider.filteredItems),
          ),
        ],
      ),
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

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN):
            const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditorScreen(),
                ),
              );
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: scaffold,
        ),
      ),
    );
  }

  Widget _buildInsightsButton(MemoryProvider provider) {
    final alertCount = provider.pendingAlertCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.auto_awesome),
          tooltip: AppLocalizations.of(context).insights,
          onPressed: () {
            provider.clearAlerts();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InsightsScreen()),
            );
          },
        ),
        if (alertCount > 0 && provider.showInsightsBadge)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$alertCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserAvatar(
    MemoryProvider provider, {
    required bool isIOS,
  }) {
    final email = provider.userEmail;
    final plan = provider.userPlan.isEmpty ? 'free' : provider.userPlan;
    final avatarUrl = provider.userAvatarUrl;

    String initialsFromEmail(String value) {
      if (value.isEmpty) return "U";
      final local = value.split('@').first;
      final parts = local.split('.');
      final buf = StringBuffer();
      for (final p in parts) {
        if (p.isNotEmpty) buf.write(p[0]);
      }
      final s = buf.toString().toUpperCase();
      if (s.isEmpty) return local[0].toUpperCase();
      return s.length > 2 ? s.substring(0, 2) : s;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: email.isEmpty ? "Account ($plan)" : "$email ($plan)",
        child: InkWell(
          key: _avatarKey,
          customBorder: const CircleBorder(),
          onTap: isIOS ? () => _showAvatarMenu(provider) : null,
          child: CircleAvatar(
            radius: 14,
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            backgroundColor: const Color(0xFFE5E7EB),
            child: avatarUrl.isEmpty
                ? Text(
                    initialsFromEmail(email),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  )
                : null,
          ),
        ),
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
          Text(AppLocalizations.of(context).noMemoriesFound),
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
    // Group by prefix -> handle -> items
    final byPrefix = <String, Map<String, List<MemoryItem>>>{};
    for (final item in items) {
      final prefix = handlePrefix(item.handle);
      byPrefix.putIfAbsent(prefix, () => {}).putIfAbsent(item.handle, () => []).add(item);
    }
    final prefixes = byPrefix.keys.toList()
      ..sort((a, b) {
        final oa = prefixOrder(a);
        final ob = prefixOrder(b);
        if (oa != ob) return oa.compareTo(ob);
        return a.compareTo(b);
      });

    final List<Widget> rows = [];
    final provider = context.watch<MemoryProvider>();
    final totalHandles = items.map((e) => e.handle).toSet().length;
    rows.add(_buildSummary(context, provider.totalCount, totalHandles));

    for (final prefix in prefixes) {
      final handleToItems = byPrefix[prefix]!;
      final handles = handleToItems.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final totalCount = handleToItems.values.fold<int>(0, (s, list) => s + list.length);
      final isPrefixExpanded = _expandedPrefixes.contains(prefix);
      final selectedHandle = _selectedHandleByPrefix[prefix];

      rows.add(_buildPrefixHeader(prefix, handles, totalCount, isPrefixExpanded));
      if (isPrefixExpanded) {
        rows.add(_buildHandleChipBar(prefix, handles, handleToItems, selectedHandle));
        if (selectedHandle != null) {
          final list = handleToItems[selectedHandle] ?? [];
          final isHandleExpanded = _expandedHandles.contains(selectedHandle);
          rows.add(_buildHandleSectionHeader(selectedHandle, list.length, isHandleExpanded));
          if (isHandleExpanded) {
            for (final item in list) {
              rows.add(_buildDismissibleMemoryCard(context, item));
            }
          }
        } else {
          for (final handle in handles) {
            final list = handleToItems[handle]!;
            final isHandleExpanded = _expandedHandles.contains(handle);
            rows.add(_buildHandleSectionHeader(handle, list.length, isHandleExpanded));
            if (isHandleExpanded) {
              for (final item in list) {
                rows.add(_buildDismissibleMemoryCard(context, item));
              }
            }
          }
        }
      }
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        ...rows,
        if (provider.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildPrefixHeader(String prefix, List<String> handles, int totalCount, bool isExpanded) {
    final display = handleDisplay(handles.isNotEmpty ? handles.first : prefix);
    final cap = localizedPrefixLabel(context, prefix);
    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedPrefixes.remove(prefix);
          } else {
            _expandedPrefixes.add(prefix);
          }
          _saveExpandedPrefixes();
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 20,
              color: Colors.blueGrey[600],
            ),
            const SizedBox(width: 4),
            Icon(display.icon, size: 18, color: Colors.blueGrey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cap,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.blueGrey[800],
                ),
              ),
            ),
            Text(
              '$totalCount',
              style: TextStyle(fontSize: 13, color: Colors.blueGrey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandleChipBar(
    String prefix,
    List<String> handles,
    Map<String, List<MemoryItem>> handleToItems,
    String? selectedHandle,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedBg = isDark ? Colors.white12 : Colors.blueGrey.shade100;
    final unselectedBg = Colors.transparent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _minimalChip(
              label: AppLocalizations.of(context).all,
              selected: selectedHandle == null,
              onTap: () => setState(() => _selectedHandleByPrefix[prefix] = null),
              selectedBg: selectedBg,
              unselectedBg: unselectedBg,
            ),
            ...handles.map((handle) {
              final count = (handleToItems[handle] ?? []).length;
              final selected = selectedHandle == handle;
              return _minimalChip(
                label: '${localizedHandleShortLabel(context, handle)} ($count)',
                selected: selected,
                onTap: () {
                  setState(() {
                    _selectedHandleByPrefix[prefix] = handle;
                    _expandedHandles.add(handle);
                  });
                },
                selectedBg: selectedBg,
                unselectedBg: unselectedBg,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _minimalChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color selectedBg,
    required Color unselectedBg,
  }) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.blueGrey[200]
        : Colors.blueGrey[800];
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected ? selectedBg : unselectedBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, int total, int handleCount) {
    final provider = context.watch<MemoryProvider>();
    final l10n = AppLocalizations.of(context);
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
            Row(
              children: [
                Text(
                  l10n.overview,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.refresh,
                  onPressed: () => provider.refreshMemories(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.overviewTagline1,
              style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.overviewTagline2,
              style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _metric(l10n.memories, total.toString()),
                const SizedBox(width: 12),
                _metric(l10n.handles, handleCount.toString()),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.lastSync(timeText(lastSync)),
              style: TextStyle(color: Colors.blueGrey[700], fontSize: 12),
            ),
            Text(
              l10n.lastAttempt(timeText(lastAttempt)),
              style: TextStyle(color: Colors.blueGrey[700], fontSize: 12),
            ),
            if (error != null && error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.lastError(error),
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

  void _onScroll() {
    final provider = context.read<MemoryProvider>();
    if (!provider.hasMore || provider.isLoadingMore) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // When near the bottom, try to load more
    if (position.pixels > position.maxScrollExtent - 200) {
      provider.loadMoreMemories();
    }
  }

  Future<void> _showHelp(BuildContext context) async {
    const docsUrl = "https://doc.yomemo.ai";
    const githubUrl = "https://github.com/yomemoai";

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final box = _helpKey.currentContext?.findRenderObject() as RenderBox?;
    final position = box != null
        ? box.localToGlobal(Offset.zero)
        : const Offset(0, 0);
    final size = box?.size ?? const Size(0, 0);
    final rect = RelativeRect.fromLTRB(
      position.dx,
      position.dy + size.height,
      overlay.size.width - position.dx,
      overlay.size.height - position.dy,
    );

    final l10n = AppLocalizations.of(context);
    final action = await showMenu<String>(
      context: context,
      position: rect,
      items: [
        PopupMenuItem(value: "docs", child: Text(l10n.docs)),
        PopupMenuItem(value: "github", child: Text(l10n.github)),
      ],
    );

    Future<void> openExternal(String url, String label) async {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.failedToOpen(label))));
      }
    }

    if (action == "docs") {
      await openExternal(docsUrl, l10n.docs);
    }
    if (action == "github") {
      await openExternal(githubUrl, l10n.github);
    }
  }

  Future<void> _showAvatarMenu(MemoryProvider provider) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final box = _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    final position = box != null
        ? box.localToGlobal(Offset.zero)
        : const Offset(0, 0);
    final size = box?.size ?? const Size(0, 0);
    final rect = RelativeRect.fromLTRB(
      position.dx,
      position.dy + size.height,
      overlay.size.width - position.dx,
      overlay.size.height - position.dy,
    );

    final action = await showMenu<String>(
      context: context,
      position: rect,
      items: [
        PopupMenuItem(
          value: "insights",
          child: Text(AppLocalizations.of(context).insights),
        ),
        PopupMenuItem(
          value: "help",
          child: Text(AppLocalizations.of(context).helpAndDocs),
        ),
      ],
    );

    if (!mounted || action == null) return;

    if (action == "insights") {
      provider.clearAlerts();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const InsightsScreen()),
      );
    } else if (action == "help") {
      await _showHelp(context);
    }
  }

  Widget _buildHandleSectionHeader(String handle, int count, bool isExpanded) {
    final l10n = AppLocalizations.of(context);
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
        padding: const EdgeInsets.only(top: 6, bottom: 4, left: 4),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 18,
              color: Colors.blueGrey[500],
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Tooltip(
                message: handle,
                child: Text(
                  localizedSectionTitle(context, handle),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.blueGrey[700],
                  ),
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey[500]),
            ),
            if (isExpanded) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.add, size: 18, color: Colors.blueGrey[600]),
                tooltip: l10n.addMemoryInHandle,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditorScreen(initialHandle: handle),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                tooltip: l10n.deleteAllInHandle,
                onPressed: () => _confirmDeleteHandle(context, handle, count),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleMemoryCard(
    BuildContext context,
    MemoryItem item,
  ) {
    final provider = context.read<MemoryProvider>();
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: provider.confirmSwipeDelete
          ? (_) async {
              final l10n = AppLocalizations.of(context);
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.deleteMemory),
                  content: Text(l10n.deleteMemoryConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              return ok == true;
            }
          : null,
      onDismissed: (_) async {
        await provider.deleteMemory(item.id);
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.lastSyncError != null
                  ? l10n.deleteFailed(provider.lastSyncError!)
                  : l10n.deleted),
            ),
          );
        }
      },
      child: _buildMemoryCard(context, item, showHandle: false),
    );
  }

  Widget _buildMemoryCard(
    BuildContext context,
    MemoryItem item, {
    bool showHandle = true,
  }) {
    final l10n = AppLocalizations.of(context);
    final isNew = context.watch<MemoryProvider>().isNewItem(item);
    final card = GestureDetector(
      onTap: () => _openDetail(context, item),
      onLongPressStart: (details) {
        _lastTapPosition = details.globalPosition;
      },
      onLongPress: () => _showMemoryMenuAt(context, item),
      child: Card(
        elevation: 2,
        color: isNew ? const Color(0xFFE0F2FE) : null,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: showHandle
              ? Tooltip(
                  message: item.handle,
                  child: Text(
                    localizedSectionTitle(context, item.handle),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
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
          leading: Icon(
            handleDisplay(item.handle).icon,
            color: Colors.blueGrey[600],
            size: 22,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNew)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    AppLocalizations.of(context).newBadge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: l10n.copy,
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
                tooltip: l10n.edit,
                onPressed: () => _openEditor(context, item),
              ),
              if (defaultTargetPlatform == TargetPlatform.macOS)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  tooltip: l10n.delete,
                  onPressed: () => _confirmDeleteMemory(context, item),
                ),
            ],
          ),
        ),
      ),
    );
    if (!isNew) return card;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      child: Container(key: ValueKey(item.id), child: card),
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
      items: [PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context).edit))],
    );

    if (!mounted) return;
    if (action == 'edit') {
      _openEditor(context, item);
    }
  }

  Future<void> _confirmDeleteMemory(BuildContext context, MemoryItem item) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteMemory),
        content: Text(l10n.deleteMemoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    final provider = context.read<MemoryProvider>();
    await provider.deleteMemory(item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.lastSyncError != null
              ? l10n.deleteFailed(provider.lastSyncError!)
              : l10n.deleted),
        ),
      );
    }
  }

  Future<void> _confirmDeleteHandle(
    BuildContext context,
    String handle,
    int count,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteEntireHandle),
        content: Text(l10n.deleteEntireHandleConfirm(count, handle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteAll),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    final provider = context.read<MemoryProvider>();
    await provider.deleteMemoriesByHandle(handle);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.lastSyncError != null
              ? l10n.deleteFailed(provider.lastSyncError!)
              : l10n.deletedCountMemories(count)),
        ),
      );
    }
  }
}
