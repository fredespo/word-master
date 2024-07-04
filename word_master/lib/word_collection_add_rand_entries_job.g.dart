// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_collection_add_rand_entries_job.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

class WordCollectionAddRandEntriesJob extends _WordCollectionAddRandEntriesJob
    with RealmEntity, RealmObjectBase, RealmObject {
  WordCollectionAddRandEntriesJob(
    String wordCollectionId,
    String dictionaryId,
    int numEntries,
  ) {
    RealmObjectBase.set(this, 'wordCollectionId', wordCollectionId);
    RealmObjectBase.set(this, 'dictionaryId', dictionaryId);
    RealmObjectBase.set(this, 'numEntries', numEntries);
  }

  WordCollectionAddRandEntriesJob._();

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
  int get numEntries => RealmObjectBase.get<int>(this, 'numEntries') as int;
  @override
  set numEntries(int value) => RealmObjectBase.set(this, 'numEntries', value);

  @override
  Stream<RealmObjectChanges<WordCollectionAddRandEntriesJob>> get changes =>
      RealmObjectBase.getChanges<WordCollectionAddRandEntriesJob>(this);

  @override
  WordCollectionAddRandEntriesJob freeze() =>
      RealmObjectBase.freezeObject<WordCollectionAddRandEntriesJob>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(WordCollectionAddRandEntriesJob._);
    return const SchemaObject(ObjectType.realmObject,
        WordCollectionAddRandEntriesJob, 'WordCollectionAddRandEntriesJob', [
      SchemaProperty('wordCollectionId', RealmPropertyType.string),
      SchemaProperty('dictionaryId', RealmPropertyType.string),
      SchemaProperty('numEntries', RealmPropertyType.int),
    ]);
  }
}
