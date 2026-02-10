import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'api_service.dart';
import 'crypto_service.dart';
import 'rule_engine.dart';
import 'rule_models.dart';

const String kClientVersion = "v0.0.5";
const String _kPrefLocalPassword = "local_password_hash";
const String _kPrefLockTimeout = "lock_timeout_minutes";
const String _kPrefAutoSaveSeconds = "auto_save_seconds";
const String _kPrefConfirmSwipeDelete = "confirm_swipe_delete";
const String _kPrefShowInsightsBadge = "show_insights_badge";
const String _kPrefAlertHaptics = "alert_haptics_enabled";

class MemoryItem {
  final String id;
  final String handle, description, idempotentKey, content;
  final Map<String, dynamic>? metadata;

  MemoryItem({
    required this.id,
    required this.handle,
    required this.description,
    required this.idempotentKey,
    required this.content,
    this.metadata,
  });

  // --- Semantic Fingerprint accessors (from metadata) ---

  Map<String, dynamic>? get _fingerprint {
    final sf = metadata?['semantic_fingerprint'];
    if (sf is Map<String, dynamic>) return sf;
    return null;
  }

  bool get hasFingerprint => _fingerprint != null;

  double get elapE =>
      (_fingerprint?['metrics']?['E'] as num?)?.toDouble() ?? 0.0;
  double get elapL =>
      (_fingerprint?['metrics']?['L'] as num?)?.toDouble() ?? 0.0;
  double get elapA =>
      (_fingerprint?['metrics']?['A'] as num?)?.toDouble() ?? 0.0;
  double get elapP =>
      (_fingerprint?['metrics']?['P'] as num?)?.toDouble() ?? 0.0;

  List<String> get tags {
    final t = _fingerprint?['classification']?['tags'];
    if (t is List) return t.cast<String>();
    return [];
  }

  String get layer =>
      _fingerprint?['classification']?['layer']?.toString() ?? '';

  String get ontologyMode =>
      _fingerprint?['ontology']?['mode']?.toString() ?? '';

  String get ontologyDep =>
      _fingerprint?['ontology']?['dependency']?.toString() ?? '';

  String get vcsStatus =>
      _fingerprint?['vcs']?['status']?.toString() ?? '';

  String get vcsStack =>
      _fingerprint?['vcs']?['stack']?.toString() ?? '';
}

class MemoryProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final CryptoService _crypto = CryptoService();

  List<MemoryItem> items = [];
  String apiKey = "";
  String pkPath = "";
  bool isLoading = false;
  DateTime? lastSyncAt;
  DateTime? lastSyncAttemptAt;
  String? lastSyncError;
  bool hasLoadedOnce = false;
  final Set<String> _newItemIds = {};

  // Pagination state for cursor-based loading
  String _nextCursor = "";
  bool _hasMore = true;
  bool _isLoadingMore = false;
  /// Total count of memories on the server (from search response). 0 if not yet known.
  int _totalCount = 0;

  String _localPasswordHash = "";
  int _lockTimeoutMinutes = 15;
  int _autoSaveSeconds = 5;
  bool _confirmSwipeDelete = true;
  DateTime _lastActive = DateTime.now();
  bool _isLocked = false;
  Timer? _lockTimer;
  Timer? _autoRefreshTimer;

  // ───────── User Profile (for UI display) ─────────
  String _userEmail = "";
  String _userPlan = "";
  String _userAvatarUrl = "";

  bool _showInsightsBadge = true;
  bool _alertHapticsEnabled = false;

  // ───────── Rule Engine & Triggers ─────────
  late final RuleEngine ruleEngine = RuleEngine(apiService: _api);
  Timer? _periodicRuleTimer;
  List<RuleResult> _pendingAlerts = [];
  final Map<String, DateTime> _lastPeriodicRun = {};
  bool _ruleEngineReady = false;

  bool get ruleEngineReady => _ruleEngineReady;
  List<RuleResult> get pendingAlerts => _pendingAlerts;
  int get pendingAlertCount =>
      _pendingAlerts.where((r) => !r.isEmpty).length;

  void clearAlerts() {
    _pendingAlerts = [];
    notifyListeners();
  }

  bool get hasLocalPassword => _localPasswordHash.isNotEmpty;
  bool get isLocked => _isLocked;
  int get lockTimeoutMinutes => _lockTimeoutMinutes;
  int get autoSaveSeconds => _autoSaveSeconds;
  bool get confirmSwipeDelete => _confirmSwipeDelete;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasValidCrypto => _crypto.isInitialized;
  /// Total number of memories on the server. Use for summary; falls back to items.length if 0 and we have items.
  int get totalCount => _totalCount > 0 ? _totalCount : items.length;

  String get userEmail => _userEmail;
  String get userPlan => _userPlan;
  String get userAvatarUrl => _userAvatarUrl;
  bool get showInsightsBadge => _showInsightsBadge;
  bool get alertHapticsEnabled => _alertHapticsEnabled;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    apiKey = prefs.getString('api_key') ?? "";
    pkPath = prefs.getString('pk_path') ?? "";
    _localPasswordHash = prefs.getString(_kPrefLocalPassword) ?? "";
    _lockTimeoutMinutes = prefs.getInt(_kPrefLockTimeout) ?? 15;
    _autoSaveSeconds = prefs.getInt(_kPrefAutoSaveSeconds) ?? 5;
    _confirmSwipeDelete = prefs.getBool(_kPrefConfirmSwipeDelete) ?? true;
    _showInsightsBadge = prefs.getBool(_kPrefShowInsightsBadge) ?? true;
    _alertHapticsEnabled = prefs.getBool(_kPrefAlertHaptics) ?? false;

    if (apiKey.isNotEmpty) {
      _api.updateApiKey(apiKey);
      _loadUserProfile();
    }
    if (apiKey.isNotEmpty && pkPath.isNotEmpty) {
      final file = File(pkPath);
      if (await file.exists()) {
        _crypto.init(await file.readAsString());
        await refreshMemories();
      }
    }
    _startLockTimerIfNeeded();
    _startAutoRefreshIfNeeded();
    // Init rule engine after memories are available
    _initRuleEngine();
    notifyListeners();
  }

  Future<void> saveSettings(String key, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', key);
    await prefs.setString('pk_path', path);
    await loadSettings();
  }

  Future<void> _loadUserProfile() async {
    try {
      final me = await _api.fetchMe();
      _userEmail = me['email']?.toString() ?? "";
      _userPlan = me['plan']?.toString() ?? "";
      _userAvatarUrl = me['avatar_url']?.toString() ?? "";
      notifyListeners();
    } catch (e) {
      debugPrint("Load user profile error: $e");
    }
  }

  // ───────── Rule Engine Lifecycle ─────────

  Future<void> _initRuleEngine() async {
    try {
      await ruleEngine.init();
      _ruleEngineReady = true;
      debugPrint('[MemoryProvider] RuleEngine ready (prolog=${ruleEngine.usesProlog})');
      // Run on_app_open triggers once
      _runTrigger('on_app_open');
      // Start periodic check timer
      _startPeriodicRuleTimer();
    } catch (e) {
      debugPrint('[MemoryProvider] RuleEngine init failed: $e');
      _ruleEngineReady = false;
    }
  }

  void _startPeriodicRuleTimer() {
    _periodicRuleTimer?.cancel();
    // Check every 5 minutes whether any periodic rule interval has elapsed
    _periodicRuleTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isLocked || items.isEmpty || !_ruleEngineReady) return;
      _runPeriodicRulesIfNeeded();
    });
  }

  /// Check each periodic rule; only re-run if its interval has elapsed.
  void _runPeriodicRulesIfNeeded() {
    if (!_ruleEngineReady || items.isEmpty) return;

    final periodicRules = ruleEngine.enabledRules
        .where((r) => r.trigger.type == 'periodic')
        .toList();
    if (periodicRules.isEmpty) return;

    final now = DateTime.now();
    final dueRules = <Rule>[];

    for (final rule in periodicRules) {
      final lastRun = _lastPeriodicRun[rule.id];
      final interval =
          Duration(minutes: rule.trigger.intervalMinutes ?? 1440);
      if (lastRun == null || now.difference(lastRun) >= interval) {
        dueRules.add(rule);
        _lastPeriodicRun[rule.id] = now;
      }
    }

    if (dueRules.isEmpty) return;

    debugPrint('[MemoryProvider] Running ${dueRules.length} periodic rule(s)');
    final results = ruleEngine.executeByTrigger('periodic', items);
    _mergeAlerts(results);
  }

  /// Execute rules for a specific trigger type and merge results into alerts.
  void _runTrigger(String triggerType) {
    if (!_ruleEngineReady || items.isEmpty) return;
    debugPrint('[MemoryProvider] Running trigger: $triggerType');
    final results = ruleEngine.executeByTrigger(triggerType, items);
    _mergeAlerts(results);
  }

  /// Merge non-empty results into pending alerts and notify listeners.
  void _mergeAlerts(List<RuleResult> results) {
    final nonEmpty = results.where((r) => !r.isEmpty).toList();
    if (nonEmpty.isEmpty) return;

    final beforeCount =
        _pendingAlerts.where((r) => !r.isEmpty).length;

    // Replace existing alerts for the same rule id, add new ones
    final alertMap = <String, RuleResult>{
      for (final a in _pendingAlerts) a.rule.id: a,
    };
    for (final r in nonEmpty) {
      alertMap[r.rule.id] = r;
    }
    _pendingAlerts = alertMap.values.toList();

    final afterCount =
        _pendingAlerts.where((r) => !r.isEmpty).length;
    if (afterCount > beforeCount &&
        !_isLocked &&
        _alertHapticsEnabled) {
      _triggerAlertFeedback();
    }

    notifyListeners();
  }

  void _triggerAlertFeedback() {
    // Light haptic / system click when new insights arrive.
    // Safe to call on platforms that ignore haptics.
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  void _startAutoRefreshIfNeeded() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (apiKey.isEmpty || !_crypto.isInitialized || _isLocked) return;
      refreshMemories();
    });
  }

  Future<void> setLocalPassword(String password) async {
    final hash = sha256.convert(utf8.encode(password)).toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefLocalPassword, hash);
    _localPasswordHash = hash;
    _isLocked = false;
    _lastActive = DateTime.now();
    _startLockTimerIfNeeded();
    notifyListeners();
  }

  bool verifyLocalPassword(String password) {
    final hash = sha256.convert(utf8.encode(password)).toString();
    if (hash == _localPasswordHash) {
      _isLocked = false;
      _lastActive = DateTime.now();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> updateLockTimeoutMinutes(int minutes) async {
    _lockTimeoutMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefLockTimeout, minutes);
    notifyListeners();
  }

  Future<void> updateAutoSaveSeconds(int seconds) async {
    _autoSaveSeconds = seconds.clamp(1, 300);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefAutoSaveSeconds, _autoSaveSeconds);
    notifyListeners();
  }

  Future<void> updateConfirmSwipeDelete(bool value) async {
    _confirmSwipeDelete = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefConfirmSwipeDelete, _confirmSwipeDelete);
    notifyListeners();
  }

  Future<void> updateShowInsightsBadge(bool value) async {
    _showInsightsBadge = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefShowInsightsBadge, _showInsightsBadge);
    notifyListeners();
  }

  Future<void> updateAlertHaptics(bool value) async {
    _alertHapticsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefAlertHaptics, _alertHapticsEnabled);
    notifyListeners();
  }

  void recordActivity() {
    _lastActive = DateTime.now();
    if (_isLocked) return;
  }

  void _startLockTimerIfNeeded() {
    _lockTimer?.cancel();
    if (!hasLocalPassword) return;
    _lockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _evaluateLock();
    });
  }

  void _evaluateLock() {
    if (!hasLocalPassword || _isLocked) return;
    final idle = DateTime.now().difference(_lastActive);
    if (idle >= Duration(minutes: _lockTimeoutMinutes)) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void lockNow() {
    if (!hasLocalPassword) return;
    _isLocked = true;
    notifyListeners();
  }

  Future<void> refreshMemories() async {
    if (apiKey.isEmpty || !_crypto.isInitialized) return;
    // Reset pagination state
    _nextCursor = "";
    _hasMore = true;
    _isLoadingMore = false;
    isLoading = items.isEmpty && !hasLoadedOnce;
    lastSyncAttemptAt = DateTime.now();
    notifyListeners();

    try {
      final result = await _api.fetchMemories(limit: 50);
      final rawData = result["data"] as List<dynamic>? ?? [];
      _nextCursor = (result["nextCursor"] as String? ?? "").trim();
      _hasMore = _nextCursor.isNotEmpty;
      final totalFromApi = result["total"];
      if (totalFromApi is int && totalFromApi >= 0) {
        _totalCount = totalFromApi;
      }

      final prevIds = items.map((e) => e.id).toSet();
      String asString(dynamic v, {String fallback = ""}) {
        if (v == null) return fallback;
        return v.toString();
      }

      final nextItems = rawData.whereType<Map>().map((raw) {
        final j = raw;
        final String id = asString(
          j['id'],
          fallback: asString(j['idempotent_key'], fallback: ""),
        );
        final String handle = asString(j['handle'], fallback: "No Handle");
        final String desc = asString(j['description'], fallback: "");
        final String key = asString(
          j['idempotent_key'],
          fallback: asString(j['id'], fallback: ""),
        );

        final String? rawContent = j.containsKey('content')
            ? asString(j['content'])
            : null;

        String decryptedContent = "";
        if (rawContent != null && rawContent.isNotEmpty) {
          decryptedContent = _crypto.decrypt(rawContent);
        } else {
          decryptedContent = "[Empty]";
        }

        final Map<String, dynamic>? meta =
            j['metadata'] is Map ? Map<String, dynamic>.from(j['metadata'] as Map) : null;

        return MemoryItem(
          id: id.isNotEmpty ? id : key,
          handle: handle,
          description: desc,
          idempotentKey: key,
          content: decryptedContent,
          metadata: meta,
        );
      }).toList();
      items = nextItems;
      _newItemIds
        ..clear()
        ..addAll(
          nextItems.map((e) => e.id).where((id) => !prevIds.contains(id)),
        );
      lastSyncAt = DateTime.now();
      lastSyncError = null;
      hasLoadedOnce = true;
    } catch (e) {
      debugPrint("Refresh Error: $e");
      lastSyncError = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Load the next page of memories (if any) and append to the list.
  Future<void> loadMoreMemories() async {
    if (apiKey.isEmpty || !_crypto.isInitialized) return;
    if (!_hasMore || _isLoadingMore) return;
    if (_nextCursor.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result =
          await _api.fetchMemories(cursor: _nextCursor, limit: 50);
      final rawData = result["data"] as List<dynamic>? ?? [];
      final newCursor = (result["nextCursor"] as String? ?? "").trim();

      if (rawData.isEmpty) {
        _hasMore = false;
        _nextCursor = "";
      } else {
        String asString(dynamic v, {String fallback = ""}) {
          if (v == null) return fallback;
          return v.toString();
        }

        final prevIds = items.map((e) => e.id).toSet();
        final moreItems = rawData.whereType<Map>().map((raw) {
          final j = raw;
          final String id = asString(
            j['id'],
            fallback: asString(j['idempotent_key'], fallback: ""),
          );
          final String handle = asString(j['handle'], fallback: "No Handle");
          final String desc = asString(j['description'], fallback: "");
          final String key = asString(
            j['idempotent_key'],
            fallback: asString(j['id'], fallback: ""),
          );

          final String? rawContent = j.containsKey('content')
              ? asString(j['content'])
              : null;

          String decryptedContent = "";
          if (rawContent != null && rawContent.isNotEmpty) {
            decryptedContent = _crypto.decrypt(rawContent);
          } else {
            decryptedContent = "[Empty]";
          }

          final Map<String, dynamic>? meta =
              j['metadata'] is Map ? Map<String, dynamic>.from(j['metadata'] as Map) : null;

          return MemoryItem(
            id: id.isNotEmpty ? id : key,
            handle: handle,
            description: desc,
            idempotentKey: key,
            content: decryptedContent,
            metadata: meta,
          );
        }).toList();

        items = [...items, ...moreItems];
        _newItemIds.addAll(
          moreItems
              .map((e) => e.id)
              .where((id) => !prevIds.contains(id)),
        );
        _nextCursor = newCursor;
        _hasMore = _nextCursor.isNotEmpty;
        lastSyncAt = DateTime.now();
        lastSyncError = null;
      }
    } catch (e) {
      debugPrint("LoadMore Error: $e");
      lastSyncError = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  bool isNewItem(MemoryItem item) => _newItemIds.contains(item.id);

  /// Deletes a memory by id. On success removes from [items]; on failure sets [lastSyncError].
  Future<void> deleteMemory(String id) async {
    if (apiKey.isEmpty) return;
    try {
      await _api.deleteMemory(id);
      items = items.where((e) => e.id != id).toList();
      lastSyncError = null;
    } catch (e) {
      debugPrint("Delete memory error: $e");
      lastSyncError = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Deletes all memories under [handle] by calling delete for each. Stops on first API error.
  Future<void> deleteMemoriesByHandle(String handle) async {
    if (apiKey.isEmpty) return;
    final ids = items.where((e) => e.handle == handle).map((e) => e.id).toList();
    for (final id in ids) {
      await deleteMemory(id);
      if (lastSyncError != null) return;
    }
  }

  /// Saves and returns the idempotent_key from the server (for editor to track).
  /// Refreshes the list in the background, then triggers on_new_memory rules.
  Future<String?> save(String h, String c, String d, String? k) async {
    final res = await _api.syncMemory(
      handle: h,
      encryptedBase64: _crypto.encrypt(c),
      description: d,
      existingIdempotentKey: k,
      metadata: {"client_version": kClientVersion, "client": "flutter"},
    );
    final key = res["idempotent_key"]?.toString();
    await refreshMemories();
    // Trigger on_new_memory rules after data is fresh
    _runTrigger('on_new_memory');
    return key;
  }
}
