# Changelog

## 0.4.0

* Add an extension method on String to allow easy creation of Characters from
  existing Strings:

    ```dart
    print('The first character is: ' + myString.characters.take(1))
    ```
* Update Dart SDK dependency to Dart 2.6.0

## 0.3.1

* Added small example in `example/main.dart`
* Enabled pedantic lints and updated code to resolve issues.

## 0.3.0

* Updated API which does not expose the underlying string indices.

## 0.1.0

* Initial release