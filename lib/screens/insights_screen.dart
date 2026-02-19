import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../memory_provider.dart';
import '../rule_engine.dart';
import '../rule_models.dart';
import '../l10n/app_localizations.dart';
import 'memory_detail_screen.dart';
import 'editor_screen.dart';

/// Maps icon name strings from the ruleset JSON to Material icons.
IconData _iconFromName(String name) {
  switch (name) {
    case 'list_alt':
      return Icons.list_alt;
    case 'warning':
      return Icons.warning_amber_rounded;
    case 'star':
      return Icons.star_rounded;
    case 'bar_chart':
      return Icons.bar_chart_rounded;
    case 'inventory_2':
      return Icons.inventory_2_outlined;
    case 'favorite':
      return Icons.favorite_rounded;
    case 'hub':
      return Icons.hub_rounded;
    case 'link':
      return Icons.link_rounded;
    case 'rocket_launch':
      return Icons.rocket_launch_rounded;
    default:
      return Icons.auto_awesome;
  }
}

Color _colorFromHex(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
  return const Color(0xFF6366F1);
}

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<RuleResult> _results = [];
  bool _loading = true;
  String? _selectedCategory;
  bool _isZh = false;
  Offset? _lastTapPosition;

  RuleEngine get _engine => context.read<MemoryProvider>().ruleEngine;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final provider = context.read<MemoryProvider>();
    // If engine not ready yet, wait for it
    if (!provider.ruleEngineReady) {
      await provider.ruleEngine.init();
    }
    _runAll();
  }

  void _runAll() {
    final memories = context.read<MemoryProvider>().items;
    setState(() {
      _results = _engine.executeAll(memories);
      _loading = false;
    });
  }

  // Unique categories from enabled rules
  List<String> get _categories {
    final cats = _engine.enabledRules.map((r) => r.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<RuleResult> get _filteredResults {
    if (_selectedCategory == null) return _results;
    return _results.where((r) => r.rule.category == _selectedCategory).toList();
  }

  // Alert-worthy results (critical/high priority with non-empty results)
  List<RuleResult> get _alerts {
    return _results.where((r) =>
        !r.isEmpty &&
        (r.rule.priority == 'critical' || r.rule.priority == 'high') &&
        (r.rule.ui.type == 'alert' || r.rule.ui.type == 'banner')).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.insights),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _engine.usesProlog
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _engine.usesProlog ? 'Prolog' : 'Dart',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _engine.usesProlog ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isZh ? Icons.translate : Icons.language),
            tooltip: _isZh ? 'English' : '中文',
            onPressed: () => setState(() => _isZh = !_isZh),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-run',
            onPressed: () {
              setState(() => _loading = true);
              _runAll();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              if (action == 'reset') {
                _engine.resetToDefault().then((_) => _runAll());
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'reset',
                child: Text(l10n.resetToDefaultRules),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Alerts banner
        if (_alerts.isNotEmpty) _buildAlertBanner(),
        // Category chips
        _buildCategoryChips(),
        // Results list
        Expanded(child: _buildResultsList()),
      ],
    );
  }

  Widget _buildAlertBanner() {
    final alert = _alerts.first;
    final color = _colorFromHex(alert.rule.ui.color);
    final name = _isZh && alert.rule.nameZh.isNotEmpty
        ? alert.rule.nameZh
        : alert.rule.name;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(_iconFromName(alert.rule.ui.icon), color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$name: ${alert.count} items',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            alert.rule.priority.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip('All', null),
            ..._categories.map((c) => _chip(c, c)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String? category) {
    final selected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label[0].toUpperCase() + label.substring(1)),
        selected: selected,
        onSelected: (_) => setState(() => _selectedCategory = category),
      ),
    );
  }

  Widget _buildResultsList() {
    final filtered = _filteredResults;
    if (filtered.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noRulesToDisplay));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildRuleCard(filtered[index]),
    );
  }

  Widget _buildRuleCard(RuleResult result) {
    final rule = result.rule;
    final color = _colorFromHex(rule.ui.color);
    final icon = _iconFromName(rule.ui.icon);
    final name = _isZh && rule.nameZh.isNotEmpty ? rule.nameZh : rule.name;
    final desc = _isZh && rule.descriptionZh.isNotEmpty
        ? rule.descriptionZh
        : rule.description;
    final emptyMsg = _isZh && rule.ui.emptyMessageZh.isNotEmpty
        ? rule.ui.emptyMessageZh
        : rule.ui.emptyMessage;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              _countBadge(result.count, color),
            ],
          ),
          subtitle: Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
          ),
          children: [
            if (result.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  emptyMsg,
                  style: TextStyle(
                    color: Colors.blueGrey[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              _buildResultRows(context, result),
          ],
        ),
      ),
    );
  }

  Widget _countBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: count > 0
            ? color.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: count > 0 ? color : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildResultRows(BuildContext context, RuleResult result) {
    final visibleVars = result.rule.resultVars.where((v) => !v.hidden).toList();
    if (visibleVars.isEmpty || result.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final provider = context.read<MemoryProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: visibleVars
                  .map((v) => _headerCell(
                        _isZh && v.displayNameZh.isNotEmpty
                            ? v.displayNameZh
                            : v.displayName,
                        v,
                      ))
                  .toList(),
            ),
          ),
          // Rows
          ...result.rows.take(20).map(
                (row) {
                  final memory = _findMemoryForRow(result, row, provider);
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade100,
                        ),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTapDown: (details) {
                          _lastTapPosition = details.globalPosition;
                        },
                        onTap: memory == null
                            ? null
                            : () => _openDetail(context, memory),
                        // mac 触摸板双击（以及桌面鼠标双击）也弹出菜单，和长按一致
                        onDoubleTap: memory == null
                            ? null
                            : () => _showMemoryMenuAt(context, memory),
                        onLongPress: memory == null
                            ? null
                            : () => _showMemoryMenuAt(context, memory),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: visibleVars
                                .map((v) => _dataCell(row[v.name], v))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          if (result.rows.length > 20)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... and ${result.rows.length - 20} more',
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerCell(String label, ResultVar v) {
    final flex = v.type == 'string' ? 3 : (v.type == 'id' ? 2 : 1);
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.blueGrey[700],
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _dataCell(dynamic value, ResultVar v) {
    final flex = v.type == 'string' ? 3 : (v.type == 'id' ? 2 : 1);
    String text;
    if (value is double) {
      text = value.toStringAsFixed(2);
    } else if (value is num) {
      text = value.toString();
    } else {
      text = value?.toString() ?? '-';
    }

    // Truncate IDs for readability
    if (v.type == 'id' && text.length > 12) {
      text = '${text.substring(0, 8)}...';
    }

    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  MemoryItem? _findMemoryForRow(
    RuleResult result,
    Map<String, dynamic> row,
    MemoryProvider provider,
  ) {
    // Prefer variables typed as 'id' in the ruleset; use the first match.
    for (final v in result.rule.resultVars.where((v) => v.type == 'id')) {
      final val = row[v.name];
      if (val is String && val.isNotEmpty) {
        try {
          return provider.items.firstWhere((m) => m.id == val);
        } catch (_) {
          // no match for this id, try next
        }
      }
    }
    return null;
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

  Future<void> _showMemoryMenuAt(
    BuildContext context,
    MemoryItem item,
  ) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = _lastTapPosition ?? overlay.size.center(Offset.zero);
    final rect = RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & overlay.size,
    );

    final l10n = AppLocalizations.of(context);
    final action = await showMenu<String>(
      context: context,
      position: rect,
      items: [
        PopupMenuItem(value: 'detail', child: Text(l10n.openDetails)),
        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
      ],
    );

    if (!mounted || action == null) return;
    if (action == 'detail') {
      _openDetail(context, item);
    } else if (action == 'edit') {
      _openEditor(context, item);
    }
  }
}
