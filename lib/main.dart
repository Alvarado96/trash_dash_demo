import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:trash_dash_demo/screens/landing_screen.dart';
import 'package:trash_dash_demo/screens/map_screen.dart';
import 'package:trash_dash_demo/services/auth_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive for local settings (theme mode, etc.)
  await Hive.initFlutter();
  await Hive.openBox('settings');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TrashDashApp());
}

class TrashDashApp extends StatefulWidget {
  const TrashDashApp({super.key});

  @override
  State<TrashDashApp> createState() => _TrashDashAppState();
}

class _TrashDashAppState extends State<TrashDashApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final settingsBox = Hive.box('settings');
    final isDark = settingsBox.get('isDarkMode', defaultValue: false);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void toggleTheme(bool isDark) {
    final settingsBox = Hive.box('settings');
    settingsBox.put('isDarkMode', isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrashDash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          // Show loading indicator while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Colors.green,
                ),
              ),
            );
          }

          // If user is signed in, show map screen
          if (snapshot.hasData && snapshot.data != null) {
            return MapScreen(onThemeToggle: toggleTheme);
          }

          // Otherwise show landing screen
          return const LandingScreen();
        },
      ),
      routes: {
        '/map': (context) => MapScreen(onThemeToggle: toggleTheme),
        '/landing': (context) => const LandingScreen(),
      },
    );
  }
}
