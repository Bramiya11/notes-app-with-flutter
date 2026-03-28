// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../models/models.dart'; // Note y NoteTag vienen de aquí
import 'AddNoteScreen.dart';
import 'OpenNoteScreen.dart';
import 'TrashScreen.dart';
import 'VoiceNoteScreen.dart'; // Pantalla de grabación de voz

// ── Pantalla principal ───────────────────────────────────────────────────────

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  // Lista de notas de texto activas
  final List<Note> _notes = [
    const Note(
      title: 'Parcial Final',
      body: 'El dia sabado 01 de Noviembre es el parcial final de investigacion',
      date: '25/10/2025',
      isFeatured: true,
      cardColor: Color(0xFFF5F0C8),
      textColor: Color(0xFF1C1C1E),
    ),
    const Note(
      title: 'Nota 2',
      date: '24/10/2025',
      cardColor: Color(0xFF2C2C2E),
      tags: [
        NoteTag(label: 'Gym', color: Color(0xFF3B82F6)),
        NoteTag(label: 'Pagos', color: Color(0xFF22C55E)),
      ],
    ),
    const Note(
      title: 'Nota 3',
      body: 'Comprar comida del perro',
      date: '23/10/2025',
      cardColor: Color(0xFF2C2C2E),
      textColor: Color(0xFFF59E0B),
    ),
  ];

  // Lista de notas de voz grabadas
  final List<VoiceNote> _voiceNotes = [];

  // Lista de notas eliminadas (se muestran en TrashScreen)
  final List<Note> _trashedNotes = [];

  // Agrega una nota de texto nueva recibida desde AddNoteScreen
  void _addNote(Note note) {
    setState(() => _notes.insert(0, note));
  }

  // Agrega una nota de voz nueva recibida desde VoiceNoteScreen
  void _addVoiceNote(VoiceNote voiceNote) {
    setState(() => _voiceNotes.insert(0, voiceNote));
  }

  // Reemplaza la nota en el índice dado con la versión editada
  void _updateNote(int index, Note notaActualizada) {
    setState(() => _notes[index] = notaActualizada);
  }

  /// Mueve la nota del índice dado a la papelera
  void _deleteNote(int index) {
    setState(() {
      _trashedNotes.insert(0, _notes[index]);
      _notes.removeAt(index);
    });
  }

  /// Navega a [OpenNoteScreen] con animación de expansión.
  /// Si el usuario guardó cambios, actualiza la nota en la lista.
  Future<void> _openNote(BuildContext context, int index) async {
    final notaActualizada = await Navigator.push<Note>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => OpenNoteScreen(note: _notes[index]),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );

    if (notaActualizada != null) {
      _updateNote(index, notaActualizada);
    }
  }

  /// Navega a [VoiceNoteScreen] y si el usuario guardó una grabación,
  /// la agrega a la lista de notas de voz.
  Future<void> _openVoiceRecorder(BuildContext context) async {
    final voiceNote = await Navigator.push<VoiceNote>(
      context,
      MaterialPageRoute(builder: (_) => const VoiceNoteScreen()),
    );
    if (voiceNote != null) _addVoiceNote(voiceNote);
  }

  /// Navega a [TrashScreen] y al regresar sincroniza restauraciones y papelera
  Future<void> _openTrash(BuildContext context) async {
    final result = await Navigator.push<Map<String, List<Note>>>(
      context,
      MaterialPageRoute(
        builder: (_) => TrashScreen(trashedNotes: List.from(_trashedNotes)),
      ),
    );

    if (result != null) {
      setState(() {
        if (result['restored'] != null) {
          _notes.insertAll(0, result['restored']!);
        }
        if (result['trash'] != null) {
          _trashedNotes
            ..clear()
            ..addAll(result['trash']!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final featuredNotes = _notes
        .asMap()
        .entries
        .where((e) => e.value.isFeatured)
        .toList();
    final smallNotes = _notes
        .asMap()
        .entries
        .where((e) => !e.value.isFeatured)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _iconButton(Icons.menu_rounded, () {}),
                  const Text(
                    'Tus Notas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  _iconButton(Icons.history_rounded, () {}),
                ],
              ),
            ),

            // ── Filtro Todo / Favorito ───────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: _FilterBar(),
            ),

            // ── Lista de notas ───────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Notas de texto destacadas con animación y botón eliminar
                      ...featuredNotes.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _AnimatedNoteCard(
                            onTap: () => _openNote(context, entry.key),
                            child: _FeaturedNoteCard(
                              note: entry.value,
                              onDelete: () => _deleteNote(entry.key),
                            ),
                          ),
                        ),
                      ),

                      // Notas de texto pequeñas en grid con botón eliminar
                      if (smallNotes.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: smallNotes.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.05,
                          ),
                          itemBuilder: (context, i) => _AnimatedNoteCard(
                            onTap: () => _openNote(context, smallNotes[i].key),
                            child: _SmallNoteCard(
                              note: smallNotes[i].value,
                              onDelete: () => _deleteNote(smallNotes[i].key),
                            ),
                          ),
                        ),

                      // Notas de voz: se listan debajo de las notas de texto
                      if (_voiceNotes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        ...(_voiceNotes.map(
                          (vn) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            // VoiceNoteCard viene definida en VoiceNoteScreen.dart
                            child: VoiceNoteCard(voiceNote: vn),
                          ),
                        )),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        onAddTap: () async {
          final newNote = await Navigator.push<Note>(
            context,
            MaterialPageRoute(builder: (_) => const AddNoteScreen()),
          );
          if (newNote != null) _addNote(newNote);
        },
        // Abre VoiceNoteScreen al presionar el micrófono
        onMicTap: () => _openVoiceRecorder(context),
        onTrashTap: () => _openTrash(context),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Widget: Tarjeta con animación de escala al presionar ─────────────────────

class _AnimatedNoteCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedNoteCard({required this.child, required this.onTap});

  @override
  State<_AnimatedNoteCard> createState() => _AnimatedNoteCardState();
}

class _AnimatedNoteCardState extends State<_AnimatedNoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();

  void _onTapUp(_) async {
    await _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: widget.child,
      ),
    );
  }
}

// ── Widget: Barra de filtros ─────────────────────────────────────────────────

class _FilterBar extends StatefulWidget {
  const _FilterBar();

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  int _selected = 0;
  final _labels = ['Todo', 'Favorito'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_labels.length, (i) {
          final active = i == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFF5C518) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _labels[i],
                style: TextStyle(
                  color: active ? Colors.black : Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Widget: Nota destacada (grande) ─────────────────────────────────────────

class _FeaturedNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;

  const _FeaturedNoteCard({required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bgColor = note.cardColor ?? const Color(0xFF2C2C2E);
    final fgColor = note.textColor ?? Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              // Botón papelera: mueve la nota a TrashScreen
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: fgColor.withValues(alpha: 0.6),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          if (note.body != null) ...[
            const SizedBox(height: 10),
            Text(
              note.body!,
              style: TextStyle(
                color: fgColor.withValues(alpha: 0.75),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            note.date,
            style: TextStyle(
              color: fgColor.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget: Nota pequeña (grid) ──────────────────────────────────────────────

class _SmallNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;

  const _SmallNoteCard({required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bgColor = note.cardColor ?? const Color(0xFF2C2C2E);
    final fgColor = note.textColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Botón papelera pequeño para tarjetas del grid
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: fgColor.withValues(alpha: 0.5),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (note.tags.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: note.tags
                  .map(
                    (tag) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: tag.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tag.label,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            )
          else if (note.body != null)
            Text(
              note.body!,
              style: TextStyle(
                color: fgColor,
                fontSize: 13,
                height: 1.45,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

// ── Widget: Bottom Navigation Bar ───────────────────────────────────────────
// Orden: [presentación] [+ agregar nota] [🎤 grabar voz] [🗑 papelera]

class _BottomBar extends StatelessWidget {
  final VoidCallback onAddTap;
  final VoidCallback onMicTap;
  final VoidCallback onTrashTap;

  const _BottomBar({
    required this.onAddTap,
    required this.onMicTap,
    required this.onTrashTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Ícono presentación (izquierda)
          _NavIcon(icon: Icons.present_to_all_rounded, onTap: () {}),

          // Botón central amarillo para agregar nueva nota de texto
          GestureDetector(
            onTap: onAddTap,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFF5C518),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.black, size: 30),
            ),
          ),

          // Ícono micrófono: abre VoiceNoteScreen para grabar una nota de voz
          _NavIcon(icon: Icons.mic_rounded, onTap: onMicTap),

          // Ícono papelera: abre TrashScreen con las notas eliminadas
          _NavIcon(icon: Icons.delete_outline_rounded, onTap: onTrashTap),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white54, size: 26),
    );
  }
}