import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Cliente para o backend do Up!Image.
/// O aplicativo nunca deve armazenar chaves secretas do provedor de IA.
class AiService {
  AiService({required this.baseUrl});
  final String baseUrl;

  Future<Uint8List> generateImage({required String prompt}) async {
    final uri = Uri.parse('$baseUrl/v1/images/generate');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt}),
    ).timeout(const Duration(minutes: 3));
    if (response.statusCode != 200) {
      throw Exception('Servidor respondeu ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final encoded = data['imageBase64'] as String?;
    if (encoded == null) throw Exception('Resposta sem imageBase64.');
    return base64Decode(encoded);
  }

  Future<String> chat(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    ).timeout(const Duration(minutes: 2));
    if (response.statusCode != 200) {
      throw Exception('Servidor respondeu ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['reply'] as String? ?? 'O servidor não retornou uma resposta.';
  }
}
