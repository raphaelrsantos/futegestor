import 'package:flutter/material.dart';
import 'package:futegestor/theme.dart';
import 'package:futegestor/storage/local_storage.dart';
import 'package:futegestor/services/notification_service.dart';

import 'package:futegestor/state/app_state.dart';
import 'package:futegestor/state/app_state_scope.dart';
import 'package:futegestor/ui/shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _bootstrap();
}

Future<void> _bootstrap() async {
  // Initialize local storage (Web: window.localStorage; Mobile/Desktop: SharedPreferences)
  // ignore: avoid_print
  print('Bootstrap: initializing LocalStorage...');
  await LocalStorage.init();

  // Initialize notifications
  // ignore: avoid_print
  print('Bootstrap: initializing NotificationService...');
  await NotificationService.instance.initialize();

  // ignore: avoid_print
  print('Bootstrap: Services initialized. Running app.');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: AppState()..load(),
      child: MaterialApp(
        title: 'Futegestor',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const FutegestorShell(),
      ),
    );
  }
}
