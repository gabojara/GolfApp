import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  static late Database _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    // ignore: unnecessary_null_comparison
    if (_database != null) return _database;

    _database = await initDatabase();
    return _database;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'object_detection.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE detections(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            className TEXT,
            confidence REAL,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertDetection(String className, double confidence) async {
    Database db = await database;
    await db.insert(
      'detections',
      {
        'className': className,
        'confidence': confidence,
        'timestamp': DateTime.now().toString(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getDetections() async {
    Database db = await database;
    return await db.query('detections');
  }
}