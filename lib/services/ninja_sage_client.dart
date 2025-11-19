import 'dart:async';

/// Abstraction over the Ninja Sage backend that returns
/// already-decoded response payloads for a given AMF target.
abstract class NinjaSageClient {
  Future<Map<String, dynamic>> invoke(
    String target, {
    List<dynamic>? body,
  });
}

