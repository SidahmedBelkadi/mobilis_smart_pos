import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobilis_smart_pos/src/core/security/request_canonicalizer.dart';

void main() {
  group('bodySha256', () {
    test('hashes an empty body like the backend does', () {
      expect(
        RequestCanonicalizer.bodySha256(null),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('hashes the UTF-8 bytes of a string body', () {
      expect(
        RequestCanonicalizer.bodySha256('{"a":"é"}'),
        RequestCanonicalizer.bodySha256(utf8.encode('{"a":"é"}')),
      );
    });

    test('does not hash multipart bodies', () {
      expect(RequestCanonicalizer.bodySha256(FormData()), unsignedPayload);
    });
  });

  test('normalizeBody freezes maps into the JSON Dio sends', () {
    expect(RequestCanonicalizer.normalizeBody({'token': 'abc'}), '{"token":"abc"}');
    expect(RequestCanonicalizer.normalizeBody('raw'), 'raw');
  });

  test('pathAndQuery keeps the encoded query and drops the host', () {
    final uri = Uri.parse('https://api.example.dz/api/v1/offers?name=a%20b&page=2');
    expect(RequestCanonicalizer.pathAndQuery(uri), '/api/v1/offers?name=a%20b&page=2');
    expect(RequestCanonicalizer.pathAndQuery(Uri.parse('https://h/api/login')), '/api/login');
  });

  test('canonicalRequest has the 6 lines agreed with the backend', () {
    final canonical = RequestCanonicalizer.canonicalRequest(
      method: 'post',
      uri: Uri.parse('https://h/api/login/verify-otp?lang=fr'),
      timestamp: '1759660800123',
      nonce: 'nonce-1',
      bodySha256: 'hash',
      deviceId: 'device-1',
    );
    expect(
      canonical,
      'POST\n/api/login/verify-otp?lang=fr\n1759660800123\nnonce-1\nhash\ndevice-1',
    );
  });

  test('generateNonce returns distinct UUID v4 values', () {
    final pattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    final a = RequestCanonicalizer.generateNonce();
    final b = RequestCanonicalizer.generateNonce();
    expect(a, matches(pattern));
    expect(a, isNot(b));
  });
}
