import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'api_service.dart';
import 'crypto_service.dart';

const String kClientVersion = "v0.0.1";
const String _kPrefLocalPassword = "local_password_hash";
const String _kPrefLockTimeout = "lock_timeout_minutes";
const String _kPrefAutoSaveSeconds = "auto_save_seconds";

class MemoryItem {
  final String id;
  final String handle, description, idempotentKey, content;
  MemoryItem({
    required this.id,
    required this.handle,
    required this.description,
    required this.idempotentKey,
    required this.content,
  });
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

  String _localPasswordHash = "";
  int _lockTimeoutMinutes = 15;
  int _autoSaveSeconds = 5;
  DateTime _lastActive = DateTime.now();
  bool _isLocked = false;
  Timer? _lockTimer;
  Timer? _autoRefreshTimer;

  bool get hasLocalPassword => _localPasswordHash.isNotEmpty;
  bool get isLocked => _isLocked;
  int get lockTimeoutMinutes => _lockTimeoutMinutes;
  int get autoSaveSeconds => _autoSaveSeconds;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    apiKey = prefs.getString('api_key') ?? "";
    pkPath = prefs.getString('pk_path') ?? "";
    _localPasswordHash = prefs.getString(_kPrefLocalPassword) ?? "";
    _lockTimeoutMinutes = prefs.getInt(_kPrefLockTimeout) ?? 15;
    _autoSaveSeconds = prefs.getInt(_kPrefAutoSaveSeconds) ?? 5;

    if (apiKey.isNotEmpty && pkPath.isNotEmpty) {
      _api.updateApiKey(apiKey);
      final file = File(pkPath);
      if (await file.exists()) {
        _crypto.init(await file.readAsString());
        await refreshMemories();
      }
    }
    _startLockTimerIfNeeded();
    _startAutoRefreshIfNeeded();
    notifyListeners();
  }

  Future<void> saveSettings(String key, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', key);
    await prefs.setString('pk_path', path);
    await loadSettings();
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

        return MemoryItem(
          id: id.isNotEmpty ? id : key,
          handle: handle,
          description: desc,
          idempotentKey: key,
          content: decryptedContent,
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

          return MemoryItem(
            id: id.isNotEmpty ? id : key,
            handle: handle,
            description: desc,
            idempotentKey: key,
            content: decryptedContent,
          );
        }).toList();

        items = [...items, ...moreItems];
        _newItemIds
          ..addAll(
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

  Future<void> save(String h, String c, String d, String? k) async {
    await _api.syncMemory(
      handle: h,
      encryptedBase64: _crypto.encrypt(c),
      description: d,
      existingIdempotentKey: k,
      metadata: {"client_version": kClientVersion, "client": "flutter"},
    );
    await refreshMemories();
  }
}
