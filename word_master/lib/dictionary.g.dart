// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dictionary.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

class Dictionary extends _Dictionary
    with RealmEntity, RealmObjectBase, RealmObject {
  static var _defaultsSet = false;

  Dictionary(
    String id,
    String name, {
    int size = 0,
  }) {
    if (!_defaultsSet) {
      _defaultsSet = RealmObjectBase.setDefaults<Dictionary>({
        'size': 0,
      });
    }
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'size', size);
  }

  Dictionary._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  int get size => RealmObjectBase.get<int>(this, 'size') as int;
  @override
  set size(int value) => RealmObjectBase.set(this, 'size', value);

  @override
  Stream<RealmObjectChanges<Dictionary>> get changes =>
      RealmObjectBase.getChanges<Dictionary>(this);

  @override
  Dictionary freeze() => RealmObjectBase.freezeObject<Dictionary>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(Dictionary._);
    return const SchemaObject(
        ObjectType.realmObject, Dictionary, 'Dictionary', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('size', RealmPropertyType.int),
    ]);
  }
}
