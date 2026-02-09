import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../memory_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _keyCtrl;
  late TextEditingController _newPwdCtrl;
  late TextEditingController _confirmPwdCtrl;
  late TextEditingController _timeoutCtrl;
  late TextEditingController _autoSaveCtrl;
  String _path = "";
  String _existingKey = "";

  @override
  void initState() {
    super.initState();
    final p = context.read<MemoryProvider>();
    _existingKey = p.apiKey;
    _keyCtrl = TextEditingController();
    _path = p.pkPath;
    if (p.apiKey.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please set your API Key to get started"),
              duration: Duration(seconds: 4),
            ),
          );
        }
      });
    }
    _newPwdCtrl = TextEditingController();
    _confirmPwdCtrl = TextEditingController();
    _timeoutCtrl = TextEditingController(text: p.lockTimeoutMinutes.toString());
    _autoSaveCtrl = TextEditingController(text: p.autoSaveSeconds.toString());
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _timeoutCtrl.dispose();
    _autoSaveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemoryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("Configuration")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: _keyCtrl,
              decoration: InputDecoration(
                labelText: "YoMemo API Key",
                hintText: _existingKey.isEmpty ? "Enter API Key" : "Configured",
                helperText: _existingKey.isEmpty
                    ? null
                    : "Leave empty to keep current",
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text("Private Key File"),
              subtitle: Text(
                _path.isEmpty
                    ? "Select a file to use as encryption key"
                    : "Configured",
              ),
              trailing: IconButton(
                icon: const Icon(Icons.file_open),
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles();
                  if (result != null) {
                    setState(() => _path = result.files.single.path!);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Local Lock",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPwdCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPwdCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeoutCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Lock Timeout (minutes)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Editor",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text("Confirm swipe-to-delete"),
              subtitle: const Text(
                "Ask for confirmation when deleting a memory by swipe.",
              ),
              value: provider.confirmSwipeDelete,
              onChanged: (value) {
                provider.updateConfirmSwipeDelete(value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _autoSaveCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Auto-save Interval (seconds)",
                helperText: "Also saves on blur. Range: 1-300",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                final apiKeyToSave = _keyCtrl.text.trim().isEmpty
                    ? _existingKey
                    : _keyCtrl.text.trim();

                if (_newPwdCtrl.text.isNotEmpty ||
                    _confirmPwdCtrl.text.isNotEmpty) {
                  if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Passwords do not match")),
                    );
                    return;
                  }
                  await context.read<MemoryProvider>().setLocalPassword(
                    _newPwdCtrl.text,
                  );
                }

                final timeout = int.tryParse(_timeoutCtrl.text.trim());
                if (timeout != null && timeout > 0) {
                  await context.read<MemoryProvider>().updateLockTimeoutMinutes(
                    timeout,
                  );
                }

                final autoSave = int.tryParse(_autoSaveCtrl.text.trim());
                if (autoSave != null && autoSave >= 1) {
                  await context.read<MemoryProvider>().updateAutoSaveSeconds(
                    autoSave,
                  );
                }

                await context.read<MemoryProvider>().saveSettings(
                  apiKeyToSave,
                  _path,
                );
                if (mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Settings saved")),
                  );
                }
              },
              child: const Text("Save & Connect"),
            ),
          ],
        ),
      ),
    );
  }
}
