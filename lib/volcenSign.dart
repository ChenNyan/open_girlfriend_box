import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:convert/convert.dart';
import 'package:intl/intl.dart';
import 'package:pointycastle/export.dart';

// 配置常量
const String accessKeyID = '';
const String secretAccessKey = '';
const String region = 'cn-beijing';
const String service = 'rtc';
const String host = 'rtc.volcengineapi.com';
const String url = 'https://rtc.volcengineapi.com';
const String requestURI = '/';

String getUtcDate() {
  final now = DateTime.now().toUtc();
  final formattedDate = now.toIso8601String().replaceAll(':', '').replaceAll('-', '').replaceAll('.', '');
  return formattedDate.replaceAll('T', '').replaceAll('Z', '');
}

// HMAC-SHA256 计算
Uint8List hmacSHA256(Uint8List hmacKey, String data) {
  final hmac = HMac(SHA256Digest(), 64) // HMAC SHA-256: block must be 64 bytes
    ..init(KeyParameter(hmacKey));
  
  return hmac.process(utf8.encode(data));
}

// 计算签名密钥
List<int> getSigningKey(String secretKey, String date, String region, String service) {
  final kDate = hmacSHA256(utf8.encode(secretKey), date);
  final kRegion = hmacSHA256(kDate, region);
  final kService = hmacSHA256(kRegion, service);
  return hmacSHA256(kService, 'request');
}

// 计算 Hash 值
String calculateHash(String payload) {
  final bytes = utf8.encode(payload);
  final digest = sha256.convert(bytes);
  return hex.encode(digest.bytes);
}

// 构建 Canonical Request
String buildCanonicalRequest(String method, String canonicalURI, String canonicalQueryString, Map<String, String> headers, String payloadHash) {
  final signedHeaders = ['host', 'x-content-sha256', 'x-date'];
  final canonicalHeaders = signedHeaders.map((header) => '$header:${headers[header]}').join('\n') + '\n';
  final signedHeadersList = signedHeaders.join(';');

  return '$method\n$canonicalURI\n$canonicalQueryString\n$canonicalHeaders\n$signedHeadersList\n$payloadHash';
}

// 构建 StringToSign
String buildStringToSign(String date, String canonicalRequest, String credentialScope) {
  final hashedCanonicalRequest = calculateHash(canonicalRequest);
  return 'HMAC-SHA256\n$date\n$credentialScope\n$hashedCanonicalRequest';
}

// 构建 Authorization Header
String buildAuthorizationHeader(String credentialScope, String signedHeaders, String signature) {
  return 'HMAC-SHA256 Credential=$accessKeyID/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';
}

Future<void> sendRequest(String action, String version, String body) async {
  final now = DateTime.now().toUtc();
  final date = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(now);
  final authDate = date.substring(0, 8); // 取前8位作为 authDate
  final credentialScope = '$authDate/$region/$service/request';


  final payloadHash = calculateHash(body);
  final canonicalQueryString = 'Action=$action&Version=$version';
  final canonicalRequest = buildCanonicalRequest('POST', requestURI, canonicalQueryString, {
    'host': host,
    'x-content-sha256': payloadHash,
    'x-date': date
  }, payloadHash);

  final stringToSign = buildStringToSign(date, canonicalRequest, credentialScope);

  // 计算签名
  final signingKey = getSigningKey(secretAccessKey, authDate, region, service);
  final signature = hex.encode(hmacSHA256(Uint8List.fromList(signingKey), stringToSign));

  final authorizationHeader = buildAuthorizationHeader(credentialScope, 'host;x-content-sha256;x-date', signature);

  // 发送 HTTP 请求
  Dio dio = Dio();
  try {
    final response = await dio.post(
      url + '?' + canonicalQueryString,
      data: body,
      options: Options(
        headers: {
          'Authorization': authorizationHeader,
          'Content-Type': 'application/json',
          'X-Date': date,
          'X-Content-Sha256': payloadHash,
          'Host': host,
        },
      ),
    );

    print('Response: ${response.data}');
  } catch (e) {
    print('Request failed: $e');
  }
}