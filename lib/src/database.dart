import 'dart:convert';

import 'package:utopia_database/src/adapter.dart';

import 'attribute.dart';
import 'document.dart';
import 'date_time_extension.dart';

class Database {
  static const varString = 'string';

// Simple Types
  static const varInteger = 'integer';
  static const varFloat = 'double';
  static const varBoolean = 'boolean';
  static const varDateTime = 'datetime';

// Relationships Types
  static const varRelationship = 'relationship';

// Index Types
  static const indexKey = 'key';
  static const indexFulltext = 'fulltext';
  static const indexUnique = 'unique';
  static const indexSpatial = 'spatial';
  static const indexArray = 'array';

// Relation Types
  static const relationOneToOne = 'oneToOne';
  static const relationOneToMany = 'oneToMany';
  static const relationManyToOne = 'manyToOne';
  static const relationManyToMany = 'manyToMany';

// Relation Actions
  static const relationMutateCascade = 'cascade';
  static const relationMutateRestrict = 'restrict';
  static const relationMutateSetNull = 'setNull';

// Relation Sides
  static const relationSideParent = 'parent';
  static const relationSideChild = 'child';

  static const relationMaxDepth = 3;

// Orders
  static const orderAsc = 'ASC';
  static const orderDesc = 'DESC';

// Permissions
  static const permissionCreate = 'create';
  static const permissionRead = 'read';
  static const permissionUpdate = 'update';
  static const permissionDelete = 'delete';

// Aggregate permissions
  static const permissionWrite = 'write';

  static const permissions = [
    permissionCreate,
    permissionRead,
    permissionUpdate,
    permissionDelete,
  ];

// Collections
  static const metadata = '_metadata';

// Cursor
  static const cursorBefore = 'before';
  static const cursorAfter = 'after';

// Lengths
  static const lengthKey = 255;

// Cache
  static const ttl = 60 * 60 * 24; // 24 hours

// Events
  static const eventAll = '*';

  static const eventDatabaseList = 'database_list';
  static const eventDatabaseCreate = 'database_create';
  static const eventDatabaseDelete = 'database_delete';

  static const eventCollectionList = 'collection_list';
  static const eventCollectionCreate = 'collection_delete';
  static const eventCollectionRead = 'collection_read';
  static const eventCollectionDelete = 'collection_delete';

  static const eventDocumentFind = 'document_find';
  static const eventDocumentCreate = 'document_create';
  static const eventDocumentRead = 'document_read';
  static const eventDocumentUpdate = 'document_update';
  static const eventDocumentDelete = 'document_delete';
  static const eventDocumentCount = 'document_count';
  static const eventDocumentSum = 'document_sum';
  static const eventDocumentIncrease = 'document_increase';
  static const eventDocumentDecrease = 'document_decrease';

  static const eventAttributeCreate = 'attribute_create';
  static const eventAttributeUpdate = 'attribute_update';
  static const eventAttributeDelete = 'attribute_delete';

  static const eventIndexRename = 'index_rename';
  static const eventIndexCreate = 'index_create';
  static const eventIndexDelete = 'index_delete';

  /// List of Internal Ids.
  final List<Map<String, dynamic>> attributes = [
    {
      '\$id': '\$id',
      'type': varString,
      'size': lengthKey,
      'required': true,
      'signed': true,
      'array': false,
      'filters': [],
    },
    {
      '\$id': '\$collection',
      'type': varString,
      'size': lengthKey,
      'required': true,
      'signed': true,
      'array': false,
      'filters': [],
    },
    {
      '\$id': '\$createdAt',
      'type': varDateTime,
      'format': '',
      'size': 0,
      'signed': false,
      'required': false,
      'default': null,
      'array': false,
      'filters': ['datetime']
    },
    {
      '\$id': '\$updatedAt',
      'type': varDateTime,
      'format': '',
      'size': 0,
      'signed': false,
      'required': false,
      'default': null,
      'array': false,
      'filters': ['datetime']
    }
  ];

  final Map<String, dynamic> collection = {
    '\$id': metadata,
    '\$collection': metadata,
    'name': 'collections',
    'attributes': [
      {
        '\$id': 'name',
        'key': 'name',
        'type': varString,
        'size': 256,
        'required': true,
        'signed': true,
        'array': false,
        'filters': [],
      },
      {
        '\$id': 'attributes',
        'key': 'attributes',
        'type': varString,
        'size': 1000000,
        'required': false,
        'signed': true,
        'array': false,
        'filters': ['json'],
      },
      {
        '\$id': 'indexes',
        'key': 'indexes',
        'type': varString,
        'size': 1000000,
        'required': false,
        'signed': true,
        'array': false,
        'filters': ['json'],
      },
    ],
    'indexes': [],
  };

  Adapter adapter;

  static Map<String, Map<String, dynamic>> _filters = {};
  Map<String, Map<String, dynamic>> _instanceFilters = {};

  Database(this.adapter,
      [Map<String, Map<String, dynamic>> filters = const {}]) {
    _instanceFilters = filters;

    addFilter(
      'json',
      (value) {
        value = (value is Document) ? value.getArrayCopy() : value;

        if (value is! Map<String, dynamic> && value is! Map) {
          return value;
        }

        return jsonEncode(value);
      },
      (value) {
        if (value is! String) {
          return value;
        }

        value = json.decode(value) ?? {};

        if (value.containsKey('\$id')) {
          return Document(value);
        } else {
          value = value.map((key, item) {
            if (item is Map<String, dynamic> && item.containsKey('\$id')) {
              return MapEntry(key, Document(item));
            }
            return MapEntry(key, item);
          });
        }

        return value;
      },
    );

    addFilter(
      'datetime',
      (value) {
        if (value == null) {
          return null;
        }
        try {
          (value as DateTime).format();
        } catch (th) {
          return value;
        }
      },
      (value) {
        return value;
      },
    );
  }

  static void addFilter(String name, Function encode, Function decode) {
    _filters[name] = {'encode': encode, 'decode': decode};
  }

  Database setNamespace(String namespace) {
    adapter.setNamespace(namespace);
    return this;
  }

  String getNamespace() {
    return adapter.getNamespace();
  }

  bool setDefaultDatabase(String name, {bool reset = false}) {
    return adapter.setDefaultDatabase(name, reset: reset);
  }

  String getDefaultDatabase() {
    return adapter.getDefaultDatabase();
  }

  Future<bool> ping() {
    return adapter.ping();
  }

  Future<bool> create() async {
    var name = adapter.getDefaultDatabase();
    adapter.create(name);

    final attributes = [
      Attribute(id: 'name', type: varString, size: 512, required: true),
      Attribute(
          id: 'attributes', type: varString, size: 1000000, required: false),
      Attribute(id: 'indexes', type: varString, size: 1000000, required: false),
    ];

    await createCollection(metadata, attributes, []);
    return true;
  }

  Future<Document?> createCollection(
      String id, List<Attribute> attributes, List indexes) async {
    await adapter.createCollection(id, attributes, indexes);

    if (id == metadata) {
      return Document(collection);
    }
    return null;
  }

  Future<bool> exists(String database, {String? collection}) async {
    return adapter.exists(database, collection: collection);
  }
}
