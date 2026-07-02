import 'expression.dart';

class EqualToExpression extends Expression {
  final Expression left;
  final Expression right;

  EqualToExpression({required this.left, required this.right});

  @override
  String toString() {
    return 'EqualToExpression(left: $left, right: $right)';
  }
}
