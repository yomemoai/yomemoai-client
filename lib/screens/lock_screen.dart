import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../memory_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pwdCtrl = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _pwdCtrl.dispose();
    super.dispose();
  }

  void _unlock() {
    final ok = context.read<MemoryProvider>().verifyLocalPassword(
      _pwdCtrl.text,
    );
    if (!ok) {
      setState(() => _invalid = true);
    } else {
      setState(() => _invalid = false);
      _pwdCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  "assets/logo/yomemo-logo.svg",
                  width: 60,
                  height: 60,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Locked",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _pwdCtrl,
                  obscureText: true,
                  onSubmitted: (_) => _unlock(),
                  decoration: InputDecoration(
                    labelText: "Password",
                    errorText: _invalid ? "Incorrect password" : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _unlock, child: const Text("Unlock")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
