import 'expression.dart';

class VariableExpression extends Expression {
  final String name;

  VariableExpression(this.name);

  @override
  String toString() {
    return 'VariableExpression(name: $name)';
  }
}
