import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:trash_dash_demo/screens/landing_screen.dart';
import 'package:trash_dash_demo/screens/map_screen.dart';
import 'package:trash_dash_demo/models/user_model.dart';
import 'package:trash_dash_demo/models/trash_item.dart';
import 'package:trash_dash_demo/data/sample_data.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(TrashItemAdapter());
  Hive.registerAdapter(ItemStatusAdapter());
  Hive.registerAdapter(ItemCategoryAdapter());

  // Open Hive boxes
  await Hive.openBox<UserModel>('users');
  await Hive.openBox<TrashItem>('trashItems');
  await Hive.openBox('currentUser'); // For storing current user ID

  // Initialize sample data
  await SampleData.initializeSampleData();

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
    final settingsBox = Hive.box('currentUser');
    final isDark = settingsBox.get('isDarkMode', defaultValue: false);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void toggleTheme(bool isDark) {
    final settingsBox = Hive.box('currentUser');
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
      home: ValueListenableBuilder(
        valueListenable: Hive.box('currentUser').listenable(),
        builder: (context, box, widget) {
          final currentUserId = box.get('userId');

          // If user is signed in, show map screen
          if (currentUserId != null) {
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
