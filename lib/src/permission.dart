import 'role.dart';

class Permission {
  late Role role;

  static final Map<String, List<String>> _aggregates = {
    'write': [
      'Permission_create',
      'Permission_update',
      'Permission_delete',
    ]
  };

  String permission;
  String identifier = '';
  String dimension = '';

  Permission(this.permission, String role,
      {this.identifier = '', this.dimension = ''}) {
    this.role = Role(role, identifier: identifier, dimension: dimension);
  }

  Permission.fromRole(this.permission, this.role);

  @override
  String toString() {
    return '$permission("${role.toString()}")';
  }


  String getRole() {
    return role.getRole();
  }

  String getIdentifier() {
    return role.identifier;
  }

  String getDimension() {
    return role.dimension;
  }

  static Permission parse(String permissionString) {
    var permissionParts = permissionString.split('("');

    if (permissionParts.length != 2) {
      throw Exception('Invalid permission string format: "$permissionString".');
    }

    var permission = permissionParts[0];
    var fullRole = permissionParts[1].replaceAll('")', '');

    final role = Role.parse(fullRole);

    return Permission.fromRole(permission, role);
  }

  static List<String>? aggregate(List<String>? permissions,
      {List<String> allowed = const []}) {
    if (permissions == null) {
      return null;
    }
    var mutated = <String>[];
    for (var permissionString in permissions) {
      var permission = parse(permissionString);
      for (var type in _aggregates.keys) {
        if (permission.permission != type) {
          mutated.add(permission.toString());
          continue;
        }
        for (var subType in _aggregates[type]!) {
          if (!allowed.contains(subType)) {
            continue;
          }
          mutated.add(Permission(
            subType,
            permission.getRole(),
            identifier: permission.getIdentifier(),
            dimension: permission.getDimension(),
          ).toString());
        }
      }
    }
    return mutated;
  }

  static String write(Role role) {
    return Permission.fromRole('write', role).toString();
  }

  static String delete(Role role) {
    return Permission.fromRole('delete', role).toString();
  }

  static String update(Role role) {
    return Permission.fromRole('update', role).toString();
  }

  static String create(Role role) {
    return Permission.fromRole('create', role).toString();
  }

  static String read(Role role) {
    return Permission.fromRole('read', role).toString();
  }
}
