import 'statement.dart';

class FunctionDeclarationStatement extends Statement {
  final String name;
  final List<String> parameters;
  final List<Statement> body;

  FunctionDeclarationStatement({
    required this.name,
    required this.parameters,
    required this.body,
  });

  @override
  String toString() {
    return 'FunctionDeclarationStatement(name: $name, parameters: $parameters, body: $body)';
  }
}
