// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../models/models.dart'; // Note y NoteTag vienen de aquí

/// Determina si un color de fondo es claro u oscuro usando luminancia relativa.
/// Retorna [Colors.black] si el fondo es claro, [Colors.white] si es oscuro.
Color _textColorForBackground(Color background) {
  final luminance = background.computeLuminance();
  return luminance > 0.4 ? Colors.black : Colors.white;
}

/// Pantalla para ver y editar una nota existente.
///
/// - Botón REGRESAR (flecha): descarta todos los cambios y vuelve sin modificar la nota.
/// - Botón GUARDAR (check verde): guarda los cambios y los devuelve a [HomeScreen].
/// - Botón CLIP: para adjuntar imagen (pendiente de implementar).
class OpenNoteScreen extends StatefulWidget {
  final Note note;

  const OpenNoteScreen({super.key, required this.note});

  @override
  State<OpenNoteScreen> createState() => _OpenNoteScreenState();
}

class _OpenNoteScreenState extends State<OpenNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;

  late Color _cardBg;
  late Color _fgColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _bodyController = TextEditingController(text: widget.note.body ?? '');

    _cardBg = widget.note.cardColor ?? const Color(0xFF2C2C2E);
    // Color del texto calculado automáticamente según luminancia del fondo
    _fgColor = _textColorForBackground(_cardBg);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  /// REGRESAR: cierra la pantalla sin devolver ningún dato (descarta cambios)
  void _descartarYRegresar() {
    Navigator.pop(context, null);
  }

  /// GUARDAR: construye la nota actualizada y la devuelve a HomeScreen
  void _guardarYRegresar() {
    final notaActualizada = Note(
      title: _titleController.text.trim().isEmpty
          ? widget.note.title
          : _titleController.text.trim(),
      body: _bodyController.text.trim().isEmpty
          ? null
          : _bodyController.text.trim(),
      date: widget.note.date,
      isFeatured: widget.note.isFeatured,
      tags: widget.note.tags,
      cardColor: widget.note.cardColor,
      textColor: widget.note.textColor,
    );
    Navigator.pop(context, notaActualizada);
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = _fgColor;
    final bodyColor = _fgColor.withValues(alpha: 0.85);
    final hintColor = _fgColor.withValues(alpha: 0.35);
    final dateColor = _fgColor.withValues(alpha: 0.45);
    final dividerColor = _fgColor.withValues(alpha: 0.1);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        body: SafeArea(
          child: Column(
            children: [
              // ── Barra superior ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón regresar: descarta cambios
                    _TopButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: _descartarYRegresar,
                    ),

                    Row(
                      children: [
                        // Botón clip: adjuntar imagen (pendiente)
                        _TopButton(
                          icon: Icons.attach_file_rounded,
                          onTap: () {
                            // TODO: implementar adjuntar imagen
                          },
                        ),
                        const SizedBox(width: 10),
                        // Botón guardar (check verde): confirma los cambios
                        _SaveButton(onTap: _guardarYRegresar),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Recuadro principal de la nota ──────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Campo editable: título
                          TextField(
                            controller: _titleController,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: null,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Título',
                              hintStyle: TextStyle(
                                color: hintColor,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Fecha (solo lectura)
                          Text(
                            widget.note.date,
                            style: TextStyle(color: dateColor, fontSize: 13),
                          ),

                          // Separador sutil
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: dividerColor, thickness: 1),
                          ),

                          // Campo editable: cuerpo de la nota
                          TextField(
                            controller: _bodyController,
                            style: TextStyle(
                              color: bodyColor,
                              fontSize: 16,
                              height: 1.65,
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Escribe algo...',
                              hintStyle: TextStyle(
                                color: hintColor,
                                fontSize: 16,
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),

                          // Tags (solo lectura)
                          if (widget.note.tags.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 16,
                              runSpacing: 10,
                              children: widget.note.tags.map((tag) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                      style: TextStyle(
                                        color: bodyColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
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

// ── Botón superior genérico ──────────────────────────────────────────────────

class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
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

// ── Botón guardar (check verde circular) ─────────────────────────────────────

class _SaveButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SaveButton({required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
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
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF2ECC40),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}