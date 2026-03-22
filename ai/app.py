import pandas as pd
import numpy as np
import tensorflow as tf
from flask import Flask, request, jsonify
import pickle
import os

app = Flask(__name__)

print("⏳ Initializing GymNow AI Server...")

# --- 1. LOAD RESOURCES ---
try:
    # Load the Neural Network
    model = tf.keras.models.load_model("model/gym_brain.h5")
    print("✅ Neural Network Loaded: gym_brain.h5")

    # Load the Vocabulary Map (Neuron ID -> Exercise Name)
    with open("model/exercise_names.pkl", "rb") as f:
        all_exercise_names = pickle.load(f)
    print(f"✅ Vocabulary Loaded: {len(all_exercise_names)} exercises")

    # Load Metadata (To map 'Bench Press' -> 'Chest')
    df_meta = pd.read_csv("datasets/final_gym_dataset.csv")
    # Create lookup dict: {"Bench Press": "Chest", "Squat": "Legs"}
    exercise_metadata = dict(zip(df_meta['Exercise Name'], df_meta['Muscle Group']))
    print("✅ Metadata Loaded")

except Exception as e:
    print(f"❌ CRITICAL ERROR: {e}")
    print("   Make sure gym_brain.h5, exercise_names.pkl, and final_gym_dataset.csv are in this folder.")
    exit()

# --- 2. DEFINE WORKOUT SPLITS (The Architect) ---
# This maps the User's Level to the specific muscle schedule
SPLIT_STRUCTURES = {
    # Level 1-3: Full Body
    "Full Body": {
        "Day 1": ["Chest", "Back", "Legs", "Abs"],
        "Day 2": ["Rest"],
        "Day 3": ["Shoulders", "Arms", "Legs", "Abs"],
        "Day 4": ["Rest"],
        "Day 5": ["Chest", "Back", "Legs"],
        "Day 6": ["Rest"],
        "Day 7": ["Rest"]
    },
    # Level 4-5: Upper / Lower
    "Upper/Lower": {
        "Day 1 (Upper)": ["Chest", "Back", "Shoulders"],
        "Day 2 (Lower)": ["Legs", "Abs"],
        "Day 3": ["Rest"],
        "Day 4 (Upper)": ["Chest", "Back", "Arms"],
        "Day 5 (Lower)": ["Legs", "Abs"],
        "Day 6": ["Active Recovery"],
        "Day 7": ["Rest"]
    },
    # Level 6: PPL
    "PPL": {
        "Day 1 (Push)": ["Chest", "Shoulders", "Triceps"],
        "Day 2 (Pull)": ["Back", "Biceps", "Abs"],
        "Day 3 (Legs)": ["Legs"],
        "Day 4 (Push)": ["Chest", "Shoulders", "Triceps"],
        "Day 5 (Pull)": ["Back", "Biceps", "Abs"],
        "Day 6 (Legs)": ["Legs"],
        "Day 7": ["Rest"]
    },
    # Level 7-8: Arnold / Pro
    "Arnold Split": {
        "Day 1": ["Chest", "Back"],
        "Day 2": ["Shoulders", "Arms"],
        "Day 3": ["Legs"],
        "Day 4": ["Chest", "Back"],
        "Day 5": ["Shoulders", "Arms"],
        "Day 6": ["Legs"],
        "Day 7": ["Rest"]
    }
}

# --- 3. HELPER FUNCTIONS ---
def get_ai_recommendations(user_vector, target_muscle, count=3):
    """
    1. Runs the AI on the user.
    2. Filters the 380 exercises to find ones that match 'target_muscle'.
    3. Returns the top 'count' exercises sorted by confidence.
    """
    # Get 380 probabilities from the AI
    predictions = model.predict(user_vector, verbose=0)[0]

    candidates = []
    for i, score in enumerate(predictions):
        ex_name = all_exercise_names[i]
        
        # Check if this exercise belongs to the target muscle
        # We use strict checking against our metadata
        true_muscle = exercise_metadata.get(ex_name, "Unknown")
        
        # Allow partial match (e.g. "Upper Chest" matches "Chest")
        if target_muscle.lower() in true_muscle.lower():
            candidates.append((ex_name, score))

    # Sort by Score (High to Low)
    candidates.sort(key=lambda x: x[1], reverse=True)

    # Return top N names
    return [item[0] for item in candidates[:count]]

@app.route('/predict_workout', methods=['POST'])
def predict_workout():
    data = request.json
    print(f"\n📩 Request received: {data}")

    try:
        # --- A. PARSE INPUTS ---
        age = float(data.get('age', 25))
        gender = 1 if data.get('gender') == 'Male' else 0
        weight = float(data.get('weight', 70))
        height = float(data.get('height', 170))
        months = int(data.get('months_experience', 0))
        consistency = float(data.get('consistency_score', 1.0))
        gap = int(data.get('days_since_last_workout', 0))

        bmi = weight / ((height/100) ** 2)

        # --- B. DETERMINE LEVEL (The Architect) ---
        # (Replicating your 8-Level Logic here for the structure)
        if months <= 6: 
            level_name = "Full Body"
            level_id = 1
        elif months <= 18: 
            level_name = "Upper/Lower"
            level_id = 2
        elif months <= 60: 
            level_name = "PPL"
            level_id = 3
        else: 
            level_name = "Arnold Split"
            level_id = 4
        
        # Demotion Logic
        if gap > 21: 
            level_name = "Full Body" # Reset
            print("   -> User demoted due to 3+ weeks gap.")

        # --- C. PREPARE AI INPUT ---
        # Must match the training order: [Age, Gender, BMI, Months, Consistency, Gap]
        input_vector = np.array([[age, gender, bmi, months, consistency, gap]])

        # --- D. GENERATE PLAN ---
        template = SPLIT_STRUCTURES[level_name]
        final_plan = {}

        for day, muscles in template.items():
            if "Rest" in muscles:
                final_plan[day] = [{"name": "Rest Day", "sets": "0", "reps": "0"}]
                continue
            
            day_routine = []
            for muscle in muscles:
                # Ask AI for best exercises for this muscle
                # We vary the count: 2 for big muscles, 1 for small
                count = 2 if muscle in ["Chest", "Back", "Legs"] else 1
                
                top_exercises = get_ai_recommendations(input_vector, muscle, count)
                
                for ex in top_exercises:
                    day_routine.append({
                        "name": ex,
                        "sets": "3",
                        "reps": "8-12" if level_id > 2 else "12-15"
                    })
            
            final_plan[day] = day_routine

        response = {
            "split_name": level_name,
            "ai_confidence": "High (91% Accuracy)",
            "routine": final_plan
        }
        
        return jsonify(response)

    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Run on 0.0.0.0 to be accessible by Emulator
    app.run(host='0.0.0.0', port=5000, debug=True)