import 'dart:convert';

import 'package:collection/collection.dart';

class Attribute {
  final String id;
  final String type;
  final int? size;
  final bool required;
  final bool? signed;
  final bool? array;
  final List<String> filters;
  Attribute({
    required this.id,
    required this.type,
    required this.required,
    this.size,
    this.signed,
    this.array,
    this.filters = const [],
  });

  Attribute copyWith({
    String? id,
    String? type,
    int? size,
    bool? required,
    bool? signed,
    bool? array,
    List<String>? filters,
  }) {
    return Attribute(
      id: id ?? this.id,
      type: type ?? this.type,
      size: size ?? this.size,
      required: required ?? this.required,
      signed: signed ?? this.signed,
      array: array ?? this.array,
      filters: filters ?? this.filters,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'size': size,
      'required': required,
      'signed': signed,
      'array': array,
      'filters': filters,
    };
  }

  factory Attribute.fromMap(Map<String, dynamic> map) {
    return Attribute(
      id: map['id'] ?? map['\$id'] ?? '',
      type: map['type'] ?? '',
      size: map['size']?.toInt() ?? 0,
      required: map['required'] ?? false,
      signed: map['signed'] ?? false,
      array: map['array'] ?? false,
      filters: List<String>.from(map['filters']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Attribute.fromJson(String source) =>
      Attribute.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Attribute(id: $id, type: $type, size: $size, required: $required, signed: $signed, array: $array, filters: $filters)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Attribute &&
        other.id == id &&
        other.type == type &&
        other.size == size &&
        other.required == required &&
        other.signed == signed &&
        other.array == array &&
        listEquals(other.filters, filters);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        size.hashCode ^
        required.hashCode ^
        signed.hashCode ^
        array.hashCode ^
        filters.hashCode;
  }
}
