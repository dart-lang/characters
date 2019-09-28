// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "characters.dart" as i;
import "grapheme_clusters/constants.dart";
import "grapheme_clusters/breaks.dart";

/// The grapheme clusters of a string.
class Characters extends Iterable<String> implements i.Characters {
  // Try to avoid allocating more empty grapheme clusters.
  static const Characters _empty = const Characters._("");

  final String string;

  const Characters._(this.string);

  factory Characters(String string) =>
      string.isEmpty ? _empty : Characters._(string);

  @override
  i.CharacterRange get iterator => CharacterRange._(string, 0, 0);

  @override
  i.CharacterRange get iteratorAtEnd =>
      CharacterRange._(string, string.length, string.length);

  CharacterRange get _rangeAll => CharacterRange._(string, 0, string.length);

  @override
  String get first => string.isEmpty
      ? throw StateError("No element")
      : string.substring(
          0, Breaks(string, 0, string.length, stateSoTNoBreak).nextBreak());

  @override
  String get last => string.isEmpty
      ? throw StateError("No element")
      : string.substring(
          BackBreaks(string, string.length, 0, stateEoTNoBreak).nextBreak());

  @override
  String get single {
    if (string.isEmpty) throw StateError("No element");
    int firstEnd =
        Breaks(string, 0, string.length, stateSoTNoBreak).nextBreak();
    if (firstEnd == string.length) return string;
    throw StateError("Too many elements");
  }

  @override
  bool get isEmpty => string.isEmpty;

  @override
  bool get isNotEmpty => string.isNotEmpty;

  @override
  int get length {
    if (string.isEmpty) return 0;
    var brk = Breaks(string, 0, string.length, stateSoTNoBreak);
    int length = 0;
    while (brk.nextBreak() >= 0) length++;
    return length;
  }

  @override
  Iterable<T> whereType<T>() {
    Iterable<Object> self = this;
    if (self is Iterable<T>) {
      return self.map<T>((x) => x);
    }
    return Iterable<T>.empty();
  }

  @override
  String join([String separator = ""]) {
    if (separator == "") return string;
    return _explodeReplace(string, 0, string.length, separator, "");
  }

  @override
  String lastWhere(bool test(String element), {String orElse()}) {
    int cursor = string.length;
    var brk = BackBreaks(string, cursor, 0, stateEoTNoBreak);
    int next = 0;
    while ((next = brk.nextBreak()) >= 0) {
      String current = string.substring(next, cursor);
      if (test(current)) return current;
      cursor = next;
    }
    if (orElse != null) return orElse();
    throw StateError("no element");
  }

  @override
  String elementAt(int index) {
    RangeError.checkNotNegative(index, "index");
    int count = 0;
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      int start = 0;
      int end = 0;
      while ((end = breaks.nextBreak()) >= 0) {
        if (count == index) return string.substring(start, end);
        count++;
        start = end;
      }
    }
    throw RangeError.index(index, this, "index", null, count);
  }

  @override
  bool contains(Object other) {
    if (other is String) {
      if (other.isEmpty) return false;
      int next = Breaks(other, 0, other.length, stateSoTNoBreak).nextBreak();
      if (next != other.length) return false;
      // [other] is single grapheme cluster.
      return CharacterRange(string)._indexOf(other, 0, string.length) >= 0;
    }
    return false;
  }

  @override
  bool startsWith(i.Characters other) {
    int length = string.length;
    String otherString = other.string;
    if (otherString.isEmpty) return true;
    return string.startsWith(otherString) &&
        isGraphemeClusterBoundary(string, 0, length, otherString.length);
  }

  @override
  bool endsWith(i.Characters other) {
    int length = string.length;
    String otherString = other.string;
    if (otherString.isEmpty) return true;
    int otherLength = otherString.length;
    int start = string.length - otherLength;
    return start >= 0 &&
        string.startsWith(otherString, start) &&
        isGraphemeClusterBoundary(string, 0, length, start);
  }

  @override
  i.Characters replaceAll(i.Characters pattern, i.Characters replacement) =>
      _rangeAll.replaceAll(pattern, replacement);

  @override
  i.Characters replaceFirst(i.Characters pattern, i.Characters replacement) {
    var range = _rangeAll;
    if (!range.collapseToFirst(pattern)) return this;
    return range.replaceRange(replacement);
  }

  @override
  bool containsAll(i.Characters other) =>
      _rangeAll._indexOf(other.string, 0, string.length) >= 0;

  @override
  i.Characters skip(int count) {
    RangeError.checkNotNegative(count, "count");
    if (count == 0) return this;
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      int startIndex = 0;
      while (count > 0) {
        int index = breaks.nextBreak();
        if (index >= 0) {
          count--;
          startIndex = index;
        } else {
          return _empty;
        }
      }
      return Characters(string.substring(startIndex));
    }
    return this;
  }

  @override
  i.Characters take(int count) {
    RangeError.checkNotNegative(count, "count");
    if (count == 0) return _empty;
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      int endIndex = 0;
      while (count > 0) {
        int index = breaks.nextBreak();
        if (index >= 0) {
          count--;
          endIndex = index;
        } else {
          return this;
        }
      }
      return Characters._(string.substring(0, endIndex));
    }
    return this;
  }

  @override
  i.Characters skipWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      int index = 0;
      int startIndex = 0;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(startIndex, index))) {
          if (startIndex == 0) return this;
          return Characters._(string.substring(startIndex));
        }
        startIndex = index;
      }
    }
    return _empty;
  }

  @override
  i.Characters takeWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      int index = 0;
      int endIndex = 0;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(endIndex, index))) {
          if (endIndex == 0) return _empty;
          return Characters._(string.substring(0, endIndex));
        }
        endIndex = index;
      }
    }
    return this;
  }

  @override
  i.Characters where(bool Function(String) test) =>
      Characters(super.where(test).join());

  @override
  i.Characters operator +(i.Characters other) =>
      Characters(string + other.string);

  @override
  i.Characters skipLast(int count) {
    RangeError.checkNotNegative(count, "count");
    if (count == 0) return this;
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      int endIndex = string.length;
      while (count > 0) {
        int index = breaks.nextBreak();
        if (index >= 0) {
          endIndex = index;
          count--;
        } else {
          return _empty;
        }
      }
      return Characters(string.substring(0, endIndex));
    }
    return _empty;
  }

  @override
  i.Characters skipLastWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      int index = 0;
      int end = string.length;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(index, end))) {
          if (end == string.length) return this;
          return Characters(string.substring(0, end));
        }
        end = index;
      }
    }
    return _empty;
  }

  @override
  i.Characters takeLast(int count) {
    RangeError.checkNotNegative(count, "count");
    if (count == 0) return this;
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      int startIndex = string.length;
      while (count > 0) {
        int index = breaks.nextBreak();
        if (index >= 0) {
          startIndex = index;
          count--;
        } else {
          return this;
        }
      }
      return Characters(string.substring(startIndex));
    }
    return this;
  }

  @override
  i.Characters takeLastWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      int index = 0;
      int start = string.length;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(index, start))) {
          return Characters(string.substring(start));
        }
        start = index;
      }
    }
    return this;
  }

  @override
  i.Characters toLowerCase() => Characters(string.toLowerCase());

  @override
  i.Characters toUpperCase() => Characters(string.toUpperCase());

  @override
  bool operator ==(Object other) =>
      other is i.Characters && string == other.string;

  @override
  int get hashCode => string.hashCode;

  @override
  String toString() => string;

  @override
  i.CharacterRange findFirst(i.Characters characters) {
    var range = _rangeAll;
    if (range.collapseToFirst(characters)) return range;
    return null;
  }

  @override
  i.CharacterRange findLast(i.Characters characters) {
    var range = _rangeAll;
    if (range.collapseToLast(characters)) return range;
    return null;
  }
}

class CharacterRange implements i.CharacterRange {
  /// The source string.
  final String _string;

  /// Start index of range in string.
  ///
  /// The index is a code unit index in the [String].
  /// It is always at a grapheme cluster boundary.
  int _start;

  /// End index of range in string.
  ///
  /// The index is a code unit index in the [String].
  /// It is always at a grapheme cluster boundary.
  int _end;

  /// The [current] value is created lazily and cached to avoid repeated
  /// or unnecessary string allocation.
  String _currentCache;

  CharacterRange(String string) : this._(string, 0, 0);
  CharacterRange._(this._string, this._start, this._end);

  /// Changes the current range.
  ///
  /// Resets all cached state.
  void _move(int start, int end) {
    _start = start;
    _end = end;
    _currentCache = null;
  }

  /// Creates a [Breaks] from [_end] to `_string.length`.
  ///
  /// Uses information stored in [_state] for cases where the next
  /// character has already been seen.
  Breaks _breaksFromEnd() {
    return Breaks(_string, _end, _string.length, stateSoTNoBreak);
  }

  /// Creates a [Breaks] from string start to [_start].
  ///
  /// Uses information stored in [_state] for cases where the previous
  /// character has already been seen.
  BackBreaks _backBreaksFromStart() {
    return BackBreaks(_string, _start, 0, stateEoTNoBreak);
  }

  /// Finds [pattern] in the range from [start] to [end].
  ///
  /// Both [start] and [end] are grapheme cluster boundaries in the
  /// [_string] string.
  int _indexOf(String pattern, int start, int end) {
    int patternLength = pattern.length;
    if (patternLength == 0) return start;
    // Any start position after realEnd won't fit the pattern before end.
    int realEnd = end - patternLength;
    if (realEnd < start) return -1;
    // Use indexOf if what we can overshoot is
    // less than twice as much as what we have left to search.
    int rest = _string.length - realEnd;
    if (rest <= (realEnd - start) * 2) {
      int index = 0;
      while (
          start < realEnd && (index = _string.indexOf(pattern, start)) >= 0) {
        if (index > realEnd) return -1;
        if (isGraphemeClusterBoundary(_string, start, end, index) &&
            isGraphemeClusterBoundary(
                _string, start, end, index + patternLength)) {
          return index;
        }
        start = index + 1;
      }
      return -1;
    }
    return _gcIndexOf(pattern, start, end);
  }

  int _gcIndexOf(String pattern, int start, int end) {
    var breaks = Breaks(_string, start, end, stateSoT);
    int index = 0;
    while ((index = breaks.nextBreak()) >= 0) {
      int endIndex = index + pattern.length;
      if (endIndex > end) break;
      if (_string.startsWith(pattern, index) &&
          isGraphemeClusterBoundary(_string, start, end, endIndex)) {
        return index;
      }
    }
    return -1;
  }

  /// Finds pattern in the range from [start] to [end].
  /// Both [start] and [end] are grapheme cluster boundaries in the
  /// [_string] string.
  int _lastIndexOf(String pattern, int start, int end) {
    int patternLength = pattern.length;
    if (patternLength == 0) return end;
    // Start of pattern must be in range [start .. end - patternLength].
    int realEnd = end - patternLength;
    if (realEnd < start) return -1;
    // If the range from 0 to start is no more than double the range from
    // start to end, use lastIndexOf.
    if (realEnd * 2 > start) {
      int index = 0;
      while (realEnd >= start &&
          (index = _string.lastIndexOf(pattern, realEnd)) >= 0) {
        if (index < start) return -1;
        if (isGraphemeClusterBoundary(_string, start, end, index) &&
            isGraphemeClusterBoundary(
                _string, start, end, index + patternLength)) {
          return index;
        }
        realEnd = index - 1;
      }
      return -1;
    }
    return _gcLastIndexOf(pattern, start, end);
  }

  int _gcLastIndexOf(String pattern, int start, int end) {
    var breaks = BackBreaks(_string, end, start, stateEoT);
    int index = 0;
    while ((index = breaks.nextBreak()) >= 0) {
      int startIndex = index - pattern.length;
      if (startIndex < start) break;
      if (_string.startsWith(pattern, startIndex) &&
          isGraphemeClusterBoundary(_string, start, end, startIndex)) {
        return startIndex;
      }
    }
    return -1;
  }

  @override
  String get current =>
      _currentCache ??= (_start == _end ? "" : _string.substring(_start, _end));

  @override
  bool moveNext([int count = 1]) => _advanceEnd(count, _end);

  bool _advanceEnd(int count, int newStart) {
    RangeError.checkNotNegative(count, "count");
    var breaks = _breaksFromEnd();
    int end = _end;
    while (count > 0) {
      int nextBreak = breaks.nextBreak();
      if (nextBreak >= 0) {
        end = nextBreak;
      } else {
        break;
      }
      count--;
    }
    _move(newStart, end);
    return count == 0;
  }

  bool _moveNextPattern(String patternString, int start, int end) {
    int offset = _indexOf(patternString, start, end);
    if (offset >= 0) {
      _move(offset, offset + patternString.length);
      return true;
    }
    return false;
  }

  @override
  bool moveBack([int count = 1]) => _retractStart(count, _start);

  bool _retractStart(int count, int newEnd) {
    RangeError.checkNotNegative(count, "count");
    var breaks = _backBreaksFromStart();
    int start = _start;
    while (count > 0) {
      int nextBreak = breaks.nextBreak();
      if (nextBreak >= 0) {
        start = nextBreak;
      } else {
        break;
      }
      count--;
    }
    _move(start, newEnd);
    return count == 0;
  }

  bool _movePreviousPattern(String patternString, int start, int end) {
    int offset = _lastIndexOf(patternString, start, end);
    if (offset >= 0) {
      _move(offset, offset + patternString.length);
      return true;
    }
    return false;
  }

  @override
  List<int> get codeUnits => _CodeUnits(_string, _start, _end);

  @override
  Runes get runes => Runes(current);

  @override
  i.CharacterRange copy() {
    return CharacterRange._(_string, _start, _end);
  }

  @override
  void collapseToEnd() {
    _move(_end, _end);
  }

  @override
  void collapseToStart() {
    _move(_start, _start);
  }

  @override
  bool dropFirst([int count = 1]) {
    RangeError.checkNotNegative(count, "count");
    if (_start == _end) return count == 0;
    var breaks = Breaks(_string, _start, _end, stateSoTNoBreak);
    while (count > 0) {
      int nextBreak = breaks.nextBreak();
      if (nextBreak >= 0) {
        _start = nextBreak;
        _currentCache = null;
        count--;
      } else {
        return false;
      }
    }
    return true;
  }

  @override
  bool dropTo(i.Characters target) {
    if (_start == _end) return target.isEmpty;
    var targetString = target.string;
    var index = _indexOf(targetString, _start, _end);
    if (index >= 0) {
      _move(index + targetString.length, _end);
      return true;
    }
    return false;
  }

  @override
  bool dropUntil(i.Characters target) {
    if (_start == _end) return target.isEmpty;
    var targetString = target.string;
    var index = _indexOf(targetString, _start, _end);
    if (index >= 0) {
      _move(index, _end);
      return true;
    }
    _move(_end, _end);
    return false;
  }

  @override
  void dropWhile(bool Function(String) test) {
    if (_start == _end) return;
    var breaks = Breaks(_string, _start, _end, stateSoTNoBreak);
    int cursor = _start;
    int next = 0;
    while ((next = breaks.nextBreak()) >= 0) {
      if (!test(_string.substring(cursor, next))) {
        break;
      }
      cursor = next;
    }
    _move(cursor, _end);
  }

  @override
  bool dropLast([int count = 1]) {
    RangeError.checkNotNegative(count, "count");
    var breaks = BackBreaks(_string, _end, _start, stateEoTNoBreak);
    while (count > 0) {
      int nextBreak = breaks.nextBreak();
      if (nextBreak >= 0) {
        _end = nextBreak;
        _currentCache = null;
        count--;
      } else {
        return false;
      }
    }
    return true;
  }

  @override
  bool dropBackTo(i.Characters target) {
    if (_start == _end) return target.isEmpty;
    var targetString = target.string;
    var index = _lastIndexOf(targetString, _start, _end);
    if (index >= 0) {
      _move(_start, index);
      return true;
    }
    return false;
  }

  @override
  bool dropBackUntil(i.Characters target) {
    if (_start == _end) return target.isEmpty;
    var targetString = target.string;
    var index = _lastIndexOf(targetString, _start, _end);
    if (index >= 0) {
      _move(_start, index + targetString.length);
      return true;
    }
    _move(_start, _start);
    return false;
  }

  @override
  void dropBackWhile(bool Function(String) test) {
    if (_start == _end) return;
    var breaks = BackBreaks(_string, _end, _start, stateEoTNoBreak);
    int cursor = _end;
    int next = 0;
    while ((next = breaks.nextBreak()) >= 0) {
      if (!test(_string.substring(next, cursor))) {
        break;
      }
      cursor = next;
    }
    _move(_start, cursor);
  }

  @override
  bool expandNext([int count = 1]) => _advanceEnd(count, _start);

  @override
  bool expandTo(i.Characters target) {
    String targetString = target.string;
    int index = _indexOf(targetString, _end, _string.length);
    if (index >= 0) {
      _move(_start, index + targetString.length);
      return true;
    }
    return false;
  }

  @override
  void expandWhile(bool Function(String character) test) {
    var breaks = _breaksFromEnd();
    int cursor = _end;
    int next = 0;
    while ((next = breaks.nextBreak()) >= 0) {
      if (!test(_string.substring(cursor, next))) {
        break;
      }
      cursor = next;
    }
    _move(_start, cursor);
  }

  @override
  void expandAll() {
    _move(_start, _string.length);
  }

  @override
  bool expandBack([int count = 1]) => _retractStart(count, _end);

  @override
  bool expandBackTo(i.Characters target) {
    var targetString = target.string;
    int index = _lastIndexOf(targetString, 0, _start);
    if (index >= 0) {
      _move(index, _end);
      return true;
    }
    return false;
  }

  @override
  void expandBackWhile(bool Function(String character) test) {
    var breaks = _backBreaksFromStart();
    int cursor = _start;
    int next = 0;
    while ((next = breaks.nextBreak()) >= 0) {
      if (!test(_string.substring(next, cursor))) {
        _move(cursor, _end);
        return;
      }
      cursor = next;
    }
    _move(0, _end);
  }

  @override
  bool expandBackUntil(i.Characters target) {
    return _retractStartUntil(target.string, _end);
  }

  @override
  void expandBackAll() {
    _move(0, _end);
  }

  @override
  bool expandUntil(i.Characters target) {
    return _advanceEndUntil(target.string, _start);
  }

  @override
  bool get isEmpty => _start == _end;

  @override
  bool get isNotEmpty => _start != _end;

  @override
  bool moveBackUntil(i.Characters target) {
    var targetString = target.string;
    return _retractStartUntil(targetString, _start);
  }

  bool _retractStartUntil(String targetString, int newEnd) {
    var index = _lastIndexOf(targetString, 0, _start);
    if (index >= 0) {
      _move(index + targetString.length, newEnd);
      return true;
    }
    _move(0, newEnd);
    return false;
  }

  @override
  bool collapseToFirst(i.Characters target) {
    return _moveNextPattern(target.string, _start, _end);
  }

  @override
  bool collapseToLast(i.Characters target) {
    return _movePreviousPattern(target.string, _start, _end);
  }

  @override
  bool moveUntil(i.Characters target) {
    var targetString = target.string;
    return _advanceEndUntil(targetString, _end);
  }

  bool _advanceEndUntil(String targetString, int newStart) {
    int index = _indexOf(targetString, _end, _string.length);
    if (index >= 0) {
      _move(newStart, index);
      return true;
    }
    _move(newStart, _string.length);
    return false;
  }

  @override
  i.Characters replaceFirst(i.Characters pattern, i.Characters replacement) {
    String patternString = pattern.string;
    String replacementString = replacement.string;
    if (patternString.isEmpty) {
      return Characters(
          _string.replaceRange(_start, _start, replacementString));
    }
    int index = _indexOf(patternString, _start, _end);
    String result = _string;
    if (index >= 0) {
      result = _string.replaceRange(
          index, index + patternString.length, replacementString);
    }
    return Characters(result);
  }

  @override
  i.Characters replaceAll(i.Characters pattern, i.Characters replacement) {
    var patternString = pattern.string;
    var replacementString = replacement.string;
    if (patternString.isEmpty) {
      var replaced = _explodeReplace(
          _string, _start, _end, replacementString, replacementString);
      return Characters(replaced);
    }
    if (_start == _end) return i.Characters(_string);
    int start = 0;
    int cursor = _start;
    StringBuffer buffer;
    while ((cursor = _indexOf(patternString, cursor, _end)) >= 0) {
      (buffer ??= StringBuffer())
        ..write(_string.substring(start, cursor))
        ..write(replacementString);
      cursor += patternString.length;
      start = cursor;
    }
    if (buffer == null) return i.Characters(_string);
    buffer.write(_string.substring(start));
    return i.Characters(buffer.toString());
  }

  @override
  i.Characters replaceRange(i.Characters replacement) {
    return i.Characters(_string.replaceRange(_start, _end, replacement.string));
  }

  @override
  i.Characters get source => i.Characters(_string);

  @override
  bool startsWith(i.Characters characters) {
    return _startsWith(_start, _end, characters.string);
  }

  @override
  bool endsWith(i.Characters characters) {
    return _endsWith(_start, _end, characters.string);
  }

  @override
  bool isFollowedBy(i.Characters characters) {
    return _startsWith(_end, _string.length, characters.string);
  }

  @override
  bool isPrecededBy(i.Characters characters) {
    return _endsWith(0, _start, characters.string);
  }

  bool _endsWith(int start, int end, String string) {
    int length = string.length;
    int stringStart = end - length;
    return stringStart >= start &&
        _string.startsWith(string, stringStart) &&
        isGraphemeClusterBoundary(_string, start, end, stringStart);
  }

  bool _startsWith(int start, int end, String string) {
    int length = string.length;
    int stringEnd = start + length;
    return stringEnd <= end &&
        _string.startsWith(string, start) &&
        isGraphemeClusterBoundary(_string, start, end, stringEnd);
  }

  @override
  bool moveBackTo(i.Characters target) {
    var targetString = target.string;
    int index = _lastIndexOf(targetString, 0, _start);
    if (index >= 0) {
      _move(index, index + targetString.length);
      return true;
    }
    return false;
  }

  @override
  bool moveTo(i.Characters target) {
    var targetString = target.string;
    int index = _indexOf(targetString, _end, _string.length);
    if (index >= 0) {
      _move(index, index + targetString.length);
      return true;
    }
    return false;
  }
}

class _CodeUnits extends ListBase<int> {
  final String _string;
  final int _start;
  final int _end;

  _CodeUnits(this._string, this._start, this._end);

  int get length => _end - _start;

  int operator [](int index) {
    RangeError.checkValidIndex(index, this, "index", _end - _start);
    return _string.codeUnitAt(_start + index);
  }

  void operator []=(int index, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  @override
  void set length(int newLength) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }
}

String _explodeReplace(String string, int start, int end,
    String internalReplacement, String outerReplacement) {
  if (start == end) {
    return string.replaceRange(start, start, outerReplacement);
  }
  var buffer = StringBuffer(string.substring(0, start));
  var breaks = Breaks(string, start, end, stateSoTNoBreak);
  int index = 0;
  String replacement = outerReplacement;
  while ((index = breaks.nextBreak()) >= 0) {
    buffer..write(replacement)..write(string.substring(start, index));
    start = index;
    replacement = internalReplacement;
  }
  buffer..write(outerReplacement)..write(string.substring(end));
  return buffer.toString();
}
