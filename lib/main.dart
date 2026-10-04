import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/storage.dart';
import 'models/app_data.dart';
import 'services/notifications.dart';
import 'state/app_controller.dart';
import 'ui/brand.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await Storage.open();
  AppData data;
  try {
    data = await storage.load();
  } catch (e) {
    // Keep the unreadable file instead of overwriting it.
    debugPrint('Could not read saved data: $e');
    await storage.file.rename(
        '${storage.file.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}');
    data = const AppData();
  }
  await RestNotifications.instance.init();

  runApp(ProviderScope(
    overrides: [
      storageProvider.overrideWithValue(storage),
      initialDataProvider.overrideWithValue(data),
    ],
    child: const MiloLiftsApp(),
  ));
}

class MiloLiftsApp extends ConsumerWidget {
  const MiloLiftsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarded = ref.watch(appProvider.select((d) => d.onboarded));
    return MaterialApp(
      title: 'MiloLifts',
      debugShowCheckedModeBanner: false,
      theme: buildMiloTheme(),
      home: onboarded ? const HomeShell() : const OnboardingScreen(),
    );
  }
}
