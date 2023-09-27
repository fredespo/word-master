// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imported_dictionary.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

class ImportedDictionary extends _ImportedDictionary
    with RealmEntity, RealmObjectBase, RealmObject {
  ImportedDictionary(
    String dictionaryId,
    String source,
  ) {
    RealmObjectBase.set(this, 'dictionaryId', dictionaryId);
    RealmObjectBase.set(this, 'source', source);
  }

  ImportedDictionary._();

  @override
  String get dictionaryId =>
      RealmObjectBase.get<String>(this, 'dictionaryId') as String;
  @override
  set dictionaryId(String value) =>
      RealmObjectBase.set(this, 'dictionaryId', value);

  @override
  String get source => RealmObjectBase.get<String>(this, 'source') as String;
  @override
  set source(String value) => RealmObjectBase.set(this, 'source', value);

  @override
  Stream<RealmObjectChanges<ImportedDictionary>> get changes =>
      RealmObjectBase.getChanges<ImportedDictionary>(this);

  @override
  ImportedDictionary freeze() =>
      RealmObjectBase.freezeObject<ImportedDictionary>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(ImportedDictionary._);
    return const SchemaObject(
        ObjectType.realmObject, ImportedDictionary, 'ImportedDictionary', [
      SchemaProperty('dictionaryId', RealmPropertyType.string),
      SchemaProperty('source', RealmPropertyType.string),
    ]);
  }
}
