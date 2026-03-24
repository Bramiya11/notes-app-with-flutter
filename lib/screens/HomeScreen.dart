// ignore_for_file: file_names
 
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notes_app_with_flutter/models/models.dart';
import 'VoiceNoteScreen.dart'; // VoiceNoteCard vive aquí — no redefinir
import 'AddNoteScreen.dart';
import 'OpenNoteScreen.dart';
 
// ── Pantalla de notas ────────────────────────────────────────────────────────
 
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
 
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}
 
class _NotesScreenState extends State<NotesScreen> {
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
 
  final List<VoiceNote> _voiceNotes = [];
 
  void _addNote(Note note) => setState(() => _notes.insert(0, note));
  void _addVoiceNote(VoiceNote vn) => setState(() => _voiceNotes.insert(0, vn));
 
  /// Reemplaza la nota en el índice dado con la versión editada
  void _updateNote(int index, Note notaActualizada) {
    setState(() => _notes[index] = notaActualizada);
  }
 
  /// Navega a [OpenNoteScreen] con animación de expansión fade+scale.
  /// Al regresar, si hubo cambios los aplica con _updateNote.
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
 
  @override
  Widget build(BuildContext context) {
    // Usamos .asMap().entries para conservar el índice original de cada nota
    final featuredNotes =
        _notes.asMap().entries.where((e) => e.value.isFeatured).toList();
    final smallNotes =
        _notes.asMap().entries.where((e) => !e.value.isFeatured).toList();
 
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notas de voz
                      if (_voiceNotes.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'NOTAS DE VOZ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        ..._voiceNotes.map(
                          (vn) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            // VoiceNoteCard importada desde VoiceNoteScreen.dart
                            child: VoiceNoteCard(voiceNote: vn),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
 
                      // Notas destacadas con animación al tocar
                      ...featuredNotes.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _AnimatedNoteCard(
                            onTap: () => _openNote(context, entry.key),
                            child: _FeaturedNoteCard(note: entry.value),
                          ),
                        ),
                      ),
 
                      // Notas pequeñas en grid con animación al tocar
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
                            onTap: () =>
                                _openNote(context, smallNotes[i].key),
                            child: _SmallNoteCard(note: smallNotes[i].value),
                          ),
                        ),
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
        onVoiceTap: () async {
          final vn = await Navigator.push<VoiceNote>(
            context,
            MaterialPageRoute(builder: (_) => const VoiceNoteScreen()),
          );
          if (vn != null) _addVoiceNote(vn);
        },
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color:
                    active ? const Color(0xFFF5C518) : Colors.transparent,
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
  const _FeaturedNoteCard({required this.note});
 
  @override
  Widget build(BuildContext context) {
    final bgColor = note.cardColor ?? const Color(0xFF2C2C2E);
    final fgColor = note.textColor ?? Colors.white;
 
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.title,
              style: TextStyle(
                  color: fgColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2)),
          if (note.body != null) ...[
            const SizedBox(height: 10),
            Text(note.body!,
                style: TextStyle(
                    color: fgColor.withValues(alpha: 0.75),
                    fontSize: 15,
                    height: 1.5)),
          ],
          const SizedBox(height: 18),
          Text(note.date,
              style: TextStyle(
                  color: fgColor.withValues(alpha: 0.5), fontSize: 13)),
        ],
      ),
    );
  }
}
 
// ── Widget: Nota pequeña (grid) ──────────────────────────────────────────────
 
class _SmallNoteCard extends StatelessWidget {
  final Note note;
  const _SmallNoteCard({required this.note});
 
  @override
  Widget build(BuildContext context) {
    final bgColor = note.cardColor ?? const Color(0xFF2C2C2E);
    final fgColor = note.textColor ?? Colors.white;
 
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(note.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.bookmark_rounded,
                  color: Colors.white38, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          if (note.tags.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: note.tags
                  .map((tag) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: tag.color,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(tag.label,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ]),
                      ))
                  .toList(),
            )
          else if (note.body != null)
            Text(note.body!,
                style:
                    TextStyle(color: fgColor, fontSize: 13, height: 1.45),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
 
// ── Widget: Bottom Navigation Bar ───────────────────────────────────────────
 
class _BottomBar extends StatelessWidget {
  final VoidCallback onAddTap;
  final VoidCallback onVoiceTap;
  const _BottomBar({required this.onAddTap, required this.onVoiceTap});
 
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
          _NavIcon(icon: Icons.present_to_all_rounded, onTap: () {}),
          Row(
            children: [
              GestureDetector(
                onTap: onVoiceTap,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D3D3F),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          const Color(0xFFF5C518).withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.mic_rounded,
                      color: Color(0xFFF5C518), size: 24),
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: onAddTap,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5C518),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.black, size: 30),
                ),
              ),
            ],
          ),
          _NavIcon(icon: Icons.delete_outline_rounded, onTap: () {}),
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