import 'package:flutter/material.dart';
import 'package:team4_group_project/auth/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:team4_group_project/firebase_options.dart';
import 'package:team4_group_project/views/create_event_view.dart';
import '../navigation_shell.dart';
import 'package:team4_group_project/views/settings_view.dart';
import 'package:team4_group_project/views/user_home_view.dart';
import 'package:provider/provider.dart';
import 'package:team4_group_project/providers/app_providers.dart';
import 'package:team4_group_project/theme.dart';
import 'package:team4_group_project/util.dart';
import 'package:team4_group_project/viewmodels/theme_viewmodel.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MultiProvider(providers: appProviders, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    TextTheme text_theme = create_text_theme(context, "Playfair Display", "Pacifico");

    MaterialTheme theme = MaterialTheme(text_theme);

    final theme_provider = Provider.of<ThemeViewModel>(context);

    return MaterialApp(
      title: 'not flutter demo',
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode: theme_provider.theme_mode,
      routes: {
        '/createEvent': (context) => const CreateEventView(title: 'Create Event'),
        '/settings': (context) => const SettingsView(),
      },
      home: AuthGate(clientId: '', signedIn: const NavigationShell()),
    );
  }
}

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserHomeView();
  }
}

