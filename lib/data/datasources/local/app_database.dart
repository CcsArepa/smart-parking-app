import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Acceso a la base de datos SQLite local (`udlap_parking.db`).
///
/// Tablas:
/// - `parking_events`: historial de reportes del usuario.
/// - `preferences`: pares clave/valor (p. ej. última zona visitada).
///
/// La base se abre de forma perezosa (la primera vez que se usa) para no
/// retrasar el arranque de la app.
class AppDatabase {
  AppDatabase({this.fileName = 'udlap_parking.db'});

  final String fileName;

  /// Incrementa este número y agrega la migración en [_onUpgrade] cuando
  /// cambie el esquema.
  static const int _version = 1;

  Future<Database>? _db;

  Future<Database> get database => _db ??= _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, fileName),
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch()
      ..execute('''
        CREATE TABLE parking_events (
          id        INTEGER PRIMARY KEY AUTOINCREMENT,
          lot_id    TEXT    NOT NULL,
          type      TEXT    NOT NULL,
          timestamp INTEGER NOT NULL
        )
      ''')
      ..execute(
        'CREATE INDEX idx_events_timestamp ON parking_events (timestamp DESC)',
      )
      ..execute('''
        CREATE TABLE preferences (
          key   TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Ejemplo para el futuro:
    // if (oldVersion < 2) await db.execute('ALTER TABLE ...');
  }

  Future<void> close() async {
    final db = await _db;
    await db?.close();
    _db = null;
  }
}
