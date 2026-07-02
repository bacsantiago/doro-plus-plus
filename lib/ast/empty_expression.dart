import 'expression.dart';

class EmptyExpression extends Expression {
  final String name;

  EmptyExpression(this.name);

  @override
  String toString() {
    return 'EmptyExpression(name: $name)';
  }
}
