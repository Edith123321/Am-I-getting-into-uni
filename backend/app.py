from flask import Flask, request, jsonify
import pandas as pd
import joblib
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Load the trained model
model = joblib.load('models/university_admission_predictor.pkl')

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['gre_score', 'toefl_score', 'university_rating', 'sop', 'lor', 'cgpa', 'research']
        if not all(field in data for field in required_fields):
            return jsonify({'success': False, 'error': 'Missing fields'}), 400

        # Convert to DataFrame
        new_applicant = pd.DataFrame([{
            'GRE Score': data['gre_score'],
            'TOEFL Score': data['toefl_score'],
            'University Rating': data['university_rating'],
            'SOP': data['sop'],
            'LOR': data['lor'],
            'CGPA': data['cgpa'],
            'Research': data['research']
        }])

        # Predict
        prediction = model.predict(new_applicant)[0]

        return jsonify({
            'success': True,
            'prediction': float(prediction),
            'message': 'Success'
        })

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)