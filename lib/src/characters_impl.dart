// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "characters.dart";

/// The grapheme clusters of a string.
class _Characters extends Iterable<String> implements Characters {
  // Try to avoid allocating more empty grapheme clusters.
  static const Characters _empty = const _Characters._("");

  final String string;

  const _Characters._(this.string);

  factory _Characters(String string) =>
      string.isEmpty ? _empty : _Characters._(string);

  @override
  CharacterRange get iterator =>
      _CharacterRange._(string, 0, 0, stateSoTNoBreak);

  @override
  CharacterRange get iteratorEnd =>
      _CharacterRange._(string, string.length, string.length, stateSoTNoBreak);

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
    return _explodeReplace(separator, "", 0);
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
      return _indexOf(other, 0) >= 0;
    }
    return false;
  }

  /// Finds first occurrence of [otherString] at grapheme cluster boundaries.
  ///
  /// Only finds occurrences starting at or after [startIndex].
  int _indexOf(String otherString, int startIndex) {
    int otherLength = otherString.length;
    if (otherLength == 0) {
      return nextBreak(string, 0, string.length, startIndex);
    }
    int length = string.length;
    while (startIndex + otherLength <= length) {
      int matchIndex = string.indexOf(otherString, startIndex);
      if (matchIndex < 0) return matchIndex;
      if (isGraphemeClusterBoundary(string, 0, length, matchIndex) &&
          isGraphemeClusterBoundary(
              string, 0, length, matchIndex + otherLength)) {
        return matchIndex;
      }
      startIndex = matchIndex + 1;
    }
    return -1;
  }

  /// Finds last occurrence of [otherString] at grapheme cluster boundaries.
  ///
  /// Starts searching backwards at [startIndex].
  int _lastIndexOf(String otherString, int startIndex) {
    int otherLength = otherString.length;
    if (otherLength == 0) {
      return previousBreak(string, 0, string.length, startIndex);
    }
    int length = string.length;
    while (startIndex >= 0) {
      int matchIndex = string.lastIndexOf(otherString, startIndex);
      if (matchIndex < 0) return matchIndex;
      if (isGraphemeClusterBoundary(string, 0, length, matchIndex) &&
          isGraphemeClusterBoundary(
              string, 0, length, matchIndex + otherLength)) {
        return matchIndex;
      }
      startIndex = matchIndex - 1;
    }
    return -1;
  }

  @override
  bool startsWith(Characters other) {
    int length = string.length;
    String otherString = other.string;
    if (otherString.isEmpty) return true;
    return string.startsWith(otherString) &&
        isGraphemeClusterBoundary(string, 0, length, otherString.length);
  }

  @override
  bool endsWith(Characters other) {
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
  Characters replaceAll(Characters pattern, Characters replacement) {
    if (pattern.string.isEmpty) {
      if (string.isEmpty) return replacement;
      var replacementString = replacement.string;
      return Characters(
          _explodeReplace(replacementString, replacementString, 0));
    }
    int start = 0;
    StringBuffer buffer;
    int next = -1;
    String patternString = pattern.string;
    while ((next = this._indexOf(patternString, start)) >= 0) {
      (buffer ??= StringBuffer())
        ..write(string.substring(start, next))
        ..write(replacement);
      start = next + patternString.length;
    }
    if (buffer == null) return this;
    buffer.write(string.substring(start));
    return Characters(buffer.toString());
  }

  // Replaces every internal grapheme cluster boundary with
  // [internalReplacement] and adds [outerReplacement] at both ends
  // Starts at [startIndex].
  String _explodeReplace(
      String internalReplacement, String outerReplacement, int startIndex) {
    var buffer = StringBuffer(string.substring(0, startIndex));
    var breaks = Breaks(string, startIndex, string.length, stateSoTNoBreak);
    int index = 0;
    String replacement = outerReplacement;
    while ((index = breaks.nextBreak()) >= 0) {
      buffer..write(replacement)..write(string.substring(startIndex, index));
      startIndex = index;
      replacement = internalReplacement;
    }
    buffer.write(outerReplacement);
    return buffer.toString();
  }

  @override
  Characters replaceFirst(Characters pattern, Characters replacement) {
    String patternString = pattern.string;
    int index = _indexOf(patternString, 0);
    if (index < 0) return this;
    return Characters(string.replaceRange(
        index, index + patternString.length, replacement.string));
  }

  @override
  bool containsAll(Characters other) {
    return _indexOf(other.string, 0) >= 0;
  }

  @override
  Characters skip(int count) {
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
      return _Characters(string.substring(startIndex));
    }
    return this;
  }

  @override
  Characters take(int count) {
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
      return _Characters._(string.substring(0, endIndex));
    }
    return this;
  }

  @override
  Characters skipWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      int index = 0;
      int startIndex = 0;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(startIndex, index))) {
          if (startIndex == 0) return this;
          return _Characters._(string.substring(startIndex));
        }
        startIndex = index;
      }
    }
    return _empty;
  }

  @override
  Characters takeWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = Breaks(string, 0, string.length, stateSoTNoBreak);
      int index = 0;
      int endIndex = 0;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(endIndex, index))) {
          if (endIndex == 0) return _empty;
          return _Characters._(string.substring(0, endIndex));
        }
        endIndex = index;
      }
    }
    return this;
  }

  @override
  Characters where(bool Function(String) test) =>
      _Characters(super.where(test).join());

  @override
  Characters operator +(Characters other) => _Characters(string + other.string);

  @override
  Characters skipLast(int count) {
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
      return _Characters(string.substring(0, endIndex));
    }
    return _empty;
  }

  @override
  Characters skipLastWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      int index = 0;
      int end = string.length;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(index, end))) {
          if (end == string.length) return this;
          return _Characters(string.substring(0, end));
        }
        end = index;
      }
    }
    return _empty;
  }

  @override
  Characters takeLast(int count) {
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
      return _Characters(string.substring(startIndex));
    }
    return this;
  }

  @override
  Characters takeLastWhile(bool Function(String) test) {
    if (string.isNotEmpty) {
      var breaks = BackBreaks(string, string.length, 0, stateEoTNoBreak);
      int index = 0;
      int start = string.length;
      while ((index = breaks.nextBreak()) >= 0) {
        if (!test(string.substring(index, start))) {
          return _Characters(string.substring(start));
        }
        start = index;
      }
    }
    return this;
  }

  @override
  Characters toLowerCase() => _Characters(string.toLowerCase());

  @override
  Characters toUpperCase() => _Characters(string.toUpperCase());

  @override
  bool operator ==(Object other) =>
      other is Characters && string == other.string;

  @override
  int get hashCode => string.hashCode;

  @override
  String toString() => string;

  @override
  CharacterRange findFirst(Characters characters) {
    var range = _CharacterRange._(string, 0, string.length, stateSoTNoBreak);
    if (range.moveFirst(characters)) return range;
    return null;
  }

  @override
  CharacterRange findLast(Characters characters) {
    var range = _CharacterRange._(string, 0, string.length, stateSoTNoBreak);
    if (range.moveLast(characters)) return range;
    return null;
  }
}

class _CharacterRange implements CharacterRange {
  static const int _directionForward = 0;
  static const int _directionBackward = 0x04;
  static const int _directionMask = 0x04;
  static const int _cursorDeltaMask = 0x03;

  final String _string;
  int _start;
  int _end;
  // Encodes current state,
  // whether we are moving forwards or backwards ([_directionMask]),
  // and how far ahead the cursor is from the start/end ([_cursorDeltaMask]).
  int _state;
  // The [current] value is created lazily and cached to avoid repeated
  // or unnecessary string allocation.
  String _currentCache;

  _CharacterRange(String string) : this._(string, 0, 0, stateSoTNoBreak);
  _CharacterRange._(this._string, this._start, this._end, this._state);

  @override
  String get current =>
      _currentCache ??= (_start == _end ? "" : _string.substring(_start, _end));

  @override
  bool moveNext([Characters pattern]) {
    if (pattern == null) {
      int state = _state;
      int cursor = _end;
      if (state & _directionMask != _directionForward) {
        state = stateSoTNoBreak;
      } else {
        cursor += state & _cursorDeltaMask;
      }
      var breaks = Breaks(_string, cursor, _string.length, state);
      var next = breaks.nextBreak();
      _currentCache = null;
      _start = _end;
      if (next >= 0) {
        _end = next;
        _state =
            (breaks.state & 0xF0) | _directionForward | (breaks.cursor - next);
        return true;
      }
      _state = stateEoTNoBreak | _directionBackward;
      return false;
    }
    return _moveNext(pattern);
  }

  /// Finds [pattern] in the range from [start] to [end].
  ///
  /// Both [start] and [end] are grapheme cluster boundaries in the
  /// [_string] string.
  int _indexOf(String pattern, int start, int end) {
    var breaks = Breaks(_string, start, end, stateSoT);
    int index = 0;
    while ((index = breaks.nextBreak()) >= 0 && index + pattern.length <= end) {
      if (_string.startsWith(pattern, index) &&
          isGraphemeClusterBoundary(
              _string, start, end, index + pattern.length)) {
        return index;
      }
    }
    return -1;
  }

  /// Finds pattern in the range from [start] to [end].
  /// Both [start] and [end] are grapheme cluster boundaries in the
  /// [_string] string.
  int _lastIndexOf(String pattern, int start, int end) {
    if (pattern.isEmpty) return end;
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

  // Changes the current range.
  void _move(int start, int end) {
    _start = start;
    _end = end;
    _currentCache = null;
    _state = stateSoTNoBreak;
  }

  bool _moveNext(Characters pattern) {
    var patternString = pattern.string;
    int offset = _indexOf(patternString, _end, _string.length);
    if (offset >= 0) {
      _move(offset, offset + patternString.length);
      return true;
    }
    return false;
  }

  bool movePrevious([Characters pattern]) {
    if (pattern == null) {
      int state = _state;
      int cursor = _start;
      if (state & _directionMask == _directionForward) {
        state = stateEoTNoBreak;
      } else {
        cursor -= state & _cursorDeltaMask;
      }
      var breaks = BackBreaks(_string, cursor, 0, state);
      var next = breaks.nextBreak();
      _currentCache = null;
      _end = _start;
      if (next >= 0) {
        _start = next;
        _state =
            (breaks.state & 0xF0) | _directionBackward | (next - breaks.cursor);
        return true;
      }
      _state = stateSoTNoBreak | _directionForward;
      return false;
    }
    return _movePrevious(pattern);
  }

  bool _movePrevious(Characters pattern) {
    var patternString = pattern.string;
    int offset = _lastIndexOf(patternString, 0, _start);
    if (offset >= 0) {
      _move(offset, offset + patternString.length);
      return true;
    }
    return false;
  }

  List<int> get codeUnits => _CodeUnits(_string, _start, _end);

  Runes get runes => Runes(current);

  void reset(int index) {
    RangeError.checkValueInInterval(index, 0, _string.length, "index");
    _reset(index);
  }

  void resetStart() {
    _reset(0);
  }

  void resetEnd() {
    _state = stateEoTNoBreak | _directionBackward;
    _currentCache = null;
    _start = _end = _string.length;
  }

  void _reset(int index) {
    _state = stateSoTNoBreak | _directionForward;
    _currentCache = null;
    _start = _end = index;
  }

  CharacterRange copy() {
    return _CharacterRange._(_string, _start, _end, _state);
  }

  @override
  void collapseEnd() {
    _move(_end, _end);
  }

  @override
  void collapseStart() {
    _move(_start, _start);
  }

  @override
  bool dropAfterLast(Characters target) {
    var targetString = target.string;
    var index = _lastIndexOf(targetString, _start, _end);
    if (index >= 0) {
      _move(_start, index + targetString.length);
      return true;
    }
    return false;
  }

  @override
  bool dropFirst([Characters target]) {
    if (_start == _end) return false;
    if (target == null) {
      _move(nextBreak(_string, _start, _end, _start + 1), _end);
      return true;
    }
    var targetString = target.string;
    var index = _indexOf(targetString, _start, _end);
    if (index >= 0) {
      _move(index + targetString.length, _end);
      return true;
    }
    return false;
  }

  @override
  void dropFirstWhile(bool Function(String) test) {
    if (_start == _end) return;
    var breaks = Breaks(_string, _start, _end, stateSoTNoBreak);
    int cursor = _start;
    int next = 0;
    while ((next = breaks.nextBreak()) >= 0) {
      if (!test(_string.substring(cursor, next))) {
        _move(cursor, _end);
        return;
      }
      cursor = next;
    }
    _move(_end, _end);
  }

  @override
  bool dropLast([Characters target]) {
    if (_start == _end) return false;
    if (target == null) {
      _move(_start, previousBreak(_string, _start, _end, _end - 1));
      return true;
    }
    var targetString = target.string;
    var index = _lastIndexOf(targetString, _start, _end);
    if (index >= 0) {
      _move(_start, index);
      return true;
    }
    return false;
  }

  @override
  void dropLastWhile(bool Function(String) test) {
    if (_start == _end) return;
    var breaks = BackBreaks(_string, _end, _start, stateEoTNoBreak);
    int cursor = _end;
    int next = 0;
    while ((next = breaks.nextBreak()) >= 0) {
      if (!test(_string.substring(next, cursor))) {
        _move(_start, cursor);
        return;
      }
      cursor = next;
    }
    _move(_start, _start);
  }

  @override
  bool dropUntilFirst(Characters target) {
    if (_start == _end) return false;
    var targetString = target.string;
    int index = _indexOf(targetString, _start, _end);
    if (index >= 0) {
      _move(index, _end);
      return true;
    }
    return false;
  }

  @override
  bool includeAfterPrevious(Characters target) {
    var targetString = target.string;
    int index = _lastIndexOf(targetString, 0, _start);
    if (index >= 0) {
      _move(index + targetString.length, _end);
      return true;
    }
    return false;
  }

  @override
  void includeAllNext() {
    _move(_start, _string.length);
  }

  @override
  void includeAllPrevious() {
    _move(0, _end);
  }

  @override
  bool includeNext([Characters target]) {
    if (target == null) {
      if (_end == _string.length) return false;
      _move(_start, nextBreak(_string, _start, _string.length, _end));
      return true;
    }
    String targetString = target.string;
    int index = _indexOf(targetString, _end, _string.length);
    if (index >= 0) {
      _move(_start, index + targetString.length);
      return true;
    }
    return false;
  }

  @override
  void includeNextWhile(bool Function(String character) test) {
    var breaks = Breaks(_string, _end, _string.length, stateSoTNoBreak);
    int cursor = _end;
    int next = 0;
    while ((next = breaks.nextBreak()) >= 0) {
      if (!test(_string.substring(cursor, next))) {
        _move(_start, cursor);
        return;
      }
      cursor = next;
    }
    _move(_start, _string.length);
  }

  @override
  bool includePrevious([Characters target]) {
    if (target == null) {
      if (_start == 0) return false;
      _move(previousBreak(_string, 0, _end, _start), _end);
      return true;
    }
    var targetString = target.string;
    int index = _lastIndexOf(targetString, 0, _start);
    if (index >= 0) {
      if (index + targetString.length > _start) throw (index);
      _move(index, _end);
      return true;
    }
    return false;
  }

  @override
  void includePreviousWhile(bool Function(String character) test) {
    var breaks = BackBreaks(_string, _start, 0, stateEoTNoBreak);
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
  bool includeUntilNext(Characters target) {
    var targetString = target.string;
    var index = _indexOf(targetString, _end, _string.length);
    if (index >= 0) {
      _move(_start, index);
      return true;
    }
    return false;
  }

  @override
  bool get isEmpty => _start == _end;

  @override
  bool get isNotEmpty => _start != _end;

  @override
  bool moveAfterPrevious(Characters target) {
    var targetString = target.string;
    var index = _lastIndexOf(targetString, 0, _start);
    if (index >= 0) {
      _move(index + targetString.length, _start);
      return true;
    }
    return false;
  }

  @override
  bool moveFirst([Characters target]) {
    if (_start == _end) return false;
    if (target == null) {
      _move(_start, nextBreak(_string, _start, _end, _start + 1));
      return true;
    }
    var targetString = target.string;
    int index = _indexOf(targetString, _start, _end);
    if (index >= 0) {
      _move(index, index + targetString.length);
      return true;
    }
    return false;
  }

  @override
  bool moveLast([Characters target]) {
    if (_start == _end) return false;
    if (target == null) {
      _move(previousBreak(_string, _start, _end, _end - 1), _end);
      return true;
    }
    var targetString = target.string;
    int index = _lastIndexOf(targetString, _start, _end);
    if (index >= 0) {
      _move(index, index + targetString.length);
      return true;
    }
    return false;
  }

  @override
  bool moveUntilNext(Characters target) {
    var targetString = target.string;
    int index = _indexOf(targetString, _end, _string.length);
    if (index >= 0) {
      _move(_end, index);
      return true;
    }
    return false;
  }

  @override
  Characters replaceAll(Characters pattern, Characters replacement) {
    if (_start == _end) return Characters(_string);
    var patternString = pattern.string;
    if (patternString.isEmpty) {
      // Explode.
    }
    var replacementString = replacement.string;
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
    if (buffer == null) return Characters(_string);
    buffer.write(_string.substring(start));
    return Characters(buffer.toString());
  }

  @override
  Characters replaceRange(Characters replacement) {
    return Characters(_string.replaceRange(_start, _end, replacement.string));
  }

  @override
  Characters get source => Characters(_string);
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
