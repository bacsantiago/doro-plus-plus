import 'token_type.dart';

class Token {
  final TokenType type;
  final String lexeme;
  final int line;
  final int column;

  const Token({
    required this.type,
    required this.lexeme,
    required this.line,
    required this.column,
  });

  @override
  String toString() {
    return '${type.name}($lexeme)';
  }
}
