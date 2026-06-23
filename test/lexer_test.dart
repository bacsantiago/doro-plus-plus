import 'package:doro_plus_plus/lexer/lexer.dart';
import 'package:test/test.dart';

void main() {
  test('tokenizes variable declaration', () {
    final lexer = Lexer();

    final tokens = lexer.tokenize('let age = 22');

    expect(tokens.map((token) => token.toString()).toList(), [
      'keyword(let)',
      'identifier(age)',
      'equals(=)',
      'number(22)',
      'eof()',
    ]);
  });

  test('tokenizes print with concatenation', () {
    final lexer = Lexer();

    final tokens = lexer.tokenize('print "Hello " + name');

    expect(tokens.map((token) => token.toString()).toList(), [
      'keyword(print)',
      'string(Hello )',
      'plus(+)',
      'identifier(name)',
      'eof()',
    ]);
  });

  test('tokenizes if condition block', () {
    final lexer = Lexer();

    final tokens = lexer.tokenize('if age is greater than 18 { }');

    expect(tokens.map((token) => token.toString()).toList(), [
      'keyword(if)',
      'identifier(age)',
      'keyword(is)',
      'keyword(greater)',
      'keyword(than)',
      'number(18)',
      'leftBrace({)',
      'rightBrace(})',
      'eof()',
    ]);
  });
}
