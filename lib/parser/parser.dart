import '../ast/statement.dart';
import '../lexer/token.dart';
import '../ast/between_expression.dart';
import '../ast/let_statement.dart';
import '../ast/print_statement.dart';
import '../ast/binary_expression.dart';
import '../ast/empty_expression.dart';
import '../ast/equal_to_expression.dart';
import '../ast/exists_expression.dart';
import '../ast/expression.dart';
import '../ast/greater_than_expression.dart';
import '../ast/if_statement.dart';
import '../ast/less_than_expression.dart';
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
        case 'if':
          return parseIfStatement();
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

  IfStatement parseIfStatement() {
    advance(); // if

    final condition = parseConditionExpression();

    consume(TokenType.leftBrace, 'Expected "{" after if condition.');

    final thenBranch = parseBlockStatements();
    List<Statement>? elseBranch;

    if (matchKeyword('else')) {
      consume(TokenType.leftBrace, 'Expected "{" after else.');

      elseBranch = parseBlockStatements();
    }

    return IfStatement(
      condition: condition,
      thenBranch: thenBranch,
      elseBranch: elseBranch,
    );
  }

  List<Statement> parseBlockStatements() {
    final statements = <Statement>[];

    while (!isAtEnd && peek().type != TokenType.rightBrace) {
      final statement = parseStatement();

      if (statement != null) {
        statements.add(statement);
      }
    }

    consume(TokenType.rightBrace, 'Expected "}" after block.');

    return statements;
  }

  Expression parseConditionExpression() {
    final left = parsePrimary();

    if (left is! VariableExpression) {
      throw Exception('Expected variable name at the start of condition.');
    }

    if (matchKeyword('exists')) {
      return ExistsExpression(left.name);
    }

    consumeKeyword('is', 'Expected "is" in condition.');

    if (matchKeyword('greater')) {
      consumeKeyword('than', 'Expected "than" after "greater".');

      final right = parsePrimary();

      return GreaterThanExpression(left: left, right: right);
    }

    if (matchKeyword('less')) {
      consumeKeyword('than', 'Expected "than" after "less".');

      final right = parsePrimary();

      return LessThanExpression(left: left, right: right);
    }

    if (matchKeyword('equal')) {
      consumeKeyword('to', 'Expected "to" after "equal".');

      final right = parsePrimary();

      return EqualToExpression(left: left, right: right);
    }

    if (matchKeyword('between')) {
      final minimum = parsePrimary();

      consumeKeyword('and', 'Expected "and" in between condition.');

      final maximum = parsePrimary();

      return BetweenExpression(
        value: left,
        minimum: minimum,
        maximum: maximum,
      );
    }

    if (matchKeyword('empty')) {
      return EmptyExpression(left.name);
    }

    throw Exception('Expected condition after "is".');
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

  Token consume(TokenType type, String message) {
    if (peek().type == type) {
      return advance();
    }

    throw Exception(message);
  }

  void consumeKeyword(String keyword, String message) {
    if (matchKeyword(keyword)) {
      return;
    }

    throw Exception(message);
  }

  bool matchKeyword(String keyword) {
    if (peek().type == TokenType.keyword && peek().lexeme == keyword) {
      advance();
      return true;
    }

    return false;
  }

  LetStatement parseLetStatement() {
    advance(); // let

    final nameToken = advance(); // variable name
    advance(); // =

    final expression = parseExpression();

    return LetStatement(name: nameToken.lexeme, expression: expression);
  }
}
