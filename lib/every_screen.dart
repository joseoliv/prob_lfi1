// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prob_lfi1/common_lib.dart';
import 'package:prob_lfi1/fraction.dart';

/// for variables A, \neg A, B, \neg B, C, \neg C, there are 64 possibilities
final numLinesTruthTable = 64;
final numCombTruthValues = 4; //  0 0, 0 1, 1 0, 1 1

bool hideZeroProbabilities = true;

class EveryScreen extends StatefulWidget {
  const EveryScreen({super.key});

  @override
  State<EveryScreen> createState() => _EveryScreenState();
}

class _EveryScreenState extends State<EveryScreen> implements ILogic {
  bool _isLoading = false;
  // --- State Variables ---

  // (b) probValues and related
  late List<TextEditingController> _textControllers;
  late List<(int, int)> _probValues;
  late List<String> _probLabels;
  late String octaveStr = '';

  /// Truth variable table for the numLinesTruthTable probabilities
  /// Each sublist corresponds to a combination of A, B, C truth values
  late List<List<int>> _truthVariableTable;
  // (c) Calculated results
  (int, int) _prA = (0, 1);
  (int, int) _prB = (0, 1);
  (int, int) _prC = (0, 1);
  (int, int) _prAB = (0, 1);
  (int, int) _prAC = (0, 1);
  (int, int) _prBC = (0, 1);
  (int, int) _prABC = (0, 1);
  (int, int) _prSum = (0, 1);
  @override
  bool get isLoading => _isLoading;
  @override
  set isLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

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

  String _prANumeratorSum = '';
  String _prBNumeratorSum = '';
  String _prCNumeratorSum = '';
  String _prABNumeratorSum = '';
  String _prACNumeratorSum = '';
  String _prBCNumeratorSum = '';
  String _prABCNumeratorSum = '';
  String _prNotANumeratorSum = '';
  String _prNotBNumeratorSum = '';
  String _prCNotANumeratorSum = '';
  String _prCNotBNumeratorSum = '';

  @override
  void initState() {
    super.initState();
    initializeProbabilities();
  }

  // --- Undo/Redo Logic ---
  // a circular buffer to store the last 10 changes
  final UndoRedoManager<List<String>> _undoRedoManager = UndoRedoManager();

  @override
  void undoLastChange() {
    if (_undoRedoManager.canUndo()) {
      List<Object> objList = _undoRedoManager.undo() ?? _probValues;
      List<String> strList = objList.cast<String>();

      /// three variables, each one and its negation can have a truth value. That is,
      /// the truth value for A is independent of the truth value for \neg A
      /// Therefore, there are 2*2*2*2*2*2 = 64 combinations of truth values for variables A, B, C
      for (int i = 0; i < numLinesTruthTable; i++) {
        final parsed = _parseFraction(strList[i], i);
        _probValues[i] = parsed;
        // If _parseFraction showed a SnackBar for an error, we might consider allValid as false
        // For simplicity here, we proceed with the parsed (or default) values.
        // A more robust solution might halt calculation or highlight fields.
      }

      initializeProbabilities(initialValues: _probValues);
      calculateAndDisplayProbabilities();
      setState(() {});
    } else {
      /// show a SnackBar if there is no undo available for 1 second
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelText('No more undos available'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void redoLastChange() {
    if (_undoRedoManager.canRedo()) {
      List<Object> objList = _undoRedoManager.redo() ?? _probValues;
      List<String> strList = objList.cast<String>();
      for (int i = 0; i < numLinesTruthTable; i++) {
        final parsed = _parseFraction(strList[i], i);
        _probValues[i] = parsed;
        // If _parseFraction showed a SnackBar for an error, we might consider allValid as false
        // For simplicity here, we proceed with the parsed (or default) values.
        // A more robust solution might halt calculation or highlight fields.
      }

      initializeProbabilities(initialValues: _probValues);
      calculateAndDisplayProbabilities();
      setState(() {});
    } else {
      /// show a SnackBar if there is no redo available for 1 second
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelText('No more redos available'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

//
  // void _initializeProbabilities(
  //     {List<(int, int)>? initialValues,
  //     Map<int, List<(int, int)>>? initialMap}) {

  void initializeProbabilities(
      {List<(int, int)>? initialValues, Map<int, (int, int)>? initialMap}) {
    _probValues = List.filled(numLinesTruthTable, (0, 1));
    if (initialMap != null) {
      // Initialize _probValues from initialMap
      for (var entry in initialMap.entries) {
        if (entry.key < _probValues.length) {
          _probValues[entry.key] = entry.value;
        }
      }
    } else {
      if (initialValues != null) {
        for (int i = 0;
            i < initialValues.length && i < _probValues.length;
            i++) {
          _probValues[i] = initialValues[i];
        }
      }
    }
    //_undoRedoManager.addToHistory(_probValues);

    /// Initialize all TextEditingControllers with the values corresponding to the probabilities
    /// _probValues
    _textControllers = List.generate(numLinesTruthTable, (index) {
      final value = _probValues[index];
      return TextEditingController(text: '${value.$1}/${value.$2}');
    });
    _probLabels = [];

    var valuesAnegA = [
      '0, 0, ',
      '0, 1, ',
      '1, 0, ',
      '1, 1, ',
    ];
    _truthVariableTable = [];
    for (int i = 0; i < numCombTruthValues; i++) {
      // A, \neg A
      var s = valuesAnegA[i];
      for (int j = 0; j < numCombTruthValues; j++) {
        // B, \neg B, \and \circ B
        var p = s + valuesAnegA[j];
        for (int k = 0; k < numCombTruthValues; k++) {
          // C, \neg C, \and \circ C
          var t = p + valuesAnegA[k];
          // remove the , followed by a space at the end
          t = t.substring(0, t.length - 2);
          var reducedPr = t.replaceAll(' ', '').replaceAll(',', '');
          _probLabels.add('Pr($reducedPr)');

          /// add the values of t to _truthVariableTable
          /// t.split(', ') is a list of strings
          List<String> parts = t.split(', ');
          List<int> truthValuesLine = parts.map((part) {
            return int.parse(part);
          }).toList();
          _truthVariableTable.add(truthValuesLine);
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

  (int, int) _parseFraction(String text, int index) {
    try {
      return parseFraction(text, index);
    } catch (e) {
      // var msg = e.toString();
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: SelText(msg)),
      // );
    }
    return (0, 1); // Default to 0/1 on error
  }

  // --- Calculation Logic ---
  @override
  void calculateAndDisplayProbabilities() {
    // put in the undo/redo manager

    // 1. Parse all TextField values and store them in _probValues
    var continueParsing = true;
    for (int i = 0; i < numLinesTruthTable; i++) {
      //final parsed = _parseFraction(_textControllers[i].text, i);
      (int, int) parsed = (0, 1); // Default value
      try {
        parsed = parseFraction(_textControllers[i].text, i);
        if (!continueParsing) {
          // If continueParsing is false, skip further parsing
          return;
        }
      } catch (e) {
        var msg = e.toString();

        /// show a Dialog with the error message. There should be two options:
        /// "Skip other errors" and "Continue". If "Skip other errors" is selected,
        /// this method returns. In either case, a SnackBar is shown with the message
        /// "The probabilities were not calculated"
        /// Show a Dialog with the error message
        continueParsing = false;
        showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const SelText('Error'),
              content: SelText(msg),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Close the dialog
                  },
                  child: const SelText('Skip other errors'),
                ),
                TextButton(
                  onPressed: () {
                    continueParsing = true;
                    Navigator.of(context).pop(true); // Close the dialog
                  },
                  child: const SelText('Continue'),
                ),
              ],
            );
          },
        );
      }

      _probValues[i] = parsed;
      // If _parseFraction showed a SnackBar for an error, we might consider allValid as false
      // For simplicity here, we proceed with the parsed (or default) values.
      // A more robust solution might halt calculation or highlight fields.
    }
    List<String> strList;
    // copy _textControllers to strList
    strList = _textControllers.map((controller) => controller.text).toList();
    _undoRedoManager.addToHistory(strList);

    _prSum = (0, 1);

    // Iterate through all 27 probabilities
    // Index mapping:
    // x_idx corresponds to _valueStrings[x_idx] (0 for "0", 1 for "1/2", 2 for "1")
    // y_idx corresponds to _valueStrings[y_idx]
    // z_idx corresponds to _valueStrings[z_idx]
    // The flat index in _probValues is x_idx * 9 + y_idx * 3 + z_idx
    _prANumeratorSum = '';
    _prBNumeratorSum = '';
    _prCNumeratorSum = '';
    _prABNumeratorSum = '';
    _prACNumeratorSum = '';
    _prBCNumeratorSum = '';
    _prABCNumeratorSum = '';
    _prNotANumeratorSum = '';
    _prNotBNumeratorSum = '';
    _prCNotANumeratorSum = '';
    _prCNotBNumeratorSum = '';

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

    for (int flatIndex = 0; flatIndex < numLinesTruthTable; flatIndex++) {
      (int, int) currentProb = _probValues[flatIndex];

      _prSum = addFractions(_prSum, currentProb);
      bool aIsTrue = _truthVariableTable[flatIndex][0] >= 1;
      bool bIsTrue = _truthVariableTable[flatIndex][2] >= 1;
      bool cIsTrue = _truthVariableTable[flatIndex][4] >= 1;
      bool aIsFalse = _truthVariableTable[flatIndex][1] >= 1;
      bool bIsFalse = _truthVariableTable[flatIndex][3] >= 1;
      bool cIsFalse = _truthVariableTable[flatIndex][5] >= 1;

      if (currentProb.$1 == 0) {
        // If the probability is 0, skip further calculations for this entry
        continue;
      }
      if (aIsTrue) {
        _prA = addFractions(_prA, currentProb);
        if (_prANumeratorSum.isNotEmpty) {
          _prANumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prANumeratorSum = '${currentProb.$1}';
        }
      }
      if (bIsTrue) {
        _prB = addFractions(_prB, currentProb);
        if (_prBNumeratorSum.isNotEmpty) {
          _prBNumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prBNumeratorSum = '${currentProb.$1}';
        }
      }
      if (cIsTrue) {
        _prC = addFractions(_prC, currentProb);
        if (_prCNumeratorSum.isNotEmpty) {
          _prCNumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prCNumeratorSum = '${currentProb.$1}';
        }
      }
      if (aIsTrue && bIsTrue) {
        _prAB = addFractions(_prAB, currentProb);
        if (_prABNumeratorSum.isNotEmpty) {
          _prABNumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prABNumeratorSum = '${currentProb.$1}';
        }
      }
      if (aIsTrue && cIsTrue) {
        _prAC = addFractions(_prAC, currentProb);
        if (_prACNumeratorSum.isNotEmpty) {
          _prACNumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prACNumeratorSum = '${currentProb.$1}';
        }
      }
      if (bIsTrue && cIsTrue) {
        _prBC = addFractions(_prBC, currentProb);
        if (_prBCNumeratorSum.isNotEmpty) {
          _prBCNumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prBCNumeratorSum = '${currentProb.$1}';
        }
      }

      if (aIsTrue && bIsTrue && cIsTrue) {
        _prABC = addFractions(_prABC, currentProb);
        if (_prABCNumeratorSum.isNotEmpty) {
          _prABCNumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prABCNumeratorSum = '${currentProb.$1}';
        }
      }

      if (aIsFalse) {
        _prNotA = addFractions(_prNotA, currentProb);
        if (_prNotANumeratorSum.isNotEmpty) {
          _prNotANumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prNotANumeratorSum = '${currentProb.$1}';
        }
      }
      if (bIsFalse) {
        _prNotB = addFractions(_prNotB, currentProb);
        if (_prNotBNumeratorSum.isNotEmpty) {
          _prNotBNumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prNotBNumeratorSum = '${currentProb.$1}';
        }
      }
      if (cIsFalse) {
        _prNotC = addFractions(_prNotC, currentProb);
        if (_prCNotANumeratorSum.isNotEmpty) {
          _prCNotANumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prCNotANumeratorSum = '${currentProb.$1}';
        }
      }

      if (cIsTrue && aIsFalse) {
        _prCNotA = addFractions(_prCNotA, currentProb);
        if (_prCNotANumeratorSum.isNotEmpty) {
          _prCNotANumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prCNotANumeratorSum = '${currentProb.$1}';
        }
      }
      if (cIsTrue && bIsFalse) {
        _prCNotB = addFractions(_prCNotB, currentProb);
        if (_prCNotBNumeratorSum.isNotEmpty) {
          _prCNotBNumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prCNotBNumeratorSum = '${currentProb.$1}';
        }
      }
      /*
            (int, int) _prCNotAandB = (0, 1);
  (int, int) _prNotAB = (0, 1);
  (int, int) _prANotB = (0, 1);
  (int, int) _prCNotAB = (0, 1);
  (int, int) _prCNotBA = (0, 1);

          */
      if (cIsTrue && !(aIsTrue && bIsTrue)) {
        _prCNotAandB = addFractions(_prCNotAandB, currentProb);
      }
      if (aIsFalse && bIsTrue) {
        _prNotAB = addFractions(_prNotAB, currentProb);
      }
      if (aIsTrue && bIsFalse) {
        _prANotB = addFractions(_prANotB, currentProb);
      }
      if (cIsTrue && aIsFalse && bIsTrue) {
        _prCNotAB = addFractions(_prCNotAB, currentProb);
      }
      if (cIsTrue && bIsFalse && aIsTrue) {
        _prCNotBA = addFractions(_prCNotBA, currentProb);
      }
      // ~(A & B) = ~A || ~B
      if (aIsFalse || bIsFalse) {
        _prNotAandB = addFractions(_prNotAandB, currentProb);
      }
      if (aIsTrue && cIsFalse) {
        _prANotC = addFractions(_prANotC, currentProb);
      }
      if (bIsTrue && cIsFalse) {
        _prBNotC = addFractions(_prBNotC, currentProb);
      }
      if (aIsTrue && bIsFalse && cIsFalse) {
        // A 1, B 0, C 0
        _prANotBNotC = addFractions(_prANotBNotC, currentProb);
      }
      if (bIsFalse && cIsFalse) {
        // B 0, C 0
        _prNotBNotC = addFractions(_prNotBNotC, currentProb);
      }
      if (aIsTrue && bIsTrue && cIsFalse) {
        // A 1, B 1, C 0
        _prABNotC = addFractions(_prABNotC, currentProb);
      }
    }
    // Update state to re-render the UI
    setState(() {});
  }

  // --- UI Building ---

  Widget _buildLeftPanel() {
    return Container(
      color: leftPanelColor,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          if (hideZeroProbabilities)
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      hideZeroProbabilities = false;
                    });
                  },
                  child: const SelText('Show All Probabilities'),
                ),
                SizedBox(height: 30),
              ],
            ),
          if (!hideZeroProbabilities)
            Column(
              /// center the button in the horizontal axis
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      hideZeroProbabilities = true;
                    });
                  },
                  child: const SelText('Show Only Non-Zero Probabilities'),
                ),
                SizedBox(height: 30),
              ],
            ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: valuationProbList(22, 0),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: valuationProbList(22, 22),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: valuationProbList(20, 44),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ListView valuationProbList(int size, int startIndex) {
    return ListView.builder(
      itemCount: size,
      itemBuilder: (context, index) {
        final actualIndex = index + startIndex;
        if (hideZeroProbabilities && _probValues[actualIndex].$1 == 0) {
          return const SizedBox.shrink(); // Return an empty widget
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            children: [
              SizedBox(
                width: 120, // Give label enough space
                child: SelText(
                  '$actualIndex: ${_probLabels[actualIndex]}',
                  style: TextStyle(fontSize: 11, fontFamily: 'Courier New'),
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                height: 20,
                width: 100, // Adjust height as needed
                child: TextField(
                  style: TextStyle(fontSize: 12),
                  controller: _textControllers[actualIndex],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onChanged: (value) =>
                      _onProbManualChanged(actualIndex, value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onProbManualChanged(int index, String value) {
    // Parse the new value and update the probability
    final parsedValue = _parseFraction(value, index);
    setState(() {
      _probValues[index] = parsedValue;
    });

    // Recalculate probabilities that depend on this value
    //_calculateAndDisplayProbabilities();
  }

  Widget _buildRightPanel() {
    return Container(
      color: rightPanelColor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          wrapToButtons(this, _prSum, context, isLoading: _isLoading),
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

  @override
  Future<void> resetBCT() async {
    setState(() {});
    initializeProbabilities(
      initialMap: {
        21: (835, 5120),
        22: (125, 5120),
        25: (1341, 5120),
        26: (1539, 5120),
        37: (193, 5120),
        41: (291, 5120),
        42: (669, 5120),
        47: (27, 5120),
        63: (100, 5120)
      },
    );
    calculateAndDisplayProbabilities();
  }

  @override
  Future<void> resetRaven() async {
    setState(() {});
    initializeProbabilities(
      initialMap: {
        ///  0   0  0
        21: (1000, 2650),

        ///  0   0 1/2
        22: (88, 2650),

        ///  0  1/2  0
        25: (36, 2650),

        ///  0  1/2 1/2   011010
        26: (138, 2650),

        ///  1   1   1    101010
        42: (940, 2650),

        /// 1/2  0   0    100101
        37: (181, 2650),

        /// 1/2  0  1/2   100110
        38: (0, 2650),

        /// 1/2 1/2  0     101001
        41: (52, 2650),

        /// 1/2 1/2 1/2
        63: (215, 2650),

        /*
        ///  0   0  0
        21: (1000, 2650),

        ///  0   0 1/2
        23: (88, 2650),

        ///  0  1/2  0
        29: (36, 2650),

        ///  0  1/2 1/2
        31: (138, 2650),

        ///  1   1   1
        42: (940, 2650),

        /// 1/2  0   0
        53: (181, 2650),

        /// 1/2  0  1/2
        55: (0, 2650),

        /// 1/2 1/2  0
        61: (52, 2650),

        /// 1/2 1/2 1/2
        63: (215, 2650),

        */
      },
    );
    calculateAndDisplayProbabilities();
  }

  @override
  Future<void> resetMiracle() async {
    setState(() {});
    initializeProbabilities(
      initialMap: {
        // 0  0   6033/8192

        21: (6033, 8192),

        // 0  1      1/64
        29: (128, 8192),

        // 1  0   1007/8192
        52: (1007, 8192),

        // 1  1      1/8
        60: (1024, 8192),
      },
    );
    calculateAndDisplayProbabilities();
  }

  // void _resetBCTCorpus() {
  //   setState(() {});
  //   initializeProbabilities(
  //     initialMap: {
  //       21: (735, 5120),
  //       22: (225, 5120),
  //       25: (1341, 5120),
  //       26: (1539, 5120),
  //       37: (193, 5120),
  //       38: (127, 5120),
  //       41: (291, 5120),
  //       42: (669, 5120),
  //       //47: (127, 5120),
  //       //63: (100, 5120)
  //     },
  //   );
  //   calculateAndDisplayProbabilities();
  // }

  @override
  Future<void> resetIP() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      initializeProbabilities(initialMap: {
        /*
        21: 0 1 0 1 0 1 : 1459/2000
23: 0 1 0 1 1 1 :  161/2000
25: 0 1 1 0 0 1 : 1/2000
29: 0 1 1 1 0 1 : 160/2000
31: 0 1 1 1 1 1 :  19/2000
37: 1 0 0 1 0 1 :   1/2000
53: 1 1 0 1 0 1 : 160/2000
55: 1 1 0 1 1 1 : 19/2000
61: 1 1 1 1 0 1 : 19/2000
63: 1 1 1 1 1 1 : 1/2000

        */
        21: (1459, 2000),
        23: (161, 2000),
        25: (1, 2000),
        29: (160, 2000),
        31: (19, 2000),
        37: (1, 2000),
        53: (160, 2000),
        55: (19, 2000),
        61: (19, 2000),
        63: (1, 2000),
      });

      calculateAndDisplayProbabilities();
    });
  }

  @override
  Future<void> reset() async {
    setState(() {
      initializeProbabilities();
      calculateAndDisplayProbabilities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SelText(
            'Probability Calculator for 4V (a logic with 4 truth values, like Belnap-Dunn)'),
        backgroundColor: scaffoldBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            selectedResult = ResultKind.reset;
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 800,
            child: _buildLeftPanel(),
          ),
          const SizedBox(width: 16.0), // Space between panels
          Expanded(
            flex: 1,
            child: _buildRightPanel(),
          ),
        ],
      ),
    );
  }

  @override
  void showText() {
    var text = r'\begin{align*}' '\n';
    String intToTruthValue(int i) {
      switch (i) {
        case 0:
          return '0, 0';
        case 1:
          return '0, 1';
        case 2:
          return '1, 0';
        case 3:
          return '1, 1';
        default:
          return '';
      }
    }

    int size = _probValues.length;
    var k = 0;
    for (int aA = 0; aA < numCombTruthValues; aA++) {
      for (int bB = 0; bB < numCombTruthValues; bB++) {
        for (int cC = 0; cC < numCombTruthValues; cC++) {
          /// \rule{0pt}{3ex}$(0, 0, 0)$ &
          if (_probValues[k].$1 != 0) {
            var frac = _textControllers[k].text;
            text +=
                's_{$k} &= (${intToTruthValue(aA)}, ${intToTruthValue(bB)}, ${intToTruthValue(cC)}) & Pr(s_{$k}) = $frac ${k < size - 1 ? '\\\\[0.2cm] ' : ''}\n';
          }
          k++;
        }
      }
    }

    text += r'\end{align*}' '\n';

    String denom = '';

    /// found the first _probValues with a non-zero denominator and assing the corresponding
    /// _textControllers text to denom
    for (int i = 0; i < _probValues.length; i++) {
      if (_probValues[i].$2 != 0) {
        denom = _textControllers[i].text.split('/')[1];
        break;
      }
    }

    text += r'\begin{align*}' '\n';
    text += r'Pr(A) &= \frac{' +
        _prANumeratorSum +
        r'}{' +
        denom +
        r'} &= ' '${(_prA.$1 * 1.0 / _prA.$2).toStringAsFixed(5)}\\\\' '\n';
    text += r'Pr(B) &= \frac{' +
        _prBNumeratorSum +
        r'}{' +
        denom +
        r'} &= ' '${(_prB.$1 * 1.0 / _prB.$2).toStringAsFixed(5)}\\\\' '\n';
    text += r'Pr(C) &= \frac{' +
        _prCNumeratorSum +
        r'}{' +
        denom +
        r'} &= ' '${(_prC.$1 * 1.0 / _prC.$2).toStringAsFixed(5)}\\\\' '\n';
    text += r'Pr(A \land B) &= \frac{' +
        _prABNumeratorSum +
        r'}{' +
        denom +
        r'} &= ' '${(_prAB.$1 * 1.0 / _prAB.$2).toStringAsFixed(5)}\\\\' '\n';
    text += r'Pr(A \land C) &= \frac{' +
        _prACNumeratorSum +
        r'}{' +
        denom +
        r'} &= ' '${(_prAC.$1 * 1.0 / _prAC.$2).toStringAsFixed(5)}\\\\' '\n';
    text += r'Pr(B \land C) &= \frac{' +
        _prBCNumeratorSum +
        r'}{' +
        denom +
        r'} &= ' '${(_prBC.$1 * 1.0 / _prBC.$2).toStringAsFixed(5)}\\\\' '\n';
    text += r'Pr(A \land B \land C) &= \frac{' +
        _prABCNumeratorSum +
        r'}{' +
        denom +
        r'} \\\\' '\n';
    text += r'Pr(\neg A) &= \frac{' +
        _prNotANumeratorSum +
        r'}{' +
        denom +
        r'} &= '
            '${(_prNotA.$1 * 1.0 / _prNotA.$2).toStringAsFixed(5)}\\\\'
            '\n';
    text += r'Pr(\neg B) &= \frac{' +
        _prNotBNumeratorSum +
        r'}{' +
        denom +
        r'} &= '
            '${(_prNotB.$1 * 1.0 / _prNotB.$2).toStringAsFixed(5)}\\\\'
            '\n';
    text += r'Pr(C \land \neg A) &= \frac{' +
        _prCNotANumeratorSum +
        r'}{' +
        denom +
        r'} &= '
            '${(_prCNotA.$1 * 1.0 / _prCNotA.$2).toStringAsFixed(5)}\\\\'
            '\n';
    text += r'Pr(C \land \neg B) &= \frac{' +
        _prCNotBNumeratorSum +
        r'}{' +
        denom +
        r'} &= '
            '${(_prCNotB.$1 * 1.0 / _prCNotB.$2).toStringAsFixed(5)}\\\\'
            '\n';
    text += r'Pr(\Sigma) &= \frac{' +
        _prSum.$1.toString() +
        r'}{' +
        _prSum.$2.toString() +
        r'} &= ' '${(_prSum.$1 * 1.0 / _prSum.$2).toStringAsFixed(5)}\\\\' '\n';

    text += r'Pr(A)Pr(B) &= \frac{' +
        (_prA.$1 * _prB.$1).toString() +
        r'}{' +
        (_prA.$2 * _prB.$2).toString() +
        r'} & = '
            '${((_prA.$1 * 1.0 * _prB.$1) / (_prA.$2 * _prB.$2)).toStringAsFixed(5)}\\\\'
            '\n';
    text += r'Pr(A)Pr(C) &= \frac{' +
        (_prA.$1 * _prC.$1).toString() +
        r'}{' +
        (_prA.$2 * _prC.$2).toString() +
        r'} & = '
            '${((_prA.$1 * 1.0 * _prC.$1) / (_prA.$2 * _prC.$2)).toStringAsFixed(5)}\\\\'
            '\n';
    text += r'Pr(B)Pr(C) &= \frac{' +
        (_prB.$1 * _prC.$1).toString() +
        r'}{' +
        (_prB.$2 * _prC.$2).toString() +
        r'} & = '
            '${((_prB.$1 * 1.0 * _prC.$1) / (_prB.$2 * _prC.$2)).toStringAsFixed(5)}\\\\'
            '\n';
    text += r'Pr(A)Pr(B)Pr(C) &= \frac{' +
        (_prA.$1 * _prB.$1 * _prC.$1).toString() +
        r'}{' +
        (_prA.$2 * _prB.$2 * _prC.$2).toString() +
        r'} & = '
            '${((_prA.$1 * 1.0 * _prB.$1 * 1.0 * _prC.$1) / (_prA.$2 * _prB.$2 * _prC.$2)).toStringAsFixed(5)}\\\\'
            '\n';
    var prCgivenA = div(_prAC, _prA);
    var prCgivenB = div(_prBC, _prB);
    var sCA = sub(div(_prAC, _prA), div(_prCNotA, _prNotA));
    var sCB = sub(div(_prBC, _prB), div(_prCNotB, _prNotB));

    text += r'Pr(C|A) &= \frac{' +
        (_prAC.$1 * _prA.$2).toString() +
        r'}{' +
        (_prA.$1 * _prAC.$2).toString() +
        r'} & = '
            '${(prCgivenA.$1 * 1.0 / prCgivenA.$2).toStringAsFixed(5)}\\\\'
            '\n';
    text += r'Pr(C|B) &= \frac{' +
        (_prBC.$1 * _prB.$2).toString() +
        r'}{' +
        (_prB.$1 * _prBC.$2).toString() +
        r'} & = '
            '${(prCgivenB.$1 * 1.0 / prCgivenB.$2).toStringAsFixed(5)}\\\\'
            '\n';
    text += r'Pr(C \land \neg A) &= \frac{' +
        _prCNotA.$1.toString() +
        r'}{' +
        _prCNotA.$2.toString() +
        r'} & = '
            '${(_prCNotA.$1 * 1.0 / _prCNotA.$2).toStringAsFixed(5)}\\\\'
            '\n';
    text += r'Pr(C \land \neg B) &= \frac{' +
        _prCNotB.$1.toString() +
        r'}{' +
        _prCNotB.$2.toString() +
        r'} & = '
            '${(_prCNotB.$1 * 1.0 / _prCNotB.$2).toStringAsFixed(5)}\\\\'
            '\n';
    text += r's(C, A) &= \frac{' +
        sCA.$1.toString() +
        r'}{' +
        sCA.$2.toString() +
        r'} & = ' '${(sCA.$1 * 1.0 / sCA.$2).toStringAsFixed(5)}\\\\' '\n';
    text += r's(C, B) &= \frac{' +
        sCB.$1.toString() +
        r'}{' +
        sCB.$2.toString() +
        r'} & = ' '${(sCB.$1 * 1.0 / sCB.$2).toStringAsFixed(5)}\\\\' '\n';

    var prAplusNotA = addFractions(_prNotA, _prA);
    text += r'Pr(\neg A) + Pr(A) &= \frac{' +
        _prNotA.$1.toString() +
        r'}{' +
        _prNotA.$2.toString() +
        r'} + \frac{' +
        _prA.$1.toString() +
        r'}{' +
        _prA.$2.toString() +
        r'}  & = '
            '${(prAplusNotA.$1 * 1.0 / prAplusNotA.$2).toStringAsFixed(5)}\\\\'
            '\n';
    var prBplusNotB = addFractions(_prNotB, _prB);
    text += r'Pr(\neg B) + Pr(B) &= \frac{' +
        _prNotB.$1.toString() +
        r'}{' +
        _prNotB.$2.toString() +
        r'} + \frac{' +
        _prB.$1.toString() +
        r'}{' +
        _prB.$2.toString() +
        r'}   & = '
            '${(prBplusNotB.$1 * 1.0 / prBplusNotB.$2).toStringAsFixed(5)}\\\\'
            '\n';
    text += r'\end{align*}' '\n';

    text += '\n\n\\begin{comment}' + octaveStr + '\n\\end{comment}';

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
}
