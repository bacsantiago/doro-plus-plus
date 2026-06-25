import '../ast/statement.dart';
import '../lexer/token.dart';
import '../ast/let_statement.dart';

class Parser {
  final List<Token> tokens;

  Parser(this.tokens);

  int current = 0;

  List<Statement> parse() {
    final statements = <Statement>[];

    while (!isAtEnd) {
      final statement = parseStatement();

      if (statement != null) {
        statements.add(statement);
      }
    }

    return statements;
  }

  Statement? parseStatement() {
    final token = peek();

    if (token.type.name == 'keyword' && token.lexeme == 'let') {
      return parseLetStatement();
    }

    print('Skipping unsupported token: $token');
    advance();
    return null;
  }

  bool get isAtEnd {
    return peek().type.name == 'eof';
  }

  Token peek() {
    return tokens[current];
  }

  Token advance() {
    if (!isAtEnd) {
      current++;
    }

    return tokens[current - 1];
  }

  LetStatement parseLetStatement() {
    advance(); // let

    final nameToken = advance(); // variable name
    advance(); // =

    final valueToken = advance(); // value

    return LetStatement(name: nameToken.lexeme, value: valueToken.lexeme);
  }
}
