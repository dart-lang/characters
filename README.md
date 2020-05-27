[![pub package](https://img.shields.io/pub/v/characters.svg)](https://pub.dev/packages/characters)
[![Build Status](https://travis-ci.org/dart-lang/characters.svg?branch=master)](https://travis-ci.org/dart-lang/characters)


[Characters][] are strings viewed as sequences of **user-perceived character**s, also know as [Unicode (extended) grapheme clusters][Grapheme Clusters].

The `Characters` class allows access to the individual characters of a string, and a way to navigate back and forth between them using a `CharacterRange`.

## Unicode Characters and Representations

There is no such thing as plain text.

Computers only know numbers, so any "text" on a computer is represented by numbers, which are again stored as bytes in memory.

The meaning of those bytes are provided by layers of interpretation, building up to the *glyph*s that the computer displays on the screen.

| Abstraction           | Dart Type                                                    | Usage                                                        | Example                                                      |
| --------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Bytes                 | [ByteBuffer][],<br />[Uint8List][]                           | Physical layout: Memory or network communication.            | `file.readAsBytesSync()`                                     |
| [Code units][]        | [Uint8List][] ( UTF&#x2011;8)<br />[Uint16List][], [String][] (UTF&#x2011;16) | Standard formats for<br /> encoding code points in memory.<br />Stored in memory using one (UTF&#x2011;8) or more (UTF&#x2011;16) bytes. One or more code units encode a code point. | `string.codeUnits`<br />`string.codeUnitAt(index)`<br />`utf8.encode(string)` |
| [Code points][]       | [Runes][]                                                    | The Unicode unit of meaning.                                 | `string.runes`                                               |
| [Grapheme Clusters][] | [Characters][]                                               | Human perceived character. One or more code points.          | `string.characters`                                          |
| [Glyphs][]            |                                                              | Visual rendering of grapheme clusters.                       | `print(string)`                                              |

A Dart `String` is a sequence of UTF-16 code units, just like strings in JavaScript and Java. The runtime system decides on the underlying physical representation.

That makes plain strings inadequate when needing to manipulate the text that a user is viewing, or entering, because they are working at the grapheme cluster level.

For example, to show an abbreviated text like "A long text tha&mldr;", it's necessary to find the first 15 *glyphs*, not just the first fifteen code units or code points. For non-ASCII texts, that's not always the same.

Whenever you need to manipulate strings at the character level, you should be using the `Characters` type, not the methods of the string class.

## The Characters Class

The [Characters][] class exposes a string as a sequence of grapheme clusters. All operations on [Characters][] operate on entire grapheme clusters, so it removes the risk of splitting combined characters or emojis that are inherent in the code-unit based [String][] operations. You can get a [Characters][] object for a string using either the constructor`Characters(string)` or the extension getter `string.characters`.

At its core, the class is an `Iterable<String>` where the element strings are single grapheme clusters. This allows sequential access to the individual grapheme clusters of the original string.

On top of that, there are operations mirroring the operations on [String][] that are not index, code-unit or code-point based, like [startsWith](https://pub.dev/documentation/characters/latest/characters/Characters/startsWith.html) or [`replaceAll`](https://pub.dev/documentation/characters/latest/characters/Characters/replaceAll.html). There are some differences between these and the [String][] operations. For example the replace methods only accept characters as pattern, regular expressions are not grapheme cluster aware, so they cannot be used safely on a sequence of characters.

Grapheme clusters have varying length in the underlying representation, so operations on a [Characters][] sequence cannot be index based. Instead the [CharacterRange][] *iterator* provided by [Characters.iterator][] has been greatly enhanced. It can move both forwards and backwards, and it can span a *range* of grapheme cluster. Most operations that can be performed on a full [Characters][] can also be performed on the grapheme clusters in the range of a [CharacterRange][]. The range can be contracted, expanded or moved in various ways, not restricted to using `moveNext` to move to the next grapheme cluster.

Example:

```dart
// Using String indices.
String firstTagString(String source) {
  var start = string.indexOf("<") + 1;
  if (start > 0) {
    var end = string.indexOf(">", start);
    if (end >= 0) {
	    return string.substring(start, end);
    }
  }
  return null;
}

// Using CharacterRange operations.
Characters firstTagCharacters(Characters source) =>
  var range = source.findFirst("<".characters);
  if (range != null && range.moveUntil(">".characters)) {
    return range.currentCharacters;
  }
  return null;
}
```

[ByteBuffer]: https://api.dart.dev/stable/2.0.0/dart-typed_data/ByteBuffer-class.html	"ByteBuffer class"
[Uint8List]: https://api.dart.dev/stable/2.0.0/dart-typed_data/Uint8List-class.html	"Uint8List class"
[Uint16List]: https://api.dart.dev/stable/2.0.0/dart-typed_data/Uint16List-class.html	"Uint16List class"
[String]: https://api.dart.dev/stable/2.0.0/dart-core/String-class.html	"String class"
[Runes]: https://api.dart.dev/stable/2.0.0/dart-core/Runes-class.html	"Runes class"
[Characters]: https://pub.dev/documentation/characters/latest/characters/Characters-class.html "Characters class"
[CharacterRange]:  https://pub.dev/documentation/characters/latest/characters/CharacterRange-class.html "CharacterRange class"
[Code Units]: https://unicode.org/glossary/#code_unit "Unicode Code Units"
[Code Points]: https://unicode.org/glossary/#code_point "Unicode Code Point"
[Grapheme Clusters]: https://unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries "Unicode (Extended) Grapheme Cluster"
[Characters.iterator]: https://pub.dev/documentation/characters/latest/characters/Characters/iterator.html "[CharactersRange get iterator"
