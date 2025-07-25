from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import pandas as pd
import joblib
from pathlib import Path
import sys

app = Flask(__name__)
CORS(app)

# Add model_utils to path
BASE_DIR = Path(__file__).parent
sys.path.append(str(BASE_DIR.parent / 'ml_model'))
from model_utils import DataValidator  # This must match your training code

# Configuration
MODEL_PATH = BASE_DIR / 'models' / 'university_admission_predictor.pkl'

# Load model
try:
    if not MODEL_PATH.exists():
        raise FileNotFoundError(f"Model file not found at: {MODEL_PATH}")
    
    model = joblib.load(MODEL_PATH)
    print(f"Model loaded successfully from: {MODEL_PATH}")
except Exception as e:
    print(f"Initialization error: {str(e)}")
    raise

def generate_recommendations(user_data, prediction):
    """Generate personalized improvement tips"""
    tips = []
    
    # Test Scores
    if user_data['gre_score'] < 320:
        tips.append(f"Increase GRE by {320-user_data['gre_score']}+ points (current: {user_data['gre_score']})")
    
    if user_data['toefl_score'] < 105:
        tips.append(f"Improve TOEFL by {105-user_data['toefl_score']}+ points (current: {user_data['toefl_score']})")

    # Academic
    if user_data['cgpa'] < 8.5:
        tips.append(f"Aim for {max(8.5, user_data['cgpa']+0.5):.1f}+ GPA next term (current: {user_data['cgpa']})")
    
    # Research
    if user_data['research'] == 0 and prediction < 0.8:
        tips.append("Gain research experience (1 project → +5% chance)")

    # SOP/LOR
    if user_data['sop'] < 4.0:
        tips.append(f"Strengthen Statement of Purpose (Aim for 4.5+, current: {user_data['sop']})")
        tips.append("  - Show specific research interests")
        tips.append("  - Connect to faculty work at target school")

    if user_data['lor'] < 4.0:
        tips.append(f"Get stronger LORs (Aim for 4.5+, current: {user_data['lor']})")
        tips.append("  - Ask professors who know you well")
        tips.append("  - Provide them your CV/resume")

    return tips if tips else ["Profile looks strong! Focus on interview prep"]

@app.route('/predict', methods=['GET', 'POST'])
def predict():
    if request.method == 'POST':
        try:
            data = request.get_json() if request.is_json else request.form.to_dict()
            
            # Prepare input
            user_data = {
                'gre_score': int(data['gre_score']),
                'toefl_score': int(data['toefl_score']),
                'university_rating': int(data['university_rating']),
                'sop': float(data['sop']),
                'lor': float(data['lor']),
                'cgpa': float(data['cgpa']),
                'research': int(data['research'])
            }
            
            # Predict
            X = pd.DataFrame([list(user_data.values())], 
                           columns=['GRE Score','TOEFL Score','University Rating',
                                   'SOP','LOR','CGPA','Research'])
            prediction = model.predict(X)[0]
            
            # Generate tips
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
    
    return render_template('form.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)