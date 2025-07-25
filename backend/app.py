from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import pandas as pd
import joblib
import numpy as np

app = Flask(__name__)
CORS(app)

# Load model and data
model = joblib.load('models/university_admission_predictor.pkl')
uni_df = pd.read_csv('data/universities.csv')


def generate_recommendations(user_data, prediction, uni_benchmark=None):
    """Generate personalized improvement tips for a user profile."""
    tips = []

    # GRE Score
    if user_data['gre_score'] < 320:
        tips.append(
            f"Increase GRE by {320 - user_data['gre_score']}+ points (current: {user_data['gre_score']})"
        )

    # TOEFL Score
    if user_data['toefl_score'] < 105:
        tips.append(
            f"Improve TOEFL by {105 - user_data['toefl_score']}+ points (current: {user_data['toefl_score']})"
        )

    # GPA
    if user_data['cgpa'] < 8.5:
        target_gpa = round(max(8.5, user_data['cgpa'] + 0.5), 2)
        tips.append(
            f"Aim for a GPA of {target_gpa}+ next term (current: {user_data['cgpa']})"
        )

    # Research
    if user_data['research'] == 0 and prediction < 0.8:
        tips.append("Gain research experience (1 project → +5% chance)")

    # SOP
    if user_data['sop'] < 4.0:
        tips.append(f"Strengthen SOP (Aim for 4.5+, current: {user_data['sop']})")
        tips.append("- Show specific research interests")
        tips.append("- Connect to faculty work at target school")

    # LOR
    if user_data['lor'] < 4.0:
        tips.append(f"Get stronger LORs (Aim for 4.5+, current: {user_data['lor']})")
        tips.append("- Ask professors who know you well")
        tips.append("- Provide them your CV/resume")

    # University-specific benchmark
    if uni_benchmark:
        if user_data['cgpa'] < uni_benchmark.get('avg_gpa', 0):
            tips.append(f"Target GPA for {uni_benchmark['name']}: {uni_benchmark['avg_gpa']}+")

    return tips if tips else ["Profile looks strong! Focus on interview prep."]


@app.route('/predict', methods=['GET', 'POST'])
def predict():
    """Handle prediction and return results and improvement tips."""
    if request.method == 'POST':
        try:
            data = request.get_json() if request.is_json else request.form

            user_data = {
                'gre_score': int(data['gre_score']),
                'toefl_score': int(data['toefl_score']),
                'university_rating': int(data['university_rating']),
                'sop': float(data['sop']),
                'lor': float(data['lor']),
                'cgpa': float(data['cgpa']),
                'research': int(data['research']),
            }

            X = pd.DataFrame([user_data.values()],
                             columns=['GRE Score', 'TOEFL Score', 'University Rating',
                                      'SOP', 'LOR', 'CGPA', 'Research'])
            prediction = model.predict(X)[0]

            uni_benchmark = None
            if 'university' in data and not pd.isna(data['university']):
                match = uni_df[uni_df['name'] == data['university']]
                if not match.empty:
                    uni_benchmark = match.iloc[0].to_dict()

            recommendations = generate_recommendations(user_data, prediction, uni_benchmark)

            return jsonify({
                'success': True,
                'prediction': round(float(prediction), 4),
                'recommendations': recommendations,
                'benchmark': uni_benchmark
            })

        except Exception as e:
            return jsonify({'success': False, 'error': str(e)}), 400

    return render_template('form.html')


@app.route('/universities')
def get_universities():
    """Return a list of all universities with benchmark data."""
    return jsonify(uni_df.to_dict(orient='records'))


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
