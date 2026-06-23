import 'token.dart';
import 'token_type.dart';

class Lexer {
  static const keywords = {
    'let',
    'print',
    'if',
    'else',
    'is',
    'greater',
    'less',
    'than',
    'equal',
    'to',
    'between',
    'and',
    'exists',
    'empty',
  };

  List<Token> tokenize(String source) {
    final tokens = <Token>[];

    var i = 0;

    while (i < source.length) {
      final char = source[i];

      if (char.trim().isEmpty) {
        i++;
        continue;
      }

      if (char == '=') {
        tokens.add(const Token(type: TokenType.equals, lexeme: '='));
        i++;
        continue;
      }

      if (char == '+') {
        tokens.add(const Token(type: TokenType.plus, lexeme: '+'));
        i++;
        continue;
      }

      if (char == '{') {
        tokens.add(const Token(type: TokenType.leftBrace, lexeme: '{'));
        i++;
        continue;
      }

      if (char == '}') {
        tokens.add(const Token(type: TokenType.rightBrace, lexeme: '}'));
        i++;
        continue;
      }

      // strings
      if (char == '"') {
        final start = i + 1;

        i++;

        while (i < source.length && source[i] != '"') {
          i++;
        }

        final value = source.substring(start, i);

        tokens.add(Token(type: TokenType.string, lexeme: value));

        i++;
        continue;
      }

      // numbers
      if (RegExp(r'\d').hasMatch(char)) {
        final start = i;

        while (i < source.length && RegExp(r'\d').hasMatch(source[i])) {
          i++;
        }

        tokens.add(
          Token(type: TokenType.number, lexeme: source.substring(start, i)),
        );

        continue;
      }

      // identifiers & keywords
      if (RegExp(r'[a-zA-Z_]').hasMatch(char)) {
        final start = i;

        while (i < source.length &&
            RegExp(r'[a-zA-Z0-9_]').hasMatch(source[i])) {
          i++;
        }

        final value = source.substring(start, i);

        if (keywords.contains(value)) {
          tokens.add(Token(type: TokenType.keyword, lexeme: value));
        } else {
          tokens.add(Token(type: TokenType.identifier, lexeme: value));
        }

        continue;
      }

      throw Exception('Unknown character: $char');
    }

    tokens.add(const Token(type: TokenType.eof, lexeme: ''));

    return tokens;
  }
}
