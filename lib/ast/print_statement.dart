import 'statement.dart';

class PrintStatement extends Statement {
  final dynamic value;

  PrintStatement({required this.value});

  @override
  String toString() {
    return 'PrintStatement(value: $value)';
  }
}
