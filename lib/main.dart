import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'memory_provider.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/password_setup_screen.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => MemoryProvider(),
    child: const AppRoot(),
  ),
);

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MemoryProvider>();
    return MaterialApp(
      title: "Yomemo.AI",
      home: const MainEntryPoint(),
      builder: (context, child) {
        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            final isLockKey = event.logicalKey == LogicalKeyboardKey.keyL;
            final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;
            final isControlPressed = HardwareKeyboard.instance.isControlPressed;
            if (event is KeyDownEvent &&
                isLockKey &&
                (isMetaPressed || isControlPressed)) {
              provider.lockNow();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Shortcuts(
            shortcuts: {
              LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyL):
                  ActivateIntent(),
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.keyL,
              ): ActivateIntent(),
            },
            child: Actions(
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    provider.lockNow();
                    return null;
                  },
                ),
              },
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

class MainEntryPoint extends StatelessWidget {
  const MainEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<MemoryProvider>().loadSettings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Consumer<MemoryProvider>(
          builder: (context, p, _) {
            Widget screen;
            if (!p.hasLocalPassword) {
              screen = const PasswordSetupScreen();
            } else if (p.isLocked) {
              screen = const LockScreen();
            } else if (p.apiKey.isEmpty || p.pkPath.isEmpty) {
              screen = const SettingsScreen();
            } else {
              screen = const HomeScreen();
            }

            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => p.recordActivity(),
              child: screen,
            );
          },
        );
      },
    );
  }
}
