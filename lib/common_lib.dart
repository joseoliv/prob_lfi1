import 'package:flutter/material.dart';
import 'package:prob_lfi1/fraction.dart';

Color teaBrown = Color.fromARGB(255, 245, 221, 190);
Color lightTea = Color(0xFFC7A882);
Color teaRose = Color(0xFFF88379);
// Very light tea colors
Color creamTea = Color(0xFFF5F5DC);
Color milkTea = Color(0xFFE6D3C1);
Color vanillaTea = Color(0xFFF3E5AB);
Color chamomile = Color(0xFFF7E98E);
Color whiteTea = Color(0xFFF8F6F0);
Color greenTea = Color(0xFFD0F0C0);
Color jasmineTea = Color(0xFFF8F8E8);
Color paleOolong = Color(0xFFE8D5B7);
// Very light tea colors (const)
const Color barelyTea = Color(0xFFFAFAF5);
const Color teaMist = Color(0xFFF9F7F4);
const Color paleChai = Color(0xFFF4F0E8);

Widget _buildResultRow(String label, (int, int) value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      children: [
        SizedBox(
          width: 140,
          child: SelText(label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        SelText(
            '${value.$1}/${value.$2} = ${((value.$1 * 1.0) / value.$2).toStringAsFixed(5)}'),
      ],
    ),
  );
}

Widget _buildResultRowStr(String label, String str, {double sizeFirst = 140}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      children: [
        SizedBox(
          width: sizeFirst,
          child: SelText(label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        SelText(str,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.left),
      ],
    ),
  );
}

Widget table(
    {required (int, int) prA,
    required (int, int) prB,
    required (int, int) prC,
    required (int, int) prAB,
    required (int, int) prAC,
    required (int, int) prBC,
    required (int, int) prABC,
    required (int, int) prCNotA,
    required (int, int) prCNotB,
    required (int, int) prNotA,
    required (int, int) prNotB,
    required (int, int) prNotC,
    required (int, int) prANotC,
    required (int, int) prBNotC,

    /// C & ~(A&B)
    required (int, int) prCNotAandB,

    /// ~A&B
    required (int, int) prNotAB,

    /// A & ~B
    required (int, int) prANotB,

    /// C & ~A & B
    required (int, int) prCNotAB,

    /// C & ~B & A
    required (int, int) prCNotBA,
    required (int, int) prNotAandB,
    required (int, int) prANotBNotC,
    required (int, int) prNotBNotC,
    required (int, int) prABNotC,
    required (int, int) prSum}) {
  var inSetCell = EdgeInsets.all(4.0);
  var prCgivenA = div(prAC, prA);
  var prCgivenNotA = div(prCNotA, prNotA);
  var prCgivenNotB = div(prCNotB, prNotB);
  var prCgivenB = div(prBC, prB);
  var sCA = sub(prCgivenA, prCgivenNotA);
  var sCB = sub(prCgivenB, prCgivenNotB);
  var prAgivenC = div(prAC, prC);
  var prBgivenC = div(prBC, prC);
  var prAgivenNotC = div(prANotC, prNotC);
  var prBgivenNotC = div(prBNotC, prNotC);
  var prAgivenB = div(prAB, prB);
  var prBgivenA = div(prAB, prA);
  var prAgivenNotB = div(prANotB, prNotB);

  // 'Pr(A) < 1/2'
  var lotteryAndMiraclesOne = lt(prA, (1, 2));
  // 'Pr(A|B) > 1/2 '
  var lotteryAndMiraclesTwo = gt(prAgivenB, (1, 2));
  // 'Pr(B|A) > 1/2 '
  var lotteryAndMiraclesThree = gt(prBgivenA, (1, 2));

  // 'Pr(A|~B) >= Pr(B)'
  var lotteryAndMiraclesFour = ge(prAgivenNotB, prB);
  var lotteryAndMiraclesFiveLeft = sub(prAgivenB, prAgivenNotB);
  var lotteryAndMiraclesFiveRight = sub(prNotB, prB);
  // 'Pr(A|B) - Pr(A|~B) <= Pr(~B) - Pr(B)'
  var lotteryAndMiraclesFive =
      le(lotteryAndMiraclesFiveLeft, lotteryAndMiraclesFiveRight);

  /// i(C,A) = (Pr(A|C) - Pr(A|~C)) / (Pr(A|C) + Pr(A|~C))
  /// i(C,A) = (Pr(A&C)/Pr(C) - Pr(A&~C)/Pr(~C)) / (Pr(A&C)/Pr(C) + Pr(A&~C)/Pr(~C))
  var iCA =
      div(sub(prAgivenC, prAgivenNotC), addFractions(prAgivenC, prAgivenNotC));

  var iCB =
      div(sub(prBgivenC, prBgivenNotC), addFractions(prBgivenC, prBgivenNotC));
  var prAPlusNotA = addFractions(prA, prNotA);
  var prBPlusNotB = addFractions(prB, prNotB);

  ///s(C, A&B) = Pr(C|A&B) - Pr(C|~(A&B)) =
  ///            Pr(C&A&B)/Pr(A&B) - Pr(C&~(A&B))/Pr(~(A&B))
  var sCAB = sub(div(prABC, prAB), div(prCNotAandB, prNotAandB));

  /// s(C, A|B) = Pr(C|A&B) - Pr(C|~A&B) =
  ///            Pr(C&A&B)/Pr(A&B) - Pr(C&~A&B)/Pr(~A&B)
  var sCAgivenB = sub(div(prABC, prAB), div(prCNotAB, prNotAB));

  /// s(C, B|A) = Pr(C|A&B) - Pr(C|A&~B) =
  ///            Pr(C&A&B)/Pr(A&B) - Pr(C&A&~B)/Pr(A&~B)
  var sCBgivenA = sub(div(prABC, prAB), div(prCNotBA, prANotB));

  var dCA = sub(prCgivenA, prA);
  var dCB = sub(prCgivenB, prB);

  // raven-related calculations

// _prABC == _prAC
// _prNotB > _prC

// _prAC/_prC
// _prANotB

// _prANotB/_prNotB
// _prANotBNotC

// _prNotBNotC
// _prANotBNotC/_prNotBNotC <= _prA

// _prABNotC
// _prABNotC/_prBNotC

// _prABNotC/_prBNotC >= _prA

  var aNotBdivprNotB = div(prANotB, prNotB);
  var aNotBNotCdivprNotBNotC = div(prANotBNotC, prNotBNotC);
  var aBNotCdivprBNotC = div(prABNotC, prBNotC);
  // ABNotCdivprBNotC

  final scrollController = ScrollController();

  return DefaultTextStyle(
    style: TextStyle(
        fontSize: 12, color: eq(prSum, (1, 1)) ? Colors.black : Colors.red),
    child: Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
                right: 16.0), // Space on the right for scrollbar
            child: Theme(
              data: ThemeData(
                scrollbarTheme: ScrollbarThemeData(
                  thumbColor: WidgetStateProperty.all(Colors.green),
                  trackColor: WidgetStateProperty.all(
                      Colors.lightGreen.withValues(alpha: 0.1)),
                  thickness: WidgetStateProperty.all(10.0),
                  radius: const Radius.circular(5.0),
                  thumbVisibility: WidgetStateProperty.all(true),
                  trackVisibility: WidgetStateProperty.all(true),
                ),
              ),
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        right: 16.0), // Space between table and scrollbar
                    child: Table(
                      border: TableBorder.all(color: Colors.blue),
                      columnWidths: const {
                        0: FlexColumnWidth(1.5), // First column wider
                        1: FlexColumnWidth(1.5), // Second column wider
                      },
                      children: [
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('Pr(Sum) = ', prSum))),
                          const TableCell(child: SizedBox.shrink()),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('Pr(A) = ', prA))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('Pr(~A) = ', prNotA))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('Pr(B) = ', prB))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('Pr(~B) = ', prNotB))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('Pr(C) = ', prC))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('Pr(~C) = ', prNotC))),
                        ]),
                        TableRow(children: [
                          TableCell(
                            child: Padding(
                                padding: inSetCell,
                                child: _buildResultRow(
                                    'Pr(~A)+Pr(A) = ', prAPlusNotA)),
                          ),
                          TableCell(
                            child: Padding(
                                padding: inSetCell,
                                child: _buildResultRow(
                                    'Pr(~B)+Pr(B) = ', prBPlusNotB)),
                          )
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child:
                                      _buildResultRow('Pr(A & B) = ', prAB))),
                          TableCell(
                            child: Padding(
                                padding: inSetCell,
                                child: _buildResultRow('Pr(A)Pr(B) = ',
                                    (prA.$1 * prB.$1, prA.$2 * prB.$2))),
                          ),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child:
                                      _buildResultRow('Pr(A & C) = ', prAC))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('Pr(A)Pr(C) = ',
                                      (prA.$1 * prC.$1, prA.$2 * prC.$2)))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child:
                                      _buildResultRow('Pr(B & C) = ', prBC))),
                          TableCell(
                            child: Padding(
                                padding: inSetCell,
                                child: _buildResultRow('Pr(B)Pr(C) = ',
                                    (prB.$1 * prC.$1, prB.$2 * prC.$2))),
                          ),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(A & B & C) = ', prABC))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('Pr(A)Pr(B)Pr(C) = ', (
                                    prA.$1 * prB.$1 * prC.$1,
                                    prA.$2 * prB.$2 * prC.$2
                                  )))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(C|A) = ', prCgivenA))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(C|B) = ', prCgivenB))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding:
                                      inSetCell, // ${prCNotA.$1}/${prCNotA.$2} = ${(prCNotA.$1 * 1.0) / prCNotA.$2}
                                  child: _buildResultRow(
                                      'Pr(C & ~A) = ', prCNotA))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(C & ~B) = ', prCNotB))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(C|~A) = ', prCgivenNotA))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(C|~B) = ', prCgivenNotB))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child:
                                      _buildResultRow('Pr(A&~C) = ', prANotC))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child:
                                      _buildResultRow('Pr(B&~C) = ', prBNotC))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(C&~(A&B)) = ', prCNotAandB))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(~(A&B)) = ', prNotAandB))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('s(C, A) = ', sCA))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('s(C, B) = ', sCB))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('i(C, A) = ', iCA))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('i(C, B) = ', iCB))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRowStr(
                                      'Pr(C|A) >= Pr(C|B)',
                                      (gt(sub(div(prAC, prA), div(prBC, prB)),
                                              (0, 1))
                                          ? 'True'
                                          : 'False'),
                                      sizeFirst: 180))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRowStr(
                                      's(C,A) >= s(C,B)',
                                      (gt(sub(sCA, sCB), (0, 1))
                                          ? 'True'
                                          : 'False'))))
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRowStr(
                                      'i(C,A) >= i(C,B)',
                                      (gt(sub(iCA, iCB), (0, 1))
                                          ? 'True'
                                          : 'False')))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child:
                                      _buildResultRow('s(C, A&B) = ', sCAB))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      's(C, A|B) = ', sCAgivenB))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      's(C, B|A) = ', sCBgivenA))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('d(C, A) = ', dCA))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('d(C, B) = ', dCB))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: Text(
                                      'Raven (inequalities must be true)'))),
                          const TableCell(child: SizedBox.shrink()),
                        ]),
                        // _prABC == _prAC
                        // _prNotB > _prC

                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRowStr(
                                      'Pr(A&B&C) == Pr(A&C)  = ',
                                      (prABC == prAC) ? 'True' : 'False'))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRowStr(
                                    'Pr(Not B) > Pr(C) = ',
                                    (gt(sub(div(prNotB, prC), div(prBC, prB)),
                                            (0, 1))
                                        ? 'True'
                                        : 'False'),
                                  ))),
                        ]),

// _prAC/_prC
// _prANotB
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(A&C)/Pr(C) = ', div(prAC, prC)))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child:
                                      _buildResultRow('Pr(A&~B) = ', prANotB))),
                        ]),
// _prANotB/_prNotB
// _prANotBNotC

                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(A&~B)/Pr(~B) = ', aNotBdivprNotB))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(A&~B&~C) = ', prANotBNotC))),
                        ]),
// _prNotBNotC
// _prANotBNotC/_prNotBNotC

                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(~B&~C) = ', prNotBNotC))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(A&~B&~C)/Pr(~B&~C)  = ',
                                      aNotBNotCdivprNotBNotC))),
                        ]),

// _prANotBNotC/_prNotBNotC <= _prA
// _prABNotC
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRowStr(
                                      'Pr(A&~B&~C)/Pr(~B&~C) <= Pr(A)',
                                      le(aNotBNotCdivprNotBNotC, prA)
                                          ? 'True'
                                          : 'False'))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow(
                                      'Pr(A&B&~C) = ', prABNotC))),
                        ]),

// _prABNotC/_prBNotC
// _prABNotC/_prBNotC >= _prA

                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRow('Pr(A&B&~C)/Pr(B&~C)',
                                      aBNotCdivprBNotC))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRowStr(
                                      'Pr(A&B&~C)/Pr(B&~C) >= Pr(A)',
                                      ge(aBNotCdivprBNotC, prA)
                                          ? 'True'
                                          : 'False'))),
                        ]),

                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: Text(
                                      'Lottery of Miracles (inequalities must be true)'))),
                          const TableCell(child: SizedBox.shrink()),
                        ]),
                        // _prABC == _prAC
                        // _prNotB > _prC

                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRowStr(
                                      'Pr(A) < 1/2',
                                      lotteryAndMiraclesOne
                                          ? 'True'
                                          : 'False'))),
                          TableCell(
                              child: Padding(
                            padding: inSetCell,
                            child: _buildResultRowStr('Pr(A|B) > 1/2 ',
                                lotteryAndMiraclesTwo ? 'True' : 'False'),
                          )),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRowStr(
                                      'Pr(B|A) > 1/2 ',
                                      lotteryAndMiraclesThree
                                          ? 'True'
                                          : 'False'))),
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRowStr(
                                    'Pr(A|~B) >= Pr(B)',
                                    lotteryAndMiraclesFour ? 'True' : 'False',
                                  ))),
                        ]),
                        TableRow(children: [
                          TableCell(
                              child: Padding(
                                  padding: inSetCell,
                                  child: _buildResultRowStr(
                                      'Pr(A|B) - Pr(A|~B) <= Pr(~B) - Pr(B)',
                                      lotteryAndMiraclesFive
                                          ? 'True'
                                          : 'False'))),
                          TableCell(
                              child:
                                  Padding(padding: inSetCell, child: Text(''))),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        /// a Text showing the definitions of both s(C, A) and i(C, A
        SelText(
          's(C, A) = Pr(C|A) - Pr(C|~A)\n'
          'i(C, A) = (Pr(A|C) - Pr(A|~C)) / (Pr(A|C) + Pr(A|~C))\n',
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.left,
        ),
      ],
    ),
  );
}

class SelText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const SelText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: style,
      textAlign: textAlign,
    );
  }
}

class UndoRedoManager<T> {
  final List<T> _history = [];
  int _currentIndex = -1;
  final int maxHistory;

  UndoRedoManager({this.maxHistory = 50});

  void addToHistory(T command) {
    // Remove any redo history
    _history.removeRange(_currentIndex + 1, _history.length);

    _history.add(command);
    if (_history.length > maxHistory) {
      _history.removeAt(0);
    } else {
      _currentIndex++;
    }
  }

  T? undo() {
    if (_currentIndex > 0) {
      _currentIndex--;
      return _history[_currentIndex];
    }
    return null;
  }

  T? redo() {
    if (_currentIndex < _history.length - 1) {
      _currentIndex++;
      return _history[_currentIndex];
    }
    return null;
  }

  void clear() {
    _history.clear();
    _currentIndex = -1;
  }

  bool canUndo() => _currentIndex > 0;

  bool canRedo() => _currentIndex < _history.length - 1;
}

// sumText is a string that has the following format:
//  A : (0, 0, 0) : 1459/2000
//  B : (0, 0, 0) : 161/2000
//  A : (1/2, 1/2, 1) : 1459/2000
//  C : (0, 0, 0) : 161/2000
//  ...

List<(String, String)> fractionProbSum(String sumText) {
  // Split the input text into lines
  // print('\n############\n$sumText\n');
  debugPrint('############\n');
  List<String> lines = sumText.split('\n');
  Map<String, String> formulaSumMap = {};
  for (String line in lines) {
    var parts = line.split(':');
    if (parts.length < 3) {
      // If the line does not have enough parts, skip it
      continue;
    }
    // Match lines with the format 'Label : (x, y, z) : num/den'
    var label = parts[0].trim(); // Trim whitespace from the label
    // int x = int.parse(match.group(2) ?? '-100');
    // int y = int.parse(match.group(3) ?? '-100');
    // int z = int.parse(match.group(4) ?? '-100');
    var numbers = parts[2].trim().split('/'); // Get the fraction part
    if (numbers.length != 2) {
      // If the fraction part does not have exactly two numbers, skip it
      continue;
    }
    int num = int.parse(numbers[0]);
    int den = int.parse(numbers[1]);
    if (formulaSumMap.containsKey(label)) {
      // If the label already exists, append the new fraction to the existing one
      String existing = '${formulaSumMap[label]!} + $num/$den';
      formulaSumMap[label] = existing;
    } else {
      // If the label does not exist, add it to the map
      formulaSumMap[label] = '$num/$den';
    }
  }
  List<(String, String)> list = [];

  /// convert formulaSumMap to a List<(String, String)>
  list = formulaSumMap.entries.map((e) => (e.key, e.value)).toList();

  /// Sort the list by
  list.sort((a, b) {
    if (a.$1.length == b.$1.length) {
      return a.$1.compareTo(b.$1);
    }
    return a.$1.length.compareTo(b.$1.length);
  });

  return list;
}

/// sumFractionText has the following format:
///  1/2 + 3/4 + 5/6
/// Returns the sum of the fractions as a double.
double sumFractionsToDouble(String sumFractionText) {
  // Split the input text by ' + ' to get individual fractions
  List<String> fractions = sumFractionText.split(' + ');

  // Sum the fractions
  double sum = 0.0;
  for (String fraction in fractions) {
    sum += _parseFraction(fraction);
  }
  return sum;
}

/// Helper function to parse a fraction string and return its decimal value.
double _parseFraction(String fraction) {
  var parts = fraction.split('/');
  if (parts.length == 2) {
    double numerator = double.tryParse(parts[0]) ?? 0.0;
    double denominator = double.tryParse(parts[1]) ?? 1.0;
    return numerator / denominator;
  }
  return 0.0;
}

/// sumFractionText has the following format:
///  1/2 + 3/4 + 5/6
/// Returns the sum of the fractions as fraction
(int, int) sumFractions(String sumFractionText) {
  // Split the input text by ' + ' to get individual fractions
  List<String> fractions = sumFractionText.split(' + ');

  // Sum the fractions
  int numeratorSum = 0;
  int denominatorProduct = 1;
  int previousDenominator = 0;
  bool first = true;
  bool sameDenominator = true;

  for (String fraction in fractions) {
    var parts = fraction.split('/');
    if (parts.length == 2) {
      int numerator = int.tryParse(parts[0]) ?? 0;
      int denominator = int.tryParse(parts[1]) ?? 1;
      if (first) {
        first = false;
        previousDenominator = denominator;
        numeratorSum = numerator;
      } else if (denominator != previousDenominator) {
        sameDenominator = false;
        numeratorSum =
            numeratorSum * denominator + numerator * denominatorProduct;
        denominatorProduct *= denominator;
        (numeratorSum, denominatorProduct) =
            simplifyFraction((numeratorSum, denominatorProduct));
      } else {
        // If the denominator is the same, just add the numerators
        numeratorSum += numerator;
      }
    }
  }
  if (sameDenominator) {
    return (numeratorSum, previousDenominator);
  } else {
    return (numeratorSum, denominatorProduct);
  }
}
