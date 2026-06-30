import 'expression.dart';
import 'statement.dart';

class LetStatement extends Statement {
  final String name;
  final Expression expression;

  LetStatement({required this.name, required this.expression});

  @override
  String toString() {
    return 'LetStatement(name: $name, expression: $expression)';
  }
}
