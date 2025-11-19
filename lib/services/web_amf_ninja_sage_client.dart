import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:panel_app/amf/amf3.dart';
import 'package:panel_app/services/ninja_sage_client.dart';

class WebAmfNinjaSageClient implements NinjaSageClient {
  final Uri baseUri;

  WebAmfNinjaSageClient({
    String baseUrl = 'https://play.ninjasage.id',
  }) : baseUri = Uri.parse(baseUrl);

  @override
  Future<Map<String, dynamic>> invoke(
    String target, {
    List<dynamic>? body,
  }) async {
    final message = Amf3ActionMessage(
      version: 3,
      bodies: [
        Amf3MessageBody(
          targetURI: target,
          responseURI: '/1',
          data: body ?? const <dynamic>[],
        ),
      ],
    );

    final serializer = Amf3Serializer();
    final payload = serializer.writeMessage(message);

    final url = baseUri.replace(path: '${baseUri.path}/amf');
    final resp = await http.post(
      url,
      headers: const {
        'Content-Type': 'application/x-amf',
        'Referer': 'app:/NinjaSage.swf',
        'x-flash-version': '51,1,3,10',
        'User-Agent':
            'Mozilla/5.0 (Windows; U; en) AppleWebKit/533.19.4 (KHTML, like Gecko) AdobeAIR/51.1',
        'Accept':
            'text/xml, application/xml, application/xhtml+xml, text/html;q=0.9, '
                'text/plain;q=0.8, text/css, image/png, image/jpeg, image/gif;q=0.8, '
                'application/x-shockwave-flash, video/mp4;q=0.9, flv-application/octet-stream;q=0.8, '
                'video/x-flv;q=0.7, audio/mp4, application/futuresplash, */*;q=0.5, application/x-mpegURL',
      },
      body: payload,
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'Gagal memanggil AMF (status ${resp.statusCode})',
      );
    }

    final bytes = Uint8List.fromList(resp.bodyBytes);
    final decoded = Amf3.decodeFirstBody(bytes);
    if (decoded == null) return <String, dynamic>{};

    return _normalizeContent(decoded.data);
  }

  Map<String, dynamic> _normalizeContent(Object? content) {
    if (content == null) return <String, dynamic>{};

    if (content is Map) {
      return content.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    if (content is List) {
      final status = content.isNotEmpty ? content.first : null;
      return <String, dynamic>{'status': status};
    }

    return <String, dynamic>{'status': content};
  }
}
