import 'expression.dart';
import 'statement.dart';

class IfStatement extends Statement {
  final Expression condition;
  final List<Statement> thenBranch;
  final List<Statement>? elseBranch;

  IfStatement({
    required this.condition,
    required this.thenBranch,
    this.elseBranch,
  });

  List<Statement> get body => thenBranch;

  @override
  String toString() {
    return 'IfStatement(condition: $condition, thenBranch: $thenBranch, elseBranch: $elseBranch)';
  }
}
