import 'token_type.dart';

class Token {
  final TokenType type;
  final String lexeme;

  const Token({required this.type, required this.lexeme});

  @override
  String toString() {
    return '${type.name}($lexeme)';
  }
}
