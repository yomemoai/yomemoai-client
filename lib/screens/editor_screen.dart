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

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _handleController;
  late TextEditingController _descController;
  late TextEditingController _contentController;
  bool _isSaving = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  int? _speechInsertOffset;
  String _speechLastRecognized = "";

  @override
  void initState() {
    super.initState();
    _handleController = TextEditingController(text: widget.item?.handle ?? "");
    _descController = TextEditingController(
      text: widget.item?.description ?? "",
    );
    _contentController = TextEditingController(
      text: widget.item?.content ?? "",
    );
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _handleController.dispose();
    _descController.dispose();
    _contentController.dispose();
    _speech.stop();
    super.dispose();
  }

  String _two(int v) => v < 10 ? "0$v" : "$v";

  String _defaultHandle() {
    final now = DateTime.now();
    final date = "${now.year}-${_two(now.month)}-${_two(now.day)}";
    return "voice-$date";
  }

  Future<void> _toggleListening() async {
    // 目前语音输入只在移动端启用，macOS 上避免调用底层插件导致闪退
    if (!(Platform.isIOS || Platform.isAndroid)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Voice capture is only available on mobile for now.")),
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

    // 决定语音插入起点（单手说话为主，默认从当前光标或末尾开始）
    final current = _contentController.text;
    final selection = _contentController.selection;
    final insertAt =
        selection.isValid ? selection.baseOffset : current.length;
    var safeInsertAt = insertAt.clamp(0, current.length);

    // 保证前面有空格（只插一次）
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
      final offset =
          (_speechInsertOffset ?? current.length).clamp(0, current.length);
      final before = current.substring(0, offset);

      // 使用最新一次识别结果覆盖语音区域，避免重复追加
      final updated = recognized.isEmpty ? before : "$before$recognized";
      _contentController.text = updated;
      final newOffset = updated.length;
      _contentController.selection =
          TextSelection.collapsed(offset: newOffset);

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

    setState(() => _isSaving = true);

    try {
      await context.read<MemoryProvider>().save(
        _handleController.text.trim(),
        _contentController.text,
        _descController.text.trim(),
        widget.item?.idempotentKey,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _handleController,
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
                decoration: const InputDecoration(
                  labelText: "Description (Optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _contentController,
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
              const SizedBox(height: 16),
              _buildVoiceInputBar(),
            ],
          ),
        ),
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
