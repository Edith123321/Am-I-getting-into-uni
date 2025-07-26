from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import pandas as pd
import numpy as np
from pathlib import Path
import os

app = Flask(__name__)
CORS(app)

# Model paths
BASE_DIR = Path(__file__).parent
MODEL_PATH = BASE_DIR / 'models' / 'university_admission_predictor.pkl'

def validate_input(data):
    """Validate input ranges"""
    expected_ranges = {
        'gre_score': (290, 340),
        'toefl_score': (92, 120),
        'university_rating': (1, 5),
        'sop': (1.0, 5.0),
        'lor': (1.0, 5.0),
        'cgpa': (6.8, 9.92),
        'research': (0, 1)
    }
    
    errors = []
    for field, (min_val, max_val) in expected_ranges.items():
        value = data.get(field)
        if value is None:
            errors.append(f"Missing {field}")
        elif not (min_val <= value <= max_val):
            errors.append(f"Invalid {field}: {value}. Must be {min_val}-{max_val}")
    
    if errors:
        raise ValueError("; ".join(errors))
    
    return {
        'gre_score': int(data['gre_score']),
        'toefl_score': int(data['toefl_score']),
        'university_rating': int(data['university_rating']),
        'sop': float(data['sop']),
        'lor': float(data['lor']),
        'cgpa': float(data['cgpa']),
        'research': int(data['research'])
    }

# Load model
try:
    model_data = joblib.load(MODEL_PATH)
    model = model_data['model']
    scaler = model_data['scaler']
    feature_names = model_data['feature_names']
    print(f"✅ Model loaded successfully from {MODEL_PATH}")
except Exception as e:
    print(f"❌ Failed to load model: {str(e)}")
    raise

def generate_recommendations(user_data, prediction):
    """Generate improvement suggestions"""
    tips = []
    
    if user_data['gre_score'] < 320:
        tips.append(f"Increase GRE by {320 - user_data['gre_score']} points (current: {user_data['gre_score']})")
    
    if user_data['toefl_score'] < 105:
        tips.append(f"Improve TOEFL by {105 - user_data['toefl_score']} points (current: {user_data['toefl_score']})")
    
    if user_data['cgpa'] < 8.5:
        tips.append(f"Aim for CGPA of 8.5+ (current: {user_data['cgpa']})")
    
    if not user_data['research'] and prediction < 0.7:
        tips.append("Gain research experience to boost your chances")
    
    return tips if tips else ["Your profile looks strong! Focus on application essays."]

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Get and validate input
        raw_data = request.get_json()
        user_data = validate_input(raw_data)
        
        # Prepare input in correct order
        input_values = [
            user_data['gre_score'],
            user_data['toefl_score'],
            user_data['university_rating'],
            user_data['sop'],
            user_data['lor'],
            user_data['cgpa'],
            user_data['research']
        ]
        
        # Scale features
        input_scaled = scaler.transform([input_values])
        
        # Make prediction
        prediction = model.predict(input_scaled)[0]
        
        # Generate recommendations
        recommendations = generate_recommendations(user_data, prediction)
        
        return jsonify({
            'success': True,
            'prediction': float(prediction),
            'recommendations': recommendations
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)