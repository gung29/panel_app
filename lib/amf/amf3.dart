import 'dart:convert';
import 'dart:typed_data';

/// AMF3 helpers used by web and other pure-Dart targets.
class Amf3 {
  static const int undefinedType = 0;
  static const int nullType = 1;
  static const int falseType = 2;
  static const int trueType = 3;
  static const int integerType = 4;
  static const int doubleType = 5;
  static const int stringType = 6;
  static const int dateType = 8;
  static const int arrayType = 9;
  static const int objectType = 10;
  static const int byteArrayType = 12;
  static const int amf0Amf3 = 17;

  static const int _uint29Mask = 0x1FFFFFFF;
  static const int _int28MaxValue = 0x0FFFFFFF;
  static const int _int28MinValue = -0x0FFFFFFF;

  /// Decode the first body in an AMF envelope.
  static Amf3DecodedBody? decodeFirstBody(Uint8List data) {
    final reader = _Amf3Reader(data);

    reader.readUnsignedShort(); // version
    final headerCount = reader.readUnsignedShort();
    for (var i = 0; i < headerCount; i++) {
      _readHeader(reader);
    }

    final bodyCount = reader.readUnsignedShort();
    if (bodyCount == 0) return null;
    return _readBody(reader);
  }

  static void _readHeader(_Amf3Reader reader) {
    reader.readUtf(); // name
    reader.read(); // mustUnderstand
    for (var i = 0; i < 4; i++) {
      reader.read(); // length
    }
    reader.reset();
    reader.readHeaderObject();
  }

  static Amf3DecodedBody _readBody(_Amf3Reader reader) {
    final target = reader.readUtf();
    final response = reader.readUtf();
    for (var i = 0; i < 4; i++) {
      reader.read(); // length
    }
    reader.reset();
    final data = reader.readObject();
    return Amf3DecodedBody(
      targetURI: target,
      responseURI: response,
      data: data,
    );
  }
}

// ---------------------------------------------------------------------------
// Writer
// ---------------------------------------------------------------------------

class _Amf3Writer {
  final BytesBuilder _builder = BytesBuilder();

  Uint8List toBytes() => _builder.toBytes();

  void writeByte(int v) {
    _builder.addByte(v & 0xFF);
  }

  void writeShort(int v) {
    writeByte((v >> 8) & 0xFF);
    writeByte(v & 0xFF);
  }

  void writeInt(int v) {
    writeByte((v >> 24) & 0xFF);
    writeByte((v >> 16) & 0xFF);
    writeByte((v >> 8) & 0xFF);
    writeByte(v & 0xFF);
  }

  void writeUInt29(int value) {
    var v = value & Amf3._uint29Mask;
    if (v < 0x80) {
      writeByte(v);
    } else if (v < 0x4000) {
      writeByte(((v >> 7) & 0x7F) | 0x80);
      writeByte(v & 0x7F);
    } else if (v < 0x200000) {
      writeByte(((v >> 14) & 0x7F) | 0x80);
      writeByte(((v >> 7) & 0x7F) | 0x80);
      writeByte(v & 0x7F);
    } else if (v < 0x40000000) {
      writeByte(((v >> 22) & 0x7F) | 0x80);
      writeByte(((v >> 15) & 0x7F) | 0x80);
      writeByte(((v >> 8) & 0x7F) | 0x80);
      writeByte(v & 0xFF);
    } else {
      throw ArgumentError('Integer out of range: $value');
    }
  }

  void writeBytes(List<int> bytes) {
    _builder.add(bytes);
  }

  void writeUtf(String value, {required bool asAmf}) {
    final bytes = utf8.encode(value);
    if (asAmf) {
      writeUInt29((bytes.length << 1) | 1);
      writeBytes(bytes);
    } else {
      writeShort(bytes.length);
      writeBytes(bytes);
    }
  }

  void writeStringWithoutType(String value) {
    if (value.isEmpty) {
      writeUInt29(1);
    } else {
      writeUtf(value, asAmf: true);
    }
  }

  void _writeAmfInt(int v) {
    if (v >= Amf3._int28MinValue && v <= Amf3._int28MaxValue) {
      final masked = v & Amf3._uint29Mask;
      writeByte(Amf3.integerType);
      writeUInt29(masked);
    } else {
      writeByte(Amf3.doubleType);
      _writeDouble(v.toDouble());
    }
  }

  void _writeDouble(double value) {
    final bits = Float64List(1)..[0] = value;
    final byteData = bits.buffer.asByteData();
    for (int i = 7; i >= 0; i--) {
      writeByte(byteData.getUint8(i));
    }
  }

  void writeObject(Object? value) {
    if (value == null) {
      writeByte(Amf3.nullType);
    } else if (value is String) {
      writeByte(Amf3.stringType);
      writeStringWithoutType(value);
    } else if (value is bool) {
      writeByte(value ? Amf3.trueType : Amf3.falseType);
    } else if (value is int || value is num) {
      if (value is int) {
        _writeAmfInt(value);
      } else {
        final num n = value as num;
        writeByte(Amf3.doubleType);
        _writeDouble(n.toDouble());
      }
    } else if (value is DateTime) {
      writeByte(Amf3.dateType);
      writeUInt29(1);
      _writeDouble(value.millisecondsSinceEpoch.toDouble());
    } else if (value is List) {
      _writeArray(value);
    } else if (value is Map) {
      _writeMap(value);
    } else if (value is Uint8List || value is List<int>) {
      final bytes =
          value is Uint8List ? value : Uint8List.fromList(value as List<int>);
      writeByte(Amf3.byteArrayType);
      writeUInt29((bytes.length << 1) | 1);
      writeBytes(bytes);
    } else {
      final s = value.toString();
      writeByte(Amf3.stringType);
      writeStringWithoutType(s);
    }
  }

  void _writeArray(List<dynamic> list) {
    writeByte(Amf3.arrayType);
    writeUInt29((list.length << 1) | 1);
    writeUInt29(1);
    for (final item in list) {
      writeObject(item);
    }
  }

  void _writeMap(Map<dynamic, dynamic> map) {
    writeByte(Amf3.objectType);
    writeUInt29(0x0B);
    writeStringWithoutType('');
    map.forEach((k, v) {
      final key = k?.toString() ?? '';
      writeStringWithoutType(key);
      writeObject(v);
    });
    writeStringWithoutType('');
  }
}

// ---------------------------------------------------------------------------
// Reader
// ---------------------------------------------------------------------------

class _Amf3Reader {
  final Uint8List data;
  int pos = 0;

  final List<Object?> objects = [];
  final List<Map<String, Object?>> traits = [];
  final List<String> strings = [];

  _Amf3Reader(this.data);

  int read() => data[pos++] & 0xFF;

  int readUnsignedShort() {
    final c1 = read();
    final c2 = read();
    return (c1 << 8) | c2;
  }

  int readUInt29() {
    int b = read();
    if (b < 0x80) return b;
    int value = (b & 0x7F) << 7;
    b = read();
    if (b < 0x80) return value | b;
    value = (value | (b & 0x7F)) << 7;
    b = read();
    if (b < 0x80) return value | b;
    value = (value | (b & 0x7F)) << 8;
    b = read();
    return value | b;
  }

  Uint8List _readBytes(int length) {
    final bytes = data.sublist(pos, pos + length);
    pos += length;
    return Uint8List.fromList(bytes);
  }

  String readUtf([int? length]) {
    final len = length ?? readUnsignedShort();
    if (len == 0) return '';
    final bytes = _readBytes(len);
    return utf8.decode(bytes);
  }

  void reset() {
    objects.clear();
    traits.clear();
    strings.clear();
  }

  Object? readObject() {
    final type = read();
    return _readObjectValue(type);
  }

  Object? readHeaderObject() {
    var type = read();
    if (type == Amf3.amf0Amf3) {
      type = read();
      return _readObjectValue(type);
    }
    return _readHeaderObjectValue(type);
  }

  String _readString() {
    final ref = readUInt29();
    if ((ref & 1) == 0) {
      final index = ref >> 1;
      return strings[index];
    }
    final len = ref >> 1;
    if (len == 0) return '';
    final str = readUtf(len);
    strings.add(str);
    return str;
  }

  void _rememberObject(Object? v) {
    objects.add(v);
  }

  Object? _getObject(int index) => objects[index];

  Map<String, Object?> _getTraits(int index) => traits[index];

  void _rememberTraits(Map<String, Object?> t) {
    traits.add(t);
  }

  Map<String, Object?> _readTraits(int ref) {
    if ((ref & 3) == 1) {
      return _getTraits(ref >> 2);
    }
    final count = ref >> 4;
    final className = _readString();
    final externalizable = (ref & 4) == 4;
    final dynamic = (ref & 8) == 8;
    final props = <String>[];
    for (var i = 0; i < count; i++) {
      props.add(_readString());
    }
    final traitsMap = <String, Object?>{
      'className': className.isEmpty ? null : className,
      'externalizable': externalizable,
      'dynamic': dynamic,
      'props': props,
    };
    _rememberTraits(traitsMap);
    return traitsMap;
  }

  Object? _readScriptObject() {
    final ref = readUInt29();
    if ((ref & 1) == 0) {
      return _getObject(ref >> 1);
    }

    final traitsMap = _readTraits(ref);
    final externalizable = traitsMap['externalizable'] == true;
    final dynamic = traitsMap['dynamic'] == true;
    final props = (traitsMap['props'] as List).cast<String>();

    final map = <String, Object?>{};
    _rememberObject(map);

    if (externalizable) {
      return map;
    }

    for (final prop in props) {
      final value = readObject();
      map[prop] = value;
    }

    if (dynamic) {
      while (true) {
        final name = _readString();
        if (name.isEmpty) break;
        map[name] = readObject();
      }
    }

    return map;
  }

  Object? _readArray() {
    final ref = readUInt29();
    if ((ref & 1) == 0) {
      return _getObject(ref >> 1);
    }
    final len = ref >> 1;

    Map<String, Object?>? map;
    while (true) {
      final name = _readString();
      if (name.isEmpty) break;
      map ??= <String, Object?>{};
      _rememberObject(map);
      map[name] = readObject();
    }

    if (map == null) {
      final list = List<Object?>.filled(len, null, growable: false);
      _rememberObject(list);
      for (var i = 0; i < len; i++) {
        list[i] = readObject();
      }
      return list;
    } else {
      for (var i = 0; i < len; i++) {
        map[i.toString()] = readObject();
      }
      return map;
    }
  }

  double _readDouble() {
    final b0 = read();
    final b1 = read();
    final b2 = read();
    final b3 = read();
    final b4 = read();
    final b5 = read();
    final b6 = read();
    final b7 = read();
    final bytes = Uint8List.fromList([b7, b6, b5, b4, b3, b2, b1, b0]);
    final bd = ByteData.view(bytes.buffer);
    return bd.getFloat64(0, Endian.big);
  }

  Object? _readDate() {
    final ref = readUInt29();
    if ((ref & 1) == 0) {
      return _getObject(ref >> 1);
    }
    final time = _readDouble().toInt();
    final date = DateTime.fromMillisecondsSinceEpoch(time, isUtc: true);
    _rememberObject(date);
    return date;
  }

  Map<String, Object?> _readMap() {
    final ref = readUInt29();
    if ((ref & 1) == 0) {
      return _getObject(ref >> 1) as Map<String, Object?>;
    }
    final length = ref >> 1;
    final map = <String, Object?>{};
    if (length > 0) {
      _rememberObject(map);
      while (true) {
        final name = readObject();
        if (name is! String) break;
        map[name] = readObject();
      }
    }
    return map;
  }

  Uint8List _readByteArray() {
    final ref = readUInt29();
    if ((ref & 1) == 0) {
      return _getObject(ref >> 1) as Uint8List;
    }
    final len = ref >> 1;
    final bytes = _readBytes(len);
    _rememberObject(bytes);
    return bytes;
  }

  Object? _readHeaderObjectValue(int type) {
    switch (type) {
      case 2:
        return readUtf();
      default:
        throw StateError('Unknown AMF0 header type: $type');
    }
  }

  Object? _readObjectValue(int type) {
    switch (type) {
      case Amf3.stringType:
        return _readString();
      case Amf3.objectType:
        return _readScriptObject();
      case Amf3.arrayType:
        return _readArray();
      case Amf3.falseType:
        return false;
      case Amf3.trueType:
        return true;
      case Amf3.integerType:
        final temp = readUInt29();
        return (temp << 3) >> 3;
      case Amf3.doubleType:
        return _readDouble();
      case Amf3.undefinedType:
      case Amf3.nullType:
        return null;
      case Amf3.dateType:
        return _readDate();
      case Amf3.byteArrayType:
        return _readByteArray();
      case Amf3.amf0Amf3:
        return readObject();
      default:
        throw StateError('Unknown AMF3 type: $type');
    }
  }
}

// ---------------------------------------------------------------------------
// ActionMessage and serializer
// ---------------------------------------------------------------------------

class Amf3MessageBody {
  final String targetURI;
  final String responseURI;
  final Object? data;

  const Amf3MessageBody({
    required this.targetURI,
    required this.responseURI,
    required this.data,
  });
}

class Amf3ActionMessage {
  final int version;
  final List<Amf3MessageBody> bodies;

  const Amf3ActionMessage({
    this.version = 3,
    required this.bodies,
  });
}

class Amf3Serializer {
  Uint8List writeMessage(Amf3ActionMessage message) {
    final writer = _Amf3Writer();
    writer.writeShort(message.version);
    writer.writeShort(0); // header count
    writer.writeShort(message.bodies.length);

    for (final body in message.bodies) {
      _writeBody(writer, body);
    }

    return writer.toBytes();
  }

  void _writeBody(_Amf3Writer writer, Amf3MessageBody body) {
    writer.writeUtf(body.targetURI, asAmf: false);
    writer.writeUtf(body.responseURI, asAmf: false);

    final bodyWriter = _Amf3Writer();
    bodyWriter.writeByte(Amf3.amf0Amf3);
    bodyWriter.writeObject(body.data);

    final bodyBytes = bodyWriter.toBytes();
    writer.writeInt(bodyBytes.length);
    writer.writeBytes(bodyBytes);
  }
}

class Amf3DecodedBody {
  final String targetURI;
  final String responseURI;
  final Object? data;

  const Amf3DecodedBody({
    required this.targetURI,
    required this.responseURI,
    required this.data,
  });
}
