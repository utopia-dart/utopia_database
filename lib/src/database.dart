import 'dart:convert';

import 'package:utopia_database/src/adapter.dart';
import 'package:uuid/uuid.dart';

import 'attribute.dart';
import 'document.dart';
import 'date_time_extension.dart';
import 'permission.dart';
import 'query.dart';
import 'role.dart';

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
      (value, [Document? document, Database? database]) {
        value = (value is Document) ? value.getArrayCopy() : value;
        value = (value is Attribute) ? value.toMap() : value;
        value = (value is List)
            ? value.map((value) => value is Attribute
                ? value.toMap()
                : value is Document
                    ? value.getArrayCopy()
                    : value).toList()
            : value;

        if (value is! Map && value is! List) {
          return value;
        }

        return jsonEncode(value);
      },
      (value, [Document? document, Database? database]) {
        if (value is! String) {
          return value;
        }

        value = jsonDecode(value) ?? {};

        if (value is Map && value.containsKey('\$id')) {
          return Document(Map<String, dynamic>.from(value));
        } else if(value is Map) {
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
      (value, [Document? document, Database? database]) {
        if (value == null) {
          return null;
        }
        try {
          (value as DateTime).format();
        } catch (th) {
          return value;
        }
      },
      (value, [Document? document, Database? database]) {
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

  Future<bool> delete(String name) {
    return adapter.delete(name);
  }

  Future<Document?> createCollection(
      String id, List<Attribute> attributes, List indexes) async {
    final collection = await getCollection(id);
    if (collection != null && collection.isNotEmpty && id != metadata) {
      throw Exception('Collection $id Exists!');
    }

    await adapter.createCollection(id, attributes, indexes);

    if (id == metadata) {
      return Document(collection!);
    }
    final createdCollection = Document({
      '\$id': id,
      '\$permissions': [
        Permission.read(Role.any()),
        Permission.create(Role.any()),
        Permission.update(Role.any()),
        Permission.delete(Role.any())
      ],
      'name': id,
      'attributes': attributes,
      'indexes': indexes
    });

    // if (indexes.isNotEmpty && adapter.getCountOfIndexes(createdCollection) > adapter.getLimitForIndexes()) {
    //   throw LimitException('Index limit of ${adapter.getLimitForIndexes()} exceeded. Cannot create collection.');
    // }

    // // check attribute limits, if given
    // if (attributes.isNotEmpty) {
    //   if (adapter.getLimitForAttributes() > 0 && adapter.getCountOfAttributes(createdCollection) > adapter.getLimitForAttributes()) {
    //     throw LimitException('Column limit of ${adapter.getLimitForAttributes()} exceeded. Cannot create collection.');
    //   }

    //   if (adapter.getDocumentSizeLimit() > 0 && adapter.getAttributeWidth(createdCollection) > adapter.getDocumentSizeLimit()) {
    //     throw LimitException('Row width limit of ${adapter.getDocumentSizeLimit()} exceeded. Cannot create collection.');
    //   }
    // }

    final createdDocument = await createDocument(metadata, createdCollection);
    return createdDocument;
  }

  Future<bool> deleteCollection(String id) async {
    var collection = getDocument(metadata, id);

    // var relationships = collection.attributes
    //     .where((attribute) => attribute.type == Database.VAR_RELATIONSHIP);

    // for (var relationship in relationships) {
    //   deleteRelationship(collection.id, relationship.id);
    // }

    await adapter.deleteCollection(id);

    var deleted = deleteDocument(metadata, id);

    return deleted;
  }

  Future<bool> deleteDocument(String collection, String id) async {
    var document = await getDocument(collection,
        id); // Skip ensures user does not need read permission for this
    var collectionObj = await getCollection(collection);

    if (collectionObj == null || document == null) {
      throw Exception('Not Found');
    }

    // if (collectionObj.id != metadata && !validator.isValid(document.delete)) {
    //   throw AuthorizationException(validator.getDescription());
    // }

    // if (resolveRelationships) {
    //   document =
    //       silent(() => deleteDocumentRelationships(collectionObj, document));
    // }

    var deleted = await adapter.deleteDocument(collectionObj.id!, id);

    return deleted;
  }

  Future<Document> createDocument(String collection, Document document) async {
    final collectionObj = await getCollection(collection);
    final time = DateTime.now();

    document
      ..setAttribute('\$id',
          (document.id?.isNotEmpty ?? false) ? document.id : Uuid().v4())
      ..setAttribute('\$collection', collectionObj!.id)
      ..setAttribute('\$createdAt', time)
      ..setAttribute('\$updatedAt', time);

    document = encode(collectionObj, document);

    // final validator = Structure(collectionObj);

    // if (!validator.isValid(document)) {
    //   throw StructureException(validator.getDescription());
    // }

    // if (resolveRelationships) {
    //   document =
    //       silent(() => createDocumentRelationships(collectionObj, document));
    // }

    document = await adapter.createDocument(collectionObj.id!, document);

    // if (resolveRelationships) {
    //   document =
    //       silent(() => populateDocumentRelationships(collectionObj, document));
    // }

    document = decode(collectionObj, document, []);

    return document;
  }

  Future<Document?> getCollection(String id) {
    return getDocument(metadata, id);
  }

  Future<Document?> getDocument(String collectionId, String id,
      [List<Query> queries = const []]) async {
    if (collectionId == Database.metadata && id == Database.metadata) {
      return Document(this.collection);
    }

    if (collectionId.isEmpty) {
      throw Exception('Collection not found');
    }

    if (id.isEmpty) {
      return Document({});
    }

    final collection = await getCollection(collectionId);

    if (collection == null) {
      throw Exception('Collection not found');
    }

    // final relationships = collection
    //     .getAttribute('attributes', {})
    //     .where((attribute) =>
    //         Document(attribute).getAttribute('type') == Database.varRelationship)
    //     .toList();

    // final selects = Query.groupByType(queries)['selections'];
    // final selections = validateSelections(collection, selects);
    // final nestedSelections = <Query>[];

    // for (final query in queries) {
    //   if (query.getMethod() == Query.TYPE_SELECT) {
    //     final values = query.getValues();
    //     for (var valueIndex = 0; valueIndex < values.length; valueIndex++) {
    //       final value = values[valueIndex];
    //       if (value.contains('.')) {
    //         // Shift the top level off the dot-path to pass the selection down the chain
    //         // 'foo.bar.baz' becomes 'bar.baz'
    //         nestedSelections.add(Query.select([value.split('.').skip(1).join('.')]));

    //         final key = value.split('.')[0];

    //         for (final relationship in relationships) {
    //           if (relationship.getAttribute('key') == key) {
    //             switch (relationship.getAttribute('options')['relationType']) {
    //               case Database.RELATION_MANY_TO_MANY:
    //               case Database.RELATION_ONE_TO_MANY:
    //                 values.removeAt(valueIndex);
    //                 break;
    //               case Database.RELATION_MANY_TO_ONE:
    //               case Database.RELATION_ONE_TO_ONE:
    //                 values[valueIndex] = key;
    //                 break;
    //             }
    //           }
    //         }
    //       }
    //     }
    //     query.setValues(values);
    //   }
    // }

    // queries = queries.toList();

    // final validator = Authorization(Database.PERMISSION_READ);

    // if (selections.isNotEmpty) {
    //   cacheKey += ':${md5(selections.join())}';
    // } else {
    //   cacheKey += ':*';
    // }

    // if (cache.load(cacheKey, Database.TTL) != null) {
    //   final document = Document(cache.load(cacheKey, Database.TTL));

    //   if (collection.getId() != Database.metadata && !validator.isValid(document.getRead())) {
    //     return Document();
    //   }

    //   trigger(Database.EVENT_DOCUMENT_READ, document);

    //   return document;
    // }

    var document =
        await adapter.getDocument(collection.id!, id, queries: queries);
    if (document == null || document.isEmpty) {
      return document;
    }
    document['\$collection'] = collection.id;

    if (collection.id != Database.metadata) {
      //&& !validator.isValid(document.getRead())) {
      return Document();
    }

    document = casting(collection, document);
    document = decode(collection, document, []);
    // final map = {};

    // if (resolveRelationships && (selects.isEmpty || nestedSelections.isNotEmpty)) {
    //   document = silent(() => populateDocumentRelationships(collection, document, nestedSelections));
    // }

    // final hasTwoWayRelationship = relationships.any((relationship) => relationship.getAttribute('options')['twoWay']);

    // for (final entry in map.entries) {
    //   final key = entry.key;
    //   final value = entry.value;
    //   final parts = key.split('=>');
    //   final k = parts[0];
    //   final v = parts[1];
    //   final ck = 'cache-${getNamespace()}:map:$k';

    return document;
  }

  Future<bool> exists(String database, {String? collection}) async {
    return adapter.exists(database, collection: collection);
  }

  dynamic encodeAttribute(String name, dynamic value, Document document) {
    if (!_filters.containsKey(name) && !_instanceFilters.containsKey(name)) {
      throw Exception('Filter: $name not found');
    }

    try {
      if (_instanceFilters.containsKey(name)) {
        value = _instanceFilters[name]!['encode'](value, document, this);
      } else {
        value = _filters[name]!['encode'](value, document, this);
      }
    } catch (e) {
      rethrow;
    }

    return value;
  }

  dynamic decodeAttribute(String name, dynamic value, Document document) {
    if (!_filters.containsKey(name) && !_instanceFilters.containsKey(name)) {
      throw Exception('Filter not found');
    }

    if (_instanceFilters.containsKey(name)) {
      value = _instanceFilters[name]!['decode'](value, document, this);
    } else {
      value = _filters[name]!['decode'](value, document, this);
    }

    return value;
  }

  Document decode(
      Document collection, Document document, List<String> selections) {
    List<dynamic> attributes = collection
        .getAttribute('attributes', [])
        .where((attribute) => attribute['type'] != varRelationship)
        .toList();
    List<dynamic> relationships = collection
        .getAttribute('attributes', [])
        .where((attribute) => attribute['type'] == varRelationship)
        .toList();

    for (Map<String, dynamic> relationship in relationships) {
      String key = relationship['\$id'] ?? '';

      if (document.containsKey(key) ||
          document.containsKey(adapter.filter(key))) {
        dynamic value = document.getAttribute(key) ??
            document.getAttribute(adapter.filter(key));
        document.remove(adapter.filter(key));
        document[key] = value;
      }
    }

    attributes = attributes
        .map((attribute) => attribute is Map
            ? Attribute.fromMap(Map<String, dynamic>.from(attribute))
            : attribute)
        .toList();

    attributes.addAll(getInternalAttributes());

    for (Attribute attribute in attributes) {
      String key = attribute.id;
      bool array = attribute.array ?? false;
      List<String> filters = attribute.filters;
      dynamic value = document.getAttribute(key);

      if (value == null) {
        value = document.getAttribute(adapter.filter(key));

        if (value != null) {
          document.remove(adapter.filter(key));
        }
      }

      if (attribute.type == Database.varString && value is! String) {
        value = value.toString();
      }

      value = array ? value : [value];
      value ??= [];

      for (int i = 0; i < value.length; i++) {
        dynamic node = value[i];

        for (int j = filters.length - 1; j >= 0; j--) {
          String filter = filters[j];
          node = decodeAttribute(filter, node, document);
        }

        value[i] = node;
      }

      if (selections.isEmpty ||
          selections.contains(key) ||
          selections.contains('*')) {
        document[key] = array ? value : value[0];
      }
    }

    return document;
  }

  Document encode(Document collection, Document document) {
    var attributes = collection.getAttribute('attributes', []);

    attributes = (attributes.map((attribute) => attribute is Map
        ? Attribute.fromMap(Map<String, dynamic>.from(attribute))
        : attribute is String ? Attribute.fromJson(attribute) : attribute)).toList();
    attributes.addAll(getInternalAttributes());

    for (Attribute attribute in attributes) {
      var key = attribute.id;
      var array = attribute.array ?? false;
      var defaultValue = null;
      var filters = attribute.filters;
      var value = document.getAttribute(key);

      // continue on optional param with no default
      if (value == null && defaultValue == null) {
        continue;
      }

      // assign default only if no value provided
      if (value == null && defaultValue != null) {
        value = array ? defaultValue : [defaultValue];
      } else {
        value = array ? value : [value];
      }

      for (var i = 0; i < value.length; i++) {
        var node = value[i];
        if (node != null) {
          for (var filter in filters) {
            node = encodeAttribute(filter, node, document);
          }
          value[i] = node;
        }
      }

      if (!array) {
        value = value[0];
      }

      document[key] = value;
    }

    return document;
  }

  List<Attribute> getInternalAttributes() {
    List<Attribute> attributes = [];
    for (var internal in this.attributes) {
      attributes.add(Attribute.fromMap(internal));
    }
    return attributes;
  }

  Document casting(Document collection, Document document) {
    if (adapter.getSupportForCasting()) {
      return document;
    }

    List attributes = collection.getAttribute('attributes', []);

    for (var attribute in attributes) {
      String key = attribute['\$id'] ?? '';
      String type = attribute['type'] ?? '';
      bool array = attribute['array'] ?? false;
      dynamic value = document.getAttribute(key, null);
      if (value == null) {
        continue;
      }

      if (array) {
        value = (value is String) ? jsonDecode(value) : value;
      } else {
        value = [value];
      }

      for (int i = 0; i < value.length; i++) {
        switch (type) {
          case varBoolean:
            value[i] = value[i] as bool;
            break;
          case varInteger:
            value[i] = value[i] as int;
            break;
          case varFloat:
            value[i] = value[i] as double;
            break;
          default:
            break;
        }
      }

      document[key] = (array) ? value : value[0];
    }

    return document;
  }
}
