import 'expression.dart';

class ExistsExpression extends Expression {
  final String name;

  ExistsExpression(this.name);

  @override
  String toString() {
    return 'ExistsExpression(name: $name)';
  }
}
