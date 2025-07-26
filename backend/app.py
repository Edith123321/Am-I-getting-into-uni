from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import pandas as pd
import joblib
from pathlib import Path
import sys

app = Flask(__name__)
CORS(app)

# Setup paths
BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / 'models' / 'university_admission_predictor.pkl'

# Add ML utilities to path
sys.path.append(str(BASE_DIR.parent / 'ml_model'))
from model_utils import DataValidator  # Ensure this exists in your ml_model directory

# Load model
try:
    if not MODEL_PATH.exists():
        raise FileNotFoundError(f"Model file not found at: {MODEL_PATH}")
    model = joblib.load(MODEL_PATH)
    print(f"✅ Model loaded from: {MODEL_PATH}")
except Exception as e:
    print(f"❌ Model initialization error: {str(e)}")
    raise

def generate_recommendations(user_data, prediction):
    """Generate personalized improvement suggestions based on input and result"""
    tips = []

    # GRE
    if user_data['gre_score'] < 320:
        tips.append(f"Increase GRE by {320 - user_data['gre_score']}+ points (Current: {user_data['gre_score']})")

    # TOEFL
    if user_data['toefl_score'] < 105:
        tips.append(f"Improve TOEFL by {105 - user_data['toefl_score']}+ points (Current: {user_data['toefl_score']})")

    # GPA
    if user_data['cgpa'] < 8.5:
        target = max(8.5, user_data['cgpa'] + 0.5)
        tips.append(f"Aim for {target:.1f}+ CGPA next term (Current: {user_data['cgpa']})")

    # Research
    if user_data['research'] == 0 and prediction < 0.8:
        tips.append("Gain research experience (1 project → +5% chance)")

    # SOP
    if user_data['sop'] < 4.0:
        tips.append(f"Strengthen Statement of Purpose (Aim for 4.5+, Current: {user_data['sop']})")
        tips.append("  - Highlight specific research interests")
        tips.append("  - Connect to faculty work at your target school")

    # LOR
    if user_data['lor'] < 4.0:
        tips.append(f"Secure stronger Letters of Recommendation (Aim for 4.5+, Current: {user_data['lor']})")
        tips.append("  - Ask professors who know you well")
        tips.append("  - Share your CV and academic goals with them")

    return tips if tips else ["✅ Profile looks strong! Focus on interview preparation and application timelines."]

@app.route('/predict', methods=['POST', 'GET'])
def predict():
    if request.method == 'POST':
        try:
            raw_data = request.get_json() if request.is_json else request.form.to_dict()

            # Parse and validate input
            user_data = {
                'gre_score': int(raw_data['gre_score']),
                'toefl_score': int(raw_data['toefl_score']),
                'university_rating': int(raw_data['university_rating']),
                'sop': float(raw_data['sop']),
                'lor': float(raw_data['lor']),
                'cgpa': float(raw_data['cgpa']),
                'research': int(raw_data['research']),
            }

            # Prepare input DataFrame
            X = pd.DataFrame([[
                user_data['gre_score'],
                user_data['toefl_score'],
                user_data['university_rating'],
                user_data['sop'],
                user_data['lor'],
                user_data['cgpa'],
                user_data['research']
            ]], columns=['GRE Score', 'TOEFL Score', 'University Rating', 'SOP', 'LOR', 'CGPA', 'Research'])

            # Make prediction
            prediction = model.predict(X)[0]

            # Generate suggestions
            recommendations = generate_recommendations(user_data, prediction)

            return jsonify({
                'success': True,
                'prediction': round(float(prediction), 4),
                'recommendations': recommendations
            })

        except Exception as e:
            return jsonify({
                'success': False,
                'error': f"Prediction failed: {str(e)}"
            }), 400

    # Fallback to default UI (optional)
    return render_template('form.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
