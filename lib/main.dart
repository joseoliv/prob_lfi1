import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:prob_lfi1/ci_screen.dart';
import 'package:prob_lfi1/classical_screen.dart';
import 'package:prob_lfi1/common_lib.dart';
import 'package:prob_lfi1/every_screen.dart';
import 'package:prob_lfi1/letk_plus_screen.dart';
import 'package:prob_lfi1/lfi1_screen.dart';

void main() {
  runApp(const ProbabilityApp());
}

class ProbabilityApp extends StatelessWidget {
  const ProbabilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Probability Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select an Option'),
        backgroundColor: Colors.blueGrey[100],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                currentLogic = LogicType.classical;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ClassicalScreen()),
                );
              },
              child: const Text('Classical Logic'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                currentLogic = LogicType.lfi1;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LFI1Screen()),
                );
              },
              child: const Text('LFI1'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                currentLogic = LogicType.letplusK;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LetkPlusScreen()),
                );
              },
              child: Math.tex(r'LET^{+}_K'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                currentLogic = LogicType.ci;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CiScreen()),
                );
              },
              child: const Text('Ci'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                currentLogic = LogicType.fourV;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EveryScreen()),
                );
              },
              child: const Text('4V'),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blueGrey[100],
      ),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
