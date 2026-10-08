// ignore_for_file: public_member_api_docs, sort_constructors_first
class TransSummary {
  String? Type;
  double? Amount;
  double? Expected;
  double? balance;

  /// Distinct agent codes that captured this type's transactions today, in
  /// order of first appearance. One entry per agent.
  final List<String> agents;

  TransSummary({
    this.Type,
    this.Amount,
    this.Expected,
    this.balance,
    this.agents = const [],
  });

  /// Distinct, non-empty agent codes in the order they appear.
  static List<String> distinctAgents(Iterable<String?> codes) {
    final seen = <String>{};
    for (final code in codes) {
      final trimmed = (code ?? '').trim();
      if (trimmed.isNotEmpty) seen.add(trimmed);
    }
    return seen.toList();
  }

  @override
  String toString() {
    return '$Type $Amount $Expected $balance';
  }
}
