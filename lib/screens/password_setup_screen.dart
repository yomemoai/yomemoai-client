import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../memory_provider.dart';

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
      setState(() => _error = "Password is required");
      return;
    }
    if (pwd != confirm) {
      setState(() => _error = "Passwords do not match");
      return;
    }
    await context.read<MemoryProvider>().setLocalPassword(pwd);
    if (mounted) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Local Password")),
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
            const Text(
              "Create a local password to protect your memories on this device.",
              style: TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pwdCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _save,
              child: const Text("Save Password"),
            ),
          ],
        ),
      ),
    );
  }
}
