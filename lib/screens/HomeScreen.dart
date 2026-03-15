// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'AddNoteScreen.dart';

// ── Modelo de datos ──────────────────────────────────────────────────────────

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

// ── Pantalla de notas ────────────────────────────────────────────────────────

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

// _notes pasa de 'const' a ser 'mutable' para agregar nuevas notas de forma dinámica
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

  //Con este método se agrega las notas recibidas desde AddNoteScreen
  void _addNote(Note note) {
    setState(() {
      _notes.insert(0, note);
    });
  }

  //Se separa la lógica de featuredNotes y smallNotes para que múltiples destacadas funcionen correctamente.
  @override
  Widget build(BuildContext context) {
    final featuredNotes = _notes.where((n) => n.isFeatured).toList();
    final smallNotes = _notes.where((n) => !n.isFeatured).toList();

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
                      //Aquí van las notas destacadas
                      ...featuredNotes.map(
                        (note) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _FeaturedNoteCard(note: note),
                        ),
                      ),
 
                      // Notas pequeñas en grid
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
                          itemBuilder: (context, index) =>
                              _SmallNoteCard(note: smallNotes[index]),
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
          // Navega a AddNoteScreen y espera la nota de retorno
          final newNote = await Navigator.push<Note>(
            context,
            MaterialPageRoute(builder: (_) => const AddNoteScreen()),
          );
          if (newNote != null) _addNote(newNote);
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
  const _FeaturedNoteCard({required this.note});

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
          Text(
            note.title,
            style: TextStyle(
              color: fgColor,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
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
  const _SmallNoteCard({required this.note});

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
              Text(
                note.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.bookmark_rounded, color: Colors.white38, size: 18),
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
//Cambios: este botón ahora recibe un OnAddTap con el que navegamos a AddNoteScreen con Navigator.Push
class _BottomBar extends StatelessWidget {
  final VoidCallback onAddTap;
  const _BottomBar({required this.onAddTap});

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