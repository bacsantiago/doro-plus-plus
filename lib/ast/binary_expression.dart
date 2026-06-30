import 'expression.dart';

class BinaryExpression extends Expression {
  final Expression left;
  final String operator;
  final Expression right;

  BinaryExpression({
    required this.left,
    required this.operator,
    required this.right,
  });
  @override
  String toString() {
    return 'BinaryExpression(left: $left, operator: $operator, right: $right)';
  }
}
