// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:notes_app_with_flutter/services/NotificationService.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import 'AddNoteScreen.dart';
import 'OpenNoteScreen.dart';
import 'TrashScreen.dart';
import 'VoiceNoteScreen.dart';
import 'package:notes_app_with_flutter/services/DatabaseService.dart';
import 'package:notes_app_with_flutter/services/FirestoreService.dart';
import 'package:notes_app_with_flutter/services/APIService.dart';

// ── Pantalla principal ───────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Datos ────────────────────────────────────────────────────────────────
  final List<Note> _notes = [];

  final List<VoiceNote> _voiceNotes = [];
  final List<Note> _trashedNotes = [];
  final Set<Note> _favorites = {};

  // ── Controlador del PageView para la animación de tabs ───────────────────
  late final PageController _pageController;
  int _currentTab = 0; // 0 = Todo, 1 = Favorito

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadNotesFromDB();  
  }

  Future<void> _loadNotesFromDB() async {
    final saved = await DatabaseService.getNotes();
    if (saved.isNotEmpty) {
      setState(() {
        _notes.clear();
        _notes.addAll(saved);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Cambia al tab indicado con animación de deslizamiento suave
  void _switchTab(int index) {
    setState(() => _currentTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  // ── Acciones ─────────────────────────────────────────────────────────────

  Future<void> _addNote(Note note) async {
    // 1. UI inmediata
    setState(() => _notes.insert(0, note));

    // 2. SQLite (persistencia local)
    await DatabaseService.insertNote(note);

    // 3. Firestore (nube)
    await FirestoreService.saveNote(note);

    // 4. Backend propio (lógica de negocio / registro)
    await ApiService.saveNote(note);
  }

  void _addVoiceNote(VoiceNote vn) => setState(
    () => _voiceNotes.insert(0, vn)
  );

  Future<void> _updateNote(int i, Note updated) async {
    final original = _notes[i];
    setState(() {
      final wasFav = _favorites.contains(_notes[i]);
      if (wasFav) { _favorites.remove(_notes[i]); _favorites.add(updated); }
      _notes[i] = updated;
    });
    await DatabaseService.updateNote(original.title, updated);
    await FirestoreService.saveNote(updated);
  }

  void _deleteNote(int index) async {
    final note = _notes[index];
    setState(() {
      _favorites.remove(note);
      _trashedNotes.insert(0, note);
      _notes.removeAt(index);
    });
    await DatabaseService.deleteNote(note.title);
    await FirestoreService.deleteNote(note.title);
  }

  void _shareNote(Note note) {
    final text = [
      note.title,
      if (note.body != null) '\n${note.body}',
      '\n${note.date}',
    ].join();
    Share.share(text, subject: note.title);
  }

  void _toggleFavorite(Note note) {
    setState(() {
      if (_favorites.contains(note)) {
        _favorites.remove(note);
      } else {
        _favorites.add(note);
      }
    });
  }

  Future<void> _openNote(BuildContext context, int index) async {
    final updated = await Navigator.push<Note>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => OpenNoteScreen(note: _notes[index]),
        transitionsBuilder: (ctx, anim, _, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic);
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
    if (updated != null) {
    _updateNote(index, updated);
    await NotificationService.showNotaEditada();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nota editada exitosamente'),
          backgroundColor: Color(0xFF2ECC40),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  }

  Future<void> _openFavoriteNote(BuildContext context, Note note) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => OpenNoteScreen(note: note),
        transitionsBuilder: (ctx, anim, _, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic);
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
  }

  Future<void> _openVoiceRecorder(BuildContext context) async {
    final vn = await Navigator.push<VoiceNote>(
      context,
      MaterialPageRoute(builder: (_) => const VoiceNoteScreen()),
    );
    if (vn != null) _addVoiceNote(vn);
  }

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
          _trashedNotes..clear()..addAll(result['trash']!);
        }
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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

            // ── Filtro Todo / Favorito (animado) ─────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _AnimatedFilterBar(
                selected: _currentTab,
                onTap: _switchTab,
                favoritesCount: _favorites.length,
              ),
            ),

            // ── Contenido con PageView animado ───────────────────────────
            // PageView permite deslizar entre "Todo" y "Favorito"
            // con la misma animación que cuando tocas el tab.
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // solo navegamos via tabs
                onPageChanged: (i) => setState(() => _currentTab = i),
                children: [
                  // ── Tab 0: Todas las notas ───────────────────────────
                  _AllNotesTab(
                    notes: _notes,
                    voiceNotes: _voiceNotes,
                    favorites: _favorites,
                    onOpenNote: (index) => _openNote(context, index),
                    onDelete: _deleteNote,
                    onShare: _shareNote,
                    onToggleFavorite: _toggleFavorite,
                  ),

                  // ── Tab 1: Solo favoritas ───────────────────────────
                  _FavoritesTab(
                    favorites: _favorites,
                    onOpenNote: (note) => _openFavoriteNote(context, note),
                    onShare: _shareNote,
                    onRemoveFavorite: _toggleFavorite,
                  ),
                ],
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
          if (newNote != null) {
            _addNote(newNote);
            await NotificationService.showNotaGuardada();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nota guardada exitosamente'),
                  backgroundColor: Color(0xFF2ECC40),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
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

// ── Widget: Filtro animado Todo/Favorito ──────────────────────────────────────
/// Usa AnimatedContainer para la píldora deslizante y muestra
/// el conteo de favoritos en un badge amarillo cuando hay alguno.

class _AnimatedFilterBar extends StatelessWidget {
  final int selected;
  final void Function(int) onTap;
  final int favoritesCount;

  const _AnimatedFilterBar({
    required this.selected,
    required this.onTap,
    required this.favoritesCount,
  });

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
        children: [
          // Botón "Todo"
          GestureDetector(
            onTap: () => onTap(0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: selected == 0
                    ? const Color(0xFFF5C518)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Todo',
                style: TextStyle(
                  color: selected == 0 ? Colors.black : Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          // Botón "Favorito" con badge de conteo
          GestureDetector(
            onTap: () => onTap(1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: selected == 1
                    ? const Color(0xFFF5C518)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Favorito',
                    style: TextStyle(
                      color: selected == 1 ? Colors.black : Colors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  // Badge con conteo, visible solo si hay favoritos
                  if (favoritesCount > 0) ...[
                    const SizedBox(width: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected == 1
                            ? Colors.black.withValues(alpha: 0.2)
                            : const Color(0xFFF5C518).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$favoritesCount',
                        style: TextStyle(
                          color: selected == 1
                              ? Colors.black
                              : const Color(0xFFF5C518),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget: Tab "Todas las notas" ─────────────────────────────────────────────

class _AllNotesTab extends StatelessWidget {
  final List<Note> notes;
  final List<VoiceNote> voiceNotes;
  final Set<Note> favorites;
  final void Function(int) onOpenNote;
  final void Function(int) onDelete;
  final void Function(Note) onShare;
  final void Function(Note) onToggleFavorite;

  const _AllNotesTab({
    required this.notes,
    required this.voiceNotes,
    required this.favorites,
    required this.onOpenNote,
    required this.onDelete,
    required this.onShare,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final featuredNotes =
        notes.asMap().entries.where((e) => e.value.isFeatured).toList();
    final smallNotes =
        notes.asMap().entries.where((e) => !e.value.isFeatured).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Notas destacadas
            ...featuredNotes.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AnimatedNoteCard(
                  onTap: () => onOpenNote(entry.key),
                  child: _FeaturedNoteCard(
                    note: entry.value,
                    isFavorite: favorites.contains(entry.value),
                    onDelete: () => onDelete(entry.key),
                    onShare: () => onShare(entry.value),
                    onFavorite: () => onToggleFavorite(entry.value),
                  ),
                ),
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
                itemBuilder: (context, i) => _AnimatedNoteCard(
                  onTap: () => onOpenNote(smallNotes[i].key),
                  child: _SmallNoteCard(
                    note: smallNotes[i].value,
                    isFavorite: favorites.contains(smallNotes[i].value),
                    onDelete: () => onDelete(smallNotes[i].key),
                    onShare: () => onShare(smallNotes[i].value),
                    onFavorite: () => onToggleFavorite(smallNotes[i].value),
                  ),
                ),
              ),

            // Notas de voz
            if (voiceNotes.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...voiceNotes.map(
                (vn) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VoiceNoteCard(voiceNote: vn),
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Widget: Tab "Favoritas" ───────────────────────────────────────────────────

class _FavoritesTab extends StatelessWidget {
  final Set<Note> favorites;
  final void Function(Note) onOpenNote;
  final void Function(Note) onShare;
  final void Function(Note) onRemoveFavorite;

  const _FavoritesTab({
    required this.favorites,
    required this.onOpenNote,
    required this.onShare,
    required this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final list = favorites.toList();
    final featured = list.where((n) => n.isFeatured).toList();
    final small = list.where((n) => !n.isFeatured).toList();

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline_rounded,
              size: 72,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 20),
            Text(
              'No tienes favoritos aún',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Usa el menú ••• en una nota para añadirla',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Notas destacadas favoritas
            ...featured.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AnimatedNoteCard(
                  onTap: () => onOpenNote(note),
                  child: _FeaturedNoteCard(
                    note: note,
                    isFavorite: true,
                    // En favoritos no se puede eliminar la nota, solo quitarla
                    onDelete: () => onRemoveFavorite(note),
                    onShare: () => onShare(note),
                    onFavorite: () => onRemoveFavorite(note),
                    // Etiqueta del menú personalizada para este tab
                    favoriteLabel: 'Quitar de favoritos',
                    hideDelete: true,
                  ),
                ),
              ),
            ),

            // Notas pequeñas favoritas en grid
            if (small.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: small.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, i) => _AnimatedNoteCard(
                  onTap: () => onOpenNote(small[i]),
                  child: _SmallNoteCard(
                    note: small[i],
                    isFavorite: true,
                    onDelete: () => onRemoveFavorite(small[i]),
                    onShare: () => onShare(small[i]),
                    onFavorite: () => onRemoveFavorite(small[i]),
                    favoriteLabel: 'Quitar de favoritos',
                    hideDelete: true,
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
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
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _anim = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) async {
    await _ctrl.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _anim, child: widget.child),
    );
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────
bool _isLightBackground(Color color) => color.computeLuminance() > 0.4;

// ── Widget: Botón de 3 puntos con menú contextual ────────────────────────────

class _NoteMenuButton extends StatefulWidget {
  final Color cardBgColor;
  final bool isFavorite;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final String favoriteLabel;
  final bool hideDelete;

  const _NoteMenuButton({
    required this.cardBgColor,
    required this.isFavorite,
    required this.onDelete,
    required this.onShare,
    required this.onFavorite,
    this.favoriteLabel = '',
    this.hideDelete = false,
  });

  @override
  State<_NoteMenuButton> createState() => _NoteMenuButtonState();
}

class _NoteMenuButtonState extends State<_NoteMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setHover(bool val) => val ? _ctrl.forward() : _ctrl.reverse();

  void _showMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);

    final favLabel = widget.favoriteLabel.isNotEmpty
        ? widget.favoriteLabel
        : (widget.isFavorite ? 'Quitar favorito' : 'Añadir a favoritos');

    final items = <PopupMenuEntry<String>>[];

    // Opción eliminar (oculta en tab favoritos)
    if (!widget.hideDelete) {
      items.add(PopupMenuItem(
        value: 'delete',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent, size: 17),
          ),
          const SizedBox(width: 12),
          const Text('Eliminar',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ]),
      ));
      items.add(const PopupMenuDivider(height: 1));
    }

    // Opción compartir
    items.add(PopupMenuItem(
      value: 'share',
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF5C518).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.share_rounded,
              color: Color(0xFFF5C518), size: 17),
        ),
        const SizedBox(width: 12),
        const Text('Compartir',
            style: TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      ]),
    ));
    items.add(const PopupMenuDivider(height: 1));

    // Opción favorito
    items.add(PopupMenuItem(
      value: 'favorite',
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF5C518).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            (widget.isFavorite || widget.hideDelete)
                ? Icons.bookmark_rounded
                : Icons.bookmark_outline_rounded,
            color: const Color(0xFFF5C518), size: 17,
          ),
        ),
        const SizedBox(width: 12),
        Text(favLabel,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      ]),
    ));

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height + 4,
        offset.dx + box.size.width,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: const Color(0xFF2C2C2E),
      elevation: 8,
      items: items,
    );

    if (selected == 'delete') widget.onDelete();
    if (selected == 'share') widget.onShare();
    if (selected == 'favorite') widget.onFavorite();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _isLightBackground(widget.cardBgColor);
    final restBg    = isLight ? Colors.black.withValues(alpha: 0.08)
                              : const Color(0xFF1C1C1E).withValues(alpha: 0.6);
    final hoverBg   = isLight ? Colors.black.withValues(alpha: 0.16)
                              : const Color(0xFF1C1C1E).withValues(alpha: 0.9);
    final restBdr   = isLight ? Colors.black.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.15);
    final hoverBdr  = isLight ? Colors.black.withValues(alpha: 0.40)
                              : const Color(0xFFF5C518);
    final restIcon  = isLight ? const Color(0xFF2C2C2E) : Colors.white54;
    final hoverIcon = isLight ? const Color(0xFF2C2C2E) : const Color(0xFFF5C518);

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTap: () => _showMenu(context),
        onTapDown: (_) => _setHover(true),
        onTapUp: (_) => _setHover(false),
        onTapCancel: () => _setHover(false),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Color.lerp(restBg, hoverBg, _anim.value),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color.lerp(restBdr, hoverBdr, _anim.value)!,
                width: 1.5,
              ),
            ),
            child: Icon(Icons.more_vert_rounded,
                color: Color.lerp(restIcon, hoverIcon, _anim.value), size: 16),
          ),
        ),
      ),
    );
  }
}

// ── Widget: Nota destacada (grande) ─────────────────────────────────────────

class _FeaturedNoteCard extends StatelessWidget {
  final Note note;
  final bool isFavorite;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final String favoriteLabel;
  final bool hideDelete;

  const _FeaturedNoteCard({
    required this.note,
    required this.isFavorite,
    required this.onDelete,
    required this.onShare,
    required this.onFavorite,
    this.favoriteLabel = '',
    this.hideDelete = false,
  });

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
        // Borde amarillo sutil si está en favoritos
        border: isFavorite
            ? Border.all(
                color: const Color(0xFFF5C518).withValues(alpha: 0.35),
                width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(note.title,
                    style: TextStyle(
                        color: fgColor, fontSize: 28,
                        fontWeight: FontWeight.w700, height: 1.2)),
              ),
              _NoteMenuButton(
                cardBgColor: bgColor,
                isFavorite: isFavorite,
                onDelete: onDelete,
                onShare: onShare,
                onFavorite: onFavorite,
                favoriteLabel: favoriteLabel,
                hideDelete: hideDelete,
              ),
            ],
          ),
          if (note.body != null) ...[
            const SizedBox(height: 10),
            Text(note.body!,
                style: TextStyle(
                    color: fgColor.withValues(alpha: 0.75),
                    fontSize: 15, height: 1.5)),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Text(note.date,
                  style: TextStyle(
                      color: fgColor.withValues(alpha: 0.5), fontSize: 13)),
              if (isFavorite) ...[
                const SizedBox(width: 8),
                Icon(Icons.bookmark_rounded,
                    color: const Color(0xFFF5C518).withValues(alpha: 0.8),
                    size: 15),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Widget: Nota pequeña (grid) ──────────────────────────────────────────────

class _SmallNoteCard extends StatelessWidget {
  final Note note;
  final bool isFavorite;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final String favoriteLabel;
  final bool hideDelete;

  const _SmallNoteCard({
    required this.note,
    required this.isFavorite,
    required this.onDelete,
    required this.onShare,
    required this.onFavorite,
    this.favoriteLabel = '',
    this.hideDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = note.cardColor ?? const Color(0xFF2C2C2E);
    final fgColor = note.textColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: isFavorite
            ? Border.all(
                color: const Color(0xFFF5C518).withValues(alpha: 0.35),
                width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(note.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 6),
              _NoteMenuButton(
                cardBgColor: bgColor,
                isFavorite: isFavorite,
                onDelete: onDelete,
                onShare: onShare,
                onFavorite: onFavorite,
                favoriteLabel: favoriteLabel,
                hideDelete: hideDelete,
              ),
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
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                                color: tag.color, shape: BoxShape.circle),
                          ),
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
                style: TextStyle(color: fgColor, fontSize: 13, height: 1.45),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
          if (isFavorite) ...[
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.bookmark_rounded,
                  color: const Color(0xFFF5C518).withValues(alpha: 0.8),
                  size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Widget: Bottom Navigation Bar ───────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _HoverNavIcon(icon: Icons.present_to_all_rounded, onTap: () {}),
          _HoverAddButton(onTap: onAddTap),
          _HoverNavIcon(icon: Icons.mic_rounded, onTap: onMicTap),
          _HoverNavIcon(icon: Icons.delete_outline_rounded, onTap: onTrashTap),
        ],
      ),
    );
  }
}

class _HoverNavIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HoverNavIcon({required this.icon, required this.onTap});

  @override
  State<_HoverNavIcon> createState() => _HoverNavIconState();
}

class _HoverNavIconState extends State<_HoverNavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setHover(bool val) => val ? _ctrl.forward() : _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setHover(true),
        onTapUp: (_) => _setHover(false),
        onTapCancel: () => _setHover(false),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                  Colors.transparent, const Color(0xFF1C1C1E), _anim.value),
              border: Border.all(
                color: Color.lerp(Colors.transparent,
                    const Color(0xFFF5C518), _anim.value)!,
                width: 1.5,
              ),
            ),
            child: Icon(widget.icon,
                color: Color.lerp(
                    Colors.white54, const Color(0xFFF5C518), _anim.value),
                size: 22),
          ),
        ),
      ),
    );
  }
}

class _HoverAddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverAddButton({required this.onTap});

  @override
  State<_HoverAddButton> createState() => _HoverAddButtonState();
}

class _HoverAddButtonState extends State<_HoverAddButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setHover(bool val) => val ? _ctrl.forward() : _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setHover(true),
        onTapUp: (_) => _setHover(false),
        onTapCancel: () => _setHover(false),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                  const Color(0xFFF5C518), const Color(0xFFD4A800), _anim.value),
              border: Border.all(
                color: Color.lerp(
                  Colors.transparent,
                  const Color(0xFFF5C518).withValues(alpha: 0.5),
                  _anim.value,
                )!,
                width: 3,
              ),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.black, size: 30),
          ),
        ),
      ),
    );
  }
}