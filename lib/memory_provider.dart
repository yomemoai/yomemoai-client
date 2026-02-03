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

class MemoryItem {
  final String handle, description, idempotentKey, content;
  MemoryItem({
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

  String _localPasswordHash = "";
  int _lockTimeoutMinutes = 15;
  DateTime _lastActive = DateTime.now();
  bool _isLocked = false;
  Timer? _lockTimer;
  Timer? _autoRefreshTimer;

  bool get hasLocalPassword => _localPasswordHash.isNotEmpty;
  bool get isLocked => _isLocked;
  int get lockTimeoutMinutes => _lockTimeoutMinutes;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    apiKey = prefs.getString('api_key') ?? "";
    pkPath = prefs.getString('pk_path') ?? "";
    _localPasswordHash = prefs.getString(_kPrefLocalPassword) ?? "";
    _lockTimeoutMinutes = prefs.getInt(_kPrefLockTimeout) ?? 15;

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
    isLoading = true;
    lastSyncAttemptAt = DateTime.now();
    notifyListeners();

    try {
      final rawData = await _api.fetchMemories();

      items = rawData.map((j) {
        final String handle = j['handle']?.toString() ?? "No Handle";
        final String desc = j['description']?.toString() ?? "";
        final String key =
            j['idempotent_key']?.toString() ?? j['id']?.toString() ?? "";

        final String? rawContent = j['content']?.toString();

        String decryptedContent = "";
        if (rawContent != null && rawContent.isNotEmpty) {
          decryptedContent = _crypto.decrypt(rawContent);
        } else {
          decryptedContent = "[Empty]";
        }

        return MemoryItem(
          handle: handle,
          description: desc,
          idempotentKey: key,
          content: decryptedContent,
        );
      }).toList();
      lastSyncAt = DateTime.now();
      lastSyncError = null;
    } catch (e) {
      debugPrint("Refresh Error: $e");
      lastSyncError = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

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
