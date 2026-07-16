import 'package:doro_plus_plus/ast/between_expression.dart';
import 'package:doro_plus_plus/ast/binary_expression.dart';
import 'package:doro_plus_plus/ast/boolean_literal_expression.dart';
import 'package:doro_plus_plus/ast/empty_expression.dart';
import 'package:doro_plus_plus/ast/equal_to_expression.dart';
import 'package:doro_plus_plus/ast/exists_expression.dart';
import 'package:doro_plus_plus/ast/expression.dart';
import 'package:doro_plus_plus/ast/function_call_expression.dart';
import 'package:doro_plus_plus/ast/function_call_statement.dart';
import 'package:doro_plus_plus/ast/function_declaration_statement.dart';
import 'package:doro_plus_plus/ast/greater_than_expression.dart';
import 'package:doro_plus_plus/ast/if_statement.dart';
import 'package:doro_plus_plus/ast/let_statement.dart';
import 'package:doro_plus_plus/ast/less_than_expression.dart';
import 'package:doro_plus_plus/ast/literal_expression.dart';
import 'package:doro_plus_plus/ast/print_statement.dart';
import 'package:doro_plus_plus/ast/repeat_statement.dart';
import 'package:doro_plus_plus/ast/return_statement.dart';
import 'package:doro_plus_plus/ast/statement.dart';
import 'package:doro_plus_plus/ast/variable_expression.dart';
import 'package:doro_plus_plus/expressions/expression_evaluator.dart';
import 'package:doro_plus_plus/interpreter/environment.dart';
import 'package:doro_plus_plus/interpreter/return_signal.dart';

class Interpreter {
  final Environment globalEnvironment = Environment();
  final Map<String, FunctionDeclarationStatement> functions = {};
  late Environment environment = globalEnvironment;
  late final ExpressionEvaluator expressionEvaluator;
  int functionCallDepth = 0;

  Map<String, dynamic> get variables => globalEnvironment.values;

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
      environment.define(statement.name, evaluateExpression(statement.expression));
      return;
    }

    if (statement is PrintStatement) {
      final value = evaluateExpression(statement.expression);
      print(value);
      return;
    }

    if (statement is IfStatement) {
      final condition = evaluateExpression(statement.condition);

      if (condition is! bool) {
        runtimeError(
          message: 'This if condition did not become true or false.',
          hint: 'Use a condition like:\nif age is greater than 18 {',
        );
      }

      final branch = condition ? statement.thenBranch : statement.elseBranch;

      if (branch != null) {
        for (final branchStatement in branch) {
          executeStatement(branchStatement);
        }
      }

      return;
    }

    if (statement is RepeatStatement) {
      final count = evaluateExpression(statement.count);

      if (count is! num) {
        runtimeError(
          message: 'Repeat count must be a number.',
          hint: 'Example:\nrepeat 3 {\n  print "Hello"\n}',
        );
      }

      if (count < 0) {
        runtimeError(
          message: 'Repeat count cannot be negative.',
          hint: 'Use zero or a positive number, like:\nrepeat 3 {',
        );
      }

      if (count != count.round()) {
        runtimeError(
          message: 'Repeat count must be a whole number.',
          hint: 'Use a count like 0, 1, 2, or a variable containing one.',
        );
      }

      final repeatCount = count.toInt();

      for (var i = 0; i < repeatCount; i++) {
        for (final bodyStatement in statement.body) {
          executeStatement(bodyStatement);
        }
      }

      return;
    }

    if (statement is FunctionDeclarationStatement) {
      if (functions.containsKey(statement.name)) {
        runtimeError(
          message: 'The function "${statement.name}" already exists.',
          hint:
              'Use each function name once, like:\ngreet() {\n  print "Hello"\n}',
        );
      }

      functions[statement.name] = statement;
      return;
    }

    if (statement is FunctionCallStatement) {
      invokeFunction(statement.name, statement.arguments);
      return;
    }

    if (statement is ReturnStatement) {
      if (functionCallDepth == 0) {
        runtimeError(
          message: 'Return can only be used inside a function.',
          hint:
              'Put return inside a function body:\ngreet(name) {\n  return "Hello " + name\n}',
        );
      }

      final value = evaluateExpression(statement.expression);
      throw ReturnSignal(value);
    }

    runtimeError(
      message: 'I do not know how to run this statement yet.',
      hint:
          'Supported statements right now:\nlet name = "Basil"\nprint name\nif age is greater than 18 {\nrepeat 3 {\ngreet() {\nreturn name',
    );
  }

  dynamic invokeFunction(String name, List<Expression> arguments) {
    final function = functions[name];

    if (function == null) {
      runtimeError(
        message: 'The function "$name" does not exist.',
        hint:
            'Declare it before calling it:\n$name(name) {\n  return "Hello " + name\n}\n\nprint $name("Basil")',
      );
    }

    if (arguments.length != function.parameters.length) {
      runtimeError(
        message:
            'Function "$name" expects ${function.parameters.length} ${argumentWord(function.parameters.length)}, but received ${arguments.length}.',
        hint:
            'Call it with the same number of values as its parameters:\n$name(${function.parameters.join(', ')})',
      );
    }

    final argumentValues = arguments
        .map((argument) => evaluateExpression(argument))
        .toList();

    final previousEnvironment = environment;
    environment = Environment(parent: previousEnvironment);
    functionCallDepth++;

    try {
      for (var i = 0; i < function.parameters.length; i++) {
        environment.define(function.parameters[i], argumentValues[i]);
      }

      for (final bodyStatement in function.body) {
        executeStatement(bodyStatement);
      }

      return null;
    } on ReturnSignal catch (signal) {
      return signal.value;
    } finally {
      functionCallDepth--;
      environment = previousEnvironment;
    }
  }

  dynamic evaluateExpression(Expression expression) {
    if (expression is FunctionCallExpression) {
      return invokeFunction(expression.name, expression.arguments);
    }

    if (expression is LiteralExpression) {
      return expression.value;
    }

    if (expression is BooleanLiteralExpression) {
      return expression.value;
    }

    if (expression is VariableExpression) {
      if (environment.contains(expression.name)) {
        return environment.get(expression.name);
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
        if (left is bool || right is bool) {
          runtimeError(
            message: 'I cannot use booleans with "+".',
            hint:
                'Use booleans by themselves in if statements:\nif isAdmin {',
          );
        }

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

    if (expression is GreaterThanExpression) {
      final left = evaluateExpression(expression.left);
      final right = evaluateExpression(expression.right);

      return requireNumber(left, 'left side') > requireNumber(right, 'right side');
    }

    if (expression is LessThanExpression) {
      final left = evaluateExpression(expression.left);
      final right = evaluateExpression(expression.right);

      return requireNumber(left, 'left side') < requireNumber(right, 'right side');
    }

    if (expression is EqualToExpression) {
      final left = evaluateExpression(expression.left);
      final right = evaluateExpression(expression.right);

      return left == right;
    }

    if (expression is BetweenExpression) {
      final value = evaluateExpression(expression.value);
      final minimum = evaluateExpression(expression.minimum);
      final maximum = evaluateExpression(expression.maximum);

      return requireNumber(value, 'value') >=
              requireNumber(minimum, 'minimum value') &&
          requireNumber(value, 'value') <=
              requireNumber(maximum, 'maximum value');
    }

    if (expression is ExistsExpression) {
      return environment.contains(expression.name);
    }

    if (expression is EmptyExpression) {
      if (!environment.contains(expression.name)) {
        runtimeError(
          message: 'The variable "${expression.name}" does not exist.',
          hint: 'Declare it first before checking if it is empty.',
        );
      }

      final value = environment.get(expression.name);

      if (value is String) {
        return value.isEmpty;
      }

      runtimeError(
        message: 'The variable "${expression.name}" must contain text.',
        hint: 'Example:\nlet name = ""\nif name is empty {',
      );
    }

    runtimeError(
      message: 'I do not know how to read this expression yet.',
      hint:
          'Supported expressions right now: text, numbers, variables, +, function calls, and if conditions.',
    );
  }

  num requireNumber(dynamic value, String description) {
    if (value is num) {
      return value;
    }

    runtimeError(
      message: 'The $description must be a number.',
      hint:
          'Use a number or a variable containing a number, like:\nlet age = 22',
    );
  }

  String argumentWord(int count) {
    return count == 1 ? 'argument' : 'arguments';
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

    if (parts.length == 1) {
      return evaluateBooleanCondition(parts.first, line, lineNumber);
    }

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
if isAdmin {
if score is between 75 and 100 {''',
    );
  }

  bool evaluateBooleanCondition(
    String value,
    String line,
    int lineNumber,
  ) {
    final resolved = expressionEvaluator.resolveValue(value, line, lineNumber);

    if (resolved is bool) {
      return resolved;
    }

    error(
      message: 'This if condition did not become true or false.',
      lineNumber: lineNumber,
      line: line,
      hint: 'Use a boolean value or variable, like:\nif isAdmin {',
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
