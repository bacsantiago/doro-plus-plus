import 'expression.dart';
import 'statement.dart';

class PrintStatement extends Statement {
  final Expression expression;

  PrintStatement({required this.expression});

  @override
  String toString() {
    return 'PrintStatement(expression: $expression)';
  }
}
