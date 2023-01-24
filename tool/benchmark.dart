// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:characters/src/grapheme_clusters/breaks.dart";
import "package:characters/src/grapheme_clusters/constants.dart";

import "../test/src/text_samples.dart";
import "../test/src/unicode_grapheme_tests.dart";
import "../test/src/various_tests.dart";

// Low-level benchmark of the grpaheme cluster step functions.

void main(List<String> args) {
  int count = 5;
  if (args.isNotEmpty) {
    count = int.parse(args[0]);
  }
  int gcsf = 0;
  int gcsb = 0;

  var text = genesis +
      hangul +
      genesis +
      diacretics +
      recJoin(splitTests + emojis + zalgo);
  int codeUnits = text.length;
  int codePoints = text.runes.length;
  for (int i = 0; i < count; i++) {
    gcsf = benchForward(text, i, codePoints, codeUnits);
    gcsb = benchBackward(text, i, codePoints, codeUnits);
  }
  print("gc: Grapheme Clusters, cp: Code Points, cu: Code Units.");
  if (gcsf != gcsb) {
    print("ERROR: Did not count the same number of grapheme clusters: "
        "$gcsf forward vs. $gcsb backward.");
  } else {
    print("Total: $gcsf gc, $codePoints cp, $codeUnits cu");
    print("Avg ${(codePoints / gcsf).toStringAsFixed(3)} cp/gc");
    print("Avg ${(codeUnits / gcsf).toStringAsFixed(3)} cu/gc");
  }
}

String recJoin(List<List<String>> texts) =>
    texts.map((x) => x.join("")).join("\n");

int benchForward(String text, int i, int cp, int cu) {
  int n = 0;
  int gc = 0;
  int e = 0;
  Stopwatch sw = Stopwatch()..start();
  do {
    Breaks breaks = Breaks(text, 0, text.length, stateSoTNoBreak);
    while (breaks.nextBreak() >= 0) {
      gc++;
    }
    e = sw.elapsedMilliseconds;
    n++;
  } while (e < 2000);
  print("Forward  #$i: ${(gc / e).round()} gc/ms, "
      "${(n * cp / e).round()} cp/ms, "
      "${(n * cu / e).round()} cu/ms, "
      "$n rounds");
  return gc ~/ n;
}

int benchBackward(String text, int i, int cp, int cu) {
  int n = 0;
  int gc = 0;
  int e = 0;
  Stopwatch sw = Stopwatch()..start();
  do {
    BackBreaks breaks = BackBreaks(text, text.length, 0, stateEoTNoBreak);
    while (breaks.nextBreak() >= 0) {
      gc++;
    }
    e = sw.elapsedMilliseconds;
    n++;
  } while (e < 2000);
  print("Backward #$i: ${(gc / e).round()} gc/ms, "
      "${(n * cp / e).round()} cp/ms, "
      "${(n * cu / e).round()} cu/ms, "
      "$n rounds");
  return gc ~/ n;
}
