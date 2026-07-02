import 'package:doro_plus_plus/ast/binary_expression.dart';
import 'package:doro_plus_plus/ast/expression.dart';
import 'package:doro_plus_plus/ast/let_statement.dart';
import 'package:doro_plus_plus/ast/literal_expression.dart';
import 'package:doro_plus_plus/ast/print_statement.dart';
import 'package:doro_plus_plus/ast/statement.dart';
import 'package:doro_plus_plus/ast/variable_expression.dart';
import 'package:doro_plus_plus/expressions/expression_evaluator.dart';

class Interpreter {
  final Map<String, dynamic> variables = {};
  late final ExpressionEvaluator expressionEvaluator;

  Interpreter() {
    expressionEvaluator = ExpressionEvaluator(
      variables: variables,
      error: error,
    );
  }

  void interpret(List<Statement> statements) {
    for (final statement in statements) {
      executeStatement(statement);
    }
  }

  void executeStatement(Statement statement) {
    if (statement is LetStatement) {
      variables[statement.name] = evaluateExpression(statement.expression);
      return;
    }

    if (statement is PrintStatement) {
      final value = evaluateExpression(statement.expression);
      print(value);
      return;
    }

    runtimeError(
      message: 'I do not know how to run this statement yet.',
      hint: 'Supported statements right now:\nlet name = "Basil"\nprint name',
    );
  }

  dynamic evaluateExpression(Expression expression) {
    if (expression is LiteralExpression) {
      return expression.value;
    }

    if (expression is VariableExpression) {
      if (variables.containsKey(expression.name)) {
        return variables[expression.name];
      }

      runtimeError(
        message: 'The variable "${expression.name}" does not exist.',
        hint: 'Declare it first with:\nlet ${expression.name} = "some value"',
      );
    }

    if (expression is BinaryExpression) {
      final left = evaluateExpression(expression.left);
      final right = evaluateExpression(expression.right);

      if (expression.operator == '+') {
        if (left is num && right is num) {
          return left + right;
        }

        if (left is String || right is String) {
          return '$left$right';
        }
      }

      runtimeError(
        message: 'I do not know how to use "${expression.operator}" here yet.',
        hint:
            'Supported binary operator right now:\n"Hello " + name\n10 + 20',
      );
    }

    runtimeError(
      message: 'I do not know how to read this expression yet.',
      hint: 'Supported expressions right now: text, numbers, variables, and +.',
    );
  }

  void run(String source) {
    final lines = source.split('\n');
    executeLines(lines, 0, lines.length);
  }

  void executeLines(List<String> lines, int start, int end) {
    var i = start;

    while (i < end) {
      final lineNumber = i + 1;
      final line = lines[i].trim();

      if (line.isEmpty) {
        i++;
        continue;
      }

      if (line.startsWith('if ')) {
        i = executeIf(lines, i);
        continue;
      }

      executeLine(line, lineNumber);
      i++;
    }
  }

  int executeIf(List<String> lines, int ifLineIndex) {
    final lineNumber = ifLineIndex + 1;
    final line = lines[ifLineIndex].trim();

    if (!line.endsWith('{')) {
      error(
        message: 'If statements must open a block using "{".',
        lineNumber: lineNumber,
        line: line,
        hint: 'Example:\nif age is greater than 18 {',
      );
    }

    final condition = line.substring(3, line.length - 1).trim();
    final isConditionTrue = evaluateCondition(condition, line, lineNumber);

    final ifClosingBraceIndex = findClosingBrace(lines, ifLineIndex);

    final elseLineIndex = ifClosingBraceIndex + 1;
    final hasElseBlock =
        elseLineIndex < lines.length && lines[elseLineIndex].trim() == 'else {';

    if (isConditionTrue) {
      executeLines(lines, ifLineIndex + 1, ifClosingBraceIndex);
    } else if (hasElseBlock) {
      final elseClosingBraceIndex = findClosingBrace(lines, elseLineIndex);
      executeLines(lines, elseLineIndex + 1, elseClosingBraceIndex);
      return elseClosingBraceIndex + 1;
    }

    if (hasElseBlock) {
      final elseClosingBraceIndex = findClosingBrace(lines, elseLineIndex);
      return elseClosingBraceIndex + 1;
    }

    return ifClosingBraceIndex + 1;
  }

  int findClosingBrace(List<String> lines, int startIndex) {
    for (var i = startIndex + 1; i < lines.length; i++) {
      if (lines[i].trim() == '}') {
        return i;
      }
    }

    final lineNumber = startIndex + 1;
    final line = lines[startIndex].trim();

    error(
      message: 'This if block was opened but never closed.',
      lineNumber: lineNumber,
      line: line,
      hint: 'Add a closing brace:\n}',
    );
  }

  bool evaluateCondition(String condition, String line, int lineNumber) {
    final parts = condition.split(' ');

    if (isGreaterThanCondition(parts)) {
      return evaluateGreaterThan(parts, line, lineNumber);
    }

    if (isLessThanCondition(parts)) {
      return evaluateLessThan(parts, line, lineNumber);
    }

    if (isEqualToCondition(parts)) {
      return evaluateEqualTo(parts, line, lineNumber);
    }

    if (isBetweenCondition(parts)) {
      return evaluateBetween(parts, line, lineNumber);
    }

    if (isExistsCondition(parts)) {
      return evaluateExists(parts, line, lineNumber);
    }

    if (isEmptyCondition(parts)) {
      return evaluateEmpty(parts, line, lineNumber);
    }

    error(
      message: 'I do not understand this condition yet.',
      lineNumber: lineNumber,
      line: line,
      hint: '''
Supported conditions right now:
if age is greater than 18 {
if age is less than 18 {
if age is equal to 18 {
if user exists {
if name is empty {
if score is between 75 and 100 {''',
    );
  }

  bool isGreaterThanCondition(List<String> parts) {
    return parts.length == 5 &&
        parts[1] == 'is' &&
        parts[2] == 'greater' &&
        parts[3] == 'than';
  }

  bool isLessThanCondition(List<String> parts) {
    return parts.length == 5 &&
        parts[1] == 'is' &&
        parts[2] == 'less' &&
        parts[3] == 'than';
  }

  bool isEqualToCondition(List<String> parts) {
    return parts.length == 5 &&
        parts[1] == 'is' &&
        parts[2] == 'equal' &&
        parts[3] == 'to';
  }

  bool isBetweenCondition(List<String> parts) {
    return parts.length == 6 &&
        parts[1] == 'is' &&
        parts[2] == 'between' &&
        parts[4] == 'and';
  }

  bool isExistsCondition(List<String> parts) {
    return parts.length == 2 && parts[1] == 'exists';
  }

  bool isEmptyCondition(List<String> parts) {
    return parts.length == 3 && parts[1] == 'is' && parts[2] == 'empty';
  }

  int resolveRequiredNumber(String value, String line, int lineNumber) {
    if (variables[value] is int) {
      return variables[value] as int;
    }

    final parsed = int.tryParse(value);

    if (parsed != null) {
      return parsed;
    }

    error(
      message: '"$value" must be a number.',
      lineNumber: lineNumber,
      line: line,
      hint: 'Use a number or a variable containing a number.',
    );
  }

  bool evaluateGreaterThan(List<String> parts, String line, int lineNumber) {
    final left = resolveRequiredNumber(parts[0], line, lineNumber);
    final right = resolveRequiredNumber(parts[4], line, lineNumber);

    return left > right;
  }

  bool evaluateLessThan(List<String> parts, String line, int lineNumber) {
    final left = resolveRequiredNumber(parts[0], line, lineNumber);
    final right = resolveRequiredNumber(parts[4], line, lineNumber);

    return left < right;
  }

  bool evaluateEqualTo(List<String> parts, String line, int lineNumber) {
    final left = resolveRequiredNumber(parts[0], line, lineNumber);
    final right = resolveRequiredNumber(parts[4], line, lineNumber);

    return left == right;
  }

  bool evaluateBetween(List<String> parts, String line, int lineNumber) {
    final value = resolveRequiredNumber(parts[0], line, lineNumber);
    final min = resolveRequiredNumber(parts[3], line, lineNumber);
    final max = resolveRequiredNumber(parts[5], line, lineNumber);

    return value >= min && value <= max;
  }

  bool evaluateExists(List<String> parts, String line, int lineNumber) {
    final variableName = parts[0];
    return variables.containsKey(variableName);
  }

  bool evaluateEmpty(List<String> parts, String line, int lineNumber) {
    final variableName = parts[0];

    if (!variables.containsKey(variableName)) {
      error(
        message: 'The variable "$variableName" does not exist.',
        lineNumber: lineNumber,
        line: line,
        hint: 'Declare it first before checking if it is empty.',
      );
    }

    final value = variables[variableName];

    if (value is String) {
      return value.isEmpty;
    }

    error(
      message: '"$variableName" must contain text.',
      lineNumber: lineNumber,
      line: line,
      hint: '''
Example:

let name = ""

if name is empty {
}''',
    );
  }

  void executeLine(String line, int lineNumber) {
    if (line.startsWith('let ')) {
      executeVariableDeclaration(line, lineNumber);
      return;
    }

    if (line.startsWith('print ')) {
      executePrint(line, lineNumber);
      return;
    }

    error(
      message: 'I do not understand this line yet.',
      lineNumber: lineNumber,
      line: line,
      hint: 'Supported right now:\nprint "Hello Doro++"\nlet age = 22',
    );
  }

  void executeVariableDeclaration(String line, int lineNumber) {
    final declaration = line.substring(4).trim();

    if (!declaration.contains('=')) {
      error(
        message: 'Variable declarations require "=".',
        lineNumber: lineNumber,
        line: line,
        hint: 'Example:\nlet name = "Basil"',
      );
    }

    final parts = declaration.split('=');

    if (parts.length != 2) {
      error(
        message: 'Invalid variable declaration.',
        lineNumber: lineNumber,
        line: line,
        hint: 'Example:\nlet age = 22',
      );
    }

    final variableName = parts[0].trim();
    final value = parts[1].trim();

    variables[variableName] = expressionEvaluator.evaluate(
      value,
      line,
      lineNumber,
    );
  }

  dynamic evaluateValue(String value, String line, int lineNumber) {
    if (value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }

    if (value.contains('+')) {
      return evaluateAddition(value, line, lineNumber);
    }

    if (int.tryParse(value) != null) {
      return int.parse(value);
    }

    error(
      message: 'I do not understand this value yet.',
      lineNumber: lineNumber,
      line: line,
      hint:
          'Supported values right now:\nlet name = "Basil"\nlet age = 22\nlet total = age + 1',
    );
  }

  int evaluateAddition(String value, String line, int lineNumber) {
    final parts = value.split('+');

    if (parts.length != 2) {
      error(
        message: 'Only simple addition is supported right now.',
        lineNumber: lineNumber,
        line: line,
        hint: 'Example:\nlet total = 10 + 20',
      );
    }

    final left = parts[0].trim();
    final right = parts[1].trim();

    final leftValue = resolveNumber(left);
    final rightValue = resolveNumber(right);

    if (leftValue == null || rightValue == null) {
      error(
        message: 'Addition currently supports numbers only.',
        lineNumber: lineNumber,
        line: line,
        hint: 'Example:\nlet total = 10 + 20\nlet nextAge = age + 1',
      );
    }

    return leftValue + rightValue;
  }

  int? resolveNumber(String value) {
    if (variables[value] is int) {
      return variables[value] as int;
    }

    if (int.tryParse(value) != null) {
      return int.parse(value);
    }

    return null;
  }

  void executePrint(String line, int lineNumber) {
    final value = line.substring(6).trim();

    final result = expressionEvaluator.evaluate(value, line, lineNumber);
    print(result);
  }

  dynamic evaluatePrintableExpression(
    String value,
    String line,
    int lineNumber,
  ) {
    if (value.contains('+')) {
      final parts = value.split('+');
      final buffer = StringBuffer();

      for (final part in parts) {
        final resolved = resolvePrintableValue(part.trim(), line, lineNumber);

        buffer.write(resolved);
      }

      return buffer.toString();
    }

    return resolvePrintableValue(value, line, lineNumber);
  }

  dynamic resolvePrintableValue(String value, String line, int lineNumber) {
    if (variables.containsKey(value)) {
      return variables[value];
    }

    if (value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }

    if (int.tryParse(value) != null) {
      return int.parse(value);
    }

    error(
      message: 'I do not understand this print value.',
      lineNumber: lineNumber,
      line: line,
      hint: '''
Examples:
print "Hello Doro++"
print name
print "Hello " + name''',
    );
  }

  Never error({
    required String message,
    required int lineNumber,
    required String line,
    String? hint,
  }) {
    print('Doro++ Error');
    print('');
    print(message);
    print('');
    print('Line $lineNumber:');
    print(line);

    if (hint != null) {
      print('');
      print(hint);
    }

    throw Exception('Doro++ stopped because of an error.');
  }

  Never runtimeError({required String message, String? hint}) {
    print('Doro++ Error');
    print('');
    print(message);

    if (hint != null) {
      print('');
      print(hint);
    }

    throw Exception('Doro++ stopped because of an error.');
  }
}
