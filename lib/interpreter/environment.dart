class Environment {
  final Environment? parent;
  final Map<String, dynamic> values = {};

  Environment({this.parent});

  void define(String name, dynamic value) {
    values[name] = value;
  }

  bool contains(String name) {
    if (values.containsKey(name)) {
      return true;
    }

    return parent?.contains(name) ?? false;
  }

  dynamic get(String name) {
    if (values.containsKey(name)) {
      return values[name];
    }

    if (parent != null) {
      return parent!.get(name);
    }

    throw Exception('Undefined variable "$name".');
  }
}
