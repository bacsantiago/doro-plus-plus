import '../ast/statement.dart';
import '../lexer/token.dart';
import '../ast/let_statement.dart';
import '../ast/print_statement.dart';
import '../ast/binary_expression.dart';
import '../ast/expression.dart';
import '../ast/literal_expression.dart';
import '../ast/variable_expression.dart';
import '../lexer/token_type.dart';

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
    if (isAtEnd) return null;

    final token = peek();

    if (token.type == TokenType.keyword) {
      switch (token.lexeme) {
        case 'print':
          return parsePrintStatement();
        case 'let':
          return parseLetStatement();
      }
    }

    throw Exception('Expected statement but found $token');
  }

  Expression parseExpression() {
    var expression = parsePrimary();

    while (peek().type == TokenType.plus) {
      final operator = advance();

      final right = parsePrimary();

      expression = BinaryExpression(
        left: expression,
        operator: operator.lexeme,
        right: right,
      );
    }

    return expression;
  }

  Expression parsePrimary() {
    final token = advance();

    if (token.type == TokenType.string) {
      return LiteralExpression(token.lexeme);
    }

    if (token.type == TokenType.number) {
      return LiteralExpression(int.parse(token.lexeme));
    }

    if (token.type == TokenType.identifier) {
      return VariableExpression(token.lexeme);
    }

    throw Exception('Expected expression but found $token');
  }

  PrintStatement parsePrintStatement() {
    advance(); // print

    final expression = parseExpression();

    return PrintStatement(expression: expression);
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

    final expression = parseExpression();

    return LetStatement(name: nameToken.lexeme, expression: expression);
  }
}
