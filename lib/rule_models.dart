import 'dart:convert';

/// A single result variable declaration for parsing Prolog query results.
class ResultVar {
  final String name;
  final String type; // id, atom, number, string
  final String displayName;
  final String displayNameZh;
  final bool hidden;

  const ResultVar({
    required this.name,
    required this.type,
    this.displayName = '',
    this.displayNameZh = '',
    this.hidden = false,
  });

  factory ResultVar.fromJson(Map<String, dynamic> j) => ResultVar(
        name: j['name'] ?? '',
        type: j['type'] ?? 'string',
        displayName: j['display_name'] ?? j['name'] ?? '',
        displayNameZh: j['display_name_zh'] ?? '',
        hidden: j['hidden'] == true,
      );
}

/// UI rendering configuration for a rule.
class UIConfig {
  final String type; // tab, alert, card, badge, banner, dashboard
  final String icon;
  final String color;
  final int? maxResults;
  final String? sortBy;
  final String sortOrder; // asc, desc
  final String emptyMessage;
  final String emptyMessageZh;
  final String groupPosition; // primary, secondary, hidden

  const UIConfig({
    required this.type,
    this.icon = '',
    this.color = '#6366f1',
    this.maxResults,
    this.sortBy,
    this.sortOrder = 'desc',
    this.emptyMessage = 'No results.',
    this.emptyMessageZh = '没有结果。',
    this.groupPosition = 'secondary',
  });

  factory UIConfig.fromJson(Map<String, dynamic> j) => UIConfig(
        type: j['type'] ?? 'tab',
        icon: j['icon'] ?? '',
        color: j['color'] ?? '#6366f1',
        maxResults: j['max_results'],
        sortBy: j['sort_by'],
        sortOrder: j['sort_order'] ?? 'desc',
        emptyMessage: j['empty_message'] ?? 'No results.',
        emptyMessageZh: j['empty_message_zh'] ?? '没有结果。',
        groupPosition: j['group_position'] ?? 'secondary',
      );
}

/// When and under what conditions a rule should execute.
class TriggerConfig {
  final String type; // on_new_memory, on_demand, periodic, on_app_open
  final int? intervalMinutes;
  final int? debounceMs;
  final List<String>? conditionHandles;
  final List<String>? conditionTags;

  const TriggerConfig({
    required this.type,
    this.intervalMinutes,
    this.debounceMs,
    this.conditionHandles,
    this.conditionTags,
  });

  factory TriggerConfig.fromJson(Map<String, dynamic> j) {
    final cond = j['conditions'] as Map<String, dynamic>?;
    return TriggerConfig(
      type: j['type'] ?? 'on_demand',
      intervalMinutes: j['interval_minutes'],
      debounceMs: j['debounce_ms'],
      conditionHandles: (cond?['handles'] as List?)?.cast<String>(),
      conditionTags: (cond?['tags'] as List?)?.cast<String>(),
    );
  }
}

/// A single reasoning rule: query + UI metadata + trigger config.
class Rule {
  final String id;
  final String name;
  final String nameZh;
  final String description;
  final String descriptionZh;
  final String query;
  final List<ResultVar> resultVars;
  final UIConfig ui;
  final TriggerConfig trigger;
  final String priority; // critical, high, medium, low
  final String category; // conflict, insight, health, productivity, exploration, overview
  final bool enabled;
  final bool premium;

  const Rule({
    required this.id,
    required this.name,
    this.nameZh = '',
    this.description = '',
    this.descriptionZh = '',
    required this.query,
    required this.resultVars,
    required this.ui,
    required this.trigger,
    this.priority = 'medium',
    this.category = 'insight',
    this.enabled = true,
    this.premium = false,
  });

  factory Rule.fromJson(Map<String, dynamic> j) => Rule(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        nameZh: j['name_zh'] ?? '',
        description: j['description'] ?? '',
        descriptionZh: j['description_zh'] ?? '',
        query: j['query'] ?? '',
        resultVars: (j['result_vars'] as List? ?? [])
            .map((v) => ResultVar.fromJson(v as Map<String, dynamic>))
            .toList(),
        ui: UIConfig.fromJson(j['ui'] as Map<String, dynamic>? ?? {}),
        trigger:
            TriggerConfig.fromJson(j['trigger'] as Map<String, dynamic>? ?? {}),
        priority: j['priority'] ?? 'medium',
        category: j['category'] ?? 'insight',
        enabled: j['enabled'] != false,
        premium: j['premium'] == true,
      );
}

/// A complete ruleset: metadata + fact schema + Prolog source + rules.
class RuleSet {
  final String id;
  final String name;
  final String version;
  final String updatedAt;
  final String prologSource;
  final List<Rule> rules;

  const RuleSet({
    required this.id,
    required this.name,
    required this.version,
    required this.updatedAt,
    this.prologSource = '',
    required this.rules,
  });

  factory RuleSet.fromJson(Map<String, dynamic> j) {
    final meta = j['meta'] as Map<String, dynamic>? ?? {};
    return RuleSet(
      id: meta['id'] ?? '',
      name: meta['name'] ?? '',
      version: meta['version'] ?? '0.0.0',
      updatedAt: meta['updated_at'] ?? '',
      prologSource: j['prolog_source'] ?? '',
      rules: (j['rules'] as List? ?? [])
          .map((r) => Rule.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  factory RuleSet.fromJsonString(String jsonStr) =>
      RuleSet.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
}

/// Result of executing a single rule against the memory set.
class RuleResult {
  final Rule rule;
  final List<Map<String, dynamic>> rows;
  final DateTime executedAt;

  const RuleResult({
    required this.rule,
    required this.rows,
    required this.executedAt,
  });

  int get count => rows.length;
  bool get isEmpty => rows.isEmpty;
}
