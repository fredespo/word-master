// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_collection_data.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

class WordCollectionData extends _WordCollectionData
    with RealmEntity, RealmObjectBase, RealmObject {
  WordCollectionData(
    String name,
    DateTime createdOn, {
    Iterable<String> words = const [],
  }) {
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'createdOn', createdOn);
    RealmObjectBase.set<RealmList<String>>(
        this, 'words', RealmList<String>(words));
  }

  WordCollectionData._();

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
  RealmList<String> get words =>
      RealmObjectBase.get<String>(this, 'words') as RealmList<String>;
  @override
  set words(covariant RealmList<String> value) =>
      throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<WordCollectionData>> get changes =>
      RealmObjectBase.getChanges<WordCollectionData>(this);

  @override
  WordCollectionData freeze() =>
      RealmObjectBase.freezeObject<WordCollectionData>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(WordCollectionData._);
    return const SchemaObject(
        ObjectType.realmObject, WordCollectionData, 'WordCollectionData', [
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('createdOn', RealmPropertyType.timestamp),
      SchemaProperty('words', RealmPropertyType.string,
          collectionType: RealmCollectionType.list),
    ]);
  }
}
