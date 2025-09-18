import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/models/Transaction.dart' as tMatatu;

class TransactionListItem extends StatelessWidget {
  final tMatatu.Trans transaction;
  final VoidCallback onDelete;

  const TransactionListItem({
    Key? key,
    required this.transaction,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListTile(
        key: ValueKey(transaction.Document_No),
        leading: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
        title: Text(
          transaction.Type == "SAVINGSCREW" 
              ? '${transaction.Description}(${transaction.Account_No})'
              : '${transaction.Description}',
          style: const TextStyle(fontSize: 14),
        ),
        trailing: Text(
          NumberFormat("#,##0.00").format(transaction.Amount),
          style: TextStyle(
            color: (transaction.Amount ?? 0) >= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
