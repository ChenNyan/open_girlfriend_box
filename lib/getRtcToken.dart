import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:pointycastle/export.dart';

// Constants
const String VERSION = "001";
const int VERSION_LENGTH = 3;
const int APP_ID_LENGTH = 24;

// Privileges enum
class Privileges {
  static const PrivPublishStream = 0;
  static const privPublishAudioStream = 1;
  static const privPublishVideoStream = 2;
  static const privPublishDataStream = 3;
  static const PrivSubscribeStream = 4;
}

// Helper function to create HMAC-SHA256 signature
List<int> encodeHMac(String key, List<int> message) {

  final hmac = HMac(SHA256Digest(),64 ) // HMAC SHA-256: block must be 64 bytes
    ..init(KeyParameter(utf8.encode(key)));

  return hmac.process(Uint8List.fromList(message));

}

// ByteBuffer class for packing data into binary format


class ByteBuf {
  // 使用 ByteData 来处理字节
  ByteData _buffer;
  int _position = 0;

  // 默认构造函数，分配 1024 字节的缓冲区
  ByteBuf() : _buffer = ByteData(1024);

  // 使用字节数组初始化缓冲区
  ByteBuf.fromBytes(List<int> bytes) : _buffer = ByteData.sublistView(Uint8List.fromList(bytes));

  // 获取当前缓冲区的字节数据
  List<int> asBytes() {
    // 返回从起始位置到当前缓冲区位置的所有字节
    return _buffer.buffer.asUint8List(0, _position);
  }

  // put short (16-bit unsigned integer)
  ByteBuf putShort(int value) {
    _buffer.setInt16(_position, value, Endian.little);
    _position += 2;
    return this;
  }

  // put byte array
  ByteBuf putBytes(List<int> bytes) {
    putShort(bytes.length);
    for (int byte in bytes) {
      _buffer.setUint8(_position, byte);
      _position++;
    }
    return this;
  }

  // put int (32-bit unsigned integer)
  ByteBuf putInt(int value) {
    _buffer.setInt32(_position, value, Endian.little);
    _position += 4;
    return this;
  }

  // put long (64-bit unsigned integer)
  ByteBuf putLong(int value) {
    _buffer.setInt64(_position, value, Endian.little);
    _position += 8;
    return this;
  }

  // put String as bytes
  ByteBuf putString(String value) {
    return putBytes(utf8.encode(value));
  }

  // put TreeMap<Short, String> as key-value pairs
  ByteBuf putMap(Map<int, String> extra) {
    putShort(extra.length);
    extra.forEach((key, value) {
      putShort(key);
      putString(value);
    });
    return this;
  }

  // put TreeMap<Short, Integer> as key-value pairs
  ByteBuf putIntMap(Map<int, int> extra) {
    putShort(extra.length);
    extra.forEach((key, value) {
      putShort(key);
      putInt(value);
    });
    return this;
  }

  // read short (16-bit)
  int readShort() {
    int value = _buffer.getInt16(_position, Endian.little);
    _position += 2;
    return value;
  }

  // read int (32-bit)
  int readInt() {
    int value = _buffer.getInt32(_position, Endian.little);
    _position += 4;
    return value;
  }

  // read byte array
  List<int> readBytes() {
    int length = readShort();
    List<int> bytes = List<int>.filled(length, 0);
    for (int i = 0; i < length; i++) {
      bytes[i] = _buffer.getUint8(_position);
      _position++;
    }
    return bytes;
  }

  // read String
  String readString() {
    List<int> bytes = readBytes();
    return utf8.decode(bytes);
  }

  // read TreeMap<Short, String>
  Map<int, String> readMap() {
    Map<int, String> map = {};
    int length = readShort();
    for (int i = 0; i < length; i++) {
      int key = readShort();
      String value = readString();
      map[key] = value;
    }
    return map;
  }

  // read TreeMap<Short, Integer>
  Map<int, int> readIntMap() {
    Map<int, int> map = {};
    int length = readShort();
    for (int i = 0; i < length; i++) {
      int key = readShort();
      int value = readInt();
      map[key] = value;
    }
    return map;
  }
}


// AccessToken class
class AccessToken {
  String appID;
  String appKey;
  String roomID;
  String userID;
  late int issuedAt; // Use late for initialization later
  late int nonce; // Use late for initialization later
  int expireAt = 0;
  Map<int, int> privileges = {};

  AccessToken(this.appID, this.appKey, this.roomID, this.userID) {
    issuedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;  // Initialize issuedAt
    nonce = Random().nextInt(0xFFFFFFFF);  // Initialize nonce
  }

  // Add privileges to the token
  void addPrivilege(int privilege, int expireTimestamp) {
    privileges[privilege] = expireTimestamp;

    if (privilege == Privileges.PrivPublishStream) {
      privileges[Privileges.privPublishAudioStream] = expireTimestamp;
      privileges[Privileges.privPublishVideoStream] = expireTimestamp;
      privileges[Privileges.privPublishDataStream] = expireTimestamp;
    }
  }

  // Set token expiration time
  void expireTime(int expireTimestamp) {
    expireAt = expireTimestamp;
  }

  // Pack the token data into binary format
  List<int> packMsg() {
    final buf = ByteBuf();
    buf.putInt(nonce);
    buf.putInt(issuedAt);
    buf.putInt(expireAt);
    buf.putString(roomID);
    buf.putString(userID);
    buf.putIntMap(privileges);
    return buf.asBytes();
  }

  // Serialize the token into a string
  String serialize() {
    final bytesM = packMsg();
    final signature = encodeHMac(appKey, bytesM);
    final content = ByteBuf()
      ..putBytes(bytesM)
      ..putBytes(signature);
    return VERSION + appID + base64Encode(content.asBytes());
  }

  // Method to handle the verification of the token
  bool verify(String key) {
    if (expireAt > 0 && DateTime.now().millisecondsSinceEpoch ~/ 1000 > expireAt) {
      return false;
    }
    appKey = key;
    final signature = encodeHMac(appKey, packMsg());
    return base64Encode(signature) == base64Encode(encodeHMac(appKey, packMsg()));
  }
}

// Function to parse the token from raw string
AccessToken? parse(String raw) {
  if (raw.length <= VERSION_LENGTH + APP_ID_LENGTH) return null;
  if (raw.substring(0, VERSION_LENGTH) != VERSION) return null;

  final token = AccessToken("", "", "", "");
  token.appID = raw.substring(VERSION_LENGTH, VERSION_LENGTH + APP_ID_LENGTH);
  final contentBuf = base64Decode(raw.substring(VERSION_LENGTH + APP_ID_LENGTH));

  // Read the content and extract token details
  int position = 0;
  token.nonce = ByteData.sublistView(Uint8List.fromList(contentBuf), position, position + 4).getUint32(0, Endian.little);
  position += 4;
  token.issuedAt = ByteData.sublistView(Uint8List.fromList(contentBuf), position, position + 4).getUint32(0, Endian.little);
  position += 4;
  token.expireAt = ByteData.sublistView(Uint8List.fromList(contentBuf), position, position + 4).getUint32(0, Endian.little);
  position += 4;

  // You can implement further parsing logic here

  return token;
}
