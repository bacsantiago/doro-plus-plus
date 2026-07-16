import 'dart:async';

import 'package:doro_plus_plus/ast/boolean_literal_expression.dart';
import 'package:doro_plus_plus/ast/function_call_expression.dart';
import 'package:doro_plus_plus/ast/function_call_statement.dart';
import 'package:doro_plus_plus/ast/function_declaration_statement.dart';
import 'package:doro_plus_plus/ast/if_statement.dart';
import 'package:doro_plus_plus/ast/let_statement.dart';
import 'package:doro_plus_plus/ast/return_statement.dart';
import 'package:doro_plus_plus/interpreter/interpreter.dart';
import 'package:doro_plus_plus/lexer/lexer.dart';
import 'package:doro_plus_plus/parser/parser.dart';
import 'package:test/test.dart';

void main() {
  test('parses boolean literals', () {
    final tokens = Lexer().tokenize('let isAdmin = true');

    final statements = Parser(tokens).parse();

    final statement = statements.single as LetStatement;
    final expression = statement.expression as BooleanLiteralExpression;

    expect(statement.name, 'isAdmin');
    expect(expression.value, isTrue);
  });

  test('parses boolean variables as if conditions', () {
    final tokens = Lexer().tokenize('''
let isAdmin = true
if isAdmin {
  print "Welcome"
}
''');

    final statements = Parser(tokens).parse();

    final statement = statements[1] as IfStatement;

    expect(statement.condition.toString(), 'VariableExpression(name: isAdmin)');
  });

  test('executes if body when boolean variable is true', () {
    final output = runProgram('''
let isAdmin = true
if isAdmin {
  print "Welcome"
}
''');

    expect(output, ['Welcome']);
  });

  test('skips if body when boolean variable is false', () {
    final output = runProgram('''
let isPremium = false
if isPremium {
  print "Premium User"
}
''');

    expect(output, isEmpty);
  });

  test('reports a friendly error when if condition is not boolean', () {
    expect(
      () => runProgram('''
let age = 18
if age {
  print "Welcome"
}
'''),
      throwsException,
    );
  });

  test('parses function declarations and calls', () {
    final tokens = Lexer().tokenize('''
greet(name) {
  print "Hello " + name
}

greet("Basil")
''');

    final statements = Parser(tokens).parse();

    final declaration = statements.first as FunctionDeclarationStatement;
    final call = statements.last as FunctionCallStatement;

    expect(declaration.name, 'greet');
    expect(declaration.parameters, ['name']);
    expect(declaration.body.length, 1);
    expect(call.name, 'greet');
    expect(call.arguments.length, 1);
  });

  test('stores function declarations without running the body immediately', () {
    final output = runProgram('''
greet() {
  print "Hello"
}
''');

    expect(output, isEmpty);
  });

  test('executes a function body when the function is called', () {
    final output = runProgram('''
greet() {
  print "Hello"
}

greet()
''');

    expect(output, ['Hello']);
  });

  test('passes one function argument into the function body', () {
    final output = runProgram('''
greet(name) {
  print "Hello " + name
}

greet("Basil")
''');

    expect(output, ['Hello Basil']);
  });

  test('passes multiple function arguments by position', () {
    final output = runProgram('''
introduce(name, age) {
  print name + " is " + age
}

introduce("Basil", 22)
''');

    expect(output, ['Basil is 22']);
  });

  test('allows global variables inside function bodies', () {
    final output = runProgram('''
let greeting = "Hello"

greet(name) {
  print greeting + " " + name
}

greet("Basil")
''');

    expect(output, ['Hello Basil']);
  });

  test('keeps function parameters local to the function call', () {
    expect(
      () => runProgram('''
greet(name) {
  print name
}

greet("Basil")
print name
'''),
      throwsException,
    );
  });

  test('reports a friendly error for missing functions', () {
    expect(
      () => runProgram('missingFunction()'),
      throwsException,
    );
  });

  test('reports a friendly error for duplicate function declarations', () {
    expect(
      () => runProgram('''
greet() {
  print "Hello"
}

greet() {
  print "Hi"
}
'''),
      throwsException,
    );
  });

  test('reports a friendly parser error for missing parentheses', () {
    expect(
      () => Parser(Lexer().tokenize('greet { }')).parse(),
      throwsException,
    );
  });

  test('reports a friendly parser error for duplicate parameters', () {
    expect(
      () => Parser(Lexer().tokenize('''
greet(name, name) {
  print name
}
''')).parse(),
      throwsException,
    );
  });

  test('reports a friendly parser error for invalid parameter syntax', () {
    expect(
      () => Parser(Lexer().tokenize('''
greet("Basil") {
  print "Hello"
}
''')).parse(),
      throwsException,
    );
  });

  test('reports a friendly error for too few arguments', () {
    expect(
      () => runProgram('''
greet(name) {
  print name
}

greet()
'''),
      throwsException,
    );
  });

  test('reports a friendly error for too many arguments', () {
    expect(
      () => runProgram('''
greet(name) {
  print name
}

greet("Basil", 22)
'''),
      throwsException,
    );
  });

  test('parses return statements', () {
    final tokens = Lexer().tokenize('''
greet(name) {
  return "Hello " + name
}
''');

    final statements = Parser(tokens).parse();
    final declaration = statements.single as FunctionDeclarationStatement;
    final returnStatement = declaration.body.single as ReturnStatement;

    expect(returnStatement.expression.toString(), contains('BinaryExpression'));
  });

  test('parses function calls inside expressions', () {
    final tokens = Lexer().tokenize('let message = greet("Basil")');

    final statements = Parser(tokens).parse();
    final statement = statements.single as LetStatement;

    expect(statement.expression, isA<FunctionCallExpression>());
  });

  test('returns text from a function into a variable', () {
    final output = runProgram('''
greet(name) {
  return "Hello " + name
}

let message = greet("Basil")
print message
''');

    expect(output, ['Hello Basil']);
  });

  test('returns numbers from a function', () {
    final output = runProgram('''
add(a, b) {
  return a + b
}

let total = add(10, 20)
print total
''');

    expect(output, ['30']);
  });

  test('prints a returned value directly from a function call', () {
    final output = runProgram('''
greet(name) {
  return "Hello " + name
}

print greet("Basil")
''');

    expect(output, ['Hello Basil']);
  });

  test('return stops the rest of the function body', () {
    final output = runProgram('''
test() {
  return "Done"
  print "This should not run"
}

print test()
''');

    expect(output, ['Done']);
  });

  test('functions without return produce null', () {
    final output = runProgram('''
empty() {
  print "inside"
}

print empty()
''');

    expect(output, ['inside', 'null']);
  });

  test('reports a friendly error for return outside a function', () {
    expect(
      () => runProgram('return "Nope"'),
      throwsException,
    );
  });
}

List<String> runProgram(String source) {
  final output = <String>[];

  runZoned(
    () {
      final tokens = Lexer().tokenize(source);
      final statements = Parser(tokens).parse();

      Interpreter().interpret(statements);
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        output.add(line);
      },
    ),
  );

  return output;
}
