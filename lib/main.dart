import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_page.dart';
import 'package:privacy_insight/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  int? userId = await _getOrCreateUser();
  runApp(PrivacyInsightApp(userId: userId));
}

class PrivacyInsightApp extends StatelessWidget {
  final int userId;

  const PrivacyInsightApp({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.green.shade700,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: HomePage(userId: userId),
    );
  }
}

/// Retrieves the user ID from shared preferences or creates a new user if not found.
Future<int> _getOrCreateUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? userId = prefs.getInt('user_id');

  if (userId == null) {
    DatabaseHelper dbHelper = DatabaseHelper();
    // Inserts a default guest user if no user exists
    userId = await dbHelper.insertUser({
      'name': 'Guest',
      'email': 'guest@example.com',
    });
    await prefs.setInt('user_id', userId); // Saves user ID for future sessions
  }

  return userId;
}