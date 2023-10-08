// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_collection_entry.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

class WordCollectionEntry extends _WordCollectionEntry
    with RealmEntity, RealmObjectBase, RealmObject {
  WordCollectionEntry(
    String wordCollectionId,
    String dictionaryId,
    String wordOrPhrase,
    bool isFavorite,
  ) {
    RealmObjectBase.set(this, 'wordCollectionId', wordCollectionId);
    RealmObjectBase.set(this, 'dictionaryId', dictionaryId);
    RealmObjectBase.set(this, 'wordOrPhrase', wordOrPhrase);
    RealmObjectBase.set(this, 'isFavorite', isFavorite);
  }

  WordCollectionEntry._();

  @override
  String get wordCollectionId =>
      RealmObjectBase.get<String>(this, 'wordCollectionId') as String;
  @override
  set wordCollectionId(String value) =>
      RealmObjectBase.set(this, 'wordCollectionId', value);

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
  bool get isFavorite => RealmObjectBase.get<bool>(this, 'isFavorite') as bool;
  @override
  set isFavorite(bool value) => RealmObjectBase.set(this, 'isFavorite', value);

  @override
  Stream<RealmObjectChanges<WordCollectionEntry>> get changes =>
      RealmObjectBase.getChanges<WordCollectionEntry>(this);

  @override
  WordCollectionEntry freeze() =>
      RealmObjectBase.freezeObject<WordCollectionEntry>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(WordCollectionEntry._);
    return const SchemaObject(
        ObjectType.realmObject, WordCollectionEntry, 'WordCollectionEntry', [
      SchemaProperty('wordCollectionId', RealmPropertyType.string),
      SchemaProperty('dictionaryId', RealmPropertyType.string),
      SchemaProperty('wordOrPhrase', RealmPropertyType.string),
      SchemaProperty('isFavorite', RealmPropertyType.bool),
    ]);
  }
}
