import 'expression.dart';

class LessThanExpression extends Expression {
  final Expression left;
  final Expression right;

  LessThanExpression({required this.left, required this.right});

  @override
  String toString() {
    return 'LessThanExpression(left: $left, right: $right)';
  }
}
