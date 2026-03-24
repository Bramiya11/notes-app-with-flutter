// ignore_for_file: file_names

import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:notes_app_with_flutter/models/models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum RecordingState { idle, recording, recorded }

class VoiceNoteScreen extends StatefulWidget {
  const VoiceNoteScreen({super.key});

  @override
  State<VoiceNoteScreen> createState() => _VoiceNoteScreenState();
}

class _VoiceNoteScreenState extends State<VoiceNoteScreen>
    with SingleTickerProviderStateMixin {
  RecordingState _state = RecordingState.idle;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  String? _filePath;

  final _recorder = AudioRecorder();

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ── Iniciar grabación ────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    // Verifica permiso de micrófono
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _showMicError();
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    _filePath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _filePath!,
    );

    setState(() {
      _state = RecordingState.recording;
      _elapsed = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  // ── Detener grabación ────────────────────────────────────────────────────
  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _recorder.stop(); // El archivo .aac queda guardado en _filePath
    setState(() => _state = RecordingState.recorded);
  }

  // ── Descartar: elimina el archivo temporal y regresa ─────────────────────
  Future<void> _discard() async {
    _timer?.cancel();
    if (await _recorder.isRecording()) await _recorder.stop();
    if (_filePath != null) {
      final file = File(_filePath!);
      if (await file.exists()) await file.delete();
    }
    if (mounted) Navigator.pop(context);
  }

  // ── Guardar: devuelve la VoiceNote a HomeScreen ──────────────────────────
  void _save() {
    if (_filePath == null) return;
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    Navigator.pop(
      context,
      VoiceNote(
        id: now.millisecondsSinceEpoch.toString(),
        date: date,
        duration: _elapsed,
        filePath: _filePath!,
      ),
    );
  }

  void _showMicError() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text('Sin acceso al micrófono',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Permite el acceso al micrófono en los ajustes del dispositivo e intenta de nuevo.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(color: Color(0xFFF5C518))),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
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
                  GestureDetector(
                    onTap: _discard,
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
                    'Nota de Voz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const Spacer(),

            // ── Cronómetro + estado ──────────────────────────────────────
            Column(
              children: [
                Text(
                  _state == RecordingState.idle
                      ? 'Listo para grabar'
                      : _state == RecordingState.recording
                          ? 'Grabando...'
                          : 'Grabación lista',
                  style: TextStyle(
                    color: _state == RecordingState.recording
                        ? const Color(0xFFEF4444)
                        : Colors.white54,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _formatDuration(_elapsed),
                  style: TextStyle(
                    color: _state == RecordingState.recording
                        ? Colors.white
                        : Colors.white38,
                    fontSize: 56,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 52),

            // ── Visualizador de onda ─────────────────────────────────────
            WaveVisualizer(isActive: _state == RecordingState.recording),

            const SizedBox(height: 52),

            // ── Botón principal ──────────────────────────────────────────
            if (_state != RecordingState.recorded)
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  final scale = _state == RecordingState.recording
                      ? _pulseAnim.value
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: GestureDetector(
                      onTap: _state == RecordingState.idle
                          ? _startRecording
                          : _stopRecording,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _state == RecordingState.recording
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFF5C518),
                          boxShadow: [
                            BoxShadow(
                              color: (_state == RecordingState.recording
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFF5C518))
                                  .withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _state == RecordingState.recording
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          color: Colors.black,
                          size: 38,
                        ),
                      ),
                    ),
                  );
                },
              ),

            // ── Post-grabación: descartar / guardar / repetir ────────────
            if (_state == RecordingState.recorded)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAction(
                    size: 64,
                    color: const Color(0xFF2C2C2E),
                    icon: Icons.delete_outline_rounded,
                    iconColor: Colors.white54,
                    onTap: _discard,
                  ),
                  const SizedBox(width: 32),
                  CircleAction(
                    size: 88,
                    color: const Color(0xFFF5C518),
                    icon: Icons.check_rounded,
                    iconColor: Colors.black,
                    onTap: _save,
                    glow: true,
                  ),
                  const SizedBox(width: 32),
                  CircleAction(
                    size: 64,
                    color: const Color(0xFF2C2C2E),
                    icon: Icons.refresh_rounded,
                    iconColor: Colors.white54,
                    onTap: () async {
                      // Elimina el archivo de la grabación descartada
                      if (_filePath != null) {
                        final file = File(_filePath!);
                        if (await file.exists()) await file.delete();
                      }
                      setState(() {
                        _state = RecordingState.idle;
                        _elapsed = Duration.zero;
                        _filePath = null;
                      });
                    },
                  ),
                ],
              ),

            const Spacer(),

            // ── Hint ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                _state == RecordingState.idle
                    ? 'Toca el micrófono para empezar'
                    : _state == RecordingState.recording
                        ? 'Toca el cuadrado para detener'
                        : 'Guarda o descarta la grabación',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ── VOICE NOTE CARD ───────────────────────────────────────────────────────────
// Definida UNA SOLA VEZ aquí. HOME.dart la importa desde este archivo.
// ════════════════════════════════════════════════════════════════════════════

class VoiceNoteCard extends StatefulWidget {
  final VoiceNote voiceNote;
  const VoiceNoteCard({super.key, required this.voiceNote});

  @override
  State<VoiceNoteCard> createState() => _VoiceNoteCardState();
}

class _VoiceNoteCardState extends State<VoiceNoteCard> {
  bool _isPlaying = false;
  double _progress = 0.0;
  Timer? _progressTimer;
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Cuando el audio termina naturalmente, resetea todo
    _player.onPlayerComplete.listen((_) {
      _progressTimer?.cancel();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _progress = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      _progressTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(DeviceFileSource(widget.voiceNote.filePath));
      setState(() {
        _isPlaying = true;
        _progress = 0.0;
      });

      final totalSecs = widget.voiceNote.duration.inSeconds;
      if (totalSecs == 0) return;

      _progressTimer =
          Timer.periodic(const Duration(milliseconds: 100), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _progress += 0.1 / totalSecs);
        if (_progress >= 1.0) {
          _progress = 0.0;
          _isPlaying = false;
          t.cancel();
        }
      });
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isPlaying
              ? const Color(0xFFEF4444).withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPlaying
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFF5C518),
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.mic_rounded,
                          color: Colors.white.withValues(alpha: 0.4),
                          size: 14),
                      const SizedBox(width: 4),
                      Text('Nota de voz',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12)),
                    ]),
                    Text(_fmt(widget.voiceNote.duration),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 4,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isPlaying
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF5C518),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(widget.voiceNote.date,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ── WIDGETS COMPARTIDOS ───────────────────────────────────────────────────────
// ════════════════════════════════════════════════════════════════════════════

class CircleAction extends StatelessWidget {
  final double size;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool glow;

  const CircleAction({
    super.key,
    required this.size,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: glow ? null : Border.all(color: Colors.white12, width: 1),
          boxShadow: glow
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4)
                ]
              : null,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.4),
      ),
    );
  }
}

class WaveVisualizer extends StatefulWidget {
  final bool isActive;
  const WaveVisualizer({super.key, required this.isActive});

  @override
  State<WaveVisualizer> createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends State<WaveVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: WavePainter(
            progress: _ctrl.value,
            isActive: widget.isActive,
          ),
          size: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;
  final bool isActive;
  WavePainter({required this.progress, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    const bars = 28;
    final barW = size.width / (bars * 2);
    final paint = Paint()
      ..color = isActive
          ? const Color(0xFFEF4444).withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.12)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barW;

    for (int i = 0; i < bars; i++) {
      final x = i * barW * 2 + barW;
      final heightFactor = isActive
          ? 0.2 + 0.8 * ((i % 5) / 5.0 + progress).abs() % 1.0
          : 0.15 + (i % 4) * 0.05;
      final barH = size.height * heightFactor;
      canvas.drawLine(
        Offset(x, size.height / 2 - barH / 2),
        Offset(x, size.height / 2 + barH / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WavePainter old) =>
      old.progress != progress || old.isActive != isActive;
}