import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:t_matatu/network/request.dart';

void main() {
  group('Request model — serialization', () {
    test('toJson includes non-null fields', () {
      final req = Request(
        body: 'test',
        bookmark: 'abc123',
        size: 50,
      );

      final json = jsonDecode(req.toJson()) as Map<String, dynamic>;

      expect(json['body'], 'test');
      expect(json['bookmark'], 'abc123');
      expect(json['size'], 50);
    });

    test('toJson includes null fields as null in JSON', () {
      final req = Request(body: null, bookmark: null);

      final json = jsonDecode(req.toJson()) as Map<String, dynamic>;

      // json.encode preserves null values in the map
      expect(json['body'], null);
      expect(json['bookmark'], null);
    });

    test('toJson with date formats correctly', () {
      final date = DateTime(2026, 7, 21);
      final req = Request(date: date);

      final json = jsonDecode(req.toJson()) as Map<String, dynamic>;

      expect(json['date'], isNotNull);
    });

    test('fromJson roundtrip preserves bookmark and size', () {
      final original = Request(bookmark: 'xyz', size: 100);
      final restored = Request.fromJson(original.toJson());

      expect(restored.bookmark, 'xyz');
      expect(restored.size, 100);
    });

    test('Request with vehicle and Agent fields', () {
      final req = Request(vehicle: 'KAR 492Y', Agent: 'PAUL');

      final json = jsonDecode(req.toJson()) as Map<String, dynamic>;

      expect(json['vehicle'], 'KAR 492Y');
      expect(json['Agent'], 'PAUL');
    });

    test('size defaults to 0', () {
      final req = Request();

      expect(req.size, 0);
    });

    test('bookmark is null by default', () {
      final req = Request();

      expect(req.bookmark, null);
    });
  });

  group('RequestHeader model', () {
    test('toJson serializes correctly', () {
      final header = RequestHeader(userid: 'testuser', password: 'pass');
      final json = jsonDecode(header.toJson()) as Map<String, dynamic>;

      expect(json['userid'], 'testuser');
      expect(json['password'], 'pass');
    });

    test('fromJson deserializes correctly', () {
      final header = RequestHeader.fromJson('{"userid":"u","password":"p"}');

      expect(header.userid, 'u');
      expect(header.password, 'p');
    });
  });
}
