import 'package:utopia_database/src/adapter.dart';
import 'package:dart_mysql/dart_mysql.dart';

import '../database.dart';

class MariaDB extends Adapter {
  MySqlConnection? _connection;

  @override
  Future<bool> create(String name) async {
    name = filter(name);
    if (_connection == null) return false;

    try {
      await _connection!.query(
          'CREATE DATABASE IF NOT EXISTS `$name` /*!40100 DEFAULT CHARACTER SET utf8mb4 */;');
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> init(
      {required String host,
      required int port,
      String? user,
      String? password}) async {
    _connection = await MySqlConnection.connect(ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
    ));
  }

  @override
  Future<bool> createCollection(
      String name, List attributes, List indexes) async {
    final id = filter(name);

    final attributeStrings = <String>[];
    final indexStrings = <String>[];

    for (var i = 0; i < attributes.length; i++) {
      final attribute = attributes[i];
      final attrId = filter(attribute.id);
      var attrType = _getSQLType(attribute['type'], attribute['size'] ?? 0,
          attribute['signed'] ?? true);

      if (attribute['array'] ?? false) {
        attrType = 'LONGTEXT';
      }

      attributeStrings.add('`$attrId` $attrType');
    }

    for (var i = 0; i < indexes.length; i++) {
      final index = indexes[i];
      final indexId = filter(index.id);
      final indexType = index['type'];
      final indexAttributes = <String>[];

      for (var j = 0; j < index.attributes.length; j++) {
        final attribute = filter(index.attributes[j]);
        final indexLength = index.lengths?[j] ?? '';
        final indexOrder = index.orders?[j] ?? '';
        final length =
            indexLength.isNotEmpty ? '(${int.parse(indexLength)})' : '';
        final order = indexType == Database.indexFulltext ? '' : ' $indexOrder';
        indexAttributes.add('`$attribute`$length$order');
      }

      indexStrings.add('$indexType `$indexId` (${indexAttributes.join(', ')})');
    }

    try {
      if (_connection == null) return false;
      final query = '''
        CREATE TABLE IF NOT EXISTS `$defaultDatabase`.`${namespace}_$id` (
          `_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
          `_uid` CHAR(255) NOT NULL,
          `_createdAt` datetime(3) DEFAULT NULL,
          `_updatedAt` datetime(3) DEFAULT NULL,
          `_permissions` MEDIUMTEXT DEFAULT NULL,
          ${attributeStrings.join(',\n')},
          PRIMARY KEY (`_id`),
          ${indexStrings.join(',\n')}${indexStrings.isNotEmpty ? ',' : ''}
          UNIQUE KEY `_uid` (`_uid`),
          KEY `_created_at` (`_createdAt`),
          KEY `_updated_at` (`_updatedAt`)
        )
      ''';
      await _connection!.query(query);

      await _connection!.query('''
        CREATE TABLE IF NOT EXISTS `$defaultDatabase`.`${namespace}_${id}_perms` (
          `_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
          `_type` VARCHAR(12) NOT NULL,
          `_permission` VARCHAR(255) NOT NULL,
          `_document` VARCHAR(255) NOT NULL,
          PRIMARY KEY (`_id`),
          UNIQUE INDEX `_index1` (`_document`,`_type`,`_permission`),
          INDEX `_permission` (`_permission`)
        )
      ''');

      return true;
    } catch (e) {
      // await _handleError(e, id);
      return false;
    }
  }

  @override
  Future<bool> delete(String name) async {
    name = filter(name);
    if (_connection == null) return false;

    final result = await _connection!.query("DROP DATABASE `$name`;");

    return result.affectedRows == 1;
  }

  @override
  Future<bool> deleteCollection(String name) {
    // TODO: implement deleteCollection
    throw UnimplementedError();
  }

  @override
  Future<bool> ping() async {
    try {
      final res = await _connection!.query('SELECT 1;');
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> exists(String database, {String? collection}) async {
    if (_connection == null) return false;

    database = filter(database);

    late String select, from, where, match;
    if (collection != null) {
      collection = filter(collection);

      select = 'TABLE_NAME';
      from = 'INFORMATION_SCHEMA.TABLES';
      where = 'TABLE_SCHEMA = ? AND TABLE_NAME = ?';
      match = '${getNamespace()}_$collection';
    } else {
      select = 'SCHEMA_NAME';
      from = 'INFORMATION_SCHEMA.SCHEMATA';
      where = 'SCHEMA_NAME = ?';
      match = database;
    }

    final results = await _connection!.query(
      'SELECT $select FROM $from WHERE $where',
      collection != null
          ? [database, '$getNamespace()_$collection']
          : [database],
    );

    final document = results.first.fields;

    return (document[select] ?? '') == match ||
        (document[select.toLowerCase()] ?? '') == match;
  }

  @override
  Future<List> list() {
    // TODO: implement list
    throw UnimplementedError();
  }

  String _getSQLType(String type, int size, [bool isSigned = true]) {
    String signed = '';
    switch (type) {
      case Database.varString:
        // size = size * 4; // Convert utf8mb4 size to bytes
        if (size > 16777215) {
          return 'LONGTEXT';
        }

        if (size > 65535) {
          return 'MEDIUMTEXT';
        }

        if (size > 16383) {
          return 'TEXT';
        }

        return "VARCHAR($size)";

      case Database.varInteger:
        // We don't support zerofill: https://stackoverflow.com/a/5634147/2299554
        signed = (isSigned) ? '' : ' UNSIGNED';

        if (size >= 8) {
          // INT = 4 bytes, BIGINT = 8 bytes
          return 'BIGINT$signed';
        }

        return 'INT$signed';

      case Database.varFloat:
        signed = (isSigned) ? '' : ' UNSIGNED';
        return 'DOUBLE$signed';

      case Database.varBoolean:
        return 'TINYINT(1)';

      case Database.varRelationship:
        return 'VARCHAR(255)';

      case Database.varDateTime:
        return 'DATETIME(3)';

      default:
        throw Exception('Unknown Type');
    }
  }
}
