import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'rule_models.dart';
import 'memory_provider.dart';
import 'prolog_service.dart';
import 'api_service.dart';

const String _kCachedRuleSetKey = 'cached_ruleset_json';
const String _kDefaultAsset = 'assets/rules/default-ruleset.json';

/// Rule engine: loads rulesets and evaluates rules via embedded Tau Prolog.
///
/// Primary path: Tau Prolog (via flutter_js)
/// Fallback: pure Dart evaluation (if Prolog init fails)
class RuleEngine {
  RuleSet? _ruleSet;
  final PrologService _prolog = PrologService();
  bool _prologReady = false;
  final ApiService? _api;

  RuleEngine({ApiService? apiService}) : _api = apiService;

  RuleSet? get ruleSet => _ruleSet;
  bool get usesProlog => _prologReady;
  List<Rule> get enabledRules =>
      _ruleSet?.rules.where((r) => r.enabled).toList() ?? [];

  // ───────── Loading ─────────

  /// Initialize: load ruleset + Prolog engine.
  Future<void> init() async {
    // 1) Try to load ruleset from API (cloud hot-update)
    var loaded = false;
    if (_api != null) {
      loaded = await _tryLoadFromApi();
    }

    // 2) Fallback: cached ruleset from SharedPreferences or bundled asset
    if (!loaded) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kCachedRuleSetKey);
      if (cached != null && cached.isNotEmpty) {
        try {
          _ruleSet = RuleSet.fromJsonString(cached);
        } catch (_) {
          await _loadDefault();
        }
      } else {
        await _loadDefault();
      }
    }

    // Initialize Prolog engine
    try {
      await _prolog.init();
      _prologReady = true;
      debugPrint('[RuleEngine] Prolog engine ready');
    } catch (e) {
      debugPrint('[RuleEngine] Prolog init failed, using Dart fallback: $e');
      _prologReady = false;
    }
  }

  /// Try to fetch the latest ruleset from the API. Returns true on success.
  Future<bool> _tryLoadFromApi() async {
    try {
      final jsonStr = await _api!.fetchRulesetJson();
      if (jsonStr == null || jsonStr.isEmpty) {
        return false;
      }
      await applyRuleSet(jsonStr);
      debugPrint('[RuleEngine] Loaded ruleset from API');
      return true;
    } catch (e) {
      debugPrint('[RuleEngine] Failed to fetch ruleset from API, falling back to cache/bundled: $e');
      return false;
    }
  }

  Future<void> _loadDefault() async {
    final jsonStr = await rootBundle.loadString(_kDefaultAsset);
    _ruleSet = RuleSet.fromJsonString(jsonStr);
  }

  /// Apply a ruleset from a JSON string (cloud download or manual import).
  Future<void> applyRuleSet(String jsonStr) async {
    _ruleSet = RuleSet.fromJsonString(jsonStr);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedRuleSetKey, jsonStr);
  }

  /// Reset to the bundled default ruleset.
  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCachedRuleSetKey);
    await _loadDefault();
  }

  void dispose() {
    _prolog.dispose();
  }

  // ───────── Execution ─────────

  /// Execute all enabled rules against the given memories.
  List<RuleResult> executeAll(List<MemoryItem> memories) {
    if (_prologReady && _ruleSet != null) {
      return _executeWithProlog(memories);
    }
    return _executeWithDart(memories);
  }

  /// Execute rules matching a trigger type.
  List<RuleResult> executeByTrigger(
    String triggerType,
    List<MemoryItem> memories,
  ) {
    final rules = enabledRules.where((r) => r.trigger.type == triggerType);
    if (_prologReady && _ruleSet != null) {
      return _prologBatch(rules.toList(), memories);
    }
    return rules.map((r) => _executeDartRule(r, memories)).toList();
  }

  // ───────── Prolog Execution ─────────

  List<RuleResult> _executeWithProlog(List<MemoryItem> memories) {
    // Build facts from memory items + load rule definitions
    final facts = PrologService.memoriesToProlog(memories);
    final program = '$facts\n${_ruleSet!.prologSource}';
    final error = _prolog.consult(program);

    if (error != null) {
      debugPrint('[RuleEngine] Prolog consult error: $error');
      return _executeWithDart(memories);
    }

    return _prologQueryAll(enabledRules, memories);
  }

  /// Consult once, then run multiple queries.
  List<RuleResult> _prologBatch(
    List<Rule> rules,
    List<MemoryItem> memories,
  ) {
    final facts = PrologService.memoriesToProlog(memories);
    final program = '$facts\n${_ruleSet!.prologSource}';
    final error = _prolog.consult(program);

    if (error != null) {
      debugPrint('[RuleEngine] Prolog consult error: $error');
      return rules.map((r) => _executeDartRule(r, memories)).toList();
    }

    return _prologQueryAll(rules, memories);
  }

  /// Run query for each rule on the already-consulted session.
  List<RuleResult> _prologQueryAll(
    List<Rule> rules,
    List<MemoryItem> memories,
  ) {
    final results = <RuleResult>[];
    for (final rule in rules) {
      final varNames = rule.resultVars.map((v) => v.name).toList();
      var rows = _prolog.query(rule.query, varNames);

      // If Prolog query fails, try Dart fallback for this rule
      // (rows will be empty on error, which is fine for most cases)

      rows = _sortAndLimit(rows, rule);

      results.add(RuleResult(
        rule: rule,
        rows: rows,
        executedAt: DateTime.now(),
      ));
    }
    return results;
  }

  // ───────── Dart Fallback ─────────

  List<RuleResult> _executeWithDart(List<MemoryItem> memories) {
    debugPrint('[RuleEngine] Executing with Dart fallback');
    return enabledRules
        .map((r) => _executeDartRule(r, memories))
        .toList();
  }

  RuleResult _executeDartRule(Rule rule, List<MemoryItem> memories) {
    var rows = _evaluateDart(rule.id, memories);
    rows = _sortAndLimit(rows, rule);
    return RuleResult(rule: rule, rows: rows, executedAt: DateTime.now());
  }

  List<Map<String, dynamic>> _sortAndLimit(
    List<Map<String, dynamic>> rows,
    Rule rule,
  ) {
    final sortBy = rule.ui.sortBy;
    if (sortBy != null && rows.isNotEmpty) {
      rows.sort((a, b) {
        final va = a[sortBy];
        final vb = b[sortBy];
        if (va is num && vb is num) {
          return rule.ui.sortOrder == 'asc'
              ? va.compareTo(vb)
              : vb.compareTo(va);
        }
        return 0;
      });
    }
    if (rule.ui.maxResults != null && rows.length > rule.ui.maxResults!) {
      rows = rows.sublist(0, rule.ui.maxResults!);
    }
    return rows;
  }

  // ───────── Dart-based Rule Evaluation (fallback) ─────────

  List<Map<String, dynamic>> _evaluateDart(
    String ruleId,
    List<MemoryItem> memories,
  ) {
    switch (ruleId) {
      case 'overview':
        return _overview(memories);
      case 'focus_conflict':
        return _focusConflict(memories);
      case 'high_value':
        return _highValue(memories);
      case 'roi_ranking':
        return _roiRanking(memories);
      case 'backlog_features':
        return _backlogFeatures(memories);
      case 'emotional_memories':
        return _emotionalMemories(memories);
      case 'yomemo_ecosystem':
        return _yomemoEcosystem(memories);
      case 'cross_domain':
        return _crossDomain(memories);
      case 'actionable':
        return _actionable(memories);
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _overview(List<MemoryItem> m) {
    return m.where((x) => x.hasFingerprint).map((x) => {
          'ID': x.id, 'Handle': x.handle, 'Desc': x.description,
          'Layer': x.layer, 'Mode': x.ontologyMode, 'Status': x.vcsStatus,
        }).toList();
  }

  List<Map<String, dynamic>> _focusConflict(List<MemoryItem> m) {
    final plans = m.where((x) =>
        x.handle == 'plan' && x.tags.contains('focus') && x.vcsStatus == 'Active');
    if (plans.isEmpty) return [];
    final pid = plans.first.id;
    return m.where((x) =>
        x.id != pid && x.handle != 'plan' && x.handle != 'user-goals' &&
        x.vcsStatus != 'Backlog' && x.vcsStatus != 'Active' && x.hasFingerprint)
      .map((x) => {'PlanID': pid, 'OtherID': x.id, 'Handle': x.handle, 'Desc': x.description})
      .toList();
  }

  List<Map<String, dynamic>> _highValue(List<MemoryItem> m) {
    final rows = <Map<String, dynamic>>[];
    for (final x in m.where((x) => x.hasFingerprint)) {
      final s = x.elapL + x.elapA + x.elapP;
      if (s > 2.0) rows.add({'ID': x.id, 'Handle': x.handle, 'Score': _r(s)});
    }
    rows.sort((a, b) => (b['Score'] as double).compareTo(a['Score'] as double));
    return rows;
  }

  List<Map<String, dynamic>> _roiRanking(List<MemoryItem> m) {
    final rows = <Map<String, dynamic>>[];
    for (final x in m.where((x) => x.hasFingerprint)) {
      final s = (x.elapP * x.elapL) / (1 + x.elapE);
      rows.add({'ID': x.id, 'Handle': x.handle, 'Score': _r(s)});
    }
    rows.sort((a, b) => (b['Score'] as double).compareTo(a['Score'] as double));
    return rows;
  }

  List<Map<String, dynamic>> _backlogFeatures(List<MemoryItem> m) =>
      m.where((x) => x.tags.contains('feature') && x.vcsStatus == 'Backlog')
       .map((x) => {'ID': x.id, 'Handle': x.handle, 'Desc': x.description})
       .toList();

  List<Map<String, dynamic>> _emotionalMemories(List<MemoryItem> m) =>
      m.where((x) => x.hasFingerprint && x.elapE > 0.6)
       .map((x) => {'ID': x.id, 'Handle': x.handle, 'E': _r(x.elapE), 'Desc': x.description})
       .toList();

  List<Map<String, dynamic>> _yomemoEcosystem(List<MemoryItem> m) =>
      m.where((x) => x.tags.contains('yomemo'))
       .map((x) => {'ID': x.id, 'Handle': x.handle, 'Desc': x.description, 'Status': x.vcsStatus})
       .toList();

  List<Map<String, dynamic>> _crossDomain(List<MemoryItem> m) {
    final wt = m.where((x) => x.tags.isNotEmpty).toList();
    final rows = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (var i = 0; i < wt.length; i++) {
      for (var j = i + 1; j < wt.length; j++) {
        if (wt[i].handle == wt[j].handle) continue;
        for (final t in wt[i].tags.where((t) => t != 'yomemo' && wt[j].tags.contains(t))) {
          final k = '${wt[i].id}|${wt[j].id}|$t';
          if (seen.add(k)) {
            rows.add({'ID1': wt[i].id, 'H1': wt[i].handle, 'ID2': wt[j].id, 'H2': wt[j].handle, 'Tag': t});
          }
        }
      }
    }
    return rows;
  }

  List<Map<String, dynamic>> _actionable(List<MemoryItem> m) =>
      m.where((x) => x.hasFingerprint && x.elapP >= 0.8 && x.vcsStatus == 'Active')
       .map((x) => {'ID': x.id, 'Handle': x.handle, 'Desc': x.description, 'P': _r(x.elapP)})
       .toList();

  double _r(double v) => (v * 100).roundToDouble() / 100;
}
