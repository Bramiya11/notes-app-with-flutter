// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../models/models.dart'; // Note y NoteTag vienen de aquí

/// Pantalla de papelera. Muestra todas las notas que el usuario ha eliminado.
///
/// - Si la papelera está vacía muestra un mensaje informativo.
/// - Cada nota eliminada tiene un botón para restaurarla al home.
/// - Hay un botón para vaciar toda la papelera de una vez.
/// - Al regresar, devuelve a [HomeScreen] las listas actualizadas.
class TrashScreen extends StatefulWidget {
  final List<Note> trashedNotes;

  const TrashScreen({super.key, required this.trashedNotes});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late List<Note> _trashedNotes;

  // Notas que el usuario restauró en esta sesión, para devolverlas al home
  final List<Note> _restoredNotes = [];

  @override
  void initState() {
    super.initState();
    _trashedNotes = List.from(widget.trashedNotes);
  }

  /// Restaura una nota: la saca de la papelera y la marca para volver al home
  void _restoreNote(int index) {
    setState(() {
      _restoredNotes.add(_trashedNotes[index]);
      _trashedNotes.removeAt(index);
    });
  }

  /// Vacía la papelera completamente con confirmación previa
  void _emptyTrash() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Vaciar papelera',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          '¿Eliminar todas las notas de forma permanente?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _trashedNotes.clear());
              Navigator.pop(context);
            },
            child: const Text('Vaciar',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// Regresa a HomeScreen devolviendo las notas restauradas y la papelera actual
  void _goBack() {
    Navigator.pop(context, {
      'restored': _restoredNotes,
      'trash': _trashedNotes,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _trashedNotes.isEmpty;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        body: SafeArea(
          child: Column(
            children: [
              // ── App Bar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón regresar
                    GestureDetector(
                      onTap: _goBack,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    const Text(
                      'Papelera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),

                    // Botón vaciar papelera (solo visible si hay notas)
                    AnimatedOpacity(
                      opacity: isEmpty ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: isEmpty ? null : _emptyTrash,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A1A1A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Contenido ─────────────────────────────────────────────
              Expanded(
                child: isEmpty
                    ? _EmptyTrashMessage()
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView.separated(
                          itemCount: _trashedNotes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemBuilder: (context, index) {
                            final note = _trashedNotes[index];
                            return _TrashNoteCard(
                              note: note,
                              onRestore: () => _restoreNote(index),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget: Mensaje papelera vacía ───────────────────────────────────────────

class _EmptyTrashMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            size: 72,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 20),
          Text(
            'La papelera está vacía',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notas que elimines aparecerán aquí',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget: Tarjeta de nota en papelera ──────────────────────────────────────

class _TrashNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onRestore;

  const _TrashNoteCard({required this.note, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final bgColor = note.cardColor ?? const Color(0xFF2C2C2E);
    final fgColor = note.textColor ?? Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Opacidad reducida para indicar que la nota está eliminada
        color: bgColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contenido de la nota
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (note.body != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    note.body!,
                    style: TextStyle(
                      color: fgColor.withValues(alpha: 0.65),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  note.date,
                  style: TextStyle(
                    color: fgColor.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Botón restaurar nota
          GestureDetector(
            onTap: onRestore,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC40).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.restore_rounded,
                color: Color(0xFF2ECC40),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}