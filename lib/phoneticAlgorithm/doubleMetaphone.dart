import 'package:dart_phonetics/dart_phonetics.dart';

class PhoneticAlgorithm {
  static final doubleMetaphone = DoubleMetaphone.withMaxLength(12);
  static PhoneticEncoding? getEncoding(String? val) =>
      doubleMetaphone.encode(val!);
}
