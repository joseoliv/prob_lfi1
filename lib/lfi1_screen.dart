import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/services.dart';
import 'package:prob_lfi1/common_lib.dart';
import 'package:prob_lfi1/fraction.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const String lfi1Filename = 'C:\\Users\\josed\\Downloads\\probSum_lfi1.txt';

class LFI1Screen extends StatefulWidget {
  const LFI1Screen({super.key});

  @override
  State<LFI1Screen> createState() => _LFI1ScreenState();
}

class _LFI1ScreenState extends State<LFI1Screen> {
  // --- State Variables ---

  // (b) probValues and related
  late List<TextEditingController> _textControllers;
  late List<(int, int)> _probValues;
  late List<String> _probLabels;
  String _selectedResetOption = 'Choose';
  // (c) Calculated results
  (int, int) _prA = (0, 1);
  (int, int) _prB = (0, 1);
  (int, int) _prC = (0, 1);
  (int, int) _prAB = (0, 1);
  (int, int) _prAC = (0, 1);
  (int, int) _prBC = (0, 1);
  (int, int) _prABC = (0, 1);
  (int, int) _prSum = (0, 1);
  (int, int) _prNotA = (0, 1);
  (int, int) _prNotB = (0, 1);
  (int, int) _prNotC = (0, 1);
  (int, int) _prCNotA = (0, 1);
  (int, int) _prCNotB = (0, 1);
  (int, int) _prANotC = (0, 1);
  (int, int) _prBNotC = (0, 1);
  (int, int) _prCNotAandB = (0, 1);
  (int, int) _prNotAB = (0, 1);
  (int, int) _prANotB = (0, 1);
  (int, int) _prCNotAB = (0, 1);
  (int, int) _prCNotBA = (0, 1);
  (int, int) _prNotAandB = (0, 1);

  (int, int) _prANotBNotC = (0, 1);
  (int, int) _prNotBNotC = (0, 1);
  (int, int) _prABNotC = (0, 1);

  /// text of the form
  /// A : (0, 0, 0) : 1459/2000
  /// B : (0, 1/2, 1) : 0/1
  String _sumText = '';

  /// text with all probabilities in fraction form
  ///    Pr(A) = 1459/2000 + 127/2000
  String _probSumText = '';

  final List<String> _valueStrings = ["  0", "1/2", "  1"];

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeProbabilities();
  }

  void _initializeProbabilities(
      {List<(int, int)>? initialValues,
      Map<int, List<(int, int)>>? initialMap}) {
    _probValues = List.filled(27, (0, 1));
    if (initialMap != null) {
      // Initialize _probValues from initialMap
      for (var entry in initialMap.entries) {
        if (entry.key < _probValues.length) {
          _probValues[entry.key] = entry.value.first;
        }
      }
    } else {
      if (initialValues != null) {
        for (int i = 0;
            i < initialValues.length && i < _probValues.length;
            i++) {
          _probValues[i] = initialValues[i];
        }
      } else {
        _probValues[0] = (1459, 2000);
        _probValues[2] = (161, 2000);
        _probValues[6] = (161, 2000);
        _probValues[8] = (19, 2000);
        _probValues[18] = (161, 2000);
        _probValues[20] = (19, 2000);
        _probValues[24] = (19, 2000);
        _probValues[26] = (1, 2000);
      }
    }

    /// Initialize all TextEditingControllers with the values corresponding to the probabilities
    /// _probValues
    _textControllers = List.generate(27, (index) {
      final value = _probValues[index];
      return TextEditingController(text: '${value.$1}/${value.$2}');
    });
    _probLabels = [];

    // Generate labels: Pr(0,0,0) ... Pr(1,1,1)
    for (int i = 0; i < 3; i++) {
      // x
      for (int j = 0; j < 3; j++) {
        // y
        for (int k = 0; k < 3; k++) {
          // z
          _probLabels.add(
              'Pr(${_valueStrings[i]}, ${_valueStrings[j]}, ${_valueStrings[k]})');
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _textControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- Helper Functions ---

  String getPlatform() {
    if (kIsWeb) {
      return 'Web';
    } else if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else {
      return 'Unknown';
    }
  }

  (int, int) _parseFraction(String text, int index) {
    try {
      return parseFraction(text, index);
    } catch (e) {
      var msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelText(msg)),
      );
    }
    return (0, 1); // Default to 0/1 on error
  }

  // --- Calculation Logic ---
  void _calculateAndDisplayProbabilities() {
    // delete a file named 'C:\Users\josed\Downloads\probSum_lfi1.txt'
    // only if the platform is Windows
    if (getPlatform() == 'Windows') {
      File(lfi1Filename).delete();
    }

    // 1. Parse all TextField values and store them in _probValues
    List<String> textField =
        _textControllers.map((controller) => controller.text).toList();
    for (int i = 0; i < 27; i++) {
      final parsed = _parseFraction(textField[i], i);
      _probValues[i] = parsed;
      // If _parseFraction showed a SnackBar for an error, we might consider allValid as false
      // For simplicity here, we proceed with the parsed (or default) values.
      // A more robust solution might halt calculation or highlight fields.
    }

    // Initialize sums

    _prA = (0, 1);
    _prB = (0, 1);
    _prC = (0, 1);
    _prAB = (0, 1);
    _prAC = (0, 1);
    _prBC = (0, 1);
    _prABC = (0, 1);
    _prSum = (0, 1);
    _prNotA = (0, 1);
    _prNotB = (0, 1);
    _prNotC = (0, 1);
    _prCNotA = (0, 1);
    _prCNotB = (0, 1);
    _prANotC = (0, 1);
    _prBNotC = (0, 1);
    _prCNotAandB = (0, 1);
    _prNotAB = (0, 1);
    _prANotB = (0, 1);
    _prCNotAB = (0, 1);
    _prCNotBA = (0, 1);
    _prNotAandB = (0, 1);

    _prANotBNotC = (0, 1);
    _prNotBNotC = (0, 1);
    _prABNotC = (0, 1);

    _sumText = '';

    // Iterate through all 27 probabilities
    // Index mapping:
    // x_idx corresponds to _valueStrings[x_idx] (0 for "0", 1 for "1/2", 2 for "1")
    // y_idx corresponds to _valueStrings[y_idx]
    // z_idx corresponds to _valueStrings[z_idx]
    // The flat index in _probValues is x_idx * 9 + y_idx * 3 + z_idx

    for (int xIdx = 0; xIdx < 3; xIdx++) {
      for (int yIdx = 0; yIdx < 3; yIdx++) {
        for (int zIdx = 0; zIdx < 3; zIdx++) {
          int flatIndex = xIdx * 9 + yIdx * 3 + zIdx;
          (int, int) currentProb = _probValues[flatIndex];

          if (currentProb.$1 == 0) {
            continue; // Skip zero probabilities
          }

          _prSum = addFractions(_prSum, currentProb);
          bool aIsHalfOrOne = xIdx >= 1; // "1/2" or "1"
          bool bIsHalfOrOne = yIdx >= 1; // "1/2" or "1"
          bool cIsHalfOrOne = zIdx >= 1; // "1/2" or "1"
          bool aIsHalfOrZero = xIdx <= 1; // "0" or "1/2"
          bool bIsHalfOrZero = yIdx <= 1; // "0" or "1/2"
          bool cIsHalfOrZero = zIdx <= 1; // "0" or "1/2"

          // A
          if (aIsHalfOrOne) {
            _prA = addFractions(_prA, currentProb);
            _sumText +=
                'A : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // B
          if (bIsHalfOrOne) {
            _prB = addFractions(_prB, currentProb);
            _sumText +=
                'B : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // C
          if (cIsHalfOrOne) {
            _prC = addFractions(_prC, currentProb);
            _sumText +=
                'C : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // A&B
          if (aIsHalfOrOne && bIsHalfOrOne) {
            _prAB = addFractions(_prAB, currentProb);
            _sumText +=
                'A&B : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // A&C
          if (aIsHalfOrOne && cIsHalfOrOne) {
            _prAC = addFractions(_prAC, currentProb);
            _sumText +=
                'A&C : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // B&C
          if (bIsHalfOrOne && cIsHalfOrOne) {
            _prBC = addFractions(_prBC, currentProb);
            _sumText +=
                'B&C : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // A&B&C
          if (aIsHalfOrOne && bIsHalfOrOne && cIsHalfOrOne) {
            _prABC = addFractions(_prABC, currentProb);
            _sumText +=
                'A&B&C : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // ~A
          if (aIsHalfOrZero) {
            _prNotA = addFractions(_prNotA, currentProb);
            _sumText +=
                '~A : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // ~B
          if (bIsHalfOrZero) {
            _prNotB = addFractions(_prNotB, currentProb);
            _sumText +=
                '~B : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // ~C
          if (cIsHalfOrZero) {
            _prNotC = addFractions(_prNotC, currentProb);
            _sumText +=
                '~C : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // C&~A
          if (cIsHalfOrOne && aIsHalfOrZero) {
            _prCNotA = addFractions(_prCNotA, currentProb);
            _sumText +=
                'C&~A : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // C&~B
          if (cIsHalfOrOne && bIsHalfOrZero) {
            _prCNotB = addFractions(_prCNotB, currentProb);
            _sumText +=
                'C&~B : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // ~C&A
          if (cIsHalfOrZero && aIsHalfOrOne) {
            _prANotC = addFractions(_prANotC, currentProb);
            _sumText +=
                '~C&A : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // B&~C
          if (bIsHalfOrOne && cIsHalfOrZero) {
            _prBNotC = addFractions(_prBNotC, currentProb);
            _sumText +=
                'B&~C : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // ~(A & B)
          if (aIsHalfOrZero || bIsHalfOrZero) {
            _prNotAandB = addFractions(_prNotAandB, currentProb);
            _sumText +=
                '~(A&B) : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // C&~(A&B)
          if (cIsHalfOrOne && (aIsHalfOrZero || bIsHalfOrZero)) {
            _prCNotAandB = addFractions(_prCNotAandB, currentProb);
            _sumText +=
                'C&~(A&B) : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // ~A&B
          if (aIsHalfOrZero && bIsHalfOrOne) {
            _prNotAB = addFractions(_prNotAB, currentProb);
            _sumText +=
                '~A&B : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // A&~B
          if (aIsHalfOrOne && bIsHalfOrZero) {
            _prANotB = addFractions(_prANotB, currentProb);
            _sumText +=
                'A&~B : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // C&~A&B
          if (cIsHalfOrOne && aIsHalfOrZero && bIsHalfOrOne) {
            _prCNotAB = addFractions(_prCNotAB, currentProb);
            _sumText +=
                'C&~A&B : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // C&~B&A
          if (cIsHalfOrOne && bIsHalfOrZero && aIsHalfOrOne) {
            _prCNotBA = addFractions(_prCNotBA, currentProb);
            _sumText +=
                'C&~B&A : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // A & ~B & ~C
          if (aIsHalfOrOne && bIsHalfOrZero && cIsHalfOrZero) {
            _prANotBNotC = addFractions(_prANotBNotC, currentProb);
            _sumText +=
                'A&~B&~C : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // ~B & ~C
          if (bIsHalfOrZero && cIsHalfOrZero) {
            _prNotBNotC = addFractions(_prNotBNotC, currentProb);
            _sumText +=
                '~B&~C : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
          // A & B & ~C
          if (aIsHalfOrOne && bIsHalfOrOne && cIsHalfOrZero) {
            _prABNotC = addFractions(_prABNotC, currentProb);
            _sumText +=
                'A&B&~C : (${intToTruthValue(xIdx)}, ${intToTruthValue(yIdx)}, ${intToTruthValue(zIdx)}) : ${textField[flatIndex]}\n';
          }
        }
      }
    }

    // Update state to re-render the UI
    setState(() {});

    /// Generate the probability sum text as
    ///    Pr(A) = 127/2000 + 1459/2000
    var list = fractionProbSum(_sumText).toList();
    //print('end of calculation\n@@@@@@@@@\n$_sumText\n@@@@@@@@@\n');
    _probSumText = list.map((e) {
      var sum = sumFractions(e.$2);
      var num = sum.$1;
      var den = sum.$2;
      var sSum = simplifyFraction(sum);
      var sNum = sSum.$1;
      var sDen = sSum.$2;
      return 'Pr(${e.$1}) = ${e.$2} = $num/$den = $sNum/$sDen = ${sumFractionsToDouble(e.$2)}';
    }).join('\n');

    /// Save _sumText and then _probSumText to lfi1Filename, put \n\n##############\n\n between them
    if (getPlatform() == 'Windows') {
      File(lfi1Filename)
          .writeAsStringSync('$_sumText\n\n##############\n\n$_probSumText');
    }
    //    .writeAsStringSync('$_sumText\n\n##############\n\n$_probSumText');
  }

  // --- UI Building ---

  Widget _buildLeftPanel() {
    return Container(
      color: const Color(0xFFFFF0F5), // Very light rose (LavenderBlush)
      padding: const EdgeInsets.all(12.0),
      child: ListView.builder(
        itemCount: 27,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                SizedBox(
                  width: 180, // Give label enough space
                  child: SelText(
                    '$index: ${_probLabels[index]}',
                    style: TextStyle(fontSize: 11, fontFamily: 'Courier New'),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  height: 25,
                  width: 100, // Adjust height as needed
                  child: TextField(
                    style: TextStyle(fontSize: 12),
                    controller: _textControllers[index],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    // Optional: Add input formatter or immediate validation if desired
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      color: const Color(0xFFF0FFF0), // Very light tea (Honeydew)
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: [
              ElevatedButton(
                onPressed: _calculateAndDisplayProbabilities,
                child: SelText('Calculate'),
              ),
              SizedBox(width: 8), // Space between buttons
              ElevatedButton(
                onPressed: () {
                  _showText();
                },
                child: SelText('Text'),
              ),
              ElevatedButton(
                onPressed: () {
                  _showSumText();
                },
                child: SelText('Fraction Sums'),
              ),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: EdgeInsets.fromLTRB(12, 3, 12, 5),

                  /// a rounded border to the DropdownButton
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blueGrey, // Border color
                      width: 1, // Border width
                    ),
                    color: const Color.fromARGB(
                        255, 215, 234, 238), // Same as ElevatedButton default
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedResetOption,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down,
                        size: 25), // Reset icon
                    hint: SelText(_selectedResetOption),
                    onChanged: (String? newValue) {
                      if (newValue == null) return;
                      setState(() {
                        _selectedResetOption = newValue;
                        switch (newValue) {
                          case 'Reset':
                            _reset();
                            break;
                          case 'Prob. Independency':
                            _resetPI();
                            break;
                          case 'Bayes Confirm.':
                            _resetBCT();
                            break;
                          case 'Raven':
                            _resetRaven();
                            break;
                          case 'Miracle':
                            _resetMiracle();
                            break;
                        }
                      });
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'Choose',
                        child: Row(
                          children: const [
                            Icon(Icons.restart_alt, size: 20),
                            SizedBox(width: 8),
                            SelText('Reset'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Prob. Independency',
                        child: Row(
                          children: [
                            Transform.rotate(
                              angle: 0.785398, // 45 degrees in radians (π/4)
                              child: const Text(
                                '=',
                                style: TextStyle(
                                    fontSize: 25, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(width: 8),
                            SelText('Prob. Independency'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Bayes Confirm.',
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/icons/visual-bayes-theorem.png',
                              width: 30,
                              height: 30,
                            ),
                            SizedBox(width: 8),
                            SelText('Bayes Confirm.'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Raven',
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/icons/raven-aistudio.png',
                              width: 30,
                              height: 30,
                            ),
                            SizedBox(width: 8),
                            SelText('Raven'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Miracle',
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/icons/wand-left.png',
                              width: 30,
                              height: 30,
                            ),
                            SizedBox(width: 8),
                            SelText('Miracle'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                height: 30,
                child: TextField(
                  controller: _nameController,

                  /// add a rounded border to the TextField
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
              child: table(
            prA: _prA,
            prB: _prB,
            prC: _prC,
            prAB: _prAB,
            prAC: _prAC,
            prBC: _prBC,
            prABC: _prABC,
            prCNotA: _prCNotA,
            prCNotB: _prCNotB,
            prNotA: _prNotA,
            prNotB: _prNotB,
            prNotC: _prNotC,
            prANotC: _prANotC,
            prBNotC: _prBNotC,
            prCNotAandB: _prCNotAandB,
            prNotAB: _prNotAB,
            prANotB: _prANotB,
            prCNotAB: _prCNotAB,
            prCNotBA: _prCNotBA,
            prNotAandB: _prNotAandB,
            prANotBNotC: _prANotBNotC,
            prNotBNotC: _prNotBNotC,
            prABNotC: _prABNotC,
            prSum: _prSum,
          )),
        ],
      ),
    );
  }

  void _resetPI() {
    setState(() {
      _initializeProbabilities(
          /*

 0   0   0    1459/2000
 0   0  1/2	   161/2000
 0	1/2  0	   161/2000	
 0  1/2 1/2     19/2000
1/2  0   0     161/2000 
1/2  0  1/2     19/2000 
1/2 1/2  0      19/2000 
1/2 1/2 1/2      1/2000

        */

          initialMap: {
            0: [(1459, 2000)],
            1: [(161, 2000)],
            3: [(161, 2000)],
            4: [(19, 2000)],
            9: [(161, 2000)],
            10: [(19, 2000)],
            12: [(19, 2000)],
            13: [(1, 2000)],
          }
          //   initialValues: [
          //   (1459, 2000),
          //   (150, 2000),
          //   (11, 2000),
          //   (101, 2000),
          //   (0, 1),
          //   (0, 1),
          //   (60, 2000),
          //   (0, 1),
          //   (19, 2000),
          //   (101, 2000),
          //   (0, 1),
          //   (0, 1),
          //   (0, 1),
          //   (0, 1),
          //   (0, 1),
          //   (0, 1),
          //   (0, 1),
          //   (0, 1),
          //   (60, 2000),
          //   (0, 1),
          //   (19, 2000),
          //   (0, 1),
          //   (0, 1),
          //   (0, 1),
          //   (19, 2000),
          //   (0, 1),
          //   (1, 2000)
          // ]

          );

      _calculateAndDisplayProbabilities();
    });
  }

  void _resetBCT() {
    setState(() {});
    _initializeProbabilities(
      /*
0: 835
2: 125
6: 1341
8: 1539
18: 193
22: 127
24: 291
26: 669      
      */
      initialMap: {
/*
 0   0   0     835/5120
 0   0  1/2	   125/5120
 0	1/2  0	  1341/5120	
 0   1   1    1539/5120
1/2  0   0     193/5120 
1/2 1/2  0      291/5120 
1/2 1/2 1/2     796/5120

*/
        0: [(835, 5120)],
        1: [(125, 5120)],
        3: [(1341, 5120)],
        8: [(1539, 5120)],
        9: [(193, 5120)],
        12: [(291, 5120)],
        13: [(796, 5120)],
        // 0: [(835, 5120)],
        // 2: [(125, 5120)],
        // 6: [(1341, 5120)],
        // 8: [(1539, 5120)],
        // 9: [(100, 5120)],
        // 18: [(93, 5120)],
        // 22: [(127, 5120)],
        // 24: [(291, 5120)],
        // 26: [(669, 5120)],
      },
    );
    _calculateAndDisplayProbabilities();
  }

  void _resetRaven() {
    _initializeProbabilities(initialMap: {
      0: [(1000, 2650)],

      ///  0   0  0
      1: [(88, 2650)],

      ///  0   0 1/2
      3: [(36, 2650)],

      ///  0  1/2  0
      4: [(138, 2650)],

      ///  0  1/2 1/2
      9: [(181, 2650)],

      /// 1/2  0   0
      10: [(0, 2650)],

      /// 1/2  0  1/2
      12: [(52, 2650)],

      /// 1/2 1/2  0
      13: [(215, 2650)],

      /// 1/2 1/2 1/2
      26: [(940, 2650)],

      ///  1   1   1
    });

    _calculateAndDisplayProbabilities();
    setState(() {});
  }

  void _resetMiracle() {
    // 0  0   6033/8192
    // 0  1      1/64
    // 1  0   1007/8192
    // 1  1      1/8
    _initializeProbabilities(initialMap: {
      // 0  0   6033/8192

      0: [(6033, 8192)],

      // 0  1      1/64
      3: [(128, 8192)],

      // 1  0   1007/8192
      9: [(1007, 8192)],

      // 1  1      1/8
      12: [(1024, 8192)],
    });

    _calculateAndDisplayProbabilities();
    setState(() {});
  }

  void _reset() {
    setState(() {
      _initializeProbabilities();
      _calculateAndDisplayProbabilities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SelText('Probability Calculator for LFI1'),
        backgroundColor: Colors.blueGrey[100],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildLeftPanel(),
          ),
          const SizedBox(width: 16.0), // Space between panels
          Expanded(
            flex: 3,
            child: _buildRightPanel(),
          ),
        ],
      ),
    );
  }

  void _showText() {
    var text = '';

    /// numNonZero is the number of _probValues[i].$1 != 0
    int numNonZero = _probValues.where((p) => p.$1 != 0).length;
    text += r'\vspace*{3ex}' '\n';
    text += r'\begin{tabular}{' +
        // ignore: prefer_interpolation_to_compose_strings
        r'>{\centering\arraybackslash}m{1.3cm}|' * numNonZero +
        '}\n';
    int size = _textControllers.length;
    for (int i = 0; i < _textControllers.length; i++) {
      if (_probValues[i].$1 != 0) {
        /// \rule{0pt}{3ex}$s_{0}$ &
        text +=
            '\\rule{0pt}{3ex}\$s_$i\$ ${i < size - 1 ? '& ' : '\\\\[0.2cm] \\hline'}\n';
      }
    }
    var k = 0;
    for (int aA = 0; aA < 3; aA++) {
      for (int bB = 0; bB < 3; bB++) {
        for (int cC = 0; cC < 3; cC++) {
          /// \rule{0pt}{3ex}$(0, 0, 0)$ &
          if (_probValues[k].$1 != 0) {
            text +=
                '\\rule{0pt}{3ex}\$(${intToTruthValue(aA)}, ${intToTruthValue(bB)}, ${intToTruthValue(cC)})\$ ${k < size - 1 ? '& ' : '\\\\[0.2cm] \\hline'}\n';
          }
          k++;
        }
      }
    }

    for (int i = 0; i < size; ++i) {
      /// \rule{0pt}{3ex}$\frac{1459}{2000}$ &
      if (_probValues[i].$1 != 0) {
        text += r'\rule{0pt}{3ex}\$' +
            _probValues[i].$1.toString() +
            r'/' +
            _probValues[i].$2.toString() +
            r'\$ ' +
            (i < size - 1 ? '& \n' : '\n');
      }
    }

    /// Show the text in a dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const SelText('Probability Values'),
          content: SingleChildScrollView(
            child: SelText(text),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const SelText('Close'),
            ),

            /// a button to copy the text to clipboard
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: SelText('Text copied to clipboard')),
                );
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.copy),
            ),
          ],
        );
      },
    );
  }

  void _showSumText() {
    /// Show the text in a dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const SelText('Fraction Sums'),
          content: SingleChildScrollView(
            child: SelText('$_probSumText\n\n$_sumText'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const SelText('Close'),
            ),

            /// a button to copy the text to clipboard
            TextButton(
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: '$_probSumText\n\n$_sumText'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: SelText('Text copied to clipboard')),
                );
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.copy),
            ),
          ],
        );
      },
    );
  }

  String intToTruthValue(int i) {
    switch (i) {
      case 0:
        return '0';
      case 1:
        return '1/2';
      case 2:
        return '1';
      default:
        return '';
    }
  }
}
