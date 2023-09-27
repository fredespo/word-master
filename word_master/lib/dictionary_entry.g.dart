// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dictionary_entry.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

class DictionaryEntry extends _DictionaryEntry
    with RealmEntity, RealmObjectBase, RealmObject {
  DictionaryEntry(
    String dictionaryId,
    String wordOrPhrase,
    String definitions,
  ) {
    RealmObjectBase.set(this, 'dictionaryId', dictionaryId);
    RealmObjectBase.set(this, 'wordOrPhrase', wordOrPhrase);
    RealmObjectBase.set(this, 'definitions', definitions);
  }

  DictionaryEntry._();

  @override
  String get dictionaryId =>
      RealmObjectBase.get<String>(this, 'dictionaryId') as String;
  @override
  set dictionaryId(String value) =>
      RealmObjectBase.set(this, 'dictionaryId', value);

  @override
  String get wordOrPhrase =>
      RealmObjectBase.get<String>(this, 'wordOrPhrase') as String;
  @override
  set wordOrPhrase(String value) =>
      RealmObjectBase.set(this, 'wordOrPhrase', value);

  @override
  String get definitions =>
      RealmObjectBase.get<String>(this, 'definitions') as String;
  @override
  set definitions(String value) =>
      RealmObjectBase.set(this, 'definitions', value);

  @override
  Stream<RealmObjectChanges<DictionaryEntry>> get changes =>
      RealmObjectBase.getChanges<DictionaryEntry>(this);

  @override
  DictionaryEntry freeze() =>
      RealmObjectBase.freezeObject<DictionaryEntry>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(DictionaryEntry._);
    return const SchemaObject(
        ObjectType.realmObject, DictionaryEntry, 'DictionaryEntry', [
      SchemaProperty('dictionaryId', RealmPropertyType.string),
      SchemaProperty('wordOrPhrase', RealmPropertyType.string),
      SchemaProperty('definitions', RealmPropertyType.string),
    ]);
  }
}
