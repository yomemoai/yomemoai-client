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
  String _lastPhraseBeforeComma = "";
  final List<String> _seenPhrasesBeforeComma = [];

  Timer? _autoSaveTimer;
  bool _isDirty = false;
  bool _isAutoSaving = false;
  DateTime? _lastAutoSavedAt;
  String? _savedIdempotentKey;

  late String _savedHandle;
  late String _savedDesc;
  late String _savedContent;

  final FocusNode _handleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  Timer? _speechPauseTimer;

  bool _isImmersiveMode = false;

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

    _contentFocus.addListener(() {
      setState(() {
        _isImmersiveMode = _contentFocus.hasFocus;
      });
    });

    _startAutoSaveTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    _speechPauseTimer?.cancel();
    _handleFocus.dispose();
    _descFocus.dispose();
    _contentFocus.dispose();
    _handleController.dispose();
    _descController.dispose();
    _contentController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _autoSave();
    }
  }

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

  int get _autoSaveSeconds => context.read<MemoryProvider>().autoSaveSeconds;

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

    if (mounted) setState(() => _isAutoSaving = true);
    try {
      final key = await context.read<MemoryProvider>().save(
        handle,
        content,
        _descController.text.trim(),
        _savedIdempotentKey ?? widget.item?.idempotentKey,
      );
      if (mounted && key != null) _savedIdempotentKey = key;
      if (mounted) {
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
          content: Text("Voice capture is only available on mobile."),
        ),
      );
      return;
    }
    if (_isListening) {
      _speechPauseTimer?.cancel();
      _speechPauseTimer = null;
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          _speechInsertOffset = null;
          _lastPhraseBeforeComma = "";
          _seenPhrasesBeforeComma.clear();
        });
      }
      return;
    }
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'notListening') setState(() => _isListening = false);
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
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
    if (mounted) setState(() => _isListening = true);

    _contentFocus.requestFocus();

    final current = _contentController.text;
    final selection = _contentController.selection;
    final insertAt = selection.isValid ? selection.baseOffset : current.length;
    var safeInsertAt = insertAt.clamp(0, current.length);
    if (current.isNotEmpty &&
        safeInsertAt > 0 &&
        !RegExp(r'\s$').hasMatch(current.substring(0, safeInsertAt))) {
      final before = current.substring(0, safeInsertAt);
      final after = current.substring(safeInsertAt);
      _contentController.text = "$before $after";
      safeInsertAt += 1;
    }
    _speechInsertOffset = safeInsertAt;
    _lastPhraseBeforeComma = "";
    _seenPhrasesBeforeComma.clear();
    await _speech.listen(
      onResult: _onSpeechResult,
      listenMode: stt.ListenMode.dictation,
      localeId: 'zh-CN',
    );
  }

  void _onSpeechResult(result) {
    final recognized = (result.recognizedWords as String).trim();
    if (recognized.isEmpty) return;
    _speechPauseTimer?.cancel();
    _speechPauseTimer = Timer(
      const Duration(milliseconds: 1200),
      _insertPausePunctuation,
    );
    setState(() {
      if (_handleController.text.trim().isEmpty)
        _handleController.text = _defaultHandle();
      final current = _contentController.text;
      final offset = (_speechInsertOffset ?? current.length).clamp(
        0,
        current.length,
      );
      final before = current.substring(0, offset);
      String segment = recognized;

      if (before.isNotEmpty && recognized.startsWith(before)) {
        segment = recognized.substring(before.length);
      } else if (before.isNotEmpty) {
        final beforeNorm = before.replaceAll(", ", "");
        if (beforeNorm.isNotEmpty && recognized.startsWith(beforeNorm)) {
          segment = recognized.substring(beforeNorm.length);
        } else if (_lastPhraseBeforeComma.isNotEmpty &&
            recognized.startsWith(_lastPhraseBeforeComma)) {
          segment = recognized.substring(_lastPhraseBeforeComma.length);
        }
      }

      int stripLen = 0;
      for (final phrase in _seenPhrasesBeforeComma) {
        if (phrase.isNotEmpty &&
            segment.startsWith(phrase) &&
            phrase.length > stripLen) {
          stripLen = phrase.length;
        }
      }
      if (stripLen > 0) segment = segment.substring(stripLen);

      final updated = before + segment;
      _contentController.text = updated;
      _contentController.selection = TextSelection.collapsed(
        offset: updated.length,
      );
    });
  }

  void _insertPausePunctuation() {
    _speechPauseTimer = null;
    if (!_isListening || !mounted) return;
    final current = _contentController.text;
    final offset = (_speechInsertOffset ?? current.length).clamp(
      0,
      current.length,
    );
    _lastPhraseBeforeComma = current.substring(offset);
    if (_lastPhraseBeforeComma.isNotEmpty)
      _seenPhrasesBeforeComma.add(_lastPhraseBeforeComma);
    const punctuation = ", ";
    final updated = current + punctuation;
    _contentController.text = updated;
    final newOffset = updated.length;
    _contentController.selection = TextSelection.collapsed(offset: newOffset);
    _speechInsertOffset = newOffset;
    if (mounted) setState(() {});
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
      final key = await context.read<MemoryProvider>().save(
        _handleController.text.trim(),
        _contentController.text,
        _descController.text.trim(),
        _savedIdempotentKey ?? widget.item?.idempotentKey,
      );
      if (mounted) {
        if (key != null) _savedIdempotentKey = key;
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
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isImmersiveMode
              ? const Text(
                  "Writing...",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                )
              : Text(isEditing ? "Edit Memory" : "New Memory"),
        ),
        actions: [
          if (_isAutoSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
            )
          else if (_isDirty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Icon(Icons.circle, size: 10, color: Colors.orange[400]),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _handleSave,
          ),
        ],
      ),
      body: GestureDetector(
        // 点击空白处收起键盘并退出沉浸模式
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: _isImmersiveMode
                            ? const SizedBox(height: 0)
                            : Column(
                                children: [
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _handleController,
                                    focusNode: _handleFocus,
                                    decoration: const InputDecoration(
                                      labelText: "Handle",
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
                                ],
                              ),
                      ),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.only(top: _isImmersiveMode ? 20 : 0),
                        constraints: BoxConstraints(
                          minHeight:
                              MediaQuery.of(context).size.height *
                              (_isImmersiveMode ? 0.7 : 0.3),
                        ),
                        child: TextField(
                          controller: _contentController,
                          focusNode: _contentFocus,
                          maxLines: null,
                          minLines: _isImmersiveMode ? 20 : 12,
                          style: const TextStyle(fontSize: 18, height: 1.5),
                          decoration: InputDecoration(
                            hintText: "Start writing your memory...",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: _isImmersiveMode
                                ? InputBorder.none
                                : const OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _buildAutoSaveStatus(),
              _buildVoiceInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoSaveStatus() {
    return SizedBox(
      height: 20,
      child: Center(
        child: _isAutoSaving
            ? const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1),
              )
            : (!_isDirty && _lastAutoSavedAt != null)
            ? Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black12,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildVoiceInputBar() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isListening ? 1.0 : (_isImmersiveMode ? 0.4 : 1.0),
      child: Container(
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        child: Column(
          children: [
            if (!_isImmersiveMode)
              Text(
                "Speak to capture this memory",
                style: TextStyle(fontSize: 12, color: Colors.blueGrey[300]),
              ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isListening ? 70 : 60,
                height: _isListening ? 70 : 60,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22D3EE), Color(0xFF3B82F6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isListening
                                  ? const Color(0xFF22D3EE)
                                  : Colors.black)
                              .withOpacity(_isListening ? 0.4 : 0.1),
                      blurRadius: _isListening ? 20 : 10,
                      offset: Offset(0, _isListening ? 0 : 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
