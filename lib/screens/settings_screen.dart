import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../memory_provider.dart';
import '../locale_provider.dart';
import '../l10n/app_localizations.dart';
import 'export_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

const String _kDefaultExpandedPrefixesKey = 'default_expanded_prefixes';
const String _kHomeExpandedPrefixesKey = 'home_expanded_prefixes';

/// Prefix options for "default expanded groups" (same order as handle_display).
const List<MapEntry<String, String>> _defaultExpandedOptions = [
  MapEntry('voice', 'voice'),
  MapEntry('daily', 'daily'),
  MapEntry('yomemo', 'yomemo'),
  MapEntry('plan', 'plan'),
  MapEntry('goals', 'goals'),
  MapEntry('other', 'other'),
];

String _prefixLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'voice': return l10n.categoryVoice;
    case 'daily': return l10n.categoryDaily;
    case 'yomemo': return l10n.categoryYoMemo;
    case 'plan': return l10n.categoryPlan;
    case 'goals': return l10n.categoryGoals;
    case 'other': return l10n.categoryOther;
    default: return key;
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _keyCtrl;
  late TextEditingController _newPwdCtrl;
  late TextEditingController _confirmPwdCtrl;
  late TextEditingController _timeoutCtrl;
  late TextEditingController _autoSaveCtrl;
  String _path = "";
  String _existingKey = "";
  Set<String> _defaultExpanded = {};

  @override
  void initState() {
    super.initState();
    _loadDefaultExpandedPrefixes();
    final p = context.read<MemoryProvider>();
    _existingKey = p.apiKey;
    _keyCtrl = TextEditingController();
    _path = p.pkPath;
    if (p.apiKey.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).pleaseSetApiKey),
              duration: const Duration(seconds: 4),
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

  Future<void> _loadDefaultExpandedPrefixes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kDefaultExpandedPrefixesKey);
    if (mounted) setState(() => _defaultExpanded = (list ?? []).toSet());
  }

  Future<void> _saveDefaultExpandedPrefixes(Set<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kDefaultExpandedPrefixesKey, value.toList());
  }

  Future<void> _resetHomeToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kHomeExpandedPrefixesKey, _defaultExpanded.toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).homeExpandedGroupsReset)),
      );
    }
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
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.configuration)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.language,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.languageEnglish),
                  selected: localeProvider.locale.languageCode == 'en',
                  onSelected: (_) => localeProvider.setLocale(const Locale('en')),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: Text(l10n.languageChinese),
                  selected: localeProvider.locale.languageCode == 'zh',
                  onSelected: (_) => localeProvider.setLocale(const Locale('zh')),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _keyCtrl,
              decoration: InputDecoration(
                labelText: l10n.yomemoApiKey,
                hintText: _existingKey.isEmpty ? l10n.enterApiKey : l10n.configured,
                helperText: _existingKey.isEmpty
                    ? null
                    : l10n.leaveEmptyToKeepCurrent,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(l10n.privateKeyFile),
              subtitle: Text(
                _path.isEmpty
                    ? l10n.selectFileForEncryptionKey
                    : l10n.configured,
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.localLock,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPwdCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.newPassword,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPwdCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeoutCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.lockTimeoutMinutes,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.editor,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(l10n.confirmSwipeToDelete),
              subtitle: Text(l10n.confirmSwipeToDeleteSubtitle),
              value: provider.confirmSwipeDelete,
              onChanged: (value) {
                provider.updateConfirmSwipeDelete(value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _autoSaveCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.autoSaveIntervalSeconds,
                helperText: l10n.autoSaveHelperText,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.export,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              title: Text(l10n.exportMemories),
              subtitle: Text(l10n.exportMemoriesSubtitle),
              trailing: const Icon(Icons.upload_file),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExportScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.homeDefaultExpandedGroups,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.homeDefaultExpandedGroupsHelp,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _defaultExpandedOptions.map((e) {
                final key = e.key;
                final label = _prefixLabel(l10n, key);
                final selected = _defaultExpanded.contains(key);
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (v) async {
                    final next = Set<String>.from(_defaultExpanded);
                    if (v) {
                      next.add(key);
                    } else {
                      next.remove(key);
                    }
                    setState(() => _defaultExpanded = next);
                    await _saveDefaultExpandedPrefixes(next);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.resetHomeToDefault),
              onPressed: () => _resetHomeToDefault(),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.insightsAndNotifications,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(l10n.showRedBadgeOnInsights),
              subtitle: Text(l10n.showRedBadgeOnInsightsSubtitle),
              value: provider.showInsightsBadge,
              onChanged: (value) {
                provider.updateShowInsightsBadge(value);
              },
            ),
            SwitchListTile(
              title: Text(l10n.enableHapticsForNewInsights),
              subtitle: Text(l10n.enableHapticsForNewInsightsSubtitle),
              value: provider.alertHapticsEnabled,
              onChanged: (value) {
                provider.updateAlertHaptics(value);
              },
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
                      SnackBar(content: Text(l10n.passwordsDoNotMatch)),
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
                    SnackBar(content: Text(l10n.settingsSaved)),
                  );
                }
              },
              child: Text(l10n.saveAndConnect),
            ),
          ],
        ),
      ),
    );
  }
}
