import 'dart:collection';

class Document extends MapMixin<String, dynamic> {
  static const setTypeAssign = 'assign';
  static const setTypePrepend = 'prepend';
  static const setTypeAppend = 'append';

  /**
   * Construct.
   *
   * Construct a new fields object
   *
   * @param Map<String, dynamic> input
   * @throws Exception
   * @see MapMixin::__construct
   *
   */
  Document([Map<String, dynamic> input = const {}]) {
    if (input.containsKey('\$permissions') && input['\$permissions'] is! List) {
      throw Exception('\$permissions must be of type List');
    }

    for (var key in input.keys) {
      var value = input[key];
      if (value is! Map) {
        continue;
      }
      if ((value.containsKey('\$id') || value.containsKey('\$collection'))) {
        input[key] = Document({key: value});
        continue;
      }
      for (var childKey in value.keys) {
        var child = value[childKey];
        if ((child.containsKey('\$id') || child.containsKey('\$collection')) &&
            child is! Document) {
          value[childKey] = Document(child);
        }
      }
    }

    innerMap = input;
  }
  dynamic getAttribute(String name, [dynamic defaultValue]) {
    if (containsKey(name)) {
      return this[name];
    }
    return defaultValue;
  }

  Document setAttribute(String key, dynamic value) {
    this[key] = value;
    return this;
  }

  Map<String, dynamic> getAttributes() {
    Map<String, dynamic> attributes = {};
    List<String> excludedAttributes = [
      '\$id',
      '\$internalId',
      '\$collection',
      '\$permissions',
      '\$createdAt',
      '\$updatedAt'
    ];
    innerMap.forEach((key, value) {
      if (excludedAttributes.contains(key)) {
        return;
      }
      attributes[key] = value;
    });

    return attributes;
  }

  String? get id => innerMap['\$id'];
  String? get internalId => innerMap['\$internalId']?.toString();
  DateTime? get createdAt => getAttribute('\$createdAt');
  DateTime? get updatedAt => getAttribute('\$updatedAt');
  List<String> get permissions =>
      List<String>.from(getAttribute('\$permissions', []));

  List<String> getPermissionsByType(String type) {
    List<String> typePermissions = [];
    for (String permission in permissions) {
      if (!permission.startsWith(type)) {
        continue;
      }
      typePermissions
          .add(permission.replaceAll(RegExp('$type\\(|\\)|"| '), ''));
    }
    return typePermissions.toSet().toList();
  }

  Map<String, dynamic> getArrayCopy(
      {List<String> allow = const [], List<String> disallow = const []}) {
    Map<String, dynamic> output = {};

    innerMap.forEach((key, value) {
      if (allow.isNotEmpty && !allow.contains(key)) {
        // Export only allow fields
        return;
      }

      if (disallow.isNotEmpty && disallow.contains(key)) {
        // Don't export disallowed fields
        return;
      }

      if (value is Document) {
        output[key] = value.getArrayCopy(allow: allow, disallow: disallow);
      } else if (value is List) {
        List<dynamic> children = [];

        for (var child in value) {
          if (child is Document) {
            children.add(child.getArrayCopy(allow: allow, disallow: disallow));
          } else {
            children.add(child);
          }
        }

        if (children.isEmpty) {
          output[key] = value;
        } else {
          output[key] = children;
        }
      } else {
        output[key] = value;
      }
    });

    return output;
  }

  Map<String, dynamic> innerMap = {};

  @override
  dynamic operator [](Object? key) => innerMap[key];

  @override
  void operator []=(String key, dynamic value) {
    innerMap[key] = value;
  }

  @override
  void clear() => innerMap.clear();

  @override
  Iterable<String> get keys => innerMap.keys;

  @override
  dynamic remove(Object? key) => innerMap.remove(key);
}
