import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cultivos_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Aquí definiremos las tablas de la base de datos
    await db.execute('''
      CREATE TABLE cultivos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT,
        estado TEXT NOT NULL,
        notas TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE mediciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cultivo_id INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        temperatura REAL,
        humedad REAL,
        ph REAL,
        FOREIGN KEY (cultivo_id) REFERENCES cultivos (id)
      )
    ''');
  }

  // Métodos para operaciones CRUD de cultivos
  Future<int> insertCultivo(Map<String, dynamic> cultivo) async {
    Database db = await database;
    return await db.insert('cultivos', cultivo);
  }

  Future<List<Map<String, dynamic>>> getCultivos() async {
    Database db = await database;
    return await db.query('cultivos');
  }

  Future<Map<String, dynamic>?> getCultivo(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'cultivos',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateCultivo(Map<String, dynamic> cultivo) async {
    Database db = await database;
    return await db.update(
      'cultivos',
      cultivo,
      where: 'id = ?',
      whereArgs: [cultivo['id']],
    );
  }

  Future<int> deleteCultivo(int id) async {
    Database db = await database;
    return await db.delete(
      'cultivos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para operaciones CRUD de mediciones
  Future<int> insertMedicion(Map<String, dynamic> medicion) async {
    Database db = await database;
    return await db.insert('mediciones', medicion);
  }

  Future<List<Map<String, dynamic>>> getMediciones(int cultivoId) async {
    Database db = await database;
    return await db.query(
      'mediciones',
      where: 'cultivo_id = ?',
      whereArgs: [cultivoId],
    );
  }
} 