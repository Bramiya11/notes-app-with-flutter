import 'package:flutter/material.dart';
import 'package:notes_app_with_flutter/screens/HomeScreen.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});
 
  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}
 
class _AddNoteScreenState extends State<AddNoteScreen> {
  // ── Controladores ────────────────────────────────────────────────────────
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();
 
  // ── Estado del formulario ────────────────────────────────────────────────
  bool _isFeatured = false;
  Color _selectedCardColor = const Color(0xFF2C2C2E);
  Color _selectedTextColor = Colors.white;
  final List<NoteTag> _tags = [];
 
  // ── Paleta de colores para la tarjeta ────────────────────────────────────
  final List<Color> _cardColors = [
    const Color(0xFF2C2C2E), // Gris oscuro (default)
    const Color(0xFFF5F0C8), // Crema (como la nota destacada)
    const Color(0xFF1E3A5F), // Azul marino
    const Color(0xFF2D4A3E), // Verde oscuro
    const Color(0xFF4A1E2D), // Rojo oscuro
    const Color(0xFF3D2C6B), // Morado oscuro
    const Color.fromARGB(255, 236, 22, 165), // rosado
    const Color.fromARGB(255, 73, 8, 252), // azul
  ];
 
  // ── Paleta de colores para el texto ──────────────────────────────────────
  final List<Color> _textColors = [
    Colors.white,
    const Color(0xFF1C1C1E),
    const Color(0xFFF5C518),
    const Color(0xFFF59E0B),
    const Color(0xFF3B82F6),
    const Color(0xFF22C55E),
  ];
 
  // ── Colores disponibles para los tags ────────────────────────────────────
  final List<Color> _tagColors = [
    const Color(0xFF3B82F6),
    const Color(0xFF22C55E),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFFA855F7),
    const Color(0xFFF5C518),
  ];
  Color _selectedTagColor = const Color(0xFF3B82F6);
 
  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }
 
  // ── Agrega un tag a la lista ──────────────────────────────────────────────
  void _addTag() {
    final label = _tagController.text.trim();
    if (label.isEmpty) return;
    setState(() {
      _tags.add(NoteTag(label: label, color: _selectedTagColor));
      _tagController.clear();
    });
  }
 
  // ── Elimina un tag ────────────────────────────────────────────────────────
  void _removeTag(int index) {
    setState(() => _tags.removeAt(index));
  }
 
  // ── Construye y devuelve la nota a NotesScreen ───────────────────────────
  void _saveNote() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título no puede estar vacío'),
          backgroundColor: Color.fromARGB(255, 248, 57, 9),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
 
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
 
    final note = Note(
      title: title,
      body: _bodyController.text.trim().isEmpty
          ? null
          : _bodyController.text.trim(),
      date: date,
      isFeatured: _isFeatured,
      tags: List.from(_tags),
      cardColor: _selectedCardColor,
      textColor: _selectedTextColor,
    );
 
    Navigator.pop(context, note);
  }
 
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
                  // Botón volver
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const Text(
                    'Nueva Nota',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  // Botón guardar
                  GestureDetector(
                    onTap: _saveNote,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5C518),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.black, size: 22),
                    ),
                  ),
                ],
              ),
            ),
 
            // ── Formulario ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
 
                    // ── Preview de la nota ───────────────────────────────
                    _NotePreview(
                      title: _titleController.text,
                      body: _bodyController.text,
                      cardColor: _selectedCardColor,
                      textColor: _selectedTextColor,
                      tags: _tags,
                      isFeatured: _isFeatured,
                    ),
                    const SizedBox(height: 24),
 
                    // ── Título ───────────────────────────────────────────
                    _SectionLabel('Título'),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _titleController,
                      hint: 'Escribe un título...',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
 
                    // ── Cuerpo ───────────────────────────────────────────
                    _SectionLabel('Contenido'),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _bodyController,
                      hint: 'Escribe algo...',
                      maxLines: 4,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
 
                    // ── Toggle destacada ─────────────────────────────────
                    _SectionLabel('Destacada'),
                    const SizedBox(height: 8),
                    _ToggleFeatured(
                      value: _isFeatured,
                      onChanged: (val) => setState(() => _isFeatured = val),
                    ),
                    const SizedBox(height: 20),
 
                    // ── Color de tarjeta ─────────────────────────────────
                    _SectionLabel('Color de tarjeta'),
                    const SizedBox(height: 12),
                    _ColorPicker(
                      colors: _cardColors,
                      selected: _selectedCardColor,
                      onSelect: (c) =>
                          setState(() => _selectedCardColor = c),
                    ),
                    const SizedBox(height: 20),
 
                    // ── Color de texto ────────────────────────────────────
                    _SectionLabel('Color de texto'),
                    const SizedBox(height: 12),
                    _ColorPicker(
                      colors: _textColors,
                      selected: _selectedTextColor,
                      onSelect: (c) =>
                          setState(() => _selectedTextColor = c),
                    ),
                    const SizedBox(height: 20),
 
                    // ── Tags ──────────────────────────────────────────────
                    _SectionLabel('Tags'),
                    const SizedBox(height: 8),
 
                    // Input + selector de color de tag
                    Row(
                      children: [
                        Expanded(
                          child: _StyledTextField(
                            controller: _tagController,
                            hint: 'Nombre del tag...',
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Mini paleta de color para el tag
                        SizedBox(
                          height: 52,
                          child: Row(
                            children: _tagColors.map((c) {
                              final isSelected = c == _selectedTagColor;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedTagColor = c),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(right: 6),
                                  width: isSelected ? 28 : 22,
                                  height: isSelected ? 28 : 22,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white, width: 2)
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _addTag,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5C518),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.black, size: 22),
                          ),
                        ),
                      ],
                    ),
 
                    // Lista de tags agregados
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.asMap().entries.map((entry) {
                          final i = entry.key;
                          final tag = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: tag.color.withValues(alpha: 0.6),
                                  width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: tag.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tag.label,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _removeTag(i),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white38, size: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
 
                    const SizedBox(height: 32),
 
                    // ── Botón guardar ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _saveNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5C518),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Guardar nota',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Widget: Preview de la nota ────────────────────────────────────────────────
 
class _NotePreview extends StatelessWidget {
  final String title;
  final String body;
  final Color cardColor;
  final Color textColor;
  final List<NoteTag> tags;
  final bool isFeatured;
 
  const _NotePreview({
    required this.title,
    required this.body,
    required this.cardColor,
    required this.textColor,
    required this.tags,
    required this.isFeatured,
  });
 
  @override
  Widget build(BuildContext context) {
    final displayTitle =
        title.isEmpty ? 'Título de la nota...' : title;
    final displayBody = body.isEmpty ? null : body;
    final fgColor = title.isEmpty ? textColor.withValues(alpha: 0.3) : textColor;
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vista previa',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      displayTitle,
                      style: TextStyle(
                        color: fgColor,
                        fontSize: isFeatured ? 22 : 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (isFeatured)
                    Icon(Icons.star_rounded,
                        color: const Color(0xFFF5C518).withValues(alpha: 0.8),
                        size: 18),
                ],
              ),
              if (displayBody != null) ...[
                const SizedBox(height: 8),
                Text(
                  displayBody,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: tags.map((t) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: t.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(t.label,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 8),
                    ],
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
 
// ── Widget: Label de sección ──────────────────────────────────────────────────
 
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
 
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
 
// ── Widget: TextField estilizado ──────────────────────────────────────────────
 
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
 
  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
  });
 
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: Color(0xFFF5C518), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
 
// ── Widget: Toggle destacada ──────────────────────────────────────────────────
 
class _ToggleFeatured extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
 
  const _ToggleFeatured({required this.value, required this.onChanged});
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(14),
          border: value
              ? Border.all(
                  color: const Color(0xFFF5C518).withValues(alpha: 0.6),
                  width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: value
                      ? const Color(0xFFF5C518)
                      : Colors.white38,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  value
                      ? 'Nota destacada (tarjeta grande)'
                      : 'Marcar como destacada',
                  style: TextStyle(
                    color: value ? Colors.white : Colors.white54,
                    fontSize: 14,
                    fontWeight:
                        value ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 26,
              decoration: BoxDecoration(
                color: value
                    ? const Color(0xFFF5C518)
                    : Colors.white12,
                borderRadius: BorderRadius.circular(13),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color:
                        value ? Colors.black : Colors.white54,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Widget: Selector de color ─────────────────────────────────────────────────
 
class _ColorPicker extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelect;
 
  const _ColorPicker({
    required this.colors,
    required this.selected,
    required this.onSelect,
  });
 
  @override
  Widget build(BuildContext context) {
    return Row(
      children: colors.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 10),
            width: isSelected ? 36 : 30,
            height: isSelected ? 36 : 30,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: const Color(0xFFF5C518), width: 2.5)
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.15), width: 1),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: c.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}