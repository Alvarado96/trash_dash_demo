import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:trash_dash_demo/screens/landing_screen.dart';
import 'package:trash_dash_demo/screens/map_screen.dart';
import 'package:trash_dash_demo/models/user_model.dart';
import 'package:trash_dash_demo/models/trash_item.dart';
import 'package:trash_dash_demo/data/sample_data.dart';

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

  runApp(const TrashDashApp());
}

class TrashDashApp extends StatelessWidget {
  const TrashDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrashDash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: ValueListenableBuilder(
        valueListenable: Hive.box('currentUser').listenable(),
        builder: (context, box, widget) {
          final currentUserId = box.get('userId');

          // If user is signed in, show map screen
          if (currentUserId != null) {
            return const MapScreen();
          }

          // Otherwise show landing screen
          return const LandingScreen();
        },
      ),
      routes: {
        '/map': (context) => const MapScreen(),
        '/landing': (context) => const LandingScreen(),
      },
    );
  }
}
