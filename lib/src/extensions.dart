import 'characters.dart';

extension FromString on String {
  /// Creates a [Characters] from the current String.
  Characters characters() => Characters(this);
}
