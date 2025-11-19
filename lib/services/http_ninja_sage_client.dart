import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:panel_app/services/ninja_sage_client.dart';

/// Implementasi NinjaSageClient yang berkomunikasi dengan
/// server Python di folder `contoh/api_server.py`.
class HttpNinjaSageClient implements NinjaSageClient {
  final Uri baseUri;

  HttpNinjaSageClient({
    String baseUrl = 'http://127.0.0.1:8080',
  }) : baseUri = Uri.parse(baseUrl);

  @override
  Future<Map<String, dynamic>> invoke(
    String target, {
    List<dynamic>? body,
  }) async {
    // Untuk saat ini kita hanya butuh daftar karakter,
    // sehingga semua pemanggilan diarahkan ke /api/characters.
    if (target == 'SystemLogin.getAllCharacters') {
      final uri = baseUri.replace(path: '/api/characters');
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        throw Exception(
          'Gagal memuat karakter (status ${resp.statusCode})',
        );
      }
      final decoded = json.decode(resp.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception('Response /api/characters tidak valid');
    }

    throw UnsupportedError('Target $target belum didukung di HttpNinjaSageClient');
  }
}

