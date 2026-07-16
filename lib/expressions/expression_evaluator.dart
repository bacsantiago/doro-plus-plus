class ExpressionEvaluator {
  final Map<String, dynamic> variables;
  final Never Function({
    required String message,
    required int lineNumber,
    required String line,
    String? hint,
  })
  error;

  ExpressionEvaluator({required this.variables, required this.error});

  dynamic evaluate(String value, String line, int lineNumber) {
    if (value.contains('+')) {
      return evaluateAdditionOrConcatenation(value, line, lineNumber);
    }

    return resolveValue(value, line, lineNumber);
  }

  dynamic evaluateAdditionOrConcatenation(
    String value,
    String line,
    int lineNumber,
  ) {
    final parts = value.split('+');
    final resolvedParts = parts
        .map((part) => resolveValue(part.trim(), line, lineNumber))
        .toList();

    final hasText = resolvedParts.any((value) => value is String);

    if (hasText) {
      return resolvedParts.map((value) => value.toString()).join();
    }

    final allNumbers = resolvedParts.every((value) => value is int);

    if (allNumbers) {
      return resolvedParts.fold<int>(0, (total, value) => total + value as int);
    }

    error(
      message: 'This expression mixes values I cannot combine yet.',
      lineNumber: lineNumber,
      line: line,
      hint: '''
Examples:
let total = 10 + 20
print "Hello " + name''',
    );
  }

  dynamic resolveValue(String value, String line, int lineNumber) {
    if (variables.containsKey(value)) {
      return variables[value];
    }

    if (value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }

    if (value == 'true') {
      return true;
    }

    if (value == 'false') {
      return false;
    }

    final number = int.tryParse(value);

    if (number != null) {
      return number;
    }

    error(
      message: 'I do not understand this value.',
      lineNumber: lineNumber,
      line: line,
      hint: '''
Examples:
"Basil"
22
name''',
    );
  }

  int resolveRequiredNumber(String value, String line, int lineNumber) {
    final resolved = resolveValue(value, line, lineNumber);

    if (resolved is int) {
      return resolved;
    }

    error(
      message: '"$value" must be a number.',
      lineNumber: lineNumber,
      line: line,
      hint: 'Use a number or a variable containing a number.',
    );
  }
}
