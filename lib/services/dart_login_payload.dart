import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;

/// LoaderInfo equivalent used for login payload computation.
class LoaderInfo {
  final int bytesLoaded;
  final int bytesTotal;

  const LoaderInfo({
    this.bytesLoaded = 8216461,
    this.bytesTotal = 8216461,
  });
}

/// Port of contoh/ninja_sage/login_payload.py to Dart.
class DartLoginPayload {
  static const String defaultLibraryUrl =
      'https://ns-assets.ninjasage.id/static/lib/library.bin';

  static Map<String, int>? _cachedLevels;

  static Uint8List _makeIv(String seed) {
    final iv = latin1.encode(seed);
    const blockSize = 16;
    final padLen = blockSize - (iv.length % blockSize);
    final padded = Uint8List(iv.length + padLen);
    for (var i = 0; i < iv.length; i++) {
      padded[i] = iv[i];
    }
    for (var i = iv.length; i < padded.length; i++) {
      padded[i] = padLen;
    }
    return Uint8List.fromList(padded.sublist(0, blockSize));
  }

  static String _encryptPassword(
    String plaintext,
    String key,
    int seed,
  ) {
    final aesKey = enc.Key(Uint8List.fromList(latin1.encode(key)));
    final ivBytes = _makeIv(seed.toString());
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(
      enc.AES(
        aesKey,
        mode: enc.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return base64Encode(encrypted.bytes);
  }

  static Future<Map<String, int>> _loadLibraryLevels({
    String libraryUrl = defaultLibraryUrl,
  }) async {
    if (_cachedLevels != null) {
      return _cachedLevels!;
    }
    final resp = await http.get(Uri.parse(libraryUrl));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'Gagal memuat library.bin (status ${resp.statusCode})',
      );
    }
    final compressed = resp.bodyBytes;
    final decoded = ZLibDecoder().decodeBytes(compressed);
    final text = utf8.decode(decoded);
    final items = jsonDecode(text) as List<dynamic>;
    final levels = <String, int>{};
    for (final entry in items) {
      if (entry is Map<String, dynamic>) {
        final id = entry['id'] as String?;
        if (id == null) continue;
        final level = entry['level'];
        levels[id] = level is num ? level.toInt() : 0;
      }
    }
    _cachedLevels = levels;
    return levels;
  }

  static String _cucsgHash(String value) {
    final payload = Uint8List(value.length);
    for (var i = 0; i < value.length; i++) {
      payload[i] = value.codeUnitAt(i) & 0xFF;
    }
    final digest = sha256.convert(payload);
    return digest.toString();
  }

  static int _safeMod(int a, int b) {
    if (b == 0) return 0;
    return a % b;
  }

  static String _getSpecificItem(
    LoaderInfo loader,
    int characterSeed,
    Map<String, int> levels,
  ) {
    final bytesTotal = loader.bytesTotal;
    final bytesLoaded = loader.bytesLoaded;
    final lvlHair1 = levels['hair_10000_1'] ?? 0;
    final lvlHair0 = levels['hair_10000_0'] ?? 0;
    final lvlAcc2003 = levels['accessory_2003'] ?? 0;

    final loc4Num =
        (bytesTotal ^ bytesLoaded) +
            1337 ^
            characterSeed ^
            1337 +
            1337 ^
            characterSeed ^
            1337 +
            1337 ^
            0x0539 &
            _safeMod(
              _safeMod(bytesLoaded, lvlHair1),
              bytesLoaded,
            ) &
            bytesTotal ^
            _safeMod(
              _safeMod(lvlHair0, characterSeed),
              1333777,
            ) +
            lvlAcc2003;

    final loc4Str = loc4Num.toString();
    final hashed = _cucsgHash(loc4Str);
    final seedStr = characterSeed.toString();
    return seedStr + hashed + seedStr * 4;
  }

  static String _getRandomNSeed(
    int characterSeed,
    LoaderInfo loader,
  ) {
    final seedRng = characterSeed % loader.bytesLoaded;
    final rng = _PMPrng(seedRng);
    final buffer = StringBuffer();
    for (var i = 0; i < 4; i++) {
      buffer.write(rng.nextInt());
    }
    return buffer.toString();
  }

  /// Build login components for SystemLogin.loginUser from username/password.
  static Future<Map<String, Object>> buildLoginComponents({
    required String username,
    required String password,
    required int characterSeed,
    required String characterKey,
    LoaderInfo loader = const LoaderInfo(),
    String libraryUrl = defaultLibraryUrl,
  }) async {
    final levels = await _loadLibraryLevels(libraryUrl: libraryUrl);
    final encryptedPassword =
        _encryptPassword(password, characterKey, characterSeed);
    final specificItem = _getSpecificItem(loader, characterSeed, levels);
    final randomSeed = _getRandomNSeed(characterSeed, loader);

    return <String, Object>{
      'username': username,
      'encrypted_password': encryptedPassword,
      'character_seed': characterSeed,
      'bytes_loaded': loader.bytesLoaded,
      'bytes_total': loader.bytesTotal,
      'character_key': characterKey,
      'specific_item': specificItem,
      'random_seed': randomSeed,
      'password_length': password.length,
    };
  }
}

class _PMPrng {
  static const int _mod = 2147483647;
  static const int _mul = 16807;

  int _seed;

  _PMPrng(int seed)
      : _seed = seed == 0
            ? (((DateTime.now().millisecondsSinceEpoch ^
                        (DateTime.now().microsecondsSinceEpoch &
                            0x7FFFFFFF)) &
                    0x7FFFFFFF))
            : seed & 0x7FFFFFFF;

  int nextInt() {
    _seed = ((_seed * _mul) % _mod);
    return _seed;
  }
}

