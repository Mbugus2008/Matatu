// ignore_for_file: public_member_api_docs, sort_constructors_first
class TransSummary {
  String? Type;
  double? Amount;
  double? Expected;
  double? balance;
  TransSummary({
    this.Type,
    this.Amount,
    this.Expected,
    this.balance,
  });

 @override
  String toString() {
    return '$Type $Amount $Expected $balance';
  }


}
