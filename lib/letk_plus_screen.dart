// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:prob_lfi1/common_lib.dart';
import 'package:prob_lfi1/fraction.dart';

/*
This file is for the Letk+ probability calculator screen. Logic $LET^+-k$ is a 
six-value logic with the following truth values: 
    T 
    T0
    B
    N
    F0
    F
*/

enum LetKTV {
  t,
  t0,
  b,
  n,
  f0,
  f;

  bool designated() {
    return this == LetKTV.t || this == LetKTV.t0 || this == LetKTV.b;
  }

  LetKTV not() {
    switch (this) {
      case LetKTV.t:
        return LetKTV.f;
      case LetKTV.t0:
        return LetKTV.f0;
      case LetKTV.b:
        return LetKTV.b;
      case LetKTV.n:
        return LetKTV.n;
      case LetKTV.f0:
        return LetKTV.t0;
      case LetKTV.f:
        return LetKTV.t;
    }
  }

  /// Compare enum values based on their index order
  /// Returns true if this value is >= other value
  bool operator >=(LetKTV other) {
    return index >= other.index;
  }

  /// Additional comparison operators for convenience
  bool operator <=(LetKTV other) {
    return index <= other.index;
  }

  bool operator >(LetKTV other) {
    return index > other.index;
  }

  bool operator <(LetKTV other) {
    return index < other.index;
  }
}

/// for variables A, B, and C, there are 6*6*6 = 216 possibilities
final numLinesTruthTable = 216;
final numCombTruthValues = 6;

class LetkPlusScreen extends StatefulWidget {
  const LetkPlusScreen({super.key});

  @override
  State<LetkPlusScreen> createState() => _LetkPlusScreenState();
}

class _LetkPlusScreenState extends State<LetkPlusScreen> implements ILogic {
  // --- State Variables ---

  // (b) probValues and related
  late List<TextEditingController> _textControllers;
  late List<(int, int)> _probValues;
  late List<String> _probLabels;
  late String octaveStr = '';

  /// Truth variable table for the numLinesTruthTable probabilities
  /// Each sublist corresponds to a combination of A, B, C truth values
  late List<List<LetKTV>> _truthVariableTable;
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
      {List<(int, int)>? initialValues,
      Map<int, (int, int)>? initialMap,
      Map<(LetKTV, LetKTV, LetKTV), (int, int)>? initialTruthMap}) {
    _probValues = List.filled(numLinesTruthTable, (0, 1));
    if (initialTruthMap != null) {
      // Initialize _probValues from initialTruthMap
      for (var entry in initialTruthMap.entries) {
        LetKTV a = entry.key.$1;
        LetKTV b = entry.key.$2;
        LetKTV c = entry.key.$3;

        // Find the corresponding flat index in _probValues
        for (int i = 0; i < numLinesTruthTable; i++) {
          if (_truthVariableTable[i][0] == a &&
              _truthVariableTable[i][1] == b &&
              _truthVariableTable[i][2] == c) {
            _probValues[i] = entry.value;
            break;
          }
        }
      }
    } else if (initialMap != null) {
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

    /// truthValuesA should have strings corresponding to LetKTruthValues
    var truthValuesA = [
      't, ',
      't0, ',
      'b, ',
      'n, ',
      'f0, ',
      'f, ',
    ];
    _truthVariableTable = [];
    for (int i = 0; i < numCombTruthValues; i++) {
      // A
      var s = truthValuesA[i];
      for (int j = 0; j < numCombTruthValues; j++) {
        // B
        var p = s + truthValuesA[j];
        for (int k = 0; k < numCombTruthValues; k++) {
          // C
          var t = p + truthValuesA[k];
          // remove the , followed by a space at the end
          t = t.substring(0, t.length - 2);
          var reducedPr = t.replaceAll(' ', '').replaceAll(',', '');
          _probLabels.add('Pr($reducedPr)');

          /// add the values of t to _truthVariableTable
          /// t.split(', ') is a list of strings
          List<String> parts = t.split(', ');
          List<LetKTV> truthValuesLine = parts.map((part) {
            return LetKTV.values
                .firstWhere((e) => e.toString().split('.').last == part);
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

    for (int flatIndex = 0; flatIndex < numLinesTruthTable; flatIndex++) {
      (int, int) currentProb = _probValues[flatIndex];

      _prSum = addFractions(_prSum, currentProb);

      if (currentProb.$1 == 0) {
        continue;
      }

      LetKTV aValue = _truthVariableTable[flatIndex][0];
      LetKTV bValue = _truthVariableTable[flatIndex][1];
      LetKTV cValue = _truthVariableTable[flatIndex][2];
      bool aIsTrue = aValue.designated();
      bool bIsTrue = bValue.designated();
      bool cIsTrue = cValue.designated();
      bool notAIsTrue = aValue.not().designated();
      bool notBIsTrue = bValue.not().designated();
      bool notCIsTrue = cValue.not().designated();

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

      if (notAIsTrue) {
        _prNotA = addFractions(_prNotA, currentProb);
        if (_prNotANumeratorSum.isNotEmpty) {
          _prNotANumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prNotANumeratorSum = '${currentProb.$1}';
        }
      }
      if (notBIsTrue) {
        _prNotB = addFractions(_prNotB, currentProb);
        if (_prNotBNumeratorSum.isNotEmpty) {
          _prNotBNumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prNotBNumeratorSum = '${currentProb.$1}';
        }
      }
      if (notCIsTrue) {
        _prNotC = addFractions(_prNotC, currentProb);
        if (_prCNotANumeratorSum.isNotEmpty) {
          _prCNotANumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prCNotANumeratorSum = '${currentProb.$1}';
        }
      }

      if (cIsTrue && notAIsTrue) {
        _prCNotA = addFractions(_prCNotA, currentProb);
        if (_prCNotANumeratorSum.isNotEmpty) {
          _prCNotANumeratorSum += '+ ${currentProb.$1}';
        } else {
          _prCNotANumeratorSum = '${currentProb.$1}';
        }
      }
      if (cIsTrue && notBIsTrue) {
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
      if (notAIsTrue && bIsTrue) {
        _prNotAB = addFractions(_prNotAB, currentProb);
      }
      if (aIsTrue && notBIsTrue) {
        _prANotB = addFractions(_prANotB, currentProb);
      }
      if (cIsTrue && notAIsTrue && bIsTrue) {
        _prCNotAB = addFractions(_prCNotAB, currentProb);
      }
      if (cIsTrue && notBIsTrue && aIsTrue) {
        _prCNotBA = addFractions(_prCNotBA, currentProb);
      }
      // ~(A & B) = ~A || ~B
      if (notAIsTrue || notBIsTrue) {
        _prNotAandB = addFractions(_prNotAandB, currentProb);
      }
      if (aIsTrue && notCIsTrue) {
        _prANotC = addFractions(_prANotC, currentProb);
      }
      if (bIsTrue && notCIsTrue) {
        _prBNotC = addFractions(_prBNotC, currentProb);
      }
      /*
  final (int, int) _prANotBNotC = (0, 1);
  final (int, int) _prNotBNotC = (0, 1);
  final (int, int) _prABNotC = (0, 1);

      */
      if (aIsTrue && notBIsTrue && notCIsTrue) {
        _prANotBNotC = addFractions(_prANotBNotC, currentProb);
      }
      if (notBIsTrue && notCIsTrue) {
        _prNotBNotC = addFractions(_prNotBNotC, currentProb);
      }
      if (aIsTrue && bIsTrue && notCIsTrue) {
        _prABNotC = addFractions(_prABNotC, currentProb);
      }
    }
    // Update state to re-render the UI
    setState(() {});
  }

  // --- UI Building ---

  Widget _buildLeftPanel() {
    return Container(
      color: creamTea,
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: valuationProbList(72, 0),
          ),
          const SizedBox(width: 2),
          SizedBox(
            width: 300,
            child: valuationProbList(72, 72),
          ),
          const SizedBox(width: 2),
          SizedBox(
            width: 300,
            child: valuationProbList(72, 144),
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
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            children: [
              SizedBox(
                width: 60, // Give label enough space
                child: SelText(
                  '$actualIndex: ${_probLabels[actualIndex]}',
                  style: TextStyle(fontSize: 9, fontFamily: 'Courier New'),
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                height: 20,
                width: 90, // Adjust height as needed
                child: TextField(
                  style: TextStyle(fontSize: 10),
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
      color: paleOolong,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          wrapToButtons(this, _prSum),
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
      initialTruthMap: {
        /*
 0   0   0     835/5120
 0   0  1/2	   125/5120
 0	1/2  0	  1341/5120	
 0   1   1    1539/5120
1/2  0   0     193/5120 
1/2 1/2  0      291/5120 
1/2 1/2 1/2     796/5120

        */
        (LetKTV.f0, LetKTV.f0, LetKTV.f0): (835, 5120),
        (LetKTV.f0, LetKTV.f0, LetKTV.b): (125, 5120),
        (LetKTV.f0, LetKTV.b, LetKTV.f0): (1341, 5120),
        (LetKTV.f0, LetKTV.t0, LetKTV.t0): (1539, 5120),
        (LetKTV.t0, LetKTV.f0, LetKTV.f0): (193, 5120),
        (LetKTV.t0, LetKTV.t0, LetKTV.f0): (291, 5120),
        (LetKTV.b, LetKTV.b, LetKTV.b): (796, 5120),
      },
    );
    calculateAndDisplayProbabilities();
  }

  @override
  Future<void> resetPI() async {
    setState(() {
      initializeProbabilities(initialTruthMap: {
        (LetKTV.f0, LetKTV.f0, LetKTV.f0): (1459, 2000),
        (LetKTV.f0, LetKTV.f0, LetKTV.b): (161, 2000),
        (LetKTV.f0, LetKTV.b, LetKTV.f0): (161, 2000),
        (LetKTV.f0, LetKTV.b, LetKTV.b): (19, 2000),
        (LetKTV.b, LetKTV.f0, LetKTV.f0): (161, 2000),
        (LetKTV.b, LetKTV.f0, LetKTV.b): (19, 2000),
        (LetKTV.b, LetKTV.b, LetKTV.f0): (19, 2000),
        (LetKTV.b, LetKTV.b, LetKTV.b): (1, 2000),
      });
      calculateAndDisplayProbabilities();
    });
  }

  @override
  Future<void> reset() async {
    setState(() {
      initializeProbabilities(initialTruthMap: {
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

        0: (1459, 2000),  // 0 0 0 
        1: (161, 2000),   // 0 0 1
        2: (161, 2000),   // 0 1 0
        3: (19, 2000),    // 0 1 1
        4: (161, 2000),   // 1 0 0
        5: (19, 2000),    // 1 0 1
        6: (19, 2000),    // 1 1 0
        7: (1, 2000),     // 1 1 1


        */
        (LetKTV.f0, LetKTV.f0, LetKTV.f0): (1459, 2000),
        (LetKTV.f0, LetKTV.f0, LetKTV.b): (161, 2000),
        (LetKTV.f0, LetKTV.b, LetKTV.f0): (161, 2000),
        (LetKTV.f0, LetKTV.b, LetKTV.b): (19, 2000),
        (LetKTV.b, LetKTV.f0, LetKTV.f0): (161, 2000),
        (LetKTV.b, LetKTV.f0, LetKTV.b): (19, 2000),
        (LetKTV.b, LetKTV.b, LetKTV.f0): (19, 2000),
        (LetKTV.b, LetKTV.b, LetKTV.b): (1, 2000),
        /*
        (LetKTV.f0, LetKTV.f0, LetKTV.f0): (1459, 2000),
        (LetKTV.f0, LetKTV.f0, LetKTV.t0): (161, 2000),
        (LetKTV.f0, LetKTV.t0, LetKTV.f0): (161, 2000),
        //(LetKTV.f0, LetKTV.b, LetKTV.t0): (160, 2000),
        (LetKTV.f0, LetKTV.t0, LetKTV.t0): (19, 2000),
        //(LetKTV.t0, LetKTV.f0, LetKTV.f0): (1, 2000),
        (LetKTV.t0, LetKTV.f0, LetKTV.f0): (161, 2000),
        (LetKTV.t0, LetKTV.f0, LetKTV.t0): (19, 2000),
        (LetKTV.t0, LetKTV.t0, LetKTV.f0): (19, 2000),
        (LetKTV.t0, LetKTV.t0, LetKTV.t0): (1, 2000),

        */
      });

      calculateAndDisplayProbabilities();
    });
  }

  @override
  Future<void> resetRaven() async {
    initializeProbabilities(initialTruthMap: {
      /*
          0: (1128, 2560),      // 0   0   0    1128/2560
          1: (51, 2560),        // 0   0   1      51/2560
          4: (1125, 2560),      // 1   0   0    1125/2560
          5: (0, 2560),         // 1   0   1      0/2560
          2: (21, 2560),        // 0   1   0      21/2560
          3: (80, 2560),        // 0   1   1      80/2560
          6: (30, 2560),        // 1   1   0      30/2560
          7: (125, 2560),       // 1   1   1     125/2560
      */
      (LetKTV.f0, LetKTV.f0, LetKTV.f0): (1128, 2560),
      (LetKTV.f0, LetKTV.f0, LetKTV.b): (51, 2560),
      (LetKTV.b, LetKTV.f0, LetKTV.f0): (1125, 2560),
      (LetKTV.b, LetKTV.f0, LetKTV.b): (0, 2560),
      (LetKTV.f0, LetKTV.b, LetKTV.f0): (21, 2560),
      (LetKTV.f0, LetKTV.b, LetKTV.b): (80, 2560),
      (LetKTV.b, LetKTV.b, LetKTV.f0): (30, 2560),
      (LetKTV.b, LetKTV.b, LetKTV.b): (125, 2560),

      // (LetKTV.f0, LetKTV.f0, LetKTV.f0): (1128, 2560),
      // (LetKTV.f0, LetKTV.f0, LetKTV.t0): (51, 2560),
      // (LetKTV.t0, LetKTV.f0, LetKTV.f0): (1125, 2560),
      // (LetKTV.t0, LetKTV.f0, LetKTV.t0): (0, 2560),
      // (LetKTV.f0, LetKTV.t0, LetKTV.f0): (21, 2560),
      // (LetKTV.f0, LetKTV.t0, LetKTV.t0): (80, 2560),
      // (LetKTV.t0, LetKTV.t0, LetKTV.f0): (30, 2560),
      // (LetKTV.t0, LetKTV.t0, LetKTV.t0): (125, 2560),
    });

    calculateAndDisplayProbabilities();
    setState(() {});
  }

  @override
  Future<void> resetMiracle() async {
    // 0  0   6033/8192
    // 0  1      1/64
    // 1  0   1007/8192
    // 1  1      1/8
    initializeProbabilities(initialTruthMap: {
      (LetKTV.f0, LetKTV.f0, LetKTV.f0): (6033, 8192),
      (LetKTV.f0, LetKTV.b, LetKTV.f0): (128, 8192),
      (LetKTV.b, LetKTV.f0, LetKTV.f0): (1007, 8192),
      (LetKTV.b, LetKTV.b, LetKTV.f0): (1024, 8192),
    });

    calculateAndDisplayProbabilities();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          SelText('Probability Calculator for '),
          Math.tex('LET^+_K')
        ]),
        backgroundColor: const Color.fromARGB(255, 225, 244, 252),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
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
    String text = 'No text to show';

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
