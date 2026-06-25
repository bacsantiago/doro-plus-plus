import 'statement.dart';

class LetStatement extends Statement {
  final String name;
  final dynamic value;

  LetStatement({required this.name, required this.value});

  @override
  String toString() {
    return 'LetStatement(name: $name, value: $value)';
  }
}
