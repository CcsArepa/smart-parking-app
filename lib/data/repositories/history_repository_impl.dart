import 'package:sqflite/sqflite.dart';

import '../../domain/entities/parking_event.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/local/app_database.dart';
import '../models/parking_event_model.dart';

/// Historial y preferencias guardados en SQLite (Android / iOS / macOS).
class SqliteHistoryRepository implements HistoryRepository {
  SqliteHistoryRepository(this._database);
  final AppDatabase _database;

  @override
  Future<ParkingEvent> saveEvent(ParkingEvent event) async {
    final db = await _database.database;
    final id = await db.insert(
      'parking_events',
      ParkingEventModel.fromEntity(event).toRow(),
    );
    return event.copyWith(id: id);
  }

  @override
  Future<List<ParkingEvent>> getHistory({int limit = 50}) async {
    final db = await _database.database;
    final rows = await db.query(
      'parking_events',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map((r) => ParkingEventModel.fromRow(r).toEntity()).toList();
  }

  @override
  Future<String?> getPreference(String key) async {
    final db = await _database.database;
    final rows = await db.query(
      'preferences',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  @override
  Future<void> setPreference(String key, String value) async {
    final db = await _database.database;
    await db.insert(
      'preferences',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

/// Versión en memoria del historial.
///
/// Se usa en plataformas donde `sqflite` no está disponible (web, Windows,
/// Linux) y en las pruebas automatizadas. Los datos se pierden al cerrar.
class InMemoryHistoryRepository implements HistoryRepository {
  final List<ParkingEvent> _events = [];
  final Map<String, String> _prefs = {};
  int _nextId = 1;

  @override
  Future<ParkingEvent> saveEvent(ParkingEvent event) async {
    final saved = event.copyWith(id: _nextId++);
    _events.add(saved);
    return saved;
  }

  @override
  Future<List<ParkingEvent>> getHistory({int limit = 50}) async {
    final sorted = [..._events]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  @override
  Future<String?> getPreference(String key) async => _prefs[key];

  @override
  Future<void> setPreference(String key, String value) async =>
      _prefs[key] = value;
}
