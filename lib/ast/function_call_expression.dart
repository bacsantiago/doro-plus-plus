import 'expression.dart';

class FunctionCallExpression extends Expression {
  final String name;
  final List<Expression> arguments;

  FunctionCallExpression({required this.name, required this.arguments});

  @override
  String toString() {
    return 'FunctionCallExpression(name: $name, arguments: $arguments)';
  }
}
