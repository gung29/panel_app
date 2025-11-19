import 'dart:async';

import 'package:flutter/services.dart';
import 'package:panel_app/services/ninja_sage_client.dart';

/// NinjaSageClient implementation that delegates AMF encoding/decoding
/// to the Android native layer via a MethodChannel.
class AndroidAmfNinjaSageClient implements NinjaSageClient {
  static const MethodChannel _channel =
      MethodChannel('com.example.panel_app/amf');

  const AndroidAmfNinjaSageClient();

  @override
  Future<Map<String, dynamic>> invoke(
    String target, {
    List<dynamic>? body,
  }) async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('invokeAmf', {
      'target': target,
      'body': body ?? const <dynamic>[],
    });

    if (result == null) {
      throw Exception('Null result from Android AMF bridge');
    }

    return result.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
}

