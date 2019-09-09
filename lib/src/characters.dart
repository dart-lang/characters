// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";

import "grapheme_clusters/constants.dart";
import "grapheme_clusters/breaks.dart";

part "characters_impl.dart";

/// The characters of a string.
///
/// A character is a Unicode Grapheme cluster represented
/// by a substring of the original string.
/// The `Characters` class is an [Iterable] of those strings.
/// However, unlike most iterables, many of the operations are
/// *eager*. Since the underlying string is known in its entirety,
/// and is known not to change, operations which select a subset of
/// the elements can be computed eagerly, and in that case the
/// operation returns a new `Characters` object.
abstract class Characters implements Iterable<String> {
  /// Creates a [Characters] allowing iteration of
  /// the characters of [string].
  factory Characters(String string) = _Characters;

  /// The string to iterate over.
  String get string;

  /// A specialized character iterator.
  ///
  /// Allows iterating the characters of [string] as a plain iterator,
  /// as well as controlling the iteration in more detail.
  CharacterRange get iterator;

  /// A specialized character iterator positioned at the end.
  ///
  /// Allows iterating the characters of [string] backwards from the end.
  CharacterRange get iteratorEnd;

  /// Whether [Character] is an element of this sequence of
  /// characters.
  ///
  /// Returns false if [Character] is not a string containing
  /// a single character,
  /// because then it is not a single element of this [Iterable]
  /// of characters.
  bool contains(Object Character);

  /// Whether this sequence of characters contains [other]
  /// as a subsequence.
  bool containsAll(Characters other);

  /// Whether [other] is an initial subsequence of this sequence
  /// of characters.
  ///
  /// Returns `true` if [other] is a leading sub-sequence of this sequence of
  /// characters.
  bool startsWith(Characters other);

  /// Whether [other] is an trailing subsequence of this sequence
  /// of characters.
  ///
  /// Returns `true` if [other] is a tailing sub-sequence of this sequence of
  /// characters, and `false` otherwise.
  bool endsWith(Characters other);

  /// Finds the first occurrence of [characters].
  ///
  /// Returns a [CharacterRange] containing the first occurrence of
  /// [characters]. Returns `null` if there is no such occurrence,
  CharacterRange findFirst(Characters characters);

  /// Finds the last occurrence of [characters].
  ///
  /// Returns a [CharacterRange] containing the last occurrence of
  /// [characters]. Returns `null` if there is no such occurrence,
  CharacterRange findLast(Characters characters);

  /// Eagerly selects a subset of the characters.
  ///
  /// Tests each character against [test], and returns the
  /// characters of the concatenation of those character strings.
  Characters where(bool Function(String) test);

  /// Eagerly selects all but the first [count] characters.
  ///
  /// If [count] is greater than [length], the count of character
  /// available, then the empty sequence of characters
  /// is returned.
  Characters skip(int count);

  /// Eagerly selects the first [count] characters.
  ///
  /// If [count] is greater than [length], the count of character
  /// available, then the entire sequence of characters
  /// is returned.
  Characters take(int count);

  /// Eagerly selects all but the last [count] characters.
  ///
  /// If [count] is greater than [length], the count of character
  /// available, then the empty sequence of characters
  /// is returned.
  Characters skipLast(int count);

  /// Eagerly selects the last [count] characters.
  ///
  /// If [count] is greater than [length], the count of character
  /// available, then the entire sequence of characters
  /// is returned.
  Characters takeLast(int count);

  /// Eagerly selects a trailing sequence of characters.
  ///
  /// Checks each character, from first to last, against [test],
  /// until one is found whwere [test] returns `false`.
  /// The characters starting with the first one
  /// where [test] returns `false`, are included in the result.
  ///
  /// If no characters test `false`, the result is an empty sequence
  /// of characters.
  Characters skipWhile(bool Function(String) test);

  /// Eagerly selects a leading sequnce of characters.
  ///
  /// Checks each character, from first to last, against [test],
  /// until one is found whwere [test] returns `false`.
  /// The characters up to, but not including, the first one
  /// where [test] returns `false` are included in the result.
  ///
  /// If no characters test `false`, the entire sequence of character
  /// is returned.
  Characters takeWhile(bool Function(String) test);

  /// Eagerly selects a leading sequnce of characters.
  ///
  /// Checks each character, from last to first, against [test],
  /// until one is found whwere [test] returns `false`.
  /// The characters up to and including the one with the latest index
  /// where [test] returns `false` are included in the result.
  ///
  /// If no characters test `false`, the empty sequence of character
  /// is returned.
  Characters skipLastWhile(bool Function(String) test);

  /// Eagerly selects a trailing sequence of characters.
  ///
  /// Checks each character, from last to first, against [test],
  /// until one is found whwere [test] returns `false`.
  /// The characters after the one with the latest index where
  /// [test] returns `false` are included in the result.
  ///
  /// If no characters test `false`, the entire sequence of character
  /// is returned.
  Characters takeLastWhile(bool Function(String) test);

  /// The characters of the concatenation of this and [other].
  ///
  /// This is the characters of the concatenation of the underlying
  /// strings. If there is no character break at the concatenation
  /// point in the resulting string, then the result is not the concatenation
  /// of the two character sequences.
  ///
  /// This differs from [followedBy] which provides the lazy concatenation
  /// of this sequence of strings with any other sequence of strings.
  Characters operator +(Characters other);

  /// Replaces [source] with [replacement].
  ///
  /// Returns a new [GrapehemeClusters] where all occurrences of the
  /// [source] character sequence are replaced by [replacement],
  /// unless the occurrence overlaps a prior replaced sequence.
  Characters replaceAll(Characters source, Characters replacement);

  /// Replaces the first [source] with [replacement].
  ///
  /// Returns a new [Characters] where the first occurence of the
  /// [source] character sequence, if any, is replaced by [replacement].
  Characters replaceFirst(Characters source, Characters replacement);

  /// The characters of the lower-case version of [string].
  Characters toLowerCase();

  /// The characters of the upper-case version of [string].
  Characters toUpperCase();

  /// The hash code of [string].
  int get hashCode;

  /// Whether [other] to another [Characters] with the same [string].
  bool operator ==(Object other);

  /// The [string] content of these characters.
  String toString();
}

/// A sub-sequence of a [Characters].
///
/// The sub-sequence is a range of consecutive characters in [source],
/// corresponding to a start and end position in the source sequence.
/// The range may even be empty, but will still correspond to a position,
/// only one where start and end is the same position.
///
/// The source sequence can be separated into the *previous* characters,
/// those before the range, the range itself, and the *next* characters,
/// those after the range.
///
/// Inside the range, operations may look at the *first* characters of the
/// range, those right after the range start,
/// or the *last* characters of the range, those right before the range end.
///
/// The range of a [CharacterRange] can be updated to include more
/// characters at either end, or to drop characters from either end,
/// or to simply move to a completely new range.
///
/// The character range implements [Iterator]
/// (actually an [BidirectionalIterator] of [String]).
/// The [moveNext] operation, when called with no argument,
/// iterates the *next* single characters of the [source] sequence.
abstract class CharacterRange implements BidirectionalIterator<String> {
  /// Creates a new character iterator iterating the character
  /// of [string].
  factory CharacterRange(String string) = _CharacterRange;

  /// The character sequence that this range is a sub-sequence of.
  Characters get source;

  /// The code units of the current character range.
  List<int> get codeUnits;

  /// The code points of the current character range.
  Runes get runes;

  /// Creates a copy of this [Character].
  ///
  /// The copy is in the exact same state as this iterator.
  /// Can be used to iterate the following characters more than once
  /// at the same time. To simply rewind an iterator, remember the
  /// [start] or [end] position and use [reset] to reset the iterator
  /// to that position.
  CharacterRange copy();

  /// Whether the current range is empty.
  ///
  /// An empty range has no characters, but still has a position as
  /// a sub-sequence of the source character sequence.
  bool get isEmpty;

  /// Whether the current range is not empty.
  ///
  /// A non-empty range contains at least one character.
  bool get isNotEmpty;

  /// Makes the range be next occurrence of [target] after the current range.
  ///
  /// If [target] is omitted, the range becomes the next single character
  /// after the current range, if any.
  ///
  /// If [target] does not occur in the source sequence after the
  /// current range, this operation collapses the range to the
  /// end of the current range, as by [collapesEnd].
  ///
  /// Returns `true` if [target] was found and `false` if not.
  bool moveNext([Characters target]);

  /// Makes the range be the characters up to the next occurrence of [target].
  ///
  /// If there is an occurrence of [target] after the current range,
  /// the new range starts at the end of the current range, and ends just
  /// before the first such occurrence of [target].
  ///
  /// If there is no occurrence of [target] after the current range,
  /// the range is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if not.
  bool moveUntilNext(Characters target);

  /// Makes the range be previous occurrence of [target] before the current range.
  ///
  /// If [target] is omitted, the range becomes the previous single character
  /// before the current range, if any.
  ///
  /// If [target] does not occur in the source sequence before the
  /// current range, this operation collapses the range to the
  /// start of the current range, as by [collapesStart].
  ///
  /// Returns `true` if [target] was found and `false` if not.
  bool movePrevious([Characters target]);

  /// Makes the range be the characters after to the previous occurrence of [target].
  ///
  /// If there is an occurrence of [target] before the current range,
  /// the new range starts at the end of the last such occurrence of [target],
  /// and ends at the start of the current range.
  ///
  /// If there is no occurrence of [target] after the current range,
  /// the range is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if not.
  bool moveAfterPrevious(Characters target);

  /// Collapses the range to its start.
  ///
  /// Changes the range to end at its start.
  /// The resulting range is always empty.
  void collapseStart();

  /// Collapses the range to its end.
  ///
  /// Changes the range to start at its end.
  /// The resulting range is always empty.
  void collapseEnd();

  /// Finds the first instance of [target] inside the current range.
  ///
  /// If there is no occurrence of [target] in the current range,
  /// then the range is not modified.
  ///
  /// If [target] is omitted, moves to the first single character
  /// inside the current range, if the range is non-empty.
  /// If the range is empty, it is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if it is not.
  bool moveFirst([Characters target]);

  /// Finds the last instance of [target] inside the current range.
  ///
  /// If there is no occurrence of [target] in the current range,
  /// then the range is not modified.
  ///
  /// If [target] is omitted, moves to the last single character
  /// inside the current range, if the range is non-empty.
  /// If the range is empty, it is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if it is not.
  bool moveLast([Characters target]);

  /// Starts the range at the start of the source characters.
  ///
  /// Changes the range to include all characters of the source sequence
  /// from its beginngin until the current range end.
  void includeAllPrevious();

  /// Ends the range at the end of the source characters.
  ///
  /// Changes the range to include all characters of the source sequence
  /// from the current range start to the end of the source character sequence.
  void includeAllNext();

  /// Includes the next occurrence of [target] into the current range.
  ///
  /// Finds the next occurrence of [target] after the current range,
  /// then changes the end of the range to be after that occurence of [target].
  ///
  /// If there is no occurrence of [target] after the current range,
  /// the range is not modified.
  ///
  /// If [target] is omitted, the next single character after the current
  /// range is used instead, if any. If there are no characters after the
  /// current range, the range is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if not.
  bool includeNext([Characters target]);

  /// Includes characters until the next occurrence of [target] into the current range.
  ///
  /// Finds the next occurrence of [target] after the current range,
  /// then changes the end of the range to be before that occurence of [target].
  ///
  /// If there is no occurrence of [target] after the current range,
  /// the range is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if not.
  bool includeUntilNext(Characters target);

  /// Includes the next single characters while they are accepted by [test].
  ///
  /// Each of the next single characters after the current range are
  /// tested, in first-to-last order, using [test] until reaching the end
  /// or until the call to [test] returns `false`.
  /// The end of the range is changed to the end of the most recent character
  /// accepted by [test].
  void includeNextWhile(bool test(String character));

  /// Includes the previous occurrence of [target] into the current range.
  ///
  /// Finds the previous occurrence of [target] before the current range,
  /// then changes the end of the range to be before that occurence of [target].
  ///
  /// If there is no occurrence of [target] before the current range,
  /// the range is not modified.
  ///
  /// If [target] is omitted, the previous single character before the current
  /// range is used instead, if any. If there are no before after the
  /// current range, the range is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if not.
  bool includePrevious([Characters target]);

  /// Includes characters after the previous occurrence of [target].
  ///
  /// Finds the previous occurrence of [target] before the current range,
  /// then changes the start of the range to be after that occurence of [target].
  ///
  /// If there is no occurrence of [target] before the current range,
  /// the range is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if not.
  bool includeAfterPrevious(Characters target);

  /// Includes the previous single characters while they are accepted by [test].
  ///
  /// Each of the previous single characters before the current range,
  /// in last-to-first order, are tested using [test] until reaching the end
  /// or until the call to [test] returns `false`.
  /// The start of the range is changed to the start of the most recent character
  /// accepted by [test].
  void includePreviousWhile(bool test(String character));

  /// Drops the first occurrence of [target] from the current range.
  ///
  /// Drops characters from the start of the range up to, and including,
  /// the first occurrence of [target] in the range.
  /// Finds the first occurrence of [target] in the current range,
  /// then changes the start of the range to be after that occurence of [target].
  ///
  /// If there is no occurrence of [target] in the current range,
  /// the range is not modified.
  ///
  /// If [target] is omitted, the first single character of the current
  /// range is used instead, if any. If the current range is empty,
  /// the range is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if not.
  bool dropFirst([Characters target]);

  /// Drops characters before the first occurrence of [target].
  ///
  /// Drops characters from the start of the range up to, but not including,
  /// the first occurrence of [target] in the range.
  /// Finds the first occurrence of [target] in the current range,
  /// then changes the start of the range to be before that occurence of [target].
  ///
  /// If there is no occurrence of [target] in the current range,
  /// the range is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if not.
  bool dropUntilFirst(Characters target);

  /// Drops characters from the last occurrence of [target].
  ///
  /// Drops characters from the end of the range back to, and including,
  /// the last occurrence of [target] in the range.
  /// Finds the last occurrence of [target] in the current range,
  /// then changes the end of the range to be before that occurence of [target].
  ///
  /// If there is no occurrence of [target] in the current range,
  /// the range is not modified.
  ///
  /// If [target] is omitted, the last single character of the current
  /// range is used instead, if any. If the current range is empty,
  /// the range is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if not.
  bool dropLast([Characters target]);

  /// Drops characters afer the last occurrence of [target] from the current range.
  ///
  /// Drops characters from the end of the range back to, but not including,
  /// the last occurrence of [target] in the range.
  /// Finds the last occurrence of [target] in the current range,
  /// then changes the end of the range to be after that occurence of [target].
  ///
  /// If there is no occurrence of [target] in the current range,
  /// the range is not modified.
  ///
  /// Returns `true` if the range is modified and `false` if not.
  bool dropAfterLast(Characters target);

  /// Drops initial single characters accepted by [test].
  ///
  /// Calls [test] on each single character of the range, in first-to-last
  /// order, until [test] returns `false` or until reaching the end of the range.
  /// Then changes the start of the range to the end of the most recent
  /// character which [test] accepted.
  void dropFirstWhile(bool test(String characters));

  /// Drops final single characters accepted by [test].
  ///
  /// Calls [test] on each single character of the range, in last-to-first
  /// order, until [test] returns `false` or until reaching the end of the range.
  /// Then changes the end of the range to the start of the most recent
  /// character which [test] accepted.
  void dropLastWhile(bool test(String characters));

  /// Creates a new [Characters] sequence by replacing the current range.
  ///
  /// Replaces the current range in of the source sequence with [replacement].
  ///
  /// Returns a new [Characters] instance. Since the inserted characters
  /// may combine with the previous or next characters, grapheme cluster
  /// boundaries need to be recomputed from scratch.
  Characters replaceRange(Characters replacement);

  /// Replaces all occurrences of [pattern] in the range with [replacement].
  ///
  /// Replaces the first occurrence of [pattern] in the range, then repeatedly
  /// finds and replaces the next occurrence which does not overlap with
  /// the earlier, already replaced, occurrence.
  ///
  /// Returns [source] if there are no occurrences of [pattern]
  /// in the current range, otherwise returns a new [Characters] instance.
  Characters replaceAll(Characters pattern, Characters replacement);
}
