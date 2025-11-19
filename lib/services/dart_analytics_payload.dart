import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

/// Port of contoh/ninja_sage/analytics_payload.py to Dart.
///
/// Builds the compressed JSON payload used by Analytics.libraries.
class DartAnalyticsPayload {
  static const String defaultAssetBaseUrl =
      'https://ns-assets.ninjasage.id/static/lib/';

  static const List<String> _assetNames = [
    'skills',
    'library',
    'enemy',
    'npc',
    'pet',
    'mission',
    'gamedata',
    'talents',
    'senjutsu',
    'skill-effect',
    'weapon-effect',
    'back_item-effect',
    'accessory-effect',
    'arena-effect',
    'animation',
  ];

  static const List<String> _expectedOrder = [
    'weapon-effect',
    'library',
    'animation',
    'pet',
    'back_item-effect',
    'gamedata',
    'accessory-effect',
    'skills',
    'npc',
    'arena-effect',
    'talents',
    'enemy',
    'skill-effect',
    'senjutsu',
    'mission',
  ];

  static Map<String, int>? _cachedLengths;

  static Future<Map<String, int>> _fetchAssetLengths({
    String baseUrl = defaultAssetBaseUrl,
  }) async {
    if (_cachedLengths != null) {
      return _cachedLengths!;
    }
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final result = <String, int>{};
    for (final name in _assetNames) {
      final url = Uri.parse('$base/$name.bin');
      final resp = await http.get(url);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        result[name] = resp.bodyBytes.length;
      } else {
        result[name] = 0;
      }
    }
    _cachedLengths = result;
    return result;
  }

  /// Build zlib-compressed payload containing ordered JSON of asset lengths.
  static Future<Uint8List> buildAnalyticsPayload({
    String baseUrl = defaultAssetBaseUrl,
  }) async {
    final lengths = await _fetchAssetLengths(baseUrl: baseUrl);
    final buffer = StringBuffer();
    buffer.write('{');
    var first = true;
    for (final key in _expectedOrder) {
      final len = lengths[key];
      if (len == null) continue;
      if (!first) {
        buffer.write(',');
      }
      first = false;
      buffer.write('"');
      buffer.write(key);
      buffer.write('":');
      buffer.write(len);
    }
    buffer.write('}');
    final jsonBytes = utf8.encode(buffer.toString());

    // Use default compression level; current archive ZLibEncoder
    // does not accept positional/named level arguments.
    final encoder = ZLibEncoder();
    final compressed = encoder.encode(jsonBytes);
    return Uint8List.fromList(compressed);
  }
}
