import '../ast/statement.dart';
import '../lexer/token.dart';
import '../ast/between_expression.dart';
import '../ast/boolean_literal_expression.dart';
import '../ast/let_statement.dart';
import '../ast/print_statement.dart';
import '../ast/binary_expression.dart';
import '../ast/empty_expression.dart';
import '../ast/equal_to_expression.dart';
import '../ast/exists_expression.dart';
import '../ast/expression.dart';
import '../ast/function_call_expression.dart';
import '../ast/function_call_statement.dart';
import '../ast/function_declaration_statement.dart';
import '../ast/greater_than_expression.dart';
import '../ast/if_statement.dart';
import '../ast/less_than_expression.dart';
import '../ast/literal_expression.dart';
import '../ast/return_statement.dart';
import '../ast/variable_expression.dart';
import '../ast/repeat_statement.dart';
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
        case 'repeat':
          return parseRepeatStatement();
        case 'return':
          return parseReturnStatement();
      }
    }

    if (token.type == TokenType.identifier) {
      return parseFunctionStatement();
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

    if (token.type == TokenType.keyword && token.lexeme == 'true') {
      return BooleanLiteralExpression(true);
    }

    if (token.type == TokenType.keyword && token.lexeme == 'false') {
      return BooleanLiteralExpression(false);
    }

    if (token.type == TokenType.identifier) {
      if (match(TokenType.leftParen)) {
        final arguments = parseFunctionParenItems(token.lexeme);

        return FunctionCallExpression(name: token.lexeme, arguments: arguments);
      }

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

  RepeatStatement parseRepeatStatement() {
    advance(); // repeat

    final count = parseExpression();

    consume(TokenType.leftBrace, 'Expected "{" after repeat count.');

    final body = parseBlockStatements();

    return RepeatStatement(count: count, body: body);
  }

  ReturnStatement parseReturnStatement() {
    advance(); // return

    final expression = parseExpression();

    return ReturnStatement(expression: expression);
  }

  Statement parseFunctionStatement() {
    final nameToken = advance();

    consume(
      TokenType.leftParen,
      'Expected "(" after function name "${nameToken.lexeme}".',
    );

    final items = parseFunctionParenItems(nameToken.lexeme);

    if (match(TokenType.leftBrace)) {
      final parameters = parseFunctionParameters(nameToken.lexeme, items);
      final body = parseBlockStatements();

      return FunctionDeclarationStatement(
        name: nameToken.lexeme,
        parameters: parameters,
        body: body,
      );
    }

    return FunctionCallStatement(name: nameToken.lexeme, arguments: items);
  }

  List<Expression> parseFunctionParenItems(String functionName) {
    final items = <Expression>[];

    if (match(TokenType.rightParen)) {
      return items;
    }

    do {
      items.add(parseExpression());
    } while (match(TokenType.comma));

    consume(
      TokenType.rightParen,
      'Expected ")" after function "$functionName" parameters or arguments.',
    );

    return items;
  }

  List<String> parseFunctionParameters(
    String functionName,
    List<Expression> items,
  ) {
    final parameters = <String>[];

    for (final item in items) {
      if (item is! VariableExpression) {
        throw Exception(
          'Function "$functionName" parameters must be simple names.',
        );
      }

      if (parameters.contains(item.name)) {
        throw Exception(
          'Function "$functionName" has duplicate parameter "${item.name}".',
        );
      }

      parameters.add(item.name);
    }

    return parameters;
  }

  Expression parseConditionExpression() {
    final left = parsePrimary();

    if (peek().type == TokenType.leftBrace) {
      return left;
    }

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

  bool match(TokenType type) {
    if (peek().type == type) {
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
