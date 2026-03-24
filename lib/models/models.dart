// models.dart
// Modelos de datos compartidos entre pantallas
 
import 'package:flutter/material.dart';
 
// ── Nota de texto ────────────────────────────────────────────────────────────
 
class Note {
  final String title;
  final String? body;
  final String date;
  final bool isFeatured;
  final List<NoteTag> tags;
  final Color? cardColor;
  final Color? textColor;
 
  const Note({
    required this.title,
    this.body,
    required this.date,
    this.isFeatured = false,
    this.tags = const [],
    this.cardColor,
    this.textColor,
  });
}
 
class NoteTag {
  final String label;
  final Color color;
  const NoteTag({required this.label, required this.color});
}
 
// ── Nota de voz ───────────────────────────────────────────────────────────────
 
class VoiceNote {
  final String id;
  final String date;
  final Duration duration;
  final String filePath;
 
  const VoiceNote({
    required this.id,
    required this.date,
    required this.duration,
    required this.filePath,
  });
}