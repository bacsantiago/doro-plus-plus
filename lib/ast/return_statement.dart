import 'expression.dart';
import 'statement.dart';

class ReturnStatement extends Statement {
  final Expression expression;

  ReturnStatement({required this.expression});

  @override
  String toString() {
    return 'ReturnStatement(expression: $expression)';
  }
}
