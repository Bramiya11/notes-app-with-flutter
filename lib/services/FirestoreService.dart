import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'package:flutter/material.dart';

/// Servicio de sincronización con Firestore (NoSQL en la nube).
/// Complementa SQLite: SQLite = offline, Firestore = nube.
class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'notes';

  // ── Conversores ───────────────────────────────────────────────────────────

  static Map<String, dynamic> _noteToMap(Note note) => {
    'title': note.title,
    'body': note.body,
    'date': note.date,
    'isFeatured': note.isFeatured,
    'cardColor': note.cardColor?.toARGB32(),
    'textColor': note.textColor?.toARGB32(),
    'tags': note.tags.map((t) => {
      'label': t.label,
      'color': t.color.toARGB32(),
    }).toList(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static Note _mapToNote(Map<String, dynamic> data) => Note(
    title: data['title'] ?? '',
    body: data['body'],
    date: data['date'] ?? '',
    isFeatured: data['isFeatured'] ?? false,
    cardColor: data['cardColor'] != null ? Color(data['cardColor']) : null,
    textColor: data['textColor'] != null ? Color(data['textColor']) : null,
    tags: (data['tags'] as List<dynamic>? ?? [])
        .map((t) => NoteTag(
              label: t['label'] ?? '',
              color: Color(t['color'] ?? 0xFFFFFFFF),
            ))
        .toList(),
  );

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Guarda o actualiza una nota en Firestore (usa el título como ID)
  static Future<void> saveNote(Note note) async {
    final docId = note.title.replaceAll(' ', '_').toLowerCase();
    await _db.collection(_collection).doc(docId).set(_noteToMap(note));
  }

  /// Obtiene todas las notas desde Firestore
  static Future<List<Note>> getNotes() async {
    final snapshot = await _db
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => _mapToNote(doc.data()))
        .toList();
  }

  /// Elimina una nota de Firestore
  static Future<void> deleteNote(String title) async {
    final docId = title.replaceAll(' ', '_').toLowerCase();
    await _db.collection(_collection).doc(docId).delete();
  }

  /// Stream en tiempo real de las notas (opcional, para sincronización live)
  static Stream<List<Note>> notesStream() {
    return _db
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => _mapToNote(doc.data()))
            .toList());
  }
}