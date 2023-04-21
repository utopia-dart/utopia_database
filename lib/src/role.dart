class Role {
  final String role;
  final String identifier;
  final String dimension;

  Role(this.role, {this.identifier = '', this.dimension = ''});

  @override
  String toString() {
    var str = role;
    if (identifier.isNotEmpty) {
      str += ':$identifier';
    }
    if (dimension.isNotEmpty) {
      str += '/$dimension';
    }
    return str;
  }

  String getRole() => role;
  String getIdentifier() => identifier;
  String getDimension() => dimension;

  static Role parse(String role) {
    final roleParts = role.split(':');
    final hasIdentifier = roleParts.length > 1;
    final hasDimension = role.contains('/');
    var parsedRole = roleParts[0];

    if (!hasIdentifier && !hasDimension) {
      return Role(parsedRole);
    }

    if (hasIdentifier && !hasDimension) {
      var identifier = roleParts[1];
      return Role(parsedRole, identifier: identifier);
    }

    if (!hasIdentifier) {
      final dimensionParts = role.split('/');
      if (dimensionParts.length != 2) {
        throw Exception('Only one dimension can be provided.');
      }

      parsedRole = dimensionParts[0];
      final dimension = dimensionParts[1];

      if (dimension.isEmpty) {
        throw Exception('Dimension must not be empty.');
      }

      return Role(parsedRole, dimension: dimension);
    }

    // Has both identifier and dimension
    final dimensionParts = roleParts[1].split('/');
    if (dimensionParts.length != 2) {
      throw Exception('Only one dimension can be provided.');
    }

    final identifier = dimensionParts[0];
    final dimension = dimensionParts[1];

    if (dimension.isEmpty) {
      throw Exception('Dimension must not be empty.');
    }

    return Role(parsedRole, identifier: identifier, dimension: dimension);
  }

  static Role user(String identifier, [String status = '']) =>
      Role('user', identifier: identifier, dimension: status);

  static Role users([String status = '']) => Role('users', dimension: status);

  static Role team(String identifier, [String dimension = '']) =>
      Role('team', identifier: identifier, dimension: dimension);

  static Role any() => Role('any');

  static Role guests() => Role('guests');

  static Role member(String identifier) =>
      Role('member', identifier: identifier);
}
