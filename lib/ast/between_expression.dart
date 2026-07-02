import 'expression.dart';

class BetweenExpression extends Expression {
  final Expression value;
  final Expression minimum;
  final Expression maximum;

  BetweenExpression({
    required this.value,
    required this.minimum,
    required this.maximum,
  });

  @override
  String toString() {
    return 'BetweenExpression(value: $value, minimum: $minimum, maximum: $maximum)';
  }
}
