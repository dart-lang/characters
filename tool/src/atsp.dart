// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See: Asymmetric Traveling Salesman Problem.

// Strategy for finding optimal overlapping of chunks of a larger table,
// to save space.
// Does so by solving traveling salesman/hamiltonian cycle in a graph
// where the distance between chunks is how little they overlap
// (chunk length minus overlap size).

/// An asymmetric weighted complete graph.
///
/// The vertices are identified by numbers 0 through [vertices] - 1.
/// Edges are pairs of vertices.
class Graph {
  /// Number of vertices.
  final int vertices;

  /// Table of weights, a list of length `vertices`*`vertices`.
  final List<int> _table;

  /// Creates a new complete graph with [vertices] vertices.
  ///
  /// The initial weights on all edges are [initialWeight].
  Graph(this.vertices, [int initialWeight = 0])
      : _table = List<int>.filled(vertices * vertices, initialWeight);

  /// Update the weight on the edges from [fromVertex] to [toVertex].
  void setWeight(int fromVertex, int toVertex, int newWeight) {
    _table[fromVertex * vertices + toVertex] = newWeight;
  }

  /// The weight of the edge from [fromVertex] to [toVertex].
  int weight(int fromVertex, int toVertex) =>
      _table[fromVertex * vertices + toVertex];

  /// The cummulative weight of the (sub-)path from `path[from]` to `path[to]`.
  ///
  /// If [to] is less than [from], the sub-path is traversed in reverse.
  /// The values in `path` should be vertices in this graph.
  int pathWeight(List<int> path, int from, int to) {
    int weight = 0;
    int cursor = path[from];
    int step = from <= to ? 1 : -1;
    for (int i = from; i != to;) {
      i += step;
      int next = path[i];
      weight += this.weight(cursor, next);
      cursor = next;
    }
    return weight;
  }

  int get maxWeight => _table.reduce((a, b) => a >= b ? a : b);
}

/// Optimize a cycle of a graph to minimize the edge weight.
///
/// The [cycle] must have the same node as first and last element.
///
/// This is an implementation of step of 3-opt, a simple algorithm to
/// approximate an asymmetric traveling salesman problem (ATSP).
/// It splits the cycle into three parts and then find the best recombination
/// of the parts, each potentially reversed.
bool opt3(Graph graph, List<int> cycle) {
  // Perhaps optimize the weight computations by creating
  // a single array of cummulative weights, so any range can be computed
  // as a difference between two points in that array.
  for (int i = 1; i < cycle.length; i++) {
    int wA = cycle[i - 1];
    int wB = cycle[i];
    int wAB = graph.weight(wA, wB);
    int wBA = graph.weight(wB, wA);
    int wZA = graph.pathWeight(cycle, 0, i - 1);
    int wAZ = graph.pathWeight(cycle, i - 1, 0);
    for (int j = i + 1; j < cycle.length; j++) {
      int wC = cycle[j - 1];
      int wD = cycle[j];
      int wAC = graph.weight(wA, wC);
      int wCA = graph.weight(wC, wA);
      int wAD = graph.weight(wA, wD);
      int wDA = graph.weight(wD, wA);
      int wBD = graph.weight(wB, wD);
      int wDB = graph.weight(wD, wB);
      int wCD = graph.weight(wC, wD);
      int wDC = graph.weight(wD, wC);
      int wBC = graph.pathWeight(cycle, i, j - 1);
      int wCB = graph.pathWeight(cycle, j - 1, i);
      for (int k = j + 1; k < cycle.length; k++) {
        int wE = cycle[k - 1];
        int wF = cycle[k];
        int wAE = graph.weight(wA, wE);
        int wEA = graph.weight(wE, wA);
        int wBE = graph.weight(wB, wE);
        int wEB = graph.weight(wE, wB);
        int wCE = graph.weight(wC, wE);
        int wEC = graph.weight(wE, wC);
        int wBF = graph.weight(wB, wF);
        int wFB = graph.weight(wF, wB);
        int wCF = graph.weight(wC, wF);
        int wFC = graph.weight(wF, wC);
        int wEF = graph.weight(wE, wF);
        int wFE = graph.weight(wF, wE);
        int wDF = graph.weight(wD, wF);
        int wFD = graph.weight(wF, wD);
        int wDE = graph.pathWeight(cycle, j, k - 1);
        int wED = graph.pathWeight(cycle, k - 1, j);
        int wFA = graph.pathWeight(cycle, k, cycle.length - 1) + wZA;
        int wAF = graph.pathWeight(cycle, cycle.length - 1, k) + wAZ;

        // Find best recombine of the three sections B-C, D-E, F-A
        // (possibly reversed).
        // Since there are only two ways to order three-element cycles, and three
        // parts that can be reversed, this gives 16 combinations.
        int wABCDEF = wFA + wAB + wBC + wCD + wDE + wEF;
        int wACBDEF = wFA + wAC + wCB + wBD + wDE + wEF;
        int wABCEDF = wFA + wAB + wBC + wCE + wED + wDF;
        int wACBEDF = wFA + wAC + wCB + wBE + wED + wDF;
        int wFBCDEA = wAF + wFB + wBC + wCD + wDE + wEA;
        int wFCBDEA = wAF + wFC + wCB + wBD + wDE + wEA;
        int wFBCEDA = wAF + wFB + wBC + wCE + wED + wDA;
        int wFCBEDA = wAF + wFC + wCB + wBE + wED + wDA;
        int wADEBCF = wFA + wAD + wDE + wEB + wBC + wCF;
        int wADECBF = wFA + wAD + wDE + wEC + wCB + wBF;
        int wAEDBCF = wFA + wAE + wED + wDB + wBC + wCF;
        int wAEDCBF = wFA + wAE + wED + wDC + wCB + wBF;
        int wFDEBCA = wAF + wFD + wDE + wEB + wBC + wCA;
        int wFDECBA = wAF + wFD + wDE + wEC + wCB + wBA;
        int wFEDBCA = wAF + wFE + wED + wDB + wBC + wCA;
        int wFEDCBA = wAF + wFE + wED + wDC + wCB + wBA;
        int best = [
          wABCDEF,
          wACBDEF,
          wABCEDF,
          wACBEDF,
          wFBCDEA,
          wFCBDEA,
          wFBCEDA,
          wFCBEDA,
          wADEBCF,
          wADECBF,
          wAEDBCF,
          wAEDCBF,
          wFDEBCA,
          wFDECBA,
          wFEDBCA,
          wFEDCBA
        ].reduce((a, b) => a < b ? a : b);
        if (best < wABCDEF) {
          // Reorder and reverse to match the (or a) best solution.
          if (best == wACBDEF) {
            _reverse(cycle, i, j - 1);
          } else if (best == wABCEDF) {
            _reverse(cycle, j, k - 1);
          } else if (best == wACBEDF) {
            _reverse(cycle, i, j - 1);
            _reverse(cycle, j, k - 1);
          } else if (best == wFBCDEA) {
            _reverse(cycle, i, k - 1);
            _reverse(cycle, 0, cycle.length - 1);
          } else if (best == wFCBDEA) {
            _reverse(cycle, i, j - 1);
            _reverse(cycle, i, k - 1);
            _reverse(cycle, 0, cycle.length - 1);
          } else if (best == wFBCEDA) {
            _reverse(cycle, j, k - 1);
            _reverse(cycle, i, k - 1);
            _reverse(cycle, 0, cycle.length - 1);
          } else if (best == wFCBEDA) {
            _reverse(cycle, i, j - 1);
            _reverse(cycle, j, k - 1);
            _reverse(cycle, i, k - 1);
            _reverse(cycle, 0, cycle.length - 1);
          } else if (best == wADEBCF) {
            _reverse(cycle, i, j - 1);
            _reverse(cycle, j, k - 1);
            _reverse(cycle, i, k - 1);
          } else if (best == wADECBF) {
            _reverse(cycle, j, k - 1);
            _reverse(cycle, i, k - 1);
          } else if (best == wAEDBCF) {
            _reverse(cycle, i, j - 1);
            _reverse(cycle, i, k - 1);
          } else if (best == wAEDCBF) {
            _reverse(cycle, i, k - 1);
          } else if (best == wFDEBCA) {
            _reverse(cycle, i, j - 1);
            _reverse(cycle, j, k - 1);
            _reverse(cycle, 0, cycle.length - 1);
          } else if (best == wFDECBA) {
            _reverse(cycle, j, k - 1);
            _reverse(cycle, 0, cycle.length - 1);
          } else if (best == wFEDBCA) {
            _reverse(cycle, i, j - 1);
            _reverse(cycle, 0, cycle.length - 1);
          } else if (best == wFEDCBA) {
            _reverse(cycle, 0, cycle.length - 1);
          } else {
            throw "Unreachable";
          }
          return true;
        }
      }
    }
  }
  return false;
}

/// Reverses a slice of a list.
void _reverse(List<int> list, int from, int to) {
  while (from < to) {
    int tmp = list[from];
    list[from] = list[to];
    list[to] = tmp;
    from++;
    to--;
  }
}
