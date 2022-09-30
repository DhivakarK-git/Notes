import 'package:isar/isar.dart';
import 'package:notes/phoneticAlgorithm/doubleMetaphone.dart';

part 'Note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment

  String? title, body, color;

  List<DateTime>? modified;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get revTitleWords {
    return Isar.splitWords(title! + " " + body!) +
        Isar.splitWords(title! + " " + body!)
            .map((word) => PhoneticAlgorithm.getEncoding(word)!.primary)
            .toList() +
        Isar.splitWords(title! + " " + body!)
            .map((word) => PhoneticAlgorithm.getEncoding(
                    word.split('').reversed.toString())!
                .primary)
            .toList() +
        Isar.splitWords(title! + " " + body!)
            .map((word) => word.split('').reversed.toString())
            .toList();
  }
}
