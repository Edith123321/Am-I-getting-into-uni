from flask import Flask, request
from flask_cors import CORS
from flask_restx import Api, Resource, fields
import joblib
import numpy as np
from pathlib import Path
import os

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# ===== API Configuration =====
api = Api(
    app,
    version='1.0',
    title='University Admission Predictor API',
    description='Machine learning model to predict graduate school admission chances',
    doc='/docs/',
    license='MIT',
    license_url='https://opensource.org/licenses/MIT',
    contact='e.githinji1@alustudent.com',
    contact_url='https://am-i-getting-into-uni.onrender.com/terms'
)

# ===== Data Models =====
prediction_input = api.model('PredictionInput', {
    'gre_score': fields.Integer(
        required=True, min=290, max=340, example=320,
        description='GRE Score (290-340)'
    ),
    'toefl_score': fields.Integer(
        required=True, min=92, max=120, example=110,
        description='TOEFL Score (92-120)'
    ),
    'university_rating': fields.Integer(
        required=True, min=1, max=5, example=3,
        description='University Rating (1-5)'
    ),
    'sop': fields.Float(
        required=True, min=1.0, max=5.0, example=4.5,
        description='Statement of Purpose strength (1.0-5.0)'
    ),
    'lor': fields.Float(
        required=True, min=1.0, max=5.0, example=4.0,
        description='Letter of Recommendation strength (1.0-5.0)'
    ),
    'cgpa': fields.Float(
        required=True, min=6.8, max=9.92, example=8.5,
        description='Undergraduate GPA (6.8-9.92)'
    ),
    'research': fields.Integer(
        required=True, min=0, max=1, example=1,
        description='Research experience (0=no, 1=yes)'
    )
})

prediction_response = api.model('PredictionResponse', {
    'success': fields.Boolean(example=True),
    'prediction': fields.Float(
        example=0.85,
        description='Admission probability (0-1)'
    ),
    'recommendations': fields.List(
        fields.String,
        example=["Increase GRE by 10 points", "Gain research experience"],
        description='List of improvement suggestions'
    )
})

error_response = api.model('ErrorResponse', {
    'success': fields.Boolean(example=False),
    'error': fields.String(
        example="Missing field: gre_score",
        description='Error description'
    )
})

# ===== Model Loading =====
BASE_DIR = Path(__file__).parent
MODEL_PATH = BASE_DIR / 'models' / 'university_admission_predictor.pkl'

try:
    model_data = joblib.load(MODEL_PATH)
    model = model_data['model']
    scaler = model_data['scaler']
    feature_names = model_data['feature_names']
    print(f"✅ Model loaded from {MODEL_PATH}")
except Exception as e:
    print(f"❌ Failed to load model: {e}")
    raise

# ===== Helper Functions =====
def validate_input(data):
    """Validate and sanitize input data"""
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
            cleaned[field] = float(value) if field in ['sop', 'lor', 'cgpa'] else int(value)
            if not (min_val <= cleaned[field] <= max_val):
                errors.append(f"{field} must be between {min_val} and {max_val}")
        except ValueError:
            errors.append(f"{field} must be numeric")

    if errors:
        raise ValueError("; ".join(errors))

    return cleaned

def generate_recommendations(user_data, prediction):
    """Generate personalized improvement recommendations"""
    tips = []
    
    if user_data['gre_score'] < 320:
        tips.append(f"Increase GRE by {320 - user_data['gre_score']} points")
    if user_data['toefl_score'] < 105:
        tips.append(f"Improve TOEFL by {105 - user_data['toefl_score']} points")
    if user_data['cgpa'] < 8.5:
        tips.append("Target CGPA above 8.5")
    if not user_data['research'] and prediction < 0.7:
        tips.append("Gain research experience")

    return tips if tips else ["Your profile looks strong! Focus on essays"]

# ===== API Endpoints =====
@api.route('/')
class HealthCheck(Resource):
    @api.doc(description='API health check endpoint')
    def get(self):
        """Check API status"""
        return {
            'message': '🎓 University Admission Predictor API is running',
            'status': 'OK',
            'version': '1.0'
        }

@api.route('/predict')
class Predictor(Resource):
    @api.doc(description='Predict admission probability')
    @api.expect(prediction_input)
    @api.response(200, 'Success', prediction_response)
    @api.response(400, 'Bad Request', error_response)
    @api.response(500, 'Server Error')
    def post(self):
        """Make admission prediction"""
        try:
            raw_data = request.get_json(force=True)
            if not raw_data:
                return {'success': False, 'error': 'Empty request body'}, 400

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

            input_scaled = scaler.transform([input_values])
            prediction = round(float(model.predict(input_scaled)[0]), 4)

            return {
                'success': True,
                'prediction': prediction,
                'recommendations': generate_recommendations(user_data, prediction)
            }

        except ValueError as e:
            return {'success': False, 'error': str(e)}, 400
        except Exception as e:
            return {'success': False, 'error': f'Server error: {str(e)}'}, 500

# ===== Application Entry Point =====
if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)