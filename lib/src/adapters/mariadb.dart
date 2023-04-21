import 'dart:convert';

import 'package:utopia_database/src/adapter.dart';
import 'package:dart_mysql/dart_mysql.dart';
import 'package:utopia_database/src/date_time_extension.dart';
import 'package:utopia_database/src/query.dart';

import '../attribute.dart';
import '../database.dart';
import '../document.dart';

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
      String name, List<Attribute> attributes, List indexes) async {
    final id = filter(name);

    final attributeStrings = <String>[];
    final indexStrings = <String>[];

    for (var i = 0; i < attributes.length; i++) {
      final attribute = attributes[i];
      final attrId = filter(attribute.id);
      var attrType = _getSQLType(
          attribute.type, attribute.size ?? 0, attribute.signed ?? true);

      if (attribute.array ?? false) {
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
  Future<bool> deleteCollection(String name) async {
    if (_connection == null) return false;
    try {
      await _connection!.query(
          "DROP TABLE `${getSQLTable(name)}`, `${getSQLTable('${name}_perms')}`;");
      return true;
    } on MySqlException catch (_) {
      return false;
    }
  }

  Future<bool> createAttribute(String collection, Attribute attribute) async {
    final name = filter(collection);
    final id = filter(attribute.id);
    var sqlType = _getSQLType(
        attribute.type, attribute.size ?? 0, attribute.signed ?? true);

    if (attribute.array ?? false) {
      sqlType = 'LONGTEXT';
    }

    try {
      await _connection!.query(
          "ALTER TABLE `${getSQLTable(name)}` ADD COLUMN `$id` $sqlType;");
      return true;
    } on MySqlException catch (_) {
      return false;
    }
  }

  Future<bool> updateAttribute(String collection, Attribute attribute) async {
    final name = filter(collection);
    final id = filter(attribute.id);
    var sqlType = _getSQLType(
        attribute.type, attribute.size ?? 0, attribute.signed ?? true);

    if (attribute.array ?? false) {
      sqlType = 'LONGTEXT';
    }

    try {
      await _connection!
          .query("ALTER TABLE `${getSQLTable(name)}` MODIFY `$id` $sqlType;");
      return true;
    } on MySqlException catch (_) {
      return false;
    }
  }

  Future<bool> deleteAttribute(String collection, Attribute attribute) async {
    final name = filter(collection);
    final id = filter(attribute.id);

    try {
      await _connection!
          .query("ALTER TABLE `${getSQLTable(name)}` DROP COLUMN `$id`;");
      return true;
    } on MySqlException catch (_) {
      return false;
    }
  }

  Future<bool> renameAttribute(
      String collection, String old, String newAttr) async {
    final name = filter(collection);
    old = filter(old);
    newAttr = filter(newAttr);

    try {
      await _connection!.query(
          "ALTER TABLE `${getSQLTable(name)}` RENAME COLUMN `$old` TO `$newAttr`;");
      return true;
    } on MySqlException catch (_) {
      return false;
    }
  }

  Future<bool> createRelationship(
      String collection, String relatedCollection, String type,
      {bool twoWay = false, String id = '', String twoWayKey = ''}) async {
    String name = filter(collection);
    String relatedName = filter(relatedCollection);
    String table = getSQLTable(name);
    String relatedTable = getSQLTable(relatedName);
    id = filter(id);
    twoWayKey = filter(twoWayKey);
    String sqlType = _getSQLType(Database.varRelationship, 0, false);

    String sql = '';
    switch (type) {
      case Database.relationOneToOne:
        sql = "ALTER TABLE $table ADD COLUMN `$id` $sqlType DEFAULT NULL;";
        if (twoWay) {
          sql +=
              "ALTER TABLE $relatedTable ADD COLUMN `$twoWayKey` $sqlType DEFAULT NULL;";
        }
        break;
      case Database.relationOneToMany:
        sql =
            "ALTER TABLE $relatedTable ADD COLUMN `$twoWayKey` $sqlType DEFAULT NULL;";
        break;
      case Database.relationManyToOne:
        sql = "ALTER TABLE $table ADD COLUMN `$id` $sqlType DEFAULT NULL;";
        break;
      case Database.relationManyToMany:
        return true;
      default:
        throw Exception('Invalid relationship type.');
    }

    var result = await _connection!.query(sql);
    return (result.affectedRows ?? 0) > 0;
  }

  Future<bool> updateRelationship(String collection, String relatedCollection,
      String type, bool twoWay, String key, String twoWayKey,
      [String? newKey, String? newTwoWayKey]) async {
    var name = filter(collection);
    var relatedName = filter(relatedCollection);
    var table = getSQLTable(name);
    var relatedTable = getSQLTable(relatedName);
    key = filter(key);
    twoWayKey = filter(twoWayKey);

    if (newKey != null) {
      newKey = filter(newKey);
    }
    if (newTwoWayKey != null) {
      newTwoWayKey = filter(newTwoWayKey);
    }

    var sql = '';

    switch (type) {
      case Database.relationOneToOne:
        if (newKey != null) {
          sql = "ALTER TABLE $table RENAME COLUMN $key TO $newKey;";
        }
        if (twoWay && newTwoWayKey != null) {
          sql +=
              "ALTER TABLE $relatedTable RENAME COLUMN $twoWayKey TO $newTwoWayKey;";
        }
        break;
      case Database.relationOneToMany:
        if (twoWay && newTwoWayKey != null) {
          sql =
              "ALTER TABLE $relatedTable RENAME COLUMN $twoWayKey TO $newTwoWayKey;";
        }
        break;
      case Database.relationManyToOne:
        if (newKey != null) {
          sql = "ALTER TABLE $table RENAME COLUMN $key TO $newKey;";
        }
        break;
      case Database.relationManyToMany:
        var collectionDoc = await getDocument(Database.metadata, collection);
        var relatedCollectionDoc =
            await getDocument(Database.metadata, relatedCollection);
        var junction = getSQLTable(
            '${collectionDoc.internalId}${relatedCollectionDoc.internalId}');

        if (newKey != null) {
          sql = "ALTER TABLE $junction RENAME COLUMN `$key` TO `$newKey`;";
        }
        if (twoWay && newTwoWayKey != null) {
          sql +=
              "ALTER TABLE $junction RENAME COLUMN `$twoWayKey` TO `$newTwoWayKey`;";
        }
        break;
      default:
        throw Exception('Invalid relationship type.');
    }

    if (sql.isEmpty) {
      return true;
    }

    var results = await _connection!.query(sql);
    return (results.affectedRows ?? 0) > 0;
  }

  Future<bool> deleteRelationship(
    String collection,
    String relatedCollection,
    String type,
    bool twoWay,
    String key,
    String twoWayKey,
    String side,
  ) async {
    final name = filter(collection);
    final relatedName = filter(relatedCollection);
    final table = getSQLTable(name);
    final relatedTable = getSQLTable(relatedName);
    key = filter(key);
    twoWayKey = filter(twoWayKey);

    var sql = '';

    switch (type) {
      case Database.relationOneToOne:
        sql = "ALTER TABLE $table DROP COLUMN '$key';";
        if (twoWay) {
          sql += "ALTER TABLE $relatedTable DROP COLUMN '$twoWayKey';";
        }
        break;
      case Database.relationOneToMany:
        if (side == Database.relationSideParent) {
          sql = "ALTER TABLE $relatedTable DROP COLUMN '$twoWayKey';";
        } else if (twoWay) {
          sql = "ALTER TABLE $table DROP COLUMN '$key';";
        }
        break;
      case Database.relationManyToOne:
        if (twoWay && side == Database.relationSideChild) {
          sql = "ALTER TABLE $relatedTable DROP COLUMN '$twoWayKey';";
        } else {
          sql = "ALTER TABLE $table DROP COLUMN '$key';";
        }
        break;
      case Database.relationManyToMany:
        final collectionMeta = await getDocument(Database.metadata, collection);
        final relatedCollectionMeta =
            await getDocument(Database.metadata, relatedCollection);

        final junction = side == Database.relationSideParent
            ? getSQLTable(
                '_${collectionMeta.internalId}_${relatedCollectionMeta.internalId}')
            : getSQLTable(
                '_${relatedCollectionMeta.internalId}_${collectionMeta.internalId}');

        final perms = side == Database.relationSideParent
            ? getSQLTable(
                '_${collectionMeta.internalId}_${relatedCollectionMeta.internalId}_perms')
            : getSQLTable(
                '_${relatedCollectionMeta.internalId}_${collectionMeta.internalId}_perms');

        sql = "DROP TABLE $junction; DROP TABLE $perms";
        break;
      default:
        throw Exception('Invalid relationship type.');
    }

    if (sql.isEmpty) {
      return true;
    }

    var result = await _connection!.query(sql);
    return (result.affectedRows ?? 0) > 0;
  }

  @override
  Future<Document> createDocument(String collection, Document document) async {
    final attributes = document.getAttributes();
    attributes['_createdAt'] = (document.createdAt ?? DateTime.now()).format();
    attributes['_updatedAt'] = (document.updatedAt ?? DateTime.now()).format();
    attributes['_permissions'] = json.encode(document.permissions);

    final name = filter(collection);
    var columns = <String>[];
    var columnNames = <String>[];
    var values = <Object>[];
    var index = 0;

    try {
      await _connection!.transaction((conn) async {
        for (final attribute in attributes.entries) {
          final column = filter(attribute.key);
          final bindKey = 'key_$index';
          columns.add('`$column`');
          columnNames.add('?');
          values.add(attribute.value is List || attribute.value is Map
              ? json.encode(attribute.value)
              : attribute.value);
          index++;
        }

        final statement = 'INSERT INTO ${getSQLTable(name)} '
            '(${columns.join(', ')}, `_uid`) '
            'VALUES (${columnNames.join(', ')}, ?)';

        values.add(document.id!);

        final result = await conn.query(statement, values);

        final documentResult = await getDocument(
          collection,
          document.id!,
        );
        document['\$internalId'] = documentResult.internalId;

        final permissions = <String>[];
        for (final type in Database.permissions) {
          for (final permission in document.getPermissionsByType(type)) {
            final permissionStr = permission.replaceAll('"', '');
            permissions.add("('$type', '$permissionStr', '${document.id}')");
          }
        }

        if (permissions.isNotEmpty) {
          final queryPermissions =
              "INSERT INTO ${getSQLTable('${name}_perms')} "
              "(`_type`, `_permission`, `_document`) "
              "VALUES ${permissions.join(', ')}";
          await conn.query(queryPermissions);
        }
      });
    } on MySqlException catch (e) {
      switch (e.errorNumber) {
        case 1062:
        case 23000:
          throw Exception('Duplicated document: ${e.message}');
        default:
          rethrow;
      }
    }

    return document;
  }

  @override
  Future<Document> getDocument(String collection, String id,
      {List<Query> queries = const []}) async {
    final name = filter(collection);
    final selections = getAttributeSelections(queries);

    final query = '''
      SELECT ${getAttributeProjection(selections, '')}
      FROM ${getSQLTable(name)}
      WHERE _uid = ?
    ''';
    final results = await _connection!.query(query, [id]);

    if (results.isEmpty) {
      return Document({});
    }

    final document = results.first.fields;

    document['\$id'] = document['_uid'];
    document['\$internalId'] = document['_id'];
    document['\$createdAt'] = document['_createdAt'];
    document['\$updatedAt'] = document['_updatedAt'];

    var permissions = document['_permissions'];
    if (permissions is Blob) {
      permissions = Utf8Decoder().convert(permissions.toBytes());
    }

    document['\$permissions'] = json.decode(permissions ?? '[]');

    document.remove('_id');
    document.remove('_uid');
    document.remove('_createdAt');
    document.remove('_updatedAt');
    document.remove('_permissions');

    return Document(document);
  }

  String getAttributeProjection(List<String> selections, String prefix) {
    if (selections.isEmpty || selections.contains('')) {
      if (prefix.isNotEmpty) {
        return "$prefix.";
      }
      return '*';
    }

    selections
        .addAll(['_uid', '_id', '_createdAt', '_updatedAt', '_permissions']);

    if (prefix.isNotEmpty) {
      for (var i = 0; i < selections.length; i++) {
        selections[i] = "$prefix.${selections[i]}";
      }
    } else {
      for (var i = 0; i < selections.length; i++) {
        selections[i] = "${selections[i]}";
      }
    }

    return selections.join(', ');
  }

  String getSQLSchema() {
    if (!getSupportForSchemas()) {
      return '';
    }
    return '`${getDefaultDatabase()}`.';
  }

  String getSQLTable(String name) {
    return '${getSQLSchema()}`${getNamespace()}_$name`';
  }

  bool getSupportForSchemas() {
    return true;
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

  @override
  bool getSupportForCasting() {
    return false;
  }
}
