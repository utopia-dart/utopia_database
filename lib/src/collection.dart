import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:utopia_database/src/attribute.dart';

class Collection {
  final String id;
  final String collection;
  final String name;
  final List<Attribute> attributes;
  Collection({
    required this.id,
    required this.collection,
    required this.name,
    required this.attributes,
  });

  Collection copyWith({
    String? id,
    String? collection,
    String? name,
    List<Attribute>? attributes,
  }) {
    return Collection(
      id: id ?? this.id,
      collection: collection ?? this.collection,
      name: name ?? this.name,
      attributes: attributes ?? this.attributes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection': collection,
      'name': name,
      'attributes': attributes.map((x) => x.toMap()).toList(),
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'] ?? '',
      collection: map['collection'] ?? '',
      name: map['name'] ?? '',
      attributes: List<Attribute>.from(map['attributes']?.map((x) => Attribute.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory Collection.fromJson(String source) => Collection.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Collection(id: $id, collection: $collection, name: $name, attributes: $attributes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;
  
    return other is Collection &&
      other.id == id &&
      other.collection == collection &&
      other.name == name &&
      listEquals(other.attributes, attributes);
  }

  @override
  int get hashCode {
    return id.hashCode ^
      collection.hashCode ^
      name.hashCode ^
      attributes.hashCode;
  }
}
