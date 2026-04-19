import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Servicio para comunicarse con el backend Node.js propio.
class ApiService {
  // En emulador Android usa 10.0.2.2 en vez de localhost
  static const _baseUrl = 'http://localhost:3000/api-docs/';

  /// Envía una nota al backend para validación y registro
  static Future<bool> saveNote(Note note) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': note.title,
          'body': note.body,
          'date': note.date,
          'isFeatured': note.isFeatured,
        }),
      );
      return response.statusCode == 201;
    } catch (_) {
      return false; // Si el servidor no está disponible, continúa offline
    }
  }

  /// Busca notas en el backend
  static Future<List<String>> searchNotes(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notes?q=${Uri.encodeComponent(query)}'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map<String>((n) => n['title'] as String).toList();
      }
    } catch (_) {}
    return [];
  }
}