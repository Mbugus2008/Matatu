import 'package:flutter_test/flutter_test.dart';
import 'package:t_matatu/models/TransSummary.dart';

void main() {
  group('TransSummary.distinctAgents', () {
    test('keeps the order of first appearance and dedupes', () {
      expect(TransSummary.distinctAgents(['AGNES', 'PETER', 'AGNES']),
          ['AGNES', 'PETER']);
    });

    test('trims codes and drops empty ones', () {
      expect(
          TransSummary.distinctAgents([' AGNES ', '', null, '  ']), ['AGNES']);
    });

    test('no codes gives an empty list', () {
      expect(TransSummary.distinctAgents(<String?>[]), isEmpty);
      expect(TransSummary.distinctAgents([null, '']), isEmpty);
    });
  });

  group('TransSummary', () {
    test('agents default to empty', () {
      expect(TransSummary(Type: 'SECURITY').agents, isEmpty);
    });

    test('agents are carried through the constructor', () {
      final summary = TransSummary(Type: 'SECURITY', agents: ['AGNES']);
      expect(summary.agents, ['AGNES']);
    });
  });
}
