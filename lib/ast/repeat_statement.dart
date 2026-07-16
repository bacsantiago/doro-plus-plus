import 'expression.dart';
import 'statement.dart';

class RepeatStatement extends Statement {
  final Expression count;
  final List<Statement> body;

  RepeatStatement({required this.count, required this.body});

  @override
  String toString() {
    return 'RepeatStatement(count: $count, body: $body)';
  }
}
