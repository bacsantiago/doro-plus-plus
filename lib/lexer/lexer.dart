import 'token.dart';
import 'token_type.dart';

class Lexer {
  static const keywords = {
    'let',
    'print',
    'if',
    'else',
    'repeat',
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
    'true',
    'false',
    'return',
  };

  List<Token> tokenize(String source) {
    final tokens = <Token>[];

    var i = 0;
    var line = 1;
    var column = 1;

    while (i < source.length) {
      final char = source[i];

      if (char == '\n') {
        line++;
        column = 1;
        i++;
        continue;
      }

      if (char.trim().isEmpty) {
        column++;
        i++;
        continue;
      }

      if (char == '=') {
        tokens.add(
          Token(
            type: TokenType.equals,
            lexeme: '=',
            line: line,
            column: column,
          ),
        );
        i++;
        column++;
        continue;
      }

      if (char == '+') {
        tokens.add(
          Token(type: TokenType.plus, lexeme: '+', line: line, column: column),
        );
        i++;
        column++;
        continue;
      }

      if (char == ',') {
        tokens.add(
          Token(type: TokenType.comma, lexeme: ',', line: line, column: column),
        );
        i++;
        column++;
        continue;
      }

      if (char == '{') {
        tokens.add(
          Token(
            type: TokenType.leftBrace,
            lexeme: '{',
            line: line,
            column: column,
          ),
        );
        i++;
        column++;
        continue;
      }

      if (char == '}') {
        tokens.add(
          Token(
            type: TokenType.rightBrace,
            lexeme: '}',
            line: line,
            column: column,
          ),
        );
        i++;
        column++;
        continue;
      }

      if (char == '(') {
        tokens.add(
          Token(
            type: TokenType.leftParen,
            lexeme: '(',
            line: line,
            column: column,
          ),
        );
        i++;
        column++;
        continue;
      }

      if (char == ')') {
        tokens.add(
          Token(
            type: TokenType.rightParen,
            lexeme: ')',
            line: line,
            column: column,
          ),
        );
        i++;
        column++;
        continue;
      }

      if (char == '"') {
        final tokenColumn = column;
        final start = i + 1;

        i++;
        column++;

        while (i < source.length && source[i] != '"') {
          i++;
          column++;
        }

        final value = source.substring(start, i);

        tokens.add(
          Token(
            type: TokenType.string,
            lexeme: value,
            line: line,
            column: tokenColumn,
          ),
        );

        i++;
        column++;
        continue;
      }

      if (RegExp(r'\d').hasMatch(char)) {
        final tokenColumn = column;
        final start = i;

        while (i < source.length && RegExp(r'\d').hasMatch(source[i])) {
          i++;
          column++;
        }

        tokens.add(
          Token(
            type: TokenType.number,
            lexeme: source.substring(start, i),
            line: line,
            column: tokenColumn,
          ),
        );

        continue;
      }

      if (RegExp(r'[a-zA-Z_]').hasMatch(char)) {
        final tokenColumn = column;
        final start = i;

        while (i < source.length &&
            RegExp(r'[a-zA-Z0-9_]').hasMatch(source[i])) {
          i++;
          column++;
        }

        final value = source.substring(start, i);

        tokens.add(
          Token(
            type: keywords.contains(value)
                ? TokenType.keyword
                : TokenType.identifier,
            lexeme: value,
            line: line,
            column: tokenColumn,
          ),
        );

        continue;
      }

      throw Exception(
        'Unknown character "$char" at line $line, column $column',
      );
    }

    tokens.add(
      Token(type: TokenType.eof, lexeme: '', line: line, column: column),
    );

    return tokens;
  }
}
