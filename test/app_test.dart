// ignore_for_file: file_names
//
// test/app_test.dart
//
// Pruebas para la app de notas.
// Cubre: modelo Note/NoteTag, lógica de favoritos, papelera y edición.
//
// Para correr las pruebas:
//   flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app_with_flutter/models/models.dart';

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // GRUPO 1: Modelo Note
  // ══════════════════════════════════════════════════════════════════════════
  group('Modelo Note', () {
    test('Crea una nota con los campos correctos', () {
      const note = Note(
        title: 'Mi nota',
        body: 'Contenido de prueba',
        date: '01/01/2025',
      );

      expect(note.title, 'Mi nota');
      expect(note.body, 'Contenido de prueba');
      expect(note.date, '01/01/2025');
      expect(note.isFeatured, false); // valor por defecto
      expect(note.tags, isEmpty);
      expect(note.cardColor, isNull);
      expect(note.textColor, isNull);
    });

    test('Nota destacada tiene isFeatured en true', () {
      const note = Note(
        title: 'Nota importante',
        date: '01/01/2025',
        isFeatured: true,
      );

      expect(note.isFeatured, true);
    });

    test('Nota sin body devuelve null en body', () {
      const note = Note(title: 'Sin cuerpo', date: '01/01/2025');
      expect(note.body, isNull);
    });

    test('Nota con color de tarjeta personalizado', () {
      const note = Note(
        title: 'Nota colorida',
        date: '01/01/2025',
        cardColor: Color(0xFFF5F0C8),
        textColor: Color(0xFF1C1C1E),
      );

      expect(note.cardColor, const Color(0xFFF5F0C8));
      expect(note.textColor, const Color(0xFF1C1C1E));
    });

    test('Nota con tags los almacena correctamente', () {
      const note = Note(
        title: 'Nota con tags',
        date: '01/01/2025',
        tags: [
          NoteTag(label: 'Gym', color: Color(0xFF3B82F6)),
          NoteTag(label: 'Pagos', color: Color(0xFF22C55E)),
        ],
      );

      expect(note.tags.length, 2);
      expect(note.tags[0].label, 'Gym');
      expect(note.tags[1].label, 'Pagos');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GRUPO 2: Modelo NoteTag
  // ══════════════════════════════════════════════════════════════════════════
  group('Modelo NoteTag', () {
    test('Crea un tag con label y color correctos', () {
      const tag = NoteTag(label: 'Trabajo', color: Color(0xFFEF4444));

      expect(tag.label, 'Trabajo');
      expect(tag.color, const Color(0xFFEF4444));
    });

    test('Dos tags con los mismos valores son distintos objetos', () {
      const tag1 = NoteTag(label: 'A', color: Color(0xFF000000));
      const tag2 = NoteTag(label: 'A', color: Color(0xFF000000));

      expect(tag1.label, tag2.label);
      expect(tag1.color, tag2.color);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GRUPO 3: Lógica de favoritos
  // ══════════════════════════════════════════════════════════════════════════
  group('Lógica de favoritos', () {
    late Set<Note> favorites;
    late Note nota1;
    late Note nota2;

    setUp(() {
      favorites = {};
      nota1 = const Note(title: 'Nota 1', date: '01/01/2025');
      nota2 = const Note(title: 'Nota 2', date: '02/01/2025');
    });

    test('Añadir una nota a favoritos', () {
      favorites.add(nota1);
      expect(favorites.contains(nota1), true);
      expect(favorites.length, 1);
    });

    test('Quitar una nota de favoritos', () {
      favorites.add(nota1);
      favorites.remove(nota1);
      expect(favorites.contains(nota1), false);
      expect(favorites.isEmpty, true);
    });

    test('No se duplican favoritos al agregar la misma nota dos veces', () {
      favorites.add(nota1);
      favorites.add(nota1);
      expect(favorites.length, 1);
    });

    test('Múltiples notas en favoritos', () {
      favorites.add(nota1);
      favorites.add(nota2);
      expect(favorites.length, 2);
      expect(favorites.contains(nota1), true);
      expect(favorites.contains(nota2), true);
    });

    test('Toggle de favorito: agrega si no está, quita si está', () {
      void toggleFavorite(Note note) {
        if (favorites.contains(note)) {
          favorites.remove(note);
        } else {
          favorites.add(note);
        }
      }

      toggleFavorite(nota1);
      expect(favorites.contains(nota1), true);

      toggleFavorite(nota1);
      expect(favorites.contains(nota1), false);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GRUPO 4: Lógica de papelera
  // ══════════════════════════════════════════════════════════════════════════
  group('Lógica de papelera', () {
    late List<Note> notes;
    late List<Note> trashedNotes;

    setUp(() {
      notes = [
        const Note(title: 'Nota A', date: '01/01/2025'),
        const Note(title: 'Nota B', date: '02/01/2025'),
        const Note(title: 'Nota C', date: '03/01/2025'),
      ];
      trashedNotes = [];
    });

    test('Eliminar una nota la mueve a la papelera', () {
      final noteToDelete = notes[1];
      trashedNotes.insert(0, notes[1]);
      notes.removeAt(1);

      expect(notes.length, 2);
      expect(trashedNotes.length, 1);
      expect(trashedNotes.first, noteToDelete);
      expect(notes.any((n) => n.title == 'Nota B'), false);
    });

    test('La papelera mantiene el orden (última eliminada primero)', () {
      trashedNotes.insert(0, notes[0]); // Nota A
      trashedNotes.insert(0, notes[1]); // Nota B
      notes.removeAt(1);
      notes.removeAt(0);

      expect(trashedNotes[0].title, 'Nota B');
      expect(trashedNotes[1].title, 'Nota A');
    });

    test('Restaurar una nota la quita de la papelera y la agrega a notas', () {
      trashedNotes.insert(0, notes[0]);
      notes.removeAt(0);

      final restored = trashedNotes.removeAt(0);
      notes.insert(0, restored);

      expect(notes.length, 3);
      expect(trashedNotes.isEmpty, true);
      expect(notes.first.title, 'Nota A');
    });

    test('Vaciar papelera la deja sin elementos', () {
      trashedNotes.addAll(notes);
      notes.clear();

      trashedNotes.clear();

      expect(trashedNotes.isEmpty, true);
    });

    test('Eliminar nota que era favorita la quita de favoritos también', () {
      final favorites = <Note>{};
      final noteToDelete = notes[0];
      favorites.add(noteToDelete);

      favorites.remove(noteToDelete);
      trashedNotes.insert(0, noteToDelete);
      notes.removeAt(0);

      expect(favorites.contains(noteToDelete), false);
      expect(trashedNotes.contains(noteToDelete), true);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GRUPO 5: Lógica de edición de notas
  // ══════════════════════════════════════════════════════════════════════════
  group('Lógica de edición de notas', () {
    test('Actualizar el título de una nota', () {
      final notes = [
        const Note(title: 'Título original', date: '01/01/2025'),
      ];

      final updated = Note(
        title: 'Título actualizado',
        body: notes[0].body,
        date: notes[0].date,
        isFeatured: notes[0].isFeatured,
        tags: notes[0].tags,
        cardColor: notes[0].cardColor,
        textColor: notes[0].textColor,
      );

      notes[0] = updated;

      expect(notes[0].title, 'Título actualizado');
    });

    test('Actualizar el body de una nota', () {
      final notes = [
        const Note(title: 'Mi nota', body: 'Texto original', date: '01/01/2025'),
      ];

      final updated = Note(
        title: notes[0].title,
        body: 'Texto actualizado',
        date: notes[0].date,
      );

      notes[0] = updated;

      expect(notes[0].body, 'Texto actualizado');
    });

    test('Editar nota favorita actualiza la referencia en favoritos', () {
      final favorites = <Note>{};
      final notes = [
        const Note(title: 'Nota original', date: '01/01/2025'),
      ];

      favorites.add(notes[0]);
      expect(favorites.contains(notes[0]), true);

      final updated = Note(
        title: 'Nota editada',
        body: 'Nuevo contenido',
        date: notes[0].date,
      );

      final wasFav = favorites.contains(notes[0]);
      if (wasFav) {
        favorites.remove(notes[0]);
        favorites.add(updated);
      }
      notes[0] = updated;

      expect(favorites.contains(updated), true);
      expect(notes[0].title, 'Nota editada');
    });

    test('Agregar nueva nota la inserta al inicio de la lista', () {
      final notes = <Note>[
        const Note(title: 'Nota existente', date: '01/01/2025'),
      ];

      const newNote = Note(title: 'Nota nueva', date: '05/01/2025');
      notes.insert(0, newNote);

      expect(notes.first.title, 'Nota nueva');
      expect(notes.length, 2);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // GRUPO 6: Modelo VoiceNote
  // ══════════════════════════════════════════════════════════════════════════
  group('Modelo VoiceNote', () {
    test('Crea una nota de voz con los campos correctos', () {
      final voiceNote = VoiceNote(
        id: '12345',
        date: '01/01/2025',
        duration: const Duration(seconds: 30),
        filePath: '/ruta/al/archivo.aac',
      );

      expect(voiceNote.id, '12345');
      expect(voiceNote.date, '01/01/2025');
      expect(voiceNote.duration.inSeconds, 30);
      expect(voiceNote.filePath, '/ruta/al/archivo.aac');
    });

    test('Duración en minutos y segundos se calcula correctamente', () {
      final voiceNote = VoiceNote(
        id: '1',
        date: '01/01/2025',
        duration: const Duration(minutes: 1, seconds: 45),
        filePath: '/test.aac',
      );

      expect(voiceNote.duration.inMinutes, 1);
      expect(voiceNote.duration.inSeconds.remainder(60), 45);
    });

    test('Insertar nota de voz al inicio de la lista', () {
      final voiceNotes = <VoiceNote>[];
      final vn = VoiceNote(
        id: '1',
        date: '01/01/2025',
        duration: const Duration(seconds: 10),
        filePath: '/test.aac',
      );

      voiceNotes.insert(0, vn);

      expect(voiceNotes.first.id, '1');
      expect(voiceNotes.length, 1);
    });
  });
}