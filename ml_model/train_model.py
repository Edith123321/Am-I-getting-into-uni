import pandas as pd
import joblib
import os
import numpy as np
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.base import BaseEstimator, TransformerMixin
from shared_utils import DataValidator

class DataValidator(BaseEstimator, TransformerMixin):
    """Validates data structure and ranges"""
    def __init__(self):
        self.expected_columns = {
            'GRE Score': (290, 340),
            'TOEFL Score': (92, 120),
            'University Rating': (1, 5),
            'SOP': (1.0, 5.0),
            'LOR': (1.0, 5.0),
            'CGPA': (6.8, 9.92),
            'Research': (0, 1)
        }
    
    def fit(self, X, y=None):
        return self
        
    def transform(self, X):
        # Clean column names
        X.columns = X.columns.str.strip()
        
        # Validate presence
        missing = set(self.expected_columns) - set(X.columns)
        if missing:
            raise ValueError(f"Missing columns: {missing}")
            
        # Validate ranges
        for col, (min_val, max_val) in self.expected_columns.items():
            if not X[col].between(min_val, max_val).all():
                bad = X[~X[col].between(min_val, max_val)][col]
                raise ValueError(
                    f"Invalid {col}: {bad.values}. Range: {min_val}-{max_val}"
                )
        return X

# Configure paths
current_dir = os.path.dirname(os.path.abspath(__file__))
csv_path = os.path.join(current_dir, 'Admission_Prediction.csv')
model_dir = os.path.join(current_dir, '../backend/models')
os.makedirs(model_dir, exist_ok=True)
model_path = os.path.join(model_dir, 'university_admission_predictor.pkl')

# Load and clean data
print("Loading data...")
data = pd.read_csv(csv_path)
data.columns = data.columns.str.strip()
data.rename(columns={'Chance of Admit': 'Chance of Admit'}, inplace=True)

# Validate target
if not data['Chance of Admit'].between(0, 1).all():
    raise ValueError("Target must be 0-1")

# Prepare features/target
X = data.drop(['Serial No.', 'Chance of Admit'], axis=1)
y = data['Chance of Admit']

# Modeling pipeline
pipeline = Pipeline([
    ('validator', DataValidator()),
    ('scaler', StandardScaler()),
    ('model', GradientBoostingRegressor(
        n_estimators=200,
        learning_rate=0.05,
        max_depth=4,
        random_state=42
    ))
])

# Train/validate
print("Training model...")
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
pipeline.fit(X_train, y_train)

# Evaluate
train_pred = pipeline.predict(X_train)
test_pred = pipeline.predict(X_test)
print("\nModel Performance:")
print(f"Train R²: {r2_score(y_train, train_pred):.3f}")
print(f"Test R²: {r2_score(y_test, test_pred):.3f}")
print(f"Test RMSE: {np.sqrt(mean_squared_error(y_test, test_pred)):.4f}")

# Save model
joblib.dump(pipeline, model_path)
print(f"\nModel saved to {model_path}")

# Test cases
test_cases = [
    [340, 120, 5, 5.0, 5.0, 9.9, 1],  # Perfect applicant
    [290, 92, 1, 1.0, 1.0, 6.8, 0],   # Weak applicant
    [320, 110, 3, 3.5, 4.0, 8.5, 1]   # Average applicant
]

print("\nTest Predictions:")
for case in test_cases:
    case_df = pd.DataFrame([case], columns=X.columns)
    pred = pipeline.predict(case_df)[0]
    print(f"Input: {case} -> Prediction: {pred:.1%}")