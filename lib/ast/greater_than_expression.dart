import 'expression.dart';

class GreaterThanExpression extends Expression {
  final Expression left;
  final Expression right;

  GreaterThanExpression({required this.left, required this.right});

  @override
  String toString() {
    return 'GreaterThanExpression(left: $left, right: $right)';
  }
}
