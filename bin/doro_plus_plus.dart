import 'dart:io';

import 'package:doro_plus_plus/interpreter/interpreter.dart';
import 'package:doro_plus_plus/lexer/lexer.dart';
import 'package:doro_plus_plus/lexer/token.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('Doro++ Error');
    print('Please provide a .doro file.');
    print('');
    print('Example: dart run bin/doro_plus_plus.dart examples/hello.doro');
    return;
  }

  final filePath = arguments.first;
  final file = File(filePath);

  if (!file.existsSync()) {
    print('Doro++ Error');
    print('File not found: $filePath');
    return;
  }

  final source = file.readAsStringSync();

  final interpreter = Interpreter();
  interpreter.run(source);

  final lexer = Lexer();
  final tokens = lexer.tokenize(source);

  for (final token in tokens) {
    print(token);
  }
  return;
}
