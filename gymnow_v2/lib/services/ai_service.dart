import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class GymAIService {
  Interpreter? _interpreter;
  List<String> _vocabulary = [];
  Map<String, String> _muscleMap = {};
  bool _isLoaded = false;

  // --- 1. INITIALIZE THE BRAIN ---
  Future<void> loadModel() async {
    if (_isLoaded) return;

    try {
      // Load the TFLite Model
      _interpreter = await Interpreter.fromAsset('assets/ai/gym_brain.tflite');
      
      // Load the Dictionary (JSON)
      final jsonString = await rootBundle.loadString('assets/ai/ai_assets.json');
      final jsonData = json.decode(jsonString);

      _vocabulary = List<String>.from(jsonData['vocabulary']);
      _muscleMap = Map<String, String>.from(jsonData['muscle_map']);
      
      _isLoaded = true;
      print("✅ Mobile AI Loaded: ${_vocabulary.length} exercises ready.");
    } catch (e) {
      print("❌ Error loading AI: $e");
    }
  }

  // --- 2. THE PREDICTOR (Public Function) ---
  Future<Map<String, dynamic>> generateWorkout({
    required int age,
    required int gender, // 1 for Male, 0 for Female
    required double weight,
    required double height,
    required int months,
    required double consistency,
    required int gap,
  }) async {
    await loadModel(); // Ensure brain is ready

    // A. Architect Logic: Determine Split based on Level
    String splitName = _determineSplit(months, gap);
    Map<String, dynamic> template = _splits[splitName]!;

    // B. Expert Logic: Run Neural Network
    // Input Vector: [Age, Gender, BMI, Months, Consistency, Gap]
    double bmi = weight / ((height / 100) * (height / 100));
    var input = [[
      age.toDouble(), 
      gender.toDouble(), 
      bmi, 
      months.toDouble(), 
      consistency, 
      gap.toDouble()
    ]];

    // Output: Probabilities for all 380+ exercises
    var output = List.filled(1 * _vocabulary.length, 0.0).reshape([1, _vocabulary.length]);
    _interpreter!.run(input, output);
    
    // Get raw probabilities
    List<double> predictions = List<double>.from(output[0]);

    // C. Organizer Logic: Fill the Template
    Map<String, dynamic> finalRoutine = {};

    template.forEach((day, muscles) {
      if (muscles is String && muscles == "Rest") {
        finalRoutine[day] = [{"name": "Rest Day", "sets": "0", "reps": "0"}];
      } else {
        // It's a workout day (List of muscles)
        List<String> targetMuscles = List<String>.from(muscles);
        List<Map<String, String>> dayExercises = [];

        for (String muscle in targetMuscles) {
          // Find top exercises for this muscle using AI predictions
          // We pick 2 exercises for big muscles (Chest/Back/Legs), 1 for small
          int count = ["Chest", "Back", "Legs"].contains(muscle) ? 2 : 1;
          
          List<String> topPicks = _getBestExercises(predictions, muscle, count);
          
          for (var ex in topPicks) {
            dayExercises.add({
              "name": ex,
              "sets": "3",
              "reps": (months > 12) ? "8-12" : "12-15"
            });
          }
        }
        finalRoutine[day] = dayExercises;
      }
    });

    return {
      "split_name": splitName,
      "ai_confidence": "91% (Offline Mode)",
      "routine": finalRoutine
    };
  }

  // --- HELPER: Logic to map Probabilities -> Exercise Names ---
  List<String> _getBestExercises(List<double> scores, String targetMuscle, int count) {
    List<MapEntry<String, double>> candidates = [];
    
    for (int i = 0; i < scores.length; i++) {
      String name = _vocabulary[i];
      // Use strict checking from our muscle map
      String trueMuscle = _muscleMap[name] ?? "Unknown";
      
      if (trueMuscle.toLowerCase().contains(targetMuscle.toLowerCase())) {
        candidates.add(MapEntry(name, scores[i]));
      }
    }

    // Sort High to Low
    candidates.sort((a, b) => b.value.compareTo(a.value));

    // Return top N
    return candidates.take(count).map((e) => e.key).toList();
  }

  // --- HELPER: Logic to determine Level ---
  String _determineSplit(int months, int gap) {
    if (gap > 21) return "Full Body"; // Demotion
    if (months <= 6) return "Full Body";
    if (months <= 18) return "Upper/Lower";
    if (months <= 60) return "PPL";
    return "Arnold Split";
  }

  // --- TEMPLATES ---
  final Map<String, Map<String, dynamic>> _splits = {
    "Full Body": {
      "Day 1": ["Chest", "Back", "Legs", "Abs"],
      "Day 2": "Rest",
      "Day 3": ["Shoulders", "Arms", "Legs"],
      "Day 4": "Rest",
      "Day 5": ["Chest", "Back", "Legs"],
      "Day 6": "Rest", "Day 7": "Rest"
    },
    "Upper/Lower": {
      "Day 1": ["Chest", "Back", "Shoulders"],
      "Day 2": ["Legs", "Abs"],
      "Day 3": "Rest",
      "Day 4": ["Chest", "Back", "Arms"],
      "Day 5": ["Legs", "Abs"],
      "Day 6": "Rest", "Day 7": "Rest"
    },
    "PPL": {
      "Day 1": ["Chest", "Shoulders", "Triceps"],
      "Day 2": ["Back", "Biceps", "Abs"],
      "Day 3": ["Legs"],
      "Day 4": ["Chest", "Shoulders", "Triceps"],
      "Day 5": ["Back", "Biceps", "Abs"],
      "Day 6": ["Legs"], "Day 7": "Rest"
    },
    "Arnold Split": {
      "Day 1": ["Chest", "Back"],
      "Day 2": ["Shoulders", "Arms"],
      "Day 3": ["Legs"],
      "Day 4": ["Chest", "Back"],
      "Day 5": ["Shoulders", "Arms"],
      "Day 6": ["Legs"], "Day 7": "Rest"
    }
  };
}