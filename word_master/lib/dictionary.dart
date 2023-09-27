import 'package:realm/realm.dart';

part 'dictionary.g.dart';

@RealmModel()
class _Dictionary {
  @PrimaryKey()
  late String id;
  late String name;
  late int size = 0;
}
