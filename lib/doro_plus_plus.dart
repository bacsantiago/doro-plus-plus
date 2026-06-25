import 'dart:io';

import 'package:doro_plus_plus/lexer/lexer.dart';
import 'package:doro_plus_plus/parser/parser.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('Doro++ Error');
    print('Please provide a .doro file.');
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

  final lexer = Lexer();
  final tokens = lexer.tokenize(source);

  final parser = Parser(tokens);
  parser.parse();
}
