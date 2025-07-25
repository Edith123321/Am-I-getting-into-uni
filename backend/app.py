from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_restx import Api, Resource, fields
import joblib
import numpy as np
from pathlib import Path
import os

app = Flask(__name__)
CORS(app)

# ===== Flask-RESTx API Configuration =====
api = Api(
    app,
    version='1.0',
    title='University Admission Predictor API',
    description='Predicts graduate school admission chances using machine learning',
    doc='/docs/',
    license='MIT',
    license_url='https://opensource.org/licenses/MIT',
    contact='support@unipredictor.com',
    contact_url='https://am-i-getting-into-uni.onrender.com/terms'
)

# Define models
prediction_input = api.model('PredictionInput', {
    'gre_score': fields.Integer(required=True, min=290, max=340, example=320,
                               description='GRE Score (290-340)'),
    'toefl_score': fields.Integer(required=True, min=92, max=120, example=110,
                                 description='TOEFL Score (92-120)'),
    'university_rating': fields.Integer(required=True, min=1, max=5, example=3,
                                      description='University Rating (1-5)'),
    'sop': fields.Float(required=True, min=1.0, max=5.0, example=4.5,
                       description='Statement of Purpose strength (1.0-5.0)'),
    'lor': fields.Float(required=True, min=1.0, max=5.0, example=4.0,
                       description='Letter of Recommendation strength (1.0-5.0)'),
    'cgpa': fields.Float(required=True, min=6.8, max=9.92, example=8.5,
                        description='Undergraduate GPA (6.8-9.92)'),
    'research': fields.Integer(required=True, min=0, max=1, example=1,
                             description='Research experience (0=no, 1=yes)')
})

prediction_response = api.model('PredictionResponse', {
    'success': fields.Boolean(example=True),
    'prediction': fields.Float(example=0.85),
    'recommendations': fields.List(fields.String, example=[
        "Increase GRE by 10 points",
        "Gain research experience"
    ])
})

error_response = api.model('ErrorResponse', {
    'success': fields.Boolean(example=False),
    'error': fields.String(example="Missing field: gre_score")
})

# === Paths ===
BASE_DIR = Path(__file__).parent
MODEL_PATH = BASE_DIR / 'models' / 'university_admission_predictor.pkl'

# === Load Model ===
try:
    model_data = joblib.load(MODEL_PATH)
    model = model_data['model']
    scaler = model_data['scaler']
    feature_names = model_data['feature_names']
    print(f"✅ Model loaded from {MODEL_PATH}")
except Exception as e:
    print(f"❌ Failed to load model: {e}")
    raise

# === Helper: Validate Input ===
def validate_input(data):
    """
    Validate incoming user data for expected range and completeness.
    Returns cleaned and typed data or raises ValueError.
    """
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
    cleaned = {}

    for field, (min_val, max_val) in expected_ranges.items():
        value = data.get(field)
        if value is None:
            errors.append(f"Missing field: {field}")
            continue

        try:
            if field in ['sop', 'lor', 'cgpa']:
                value = float(value)
            else:
                value = int(value)
        except ValueError:
            errors.append(f"{field} must be numeric.")
            continue

        if not (min_val <= value <= max_val):
            errors.append(f"{field} must be between {min_val} and {max_val} (got {value})")

        cleaned[field] = value

    if errors:
        raise ValueError("; ".join(errors))

    return cleaned

# === Helper: Recommendations ===
def generate_recommendations(user_data, prediction):
    """
    Suggest ways to improve chances based on user input and prediction.
    """
    tips = []

    if user_data['gre_score'] < 320:
        tips.append(f"Increase GRE by {320 - user_data['gre_score']} points.")
    if user_data['toefl_score'] < 105:
        tips.append(f"Improve TOEFL by {105 - user_data['toefl_score']} points.")
    if user_data['cgpa'] < 8.5:
        tips.append("Target CGPA above 8.5.")
    if not user_data['research'] and prediction < 0.7:
        tips.append("Gain research experience to strengthen your profile.")

    return tips if tips else ["Your profile looks strong! Focus on essays and application quality."]

# === API Routes ===
@api.route('/')
class HealthCheck(Resource):
    def get(self):
        """API Health Check"""
        return {
            'message': '🎓 University Admission Predictor API is running.',
            'status': 'OK'
        }

@api.route('/predict')
class Predictor(Resource):
    @api.expect(prediction_input)
    @api.response(200, 'Success', prediction_response)
    @api.response(400, 'Bad Request', error_response)
    def post(self):
        """Predict admission probability"""
        try:
            # Read incoming JSON
            raw_data = request.get_json(force=True)
            if not raw_data:
                return {'success': False, 'error': 'Empty request body'}, 400

            print("📥 Incoming JSON:", raw_data)

            # Validate and prepare input
            user_data = validate_input(raw_data)
            input_values = [
                user_data['gre_score'],
                user_data['toefl_score'],
                user_data['university_rating'],
                user_data['sop'],
                user_data['lor'],
                user_data['cgpa'],
                user_data['research']
            ]

            # Scale and predict
            input_scaled = scaler.transform([input_values])
            prediction = model.predict(input_scaled)[0]

            # Generate recommendation tips
            recommendations = generate_recommendations(user_data, prediction)

            return {
                'success': True,
                'prediction': round(float(prediction), 4),
                'recommendations': recommendations
            }

        except Exception as e:
            return {'success': False, 'error': str(e)}, 400

# === Entry Point ===
if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)