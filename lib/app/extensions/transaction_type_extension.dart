import 'package:flutter/material.dart';
import 'package:app_finanzas/app/model/transaction.dart';

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.I:
        return 'Ingreso';
      case TransactionType.E:
        return 'Gasto';
      case TransactionType.A:
        return 'Ahorro';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.I:
        return Icons.trending_up;
      case TransactionType.E:
        return Icons.trending_down;
      case TransactionType.A:
        return Icons.savings;
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.I:
        return Colors.green;
      case TransactionType.E:
        return Colors.red;
      case TransactionType.A:
        return Colors.blue;
    }
  }
}
