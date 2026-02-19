import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DigitalPetApp(),
  ));
}

class DigitalPetApp extends StatefulWidget {
  const DigitalPetApp({super.key});

  @override
  State<DigitalPetApp> createState() => _DigitalPetAppState();
}

class _DigitalPetAppState extends State<DigitalPetApp> {
  String petName = "Your Pet";
  int happinessLevel = 50; // 0..100
  int hungerLevel = 50; // 0..100

  // Part 2 (choose 2): Energy bar + activity selection
  int energyLevel = 60; // 0..100
  String selectedActivity = "Run";

  // Name input controller
  final TextEditingController _nameController = TextEditingController();

  // Timers
  Timer? _hungerTimer;
  Timer? _winTimer;

  // Win tracking: Happiness > 80 for 3 minutes
  bool _winCandidateActive = false;
  Duration _timeAbove80 = Duration.zero;
  static const Duration _winRequirement = Duration(minutes: 3);

  bool _gameOverShown = false;
  bool _winShown = false;

  @override
  void initState() {
    super.initState();

    // Auto-increasing hunger every 30 seconds
    _hungerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _autoIncreaseHunger();
    });

    // Track win condition over time (tick every 1 second)
    _winTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _trackWinCondition();
    });
  }

  @override
  void dispose() {
    _hungerTimer?.cancel();
    _winTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------
  int _clamp100(int v) => v.clamp(0, 100);

  Color _moodColor(int happiness) {
    if (happiness > 70) return Colors.green;
    if (happiness >= 30) return Colors.yellow;
    return Colors.red;
  }

  String _moodText(int happiness) {
    if (happiness > 70) return "Happy 😄";
    if (happiness >= 30) return "Neutral 🙂";
    return "Unhappy 😢";
  }

  void _showDialogOnce({
    required String title,
    required String message,
    required bool alreadyShownFlag,
    required VoidCallback markShown,
  }) {
    if (alreadyShownFlag) return;
    markShown();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ---------- Core Logic ----------
  void _playWithPet() {
    if (_gameOverShown || _winShown) return;
    setState(() {
      happinessLevel = _clamp100(happinessLevel + 10);
      energyLevel = _clamp100(energyLevel - 10);
      _updateHunger(); // also increases hunger a bit
    });
    _checkLossCondition();
  }

  void _feedPet() {
    if (_gameOverShown || _winShown) return;
    setState(() {
      hungerLevel = _clamp100(hungerLevel - 10);
      _updateHappiness();
    });
    _checkLossCondition();
  }

  // Starter code logic (kept, but clamped)
  void _updateHappiness() {
    if (hungerLevel < 30) {
      happinessLevel = _clamp100(happinessLevel - 20);
    } else {
      happinessLevel = _clamp100(happinessLevel + 10);
    }
  }

  void _updateHunger() {
    hungerLevel = _clamp100(hungerLevel + 5);
    if (hungerLevel >= 100) {
      hungerLevel = 100;
      happinessLevel = _clamp100(happinessLevel - 20);
    }
  }

  // Timer hunger increase
  void _autoIncreaseHunger() {
    if (_gameOverShown || _winShown) return;
    setState(() {
      hungerLevel = _clamp100(hungerLevel + 5);
      if (hungerLevel >= 100) {
        hungerLevel = 100;
        happinessLevel = _clamp100(happinessLevel - 10);
      }
      // If starving, energy drains slowly too
      if (hungerLevel > 85) {
        energyLevel = _clamp100(energyLevel - 5);
      }
    });
    _checkLossCondition();
  }

  // Loss: Hunger reaches 100 AND Happiness drops to 10
  void _checkLossCondition() {
    if (_gameOverShown || _winShown) return;
    if (hungerLevel >= 100 && happinessLevel <= 10) {
      _showDialogOnce(
        title: "Game Over",
        message: "$petName is starving and too unhappy 😵\nTry feeding and playing sooner!",
        alreadyShownFlag: _gameOverShown,
        markShown: () => setState(() => _gameOverShown = true),
      );
    }
  }

  // Win: Happiness > 80 for 3 minutes
  void _trackWinCondition() {
    if (_gameOverShown || _winShown) return;

    final bool above80 = happinessLevel > 80;
    if (above80) {
      _winCandidateActive = true;
      _timeAbove80 += const Duration(seconds: 1);
    } else {
      _winCandidateActive = false;
      _timeAbove80 = Duration.zero;
    }

    if (_timeAbove80 >= _winRequirement) {
      _showDialogOnce(
        title: "You Win! 🎉",
        message: "$petName stayed super happy for 3 minutes! 🐾",
        alreadyShownFlag: _winShown,
        markShown: () => setState(() => _winShown = true),
      );
    }
  }

  // ---------- Part 1: Name customization ----------
  void _setName() {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    setState(() {
      petName = newName;
    });
    FocusScope.of(context).unfocus();
  }

  // ---------- Part 2: Advanced features ----------
  void _doSelectedActivity() {
    if (_gameOverShown || _winShown) return;

    setState(() {
      switch (selectedActivity) {
        case "Run":
          happinessLevel = _clamp100(happinessLevel + 12);
          energyLevel = _clamp100(energyLevel - 18);
          hungerLevel = _clamp100(hungerLevel + 10);
          break;

        case "Sleep":
          energyLevel = _clamp100(energyLevel + 25);
          hungerLevel = _clamp100(hungerLevel + 8);
          // sleeping might make pet slightly less excited
          happinessLevel = _clamp100(happinessLevel - 2);
          break;

        case "Cuddle":
          happinessLevel = _clamp100(happinessLevel + 18);
          energyLevel = _clamp100(energyLevel - 6);
          hungerLevel = _clamp100(hungerLevel + 4);
          break;
      }
    });

    // Hunger at 100 can penalize happiness (consistent with starter vibe)
    if (hungerLevel >= 100) {
      setState(() {
        hungerLevel = 100;
        happinessLevel = _clamp100(happinessLevel - 10);
      });
    }

    _checkLossCondition();
  }

  @override
  Widget build(BuildContext context) {
    final mood = _moodText(happinessLevel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Pet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              // Name customization
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Set Pet Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _setName,
                    child: const Text("Set"),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Text('Name: $petName', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 10),

              // Mood indicator
              Text('Mood: $mood', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 16),

              // Pet image with dynamic color
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _moodColor(happinessLevel),
                  BlendMode.modulate,
                ),
                child: Image.asset(
                  'assets/pet_image.png',
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 20),

              // Levels
              Text('Happiness Level: $happinessLevel', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Hunger Level: $hungerLevel', style: const TextStyle(fontSize: 18)),

              const SizedBox(height: 18),

              // Part 2: Energy Bar Widget (Advanced feature #1)
              Row(
                children: [
                  const Text("Energy", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: energyLevel / 100.0,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text("$energyLevel%"),
                ],
              ),

              const SizedBox(height: 18),

              // Buttons
              ElevatedButton(
                onPressed: _playWithPet,
                child: const Text('Play with Your Pet'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _feedPet,
                child: const Text('Feed Your Pet'),
              ),

              const SizedBox(height: 24),

              // Part 2: Activity Selection (Advanced feature #2)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Activity: "),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedActivity,
                    items: const [
                      DropdownMenuItem(value: "Run", child: Text("Run")),
                      DropdownMenuItem(value: "Sleep", child: Text("Sleep")),
                      DropdownMenuItem(value: "Cuddle", child: Text("Cuddle")),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => selectedActivity = v);
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _doSelectedActivity,
                    child: const Text("Do it"),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Win timer progress (optional UI helper)
              if (!_winShown && !_gameOverShown)
                Text(
                  _winCandidateActive
                      ? "Win progress: ${(_timeAbove80.inSeconds)}s / ${_winRequirement.inSeconds}s (keep happiness > 80)"
                      : "To win: keep happiness > 80 for 3 minutes",
                  textAlign: TextAlign.center,
                ),

              if (_gameOverShown)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    "Game Over (restart the app to try again).",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

              if (_winShown)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    "You won! 🎉",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
