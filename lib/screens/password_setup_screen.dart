import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../memory_provider.dart';
import '../l10n/app_localizations.dart';

class PasswordSetupScreen extends StatefulWidget {
  const PasswordSetupScreen({super.key});

  @override
  State<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  final TextEditingController _pwdCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pwd = _pwdCtrl.text;
    final confirm = _confirmCtrl.text;
    if (pwd.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).passwordRequired);
      return;
    }
    if (pwd != confirm) {
      setState(() => _error = AppLocalizations.of(context).passwordsDoNotMatch);
      return;
    }
    await context.read<MemoryProvider>().setLocalPassword(pwd);
    if (mounted) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setLocalPassword)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SvgPicture.asset(
              "assets/logo/yomemo-logo.svg",
              width: 60,
              height: 60,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.createLocalPasswordHint,
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pwdCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.newPassword,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _save,
              child: Text(l10n.savePassword),
            ),
          ],
        ),
      ),
    );
  }
}
