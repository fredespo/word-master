// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_collection.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

class WordCollection extends _WordCollection
    with RealmEntity, RealmObjectBase, RealmObject {
  WordCollection(
    String id,
    String name,
    DateTime createdOn,
    int size,
    String status,
    double progress,
  ) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'createdOn', createdOn);
    RealmObjectBase.set(this, 'size', size);
    RealmObjectBase.set(this, 'status', status);
    RealmObjectBase.set(this, 'progress', progress);
  }

  WordCollection._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  DateTime get createdOn =>
      RealmObjectBase.get<DateTime>(this, 'createdOn') as DateTime;
  @override
  set createdOn(DateTime value) =>
      RealmObjectBase.set(this, 'createdOn', value);

  @override
  int get size => RealmObjectBase.get<int>(this, 'size') as int;
  @override
  set size(int value) => RealmObjectBase.set(this, 'size', value);

  @override
  String get status => RealmObjectBase.get<String>(this, 'status') as String;
  @override
  set status(String value) => RealmObjectBase.set(this, 'status', value);

  @override
  double get progress =>
      RealmObjectBase.get<double>(this, 'progress') as double;
  @override
  set progress(double value) => RealmObjectBase.set(this, 'progress', value);

  @override
  Stream<RealmObjectChanges<WordCollection>> get changes =>
      RealmObjectBase.getChanges<WordCollection>(this);

  @override
  WordCollection freeze() => RealmObjectBase.freezeObject<WordCollection>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(WordCollection._);
    return const SchemaObject(
        ObjectType.realmObject, WordCollection, 'WordCollection', [
      SchemaProperty('id', RealmPropertyType.string),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('createdOn', RealmPropertyType.timestamp),
      SchemaProperty('size', RealmPropertyType.int),
      SchemaProperty('status', RealmPropertyType.string),
      SchemaProperty('progress', RealmPropertyType.double),
    ]);
  }
}
