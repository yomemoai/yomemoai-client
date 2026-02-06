import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../memory_provider.dart';

class EditorScreen extends StatefulWidget {
  final MemoryItem? item;
  const EditorScreen({super.key, this.item});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with WidgetsBindingObserver {
  late TextEditingController _handleController;
  late TextEditingController _descController;
  late TextEditingController _contentController;
  bool _isSaving = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  int? _speechInsertOffset;
  String _speechLastRecognized = "";

  // --- Auto-save ---
  Timer? _autoSaveTimer;
  bool _isDirty = false;
  bool _isAutoSaving = false;
  DateTime? _lastAutoSavedAt;
  String? _savedIdempotentKey;

  // Snapshot of last-saved values to detect real changes
  late String _savedHandle;
  late String _savedDesc;
  late String _savedContent;

  // Focus nodes for blur-triggered auto-save
  final FocusNode _handleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handleController = TextEditingController(text: widget.item?.handle ?? "");
    _descController = TextEditingController(
      text: widget.item?.description ?? "",
    );
    _contentController = TextEditingController(
      text: widget.item?.content ?? "",
    );
    _speech = stt.SpeechToText();
    _savedIdempotentKey = widget.item?.idempotentKey;
    _savedHandle = widget.item?.handle ?? "";
    _savedDesc = widget.item?.description ?? "";
    _savedContent = widget.item?.content ?? "";

    _handleController.addListener(_checkDirty);
    _descController.addListener(_checkDirty);
    _contentController.addListener(_checkDirty);

    _handleFocus.addListener(_onFocusChange);
    _descFocus.addListener(_onFocusChange);
    _contentFocus.addListener(_onFocusChange);

    _startAutoSaveTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    _handleFocus.removeListener(_onFocusChange);
    _descFocus.removeListener(_onFocusChange);
    _contentFocus.removeListener(_onFocusChange);
    _handleFocus.dispose();
    _descFocus.dispose();
    _contentFocus.dispose();
    _handleController.removeListener(_checkDirty);
    _descController.removeListener(_checkDirty);
    _contentController.removeListener(_checkDirty);
    _handleController.dispose();
    _descController.dispose();
    _contentController.dispose();
    _speech.stop();
    super.dispose();
  }

  // Auto-save when app goes to background (iOS home / switch app)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _autoSave();
    }
  }

  // Auto-save when any text field loses focus
  void _onFocusChange() {
    final anyHasFocus =
        _handleFocus.hasFocus || _descFocus.hasFocus || _contentFocus.hasFocus;
    if (!anyHasFocus && _isDirty) {
      _autoSave();
    }
  }

  bool get _hasRealChanges =>
      _handleController.text != _savedHandle ||
      _descController.text != _savedDesc ||
      _contentController.text != _savedContent;

  void _checkDirty() {
    final dirty = _hasRealChanges;
    if (dirty != _isDirty) {
      setState(() => _isDirty = dirty);
    }
  }

  int get _autoSaveSeconds =>
      context.read<MemoryProvider>().autoSaveSeconds;

  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    final interval = Duration(seconds: _autoSaveSeconds);
    _autoSaveTimer = Timer.periodic(interval, (_) => _autoSave());
  }

  Future<void> _autoSave() async {
    if (!_isDirty || _isSaving || _isAutoSaving) return;
    final handle = _handleController.text.trim();
    final content = _contentController.text;
    if (handle.isEmpty || content.isEmpty) return;

    setState(() => _isAutoSaving = true);
    try {
      await context.read<MemoryProvider>().save(
        handle,
        content,
        _descController.text.trim(),
        _savedIdempotentKey ?? widget.item?.idempotentKey,
      );
      if (mounted) {
        // After first auto-save of a new memory, capture the idempotent key
        // so subsequent saves update instead of creating duplicates.
        final provider = context.read<MemoryProvider>();
        final match = provider.items.where(
          (i) => i.handle == handle && i.content == content,
        );
        if (match.isNotEmpty) {
          _savedIdempotentKey = match.first.idempotentKey;
        }
        _savedHandle = handle;
        _savedDesc = _descController.text.trim();
        _savedContent = content;
        setState(() {
          _isDirty = false;
          _isAutoSaving = false;
          _lastAutoSavedAt = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isAutoSaving = false);
    }
  }

  String _two(int v) => v < 10 ? "0$v" : "$v";

  String _defaultHandle() {
    final now = DateTime.now();
    final date = "${now.year}-${_two(now.month)}-${_two(now.day)}";
    return "voice-$date";
  }

  Future<void> _toggleListening() async {
    if (!(Platform.isIOS || Platform.isAndroid)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Voice capture is only available on mobile for now."),
        ),
      );
      return;
    }
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          _speechInsertOffset = null;
          _speechLastRecognized = "";
        });
      }
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Speech error: ${error.errorMsg}")),
        );
      },
    );

    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Speech recognition not available")),
      );
      return;
    }

    final current = _contentController.text;
    final selection = _contentController.selection;
    final insertAt = selection.isValid ? selection.baseOffset : current.length;
    var safeInsertAt = insertAt.clamp(0, current.length);

    if (current.isNotEmpty &&
        safeInsertAt > 0 &&
        !RegExp(r'\s$').hasMatch(current.substring(0, safeInsertAt))) {
      final before = current.substring(0, safeInsertAt);
      final after = current.substring(safeInsertAt);
      final updated = "$before $after";
      _contentController.text = updated;
      safeInsertAt += 1;
    }
    _speechInsertOffset = safeInsertAt;
    _speechLastRecognized = "";

    if (mounted) {
      setState(() {
        _isListening = true;
      });
    }

    await _speech.listen(
      onResult: _onSpeechResult,
      listenMode: stt.ListenMode.dictation,
      localeId: 'zh-CN',
    );
  }

  void _onSpeechResult(result) {
    final recognized = (result.recognizedWords as String).trim();
    if (recognized.isEmpty) return;

    setState(() {
      if (_handleController.text.trim().isEmpty) {
        _handleController.text = _defaultHandle();
      }

      final current = _contentController.text;
      final offset = (_speechInsertOffset ?? current.length).clamp(
        0,
        current.length,
      );
      final before = current.substring(0, offset);

      // 使用最新一次识别结果覆盖语音区域，避免重复追加
      final updated = recognized.isEmpty ? before : "$before$recognized";
      _contentController.text = updated;
      final newOffset = updated.length;
      _contentController.selection = TextSelection.collapsed(offset: newOffset);

      _speechLastRecognized = recognized;
    });
  }

  Future<void> _handleSave() async {
    if (_handleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Handle and Content are required")),
      );
      return;
    }

    _autoSaveTimer?.cancel();
    setState(() => _isSaving = true);

    try {
      await context.read<MemoryProvider>().save(
        _handleController.text.trim(),
        _contentController.text,
        _descController.text.trim(),
        _savedIdempotentKey ?? widget.item?.idempotentKey,
      );
      if (mounted) {
        _isDirty = false;
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _startAutoSaveTimer();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Memory" : "New Memory"),
        actions: [
          if (_isAutoSaving)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.blueGrey[400],
                  ),
                ),
              ),
            )
          else if (_isDirty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Icon(
                  Icons.circle,
                  size: 10,
                  color: Colors.orange[400],
                ),
              ),
            ),
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _handleSave),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          // Focus listeners will pick up the blur and trigger auto-save
        },
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _handleController,
                  focusNode: _handleFocus,
                  decoration: const InputDecoration(
                    labelText: "Handle",
                    hintText: "e.g. project-name, coding",
                    border: OutlineInputBorder(),
                  ),
                  enabled: !isEditing,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  focusNode: _descFocus,
                  decoration: const InputDecoration(
                    labelText: "Description (Optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    focusNode: _contentFocus,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      labelText: "Secret Content",
                      hintText: "Your sensitive information goes here...",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildAutoSaveStatus(),
                const SizedBox(height: 8),
                _buildVoiceInputBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoSaveStatus() {
    // No indicators at all when content hasn't changed
    if (!_isDirty && !_isAutoSaving) {
      return const SizedBox.shrink();
    }

    String text;
    Color color;
    if (_isAutoSaving) {
      text = "Saving...";
      color = Colors.blueGrey[500]!;
    } else if (_isDirty && _lastAutoSavedAt != null) {
      final t = _lastAutoSavedAt!;
      text = "Auto-saved at ${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)} · edited";
      color = Colors.orange[400]!;
    } else if (_isDirty) {
      text = "Unsaved changes";
      color = Colors.orange[400]!;
    } else {
      text = "";
      color = Colors.transparent;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: text.isEmpty
          ? const SizedBox.shrink()
          : Text(
              text,
              key: ValueKey(text),
              style: TextStyle(fontSize: 11, color: color),
            ),
    );
  }

  Widget _buildVoiceInputBar() {
    final baseGradient = const LinearGradient(
      colors: [Color(0xFF22D3EE), Color(0xFF3B82F6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Speak to capture this memory",
          style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _toggleListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: _isListening ? 90 : 80,
            height: _isListening ? 90 : 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: baseGradient,
              boxShadow: [
                if (_isListening)
                  BoxShadow(
                    color: const Color(0xFF22D3EE).withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 4,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Center(
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isListening ? "Listening..." : "Single tap, one-hand friendly",
          style: TextStyle(fontSize: 12, color: Colors.blueGrey[500]),
        ),
      ],
    );
  }
}
