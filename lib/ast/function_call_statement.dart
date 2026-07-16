import 'expression.dart';
import 'statement.dart';

class FunctionCallStatement extends Statement {
  final String name;
  final List<Expression> arguments;

  FunctionCallStatement({required this.name, required this.arguments});

  @override
  String toString() {
    return 'FunctionCallStatement(name: $name, arguments: $arguments)';
  }
}
