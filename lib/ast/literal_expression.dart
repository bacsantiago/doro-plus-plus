import 'expression.dart';

class LiteralExpression extends Expression {
  final dynamic value;

  LiteralExpression(this.value);

  @override
  String toString() {
    return 'LiteralExpression(value: $value)';
  }
}
