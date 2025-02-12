import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  // Singleton pattern: Ensures a single instance of DatabaseHelper throughout the app
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Factory constructor to return the same instance
  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  // Getter for the database, initializes it if not already available
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database and set up the file location
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'privacy_insight.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Creates necessary tables in the database
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        privacy_score REAL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE survey_responses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        question TEXT,
        answer TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  // Inserts a new user into the 'users' table
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Retrieves a list of all users from the 'users' table
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  // Inserts a survey response into the 'survey_responses' table
  Future<int> insertSurveyResponse(Map<String, dynamic> response) async {
    final db = await database;
    return await db.insert('survey_responses', response,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Retrieves all survey responses for a specific user
  Future<List<Map<String, dynamic>>> getSurveyResponses(int userId) async {
    final db = await database;
    return await db.query('survey_responses', where: 'user_id = ?', whereArgs: [userId]);
  }

  // Updates the privacy score of a user in the 'users' table
  Future<int> updateUserPrivacyScore(int userId, double score) async {
    final db = await database;
    return await db.update(
      'users',
      {'privacy_score': score},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Retrieves the privacy score of a specific user
  Future<double> getUserPrivacyScore(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      columns: ['privacy_score'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (result.isNotEmpty) {
      return (result.first['privacy_score'] as num).toDouble();
    }
    return 0.0;
  }

  // Deletes a user and all associated survey responses from the database
  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  // Closes the database connection when not needed
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
