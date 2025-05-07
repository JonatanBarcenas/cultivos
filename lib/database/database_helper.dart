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
    
    // Crear tabla de huertas
    await db.execute('''
      CREATE TABLE gardens(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        contact TEXT NOT NULL,
        location TEXT NOT NULL,
        crop_type TEXT NOT NULL,
        area REAL,
        notes TEXT,
        irrigation_type TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE mediciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cultivo_id INTEGER,
        garden_id TEXT,
        fecha TEXT NOT NULL,
        temperatura REAL,
        humedad REAL,
        ph REAL,
        conductividad REAL,
        nutrientes REAL,
        fertilidad REAL,
        FOREIGN KEY (cultivo_id) REFERENCES cultivos (id),
        FOREIGN KEY (garden_id) REFERENCES gardens (id)
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
  
  // Métodos para operaciones CRUD de gardens (huertas)
  Future<int> insertGarden(Map<String, dynamic> garden) async {
    Database db = await database;
    return await db.insert('gardens', garden);
  }
  
  Future<List<Map<String, dynamic>>> getGardens() async {
    Database db = await database;
    return await db.query('gardens');
  }
  
  Future<Map<String, dynamic>?> getGarden(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'gardens',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }
  
  Future<int> updateGarden(Map<String, dynamic> garden) async {
    Database db = await database;
    return await db.update(
      'gardens',
      garden,
      where: 'id = ?',
      whereArgs: [garden['id']],
    );
  }
  
  Future<int> deleteGarden(String id) async {
    Database db = await database;
    return await db.delete(
      'gardens',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Métodos para mediciones asociadas a huertas
  Future<int> insertGardenMeasurement(Map<String, dynamic> measurement) async {
    Database db = await database;
    return await db.insert('mediciones', measurement);
  }
  
  Future<List<Map<String, dynamic>>> getGardenMeasurements(String gardenId) async {
    Database db = await database;
    return await db.query(
      'mediciones',
      where: 'garden_id = ?',
      whereArgs: [gardenId],
      orderBy: 'fecha DESC'
    );
  }
}