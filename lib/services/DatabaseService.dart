import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';
import 'package:flutter/material.dart';

/// Servicio de base de datos SQLite local.
/// Maneja la persistencia offline de notas de texto.
class DatabaseService {
  static Database? _database;
  static const _dbName = 'notes_app.db';
  static const _version = 1;

  /// Obtiene la instancia única de la base de datos (singleton)
  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
    );
  }

  /// Crea las tablas al inicializar por primera vez
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        title     TEXT NOT NULL,
        body      TEXT,
        date      TEXT NOT NULL,
        isFeatured INTEGER NOT NULL DEFAULT 0,
        cardColor INTEGER,
        textColor INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE note_tags (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        noteId  INTEGER NOT NULL,
        label   TEXT NOT NULL,
        color   INTEGER NOT NULL,
        FOREIGN KEY (noteId) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── CRUD de Notas ─────────────────────────────────────────────────────────

  /// Inserta una nota y sus tags. Retorna la nota con el ID asignado.
  static Future<Note> insertNote(Note note) async {
    final db = await database;

    final id = await db.insert('notes', {
      'title': note.title,
      'body': note.body,
      'date': note.date,
      'isFeatured': note.isFeatured ? 1 : 0,
      'cardColor': note.cardColor?.toARGB32(),
      'textColor': note.textColor?.toARGB32(),
    });

    for (final tag in note.tags) {
      await db.insert('note_tags', {
        'noteId': id,
        'label': tag.label,
        'color': tag.color.toARGB32(),
      });
    }

    return note;
  }

  /// Obtiene todas las notas con sus tags
  static Future<List<Note>> getNotes() async {
    final db = await database;
    final rows = await db.query('notes', orderBy: 'id DESC');

    final List<Note> notes = [];
    for (final row in rows) {
      final tags = await db.query(
        'note_tags',
        where: 'noteId = ?',
        whereArgs: [row['id']],
      );

      notes.add(Note(
        title: row['title'] as String,
        body: row['body'] as String?,
        date: row['date'] as String,
        isFeatured: (row['isFeatured'] as int) == 1,
        cardColor: row['cardColor'] != null
            ? Color(row['cardColor'] as int)
            : null,
        textColor: row['textColor'] != null
            ? Color(row['textColor'] as int)
            : null,
        tags: tags
            .map((t) => NoteTag(
                  label: t['label'] as String,
                  color: Color(t['color'] as int),
                ))
            .toList(),
      ));
    }
    return notes;
  }

  /// Actualiza una nota por título (como identificador único)
  static Future<void> updateNote(String originalTitle, Note updated) async {
    final db = await database;

    final rows = await db.query('notes',
        where: 'title = ?', whereArgs: [originalTitle]);
    if (rows.isEmpty) return;

    final id = rows.first['id'] as int;

    await db.update(
      'notes',
      {
        'title': updated.title,
        'body': updated.body,
        'date': updated.date,
        'isFeatured': updated.isFeatured ? 1 : 0,
        'cardColor': updated.cardColor?.toARGB32(),
        'textColor': updated.textColor?.toARGB32(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await db.delete('note_tags', where: 'noteId = ?', whereArgs: [id]);
    for (final tag in updated.tags) {
      await db.insert('note_tags', {
        'noteId': id,
        'label': tag.label,
        'color': tag.color.toARGB32(),
      });
    }
  }

  /// Elimina una nota y sus tags por título
  static Future<void> deleteNote(String title) async {
    final db = await database;
    await db.delete('notes', where: 'title = ?', whereArgs: [title]);
  }
}