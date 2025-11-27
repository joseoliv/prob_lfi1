// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prob_lfi1/common_lib.dart';
import 'package:prob_lfi1/fraction.dart';

/// for variables A, \neg A, B, \neg B, C, \neg C, there are 64 possibilities
final numLinesTruthTable = 8;
final numCombTruthValues = 2; //  0 1

class ClassicalScreen extends StatefulWidget {
  const ClassicalScreen({super.key});

  @override
  State<ClassicalScreen> createState() => _ClassicalScreenState();
}

class _ClassicalScreenState extends State<ClassicalScreen> {
  // --- State Variables ---

  // (b) probValues and related
  late List<TextEditingController> _textControllers;
  late List<(int, int)> _probValues;
  late List<String> _probLabels;
  late String octaveStr = '';

  /// Truth variable table for the numLinesTruthTable probabilities
  /// Each sublist corresponds to a combination of A, B, C truth values
  late List<List<int>> _truthVariableTable;
  String? _selectedResetOption;
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
  String _prNotCNumeratorSum = '';
  String _prCNotANumeratorSum = '';
  String _prCNotBNumeratorSum = '';
  String _prANotCNumeratorSum = '';
  String _prBNotCNumeratorSum = '';

  @override
  void initState() {
    super.initState();
    _initializeProbabilities();
  }

  // --- Undo/Redo Logic ---
  // a circular buffer to store the last 10 changes
  final UndoRedoManager<List<String>> _undoRedoManager = UndoRedoManager();

  void _undoLastChange() {
    if (_undoRedoManager.canUndo()) {
      List<Object> objList = _undoRedoManager.undo() ?? _probValues;
      List<String> strList = objList.cast<String>();

      for (int i = 0; i < numLinesTruthTable; i++) {
        final parsed = _parseFraction(strList[i], i);
        _probValues[i] = parsed;
      }

      _initializeProbabilities(initialValues: _probValues);
      _calculateAndDisplayProbabilities();
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

  void _redoLastChange() {
    if (_undoRedoManager.canRedo()) {
      List<Object> objList = _undoRedoManager.redo() ?? _probValues;
      List<String> strList = objList.cast<String>();
      for (int i = 0; i < numLinesTruthTable; i++) {
        final parsed = _parseFraction(strList[i], i);
        _probValues[i] = parsed;
      }

      _initializeProbabilities(initialValues: _probValues);
      _calculateAndDisplayProbabilities();
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

  void _initializeProbabilities(
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

    var valuesA = [
      '0, ',
      '1, ',
    ];
    _truthVariableTable = [];
    for (int i = 0; i < numCombTruthValues; i++) {
      // A
      var s = valuesA[i];
      for (int j = 0; j < numCombTruthValues; j++) {
        // B
        var p = s + valuesA[j];
        for (int k = 0; k < numCombTruthValues; k++) {
          // C
          var t = p + valuesA[k];
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
  void _calculateAndDisplayProbabilities() {
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

    // Initialize sums
    _prA = (0, 1);
    _prB = (0, 1);
    _prC = (0, 1);
    _prAB = (0, 1);
    _prAC = (0, 1);
    _prBC = (0, 1);
    _prABC = (0, 1);

    _prNotA = (0, 1);
    _prNotB = (0, 1);
    _prNotC = (0, 1);
    _prCNotA = (0, 1);
    _prCNotB = (0, 1);
    _prANotC = (0, 1);
    _prBNotC = (0, 1);

    // Iterate through all numLinesTruthTable probabilities
    // Index mapping:
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
    _prNotCNumeratorSum = '';
    _prCNotBNumeratorSum = '';
    _prANotCNumeratorSum = '';
    _prBNotCNumeratorSum = '';

    octaveStr = '';
    var listForA = <String>[];
    var listForB = <String>[];
    var listForC = <String>[];
    var listForAB = <String>[];
    var listForAC = <String>[];
    var listForBC = <String>[];
    var listForABC = <String>[];
    var listForNotA = <String>[];
    var listForNotB = <String>[];
    var listForNotC = <String>[];
    var listForANotC = <String>[];
    var listForBNotC = <String>[];

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

    for (int xIdx = 0; xIdx < numCombTruthValues; xIdx++) {
      for (int yIdx = 0; yIdx < numCombTruthValues; yIdx++) {
        for (int zIdx = 0; zIdx < numCombTruthValues; zIdx++) {
          int flatIndex = xIdx * numCombTruthValues * numCombTruthValues +
              yIdx * numCombTruthValues +
              zIdx;
          (int, int) currentProb = _probValues[flatIndex];

          bool aIsTrue = _truthVariableTable[flatIndex][0] >= 1;
          bool bIsTrue = _truthVariableTable[flatIndex][1] >= 1;
          bool cIsTrue = _truthVariableTable[flatIndex][2] >= 1;

          _prSum = addFractionsKeepDenum(_prSum, currentProb);

          if (aIsTrue) {
            listForA.add('s$flatIndex');
          }
          if (bIsTrue) {
            listForB.add('s$flatIndex');
          }
          if (cIsTrue) {
            listForC.add('s$flatIndex');
          }
          if (aIsTrue && bIsTrue) {
            listForAB.add('s$flatIndex');
          }
          if (aIsTrue && cIsTrue) {
            listForAC.add('s$flatIndex');
          }
          if (bIsTrue && cIsTrue) {
            listForBC.add('s$flatIndex');
          }
          if (aIsTrue && bIsTrue && cIsTrue) {
            listForABC.add('s$flatIndex');
          }
          if (!aIsTrue) {
            listForNotA.add('s$flatIndex');
          }
          if (!bIsTrue) {
            listForNotB.add('s$flatIndex');
          }
          if (!cIsTrue) {
            listForNotC.add('s$flatIndex');
          }
          if (aIsTrue && !cIsTrue) {
            listForANotC.add('s$flatIndex');
          }
          if (bIsTrue && !cIsTrue) {
            listForBNotC.add('s$flatIndex');
          }

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
          if (!(aIsTrue && bIsTrue)) {
            _prNotAandB = addFractions(_prNotAandB, currentProb);
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

          if (!aIsTrue) {
            _prNotA = addFractions(_prNotA, currentProb);
            if (_prNotANumeratorSum.isNotEmpty) {
              _prNotANumeratorSum += '+ ${currentProb.$1}';
            } else {
              _prNotANumeratorSum = '${currentProb.$1}';
            }
          }
          if (!bIsTrue) {
            _prNotB = addFractions(_prNotB, currentProb);
            if (_prNotBNumeratorSum.isNotEmpty) {
              _prNotBNumeratorSum += '+ ${currentProb.$1}';
            } else {
              _prNotBNumeratorSum = '${currentProb.$1}';
            }
          }
          if (!cIsTrue) {
            _prNotC = addFractions(_prNotC, currentProb);
            if (_prNotCNumeratorSum.isNotEmpty) {
              _prNotCNumeratorSum += '+ ${currentProb.$1}';
            } else {
              _prNotCNumeratorSum = '${currentProb.$1}';
            }
          }

          if (cIsTrue && !aIsTrue) {
            _prCNotA = addFractions(_prCNotA, currentProb);
            if (_prCNotANumeratorSum.isNotEmpty) {
              _prCNotANumeratorSum += '+ ${currentProb.$1}';
            } else {
              _prCNotANumeratorSum = '${currentProb.$1}';
            }
          }
          if (cIsTrue && !bIsTrue) {
            _prCNotB = addFractions(_prCNotB, currentProb);
            if (_prCNotBNumeratorSum.isNotEmpty) {
              _prCNotBNumeratorSum += '+ ${currentProb.$1}';
            } else {
              _prCNotBNumeratorSum = '${currentProb.$1}';
            }
          }

          /// A and ~C,   B and ~C
          if (aIsTrue && !cIsTrue) {
            _prANotC = addFractions(_prANotC, currentProb);
            if (_prANotCNumeratorSum.isNotEmpty) {
              _prANotCNumeratorSum += '+ ${currentProb.$1}';
            } else {
              _prANotCNumeratorSum = '${currentProb.$1}';
            }
          }

          if (bIsTrue && !cIsTrue) {
            _prBNotC = addFractions(_prBNotC, currentProb);
            if (_prBNotCNumeratorSum.isNotEmpty) {
              _prBNotCNumeratorSum += '+ ${currentProb.$1}';
            } else {
              _prBNotCNumeratorSum = '${currentProb.$1}';
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
          if (!aIsTrue && bIsTrue) {
            _prNotAB = addFractions(_prNotAB, currentProb);
          }
          if (aIsTrue && !bIsTrue) {
            _prANotB = addFractions(_prANotB, currentProb);
          }
          if (cIsTrue && !aIsTrue && bIsTrue) {
            _prCNotAB = addFractions(_prCNotAB, currentProb);
          }
          if (cIsTrue && !bIsTrue && aIsTrue) {
            _prCNotBA = addFractions(_prCNotBA, currentProb);
          }
          // _prANotBNotC = (0, 1);
          // _prNotBNotC = (0, 1);
          // _prABNotC = (0, 1);
          if (aIsTrue && !bIsTrue && !cIsTrue) {
            _prANotBNotC = addFractions(_prANotBNotC, currentProb);
          }
          if (!bIsTrue && !cIsTrue) {
            _prNotBNotC = addFractions(_prNotBNotC, currentProb);
          }
          if (aIsTrue && bIsTrue && !cIsTrue) {
            _prABNotC = addFractions(_prABNotC, currentProb);
          }
        }
      }
    }

    /// if listForA is [ 's0', 's1', 's2' ]
    if (listForA.isNotEmpty) {
      octaveStr += 'PrA = ';
      octaveStr += listForA.join(' + ');
    }
    if (listForB.isNotEmpty) {
      octaveStr += '\nPrB = ';
      octaveStr += listForB.join(' + ');
    }
    if (listForC.isNotEmpty) {
      octaveStr += '\nPrC = ';
      octaveStr += listForC.join(' + ');
    }
    if (listForAB.isNotEmpty) {
      octaveStr += '\nPrAB = ';
      octaveStr += listForAB.join(' + ');
    }
    if (listForAC.isNotEmpty) {
      octaveStr += '\nPrAC = ';
      octaveStr += listForAC.join(' + ');
    }
    if (listForBC.isNotEmpty) {
      octaveStr += '\nPrBC = ';
      octaveStr += listForBC.join(' + ');
    }
    if (listForABC.isNotEmpty) {
      octaveStr += '\nPrABC = ';
      octaveStr += listForABC.join(' + ');
    }
    if (listForNotA.isNotEmpty) {
      octaveStr += '\nPrNotA = ';
      octaveStr += listForNotA.join(' + ');
    }
    if (listForNotB.isNotEmpty) {
      octaveStr += '\nPrNotB = ';
      octaveStr += listForNotB.join(' + ');
    }
    if (listForNotC.isNotEmpty) {
      octaveStr += '\nPrNotC = ';
      octaveStr += listForNotC.join(' + ');
    }
    if (_prCNotA.$1 > 0) {
      octaveStr += '\nPrCNotA = ';
      octaveStr += listForC
          .where((s) => s.startsWith('s') && !listForA.contains(s))
          .join(' + ');
    }
    if (_prCNotB.$1 > 0) {
      octaveStr += '\nPrCNotB = ';
      octaveStr += listForC
          .where((s) => s.startsWith('s') && !listForB.contains(s))
          .join(' + ');
    }

    // Update state to re-render the UI
    setState(() {});
  }

  // --- UI Building ---

  Widget _buildLeftPanel() {
    return Container(
      color: creamTea,
      padding: const EdgeInsets.all(12.0),
      child: valuationProbList(8, 0),
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
      color: paleOolong,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: [
              ElevatedButton(
                onPressed: _undoLastChange,
                child: Icon(Icons.undo_outlined, size: 20),
              ),
              ElevatedButton(
                onPressed: _redoLastChange,
                child: Icon(Icons.redo_outlined, size: 20),
              ),
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
              DropdownButtonHideUnderline(
                child: Container(
                  padding: EdgeInsets.fromLTRB(12, 3, 12, 5),

                  /// a rounded border to the DropdownButton
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(
                          255, 96, 139, 109), // Border color
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
                    hint: const SelText('Reset options'),
                    onChanged: (String? newValue) {
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
                          case 'Reset Raven':
                            _resetRaven();
                            break;
                        }
                        _selectedResetOption = null;
                      });
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'Reset',
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
                          children: const [
                            Icon(Icons.calculate, size: 20),
                            SizedBox(width: 8),
                            SelText('Prob. Independency'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Bayes Confirm.',
                        child: Row(
                          children: const [
                            Icon(Icons.settings_backup_restore, size: 20),
                            SizedBox(width: 8),
                            SelText('Bayes Confirm.'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Reset Raven',
                        child: Row(
                          children: [
                            /// show image from assets/icons/raven.png
                            /// with size 20x20
                            Image.asset(
                              'assets/icons/raven-aistudio.png',
                              width: 30,
                              height: 30,
                            ),
                            //Icon(Icons.auto_fix_high, size: 20),
                            SizedBox(width: 8),
                            SelText('Reset Raven'),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(child: Builder(builder: (context) {
            return table(
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
            );
          })),
        ],
      ),
    );
  }

  void _resetBCT() {
    setState(() {});
    _initializeProbabilities(initialMap: {
      /*
      0: 010101: 735
1: 010111: 225
2: 011101: 1341
4: 011111: 1539
5: 110101: 193
6: 110111: 127
7: 111101: 291
8: 111111: 669

      */
      0: (735, 5120),
      1: (225, 5120),
      2: (1341, 5120),
      3: (1539, 5120),
      4: (193, 5120),
      5: (127, 5120),
      6: (291, 5120),
      7: (669, 5120),
    });
    _calculateAndDisplayProbabilities();
  }

  void _resetPI() {
    setState(() {
      _initializeProbabilities(initialMap: {
        /*

        */
        0: (1459, 2000),
        1: (161, 2000),
        2: (161, 2000),
        3: (19, 2000),
        4: (161, 2000),
        5: (19, 2000),
        6: (19, 2000),
        7: (1, 2000),
      });

      _calculateAndDisplayProbabilities();
    });
  }

  void _resetRaven() {
    _initializeProbabilities(
        /*

 0   0   0    1128/2560
 0   0  1/2	   51/2560
 0	1/2  0	   105/2560	
 0  1/2 1/2     0/2560
1/2  0   0     21/2560 
1/2  0  1/2     80/2560 
1/2 1/2  0      30/2560 
1/2 1/2 1/2      125/2560

      // 0: (1128, 2560),
      // 1: (51, 2560),
      // 4: (1125, 2560),
      // 5: (0, 2560),
      // 2: (21, 2560),
      // 3: (80, 2560),
      // 6: (30, 2560),
      // 7: (125, 2560),    


        */

        initialMap: {
          0: (1128, 2560), // 0   0   0    1128/2560
          1: (51, 2560), // 0   0   1      51/2560
          4: (1125, 2560), // 1   0   0    1125/2560
          5: (0, 2560), // 1   0   1      0/2560
          2: (21, 2560), // 0   1   0      21/2560
          3: (80, 2560), // 0   1   1      80/2560
          6: (30, 2560), // 1   1   0      30/2560
          7: (125, 2560), // 1   1   1     125/2560
        });

    _calculateAndDisplayProbabilities();
    setState(() {});
  }
  // 25/512 + 3/256 + 1/32 + 21/2560 + 225/512 + 51/2560 + 141/320

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
        title: const SelText('Probability Calculator for a classical logic'),
        backgroundColor: const Color.fromARGB(255, 246, 221, 221),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 300,
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

  void _showText() {
    var text = r'\begin{align*}' '\n';
    String intToTruthValue(int i) {
      switch (i) {
        case 0:
          return '0';
        case 1:
          return '1';
        default:
          return '';
      }
    }

    int size = _probValues.length;
    var k = 0;
    for (int aA = 0; aA < numCombTruthValues; aA++) {
      for (int bB = 0; bB < numCombTruthValues; bB++) {
        for (int cC = 0; cC < numCombTruthValues; cC++) {
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
