import 'expression.dart';

class BooleanLiteralExpression extends Expression {
  final bool value;

  BooleanLiteralExpression(this.value);

  @override
  String toString() {
    return 'BooleanLiteralExpression(value: $value)';
  }
}
