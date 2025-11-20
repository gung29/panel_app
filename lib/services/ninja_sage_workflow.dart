import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:panel_app/services/dart_analytics_payload.dart';
import 'package:panel_app/services/dart_login_payload.dart';
import 'package:panel_app/services/web_amf_ninja_sage_client.dart';

/// High level helpers to orchestrate the Ninja Sage AMF workflow.
///
/// - Android: via MethodChannel to native Kotlin implementation.
/// - Desktop (Windows/macOS/Linux): via pure Dart AMF + HTTP.
/// - Web: login disabled at UI level.
class NinjaSageWorkflow {
  static const MethodChannel _channel =
      MethodChannel('com.example.panel_app/amf');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static int? _desktopCharacterSeed;
  static String? _desktopCharacterKey;
  static int? _desktopUid;
  static String? _desktopSessionKey;

  static bool get hasDesktopSession =>
      _desktopUid != null && _desktopSessionKey != null;

  static int? get desktopUid => _desktopUid;
  static String? get desktopSessionKey => _desktopSessionKey;

  /// Run the initial workflow steps:
  /// - SystemLogin.checkVersion
  /// - Analytics.libraries
  /// - EventsService.get
  static Future<void> bootstrap() async {
    if (_isAndroid) {
      await _channel.invokeMethod('bootstrapNinjaSage');
      return;
    }
    if (!_isDesktop) {
      return;
    }

    final client = WebAmfNinjaSageClient();

    // 1. SystemLogin.checkVersion
    final versionMap = await client.invoke(
      'SystemLogin.checkVersion',
      body: [
        ['Public 0.52'],
      ],
    );

    final seedAny = versionMap['_'] ?? versionMap['character_seed'];
    final keyAny = versionMap['__'] ?? versionMap['character_key'];
    _desktopCharacterSeed = (seedAny is num) ? seedAny.toInt() : null;
    _desktopCharacterKey = keyAny?.toString();

    // 2. Analytics.libraries
    final analyticsPayload =
        await DartAnalyticsPayload.buildAnalyticsPayload();
    await client.invoke(
      'Analytics.libraries',
      body: [
        [analyticsPayload],
      ],
    );

    // 3. EventsService.get
    await client.invoke(
      'EventsService.get',
      body: [null],
    );
  }

  /// Run SystemLogin.loginUser and SystemLogin.getAllCharacters
  /// using the character_seed and character_key obtained during
  /// [bootstrap].
  static Future<Map<String, dynamic>?> loginUser(
    String username,
    String password,
  ) async {
    if (_isAndroid) {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('loginUser', {
        'username': username,
        'password': password,
      });
      if (result == null) return null;
      return result.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    if (_isDesktop) {
      return _desktopLoginUser(username, password);
    }

    // Web or other platforms: login flow dinonaktifkan di UI.
    return {
      'login': {'status': 0},
      'characters': null,
    };
  }

  static Future<Map<String, dynamic>?> _desktopLoginUser(
    String username,
    String password,
  ) async {
    final seed = _desktopCharacterSeed;
    final key = _desktopCharacterKey;
    if (seed == null || key == null || key.isEmpty) {
      throw StateError(
        'character_seed/character_key belum diinisialisasi. Panggil bootstrap() terlebih dahulu.',
      );
    }

    final components = await DartLoginPayload.buildLoginComponents(
      username: username,
      password: password,
      characterSeed: seed,
      characterKey: key,
    );

    final params = [
      components['username'] as String,
      components['encrypted_password'] as String,
      (components['character_seed'] as num).toDouble(),
      (components['bytes_loaded'] as num).toInt(),
      (components['bytes_total'] as num).toInt(),
      components['character_key'] as String,
      components['specific_item'] as String,
      components['random_seed'] as String,
      (components['password_length'] as num).toInt(),
    ];

    final client = WebAmfNinjaSageClient();
    final loginMap = await client.invoke(
      'SystemLogin.loginUser',
      body: [params],
    );

    final status = (loginMap['status'] as num?)?.toInt() ?? 0;
    if (status != 1) {
      return {
        'login': loginMap,
        'characters': null,
      };
    }

    final uidVal = (loginMap['uid'] as num?)?.toInt();
    final sessionVal = loginMap['sessionkey']?.toString();
    _desktopUid = uidVal;
    _desktopSessionKey = sessionVal;

    if (uidVal == null || sessionVal == null || sessionVal.isEmpty) {
      throw StateError(
        'Tidak menemukan uid/sessionkey dari loginUser (desktop).',
      );
    }

    final charsBody = [
      [uidVal, sessionVal],
    ];
    final charsMap = await client.invoke(
      'SystemLogin.getAllCharacters',
      body: charsBody,
    );

    return {
      'login': loginMap,
      'characters': charsMap,
    };
  }

  /// Fetch full character data for the selected character after
  /// getAllCharacters has run. Returns the raw response map.
  static Future<Map<String, dynamic>?> getCharacterData(
    int charId,
  ) async {
    if (_isAndroid) {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getCharacterData',
        {'charId': charId},
      );
      if (result == null) return null;
      return result.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    if (_isDesktop) {
      final session = _desktopSessionKey;
      if (session == null || session.isEmpty) {
        throw StateError(
          'Session belum tersedia di desktop. Pastikan loginUser sudah berhasil.',
        );
      }
      final client = WebAmfNinjaSageClient();
      final data = await client.invoke(
        'SystemLogin.getCharacterData',
        body: [
          [charId, session],
        ],
      );
      return data;
    }

    return null;
  }
}
