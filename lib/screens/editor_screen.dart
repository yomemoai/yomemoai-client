import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  }

  @override
  void dispose() {
    _handleController.dispose();
    _descController.dispose();
    _contentController.dispose();
    super.dispose();
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
      body: Padding(
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
          ],
        ),
      ),
    );
  }
}
