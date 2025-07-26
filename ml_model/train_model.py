#!/usr/bin/env python3

import pandas as pd
import joblib
import os
import numpy as np
import sklearn
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.ensemble import GradientBoostingRegressor
from pathlib import Path
import platform

# Print environment info
print("Python version:", platform.python_version())
print("Pandas version:", pd.__version__)
print("NumPy version:", np.__version__)
print("scikit-learn version:", sklearn.__version__)

def validate_input_data(X):
    """Standalone validation function"""
    expected_ranges = {
        'GRE Score': (290, 340),
        'TOEFL Score': (92, 120),
        'University Rating': (1, 5),
        'SOP': (1.0, 5.0),
        'LOR': (1.0, 5.0),
        'CGPA': (6.8, 9.92),
        'Research': (0, 1)
    }

    X.columns = X.columns.str.strip()
    missing = set(expected_ranges) - set(X.columns)
    if missing:
        raise ValueError(f"Missing columns: {missing}")

    for col, (min_val, max_val) in expected_ranges.items():
        if not X[col].between(min_val, max_val).all():
            bad = X[~X[col].between(min_val, max_val)][col]
            raise ValueError(f"Invalid {col}: {bad.values}. Range: {min_val}-{max_val}")
    return X

# Configure paths
current_dir = Path(__file__).parent
csv_path = current_dir / 'Admission_Prediction.csv'
model_path = current_dir.parent / "backend" / "models" / "university_admission_predictor.pkl"
model_path.parent.mkdir(parents=True, exist_ok=True)

# Load and clean data
print("\nLoading data...")
data = pd.read_csv(csv_path)
data.columns = data.columns.str.strip()

# Validate data
validate_input_data(data.drop(['Serial No.', 'Chance of Admit'], axis=1))
if not data['Chance of Admit'].between(0, 1).all():
    raise ValueError("Target 'Chance of Admit' must be in the range [0, 1]")

# Prepare features/target
X = data.drop(['Serial No.', 'Chance of Admit'], axis=1)
y = data['Chance of Admit']

# Scale features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Train model
print("Training model...")
X_train, X_test, y_train, y_test = train_test_split(X_scaled, y, test_size=0.2, random_state=42)

model = GradientBoostingRegressor(
    n_estimators=200,
    learning_rate=0.05,
    max_depth=4,
    random_state=42
)
model.fit(X_train, y_train)

# Evaluate
train_pred = model.predict(X_train)
test_pred = model.predict(X_test)
print("\nModel Performance:")
print(f"Train R²: {r2_score(y_train, train_pred):.3f}")
print(f"Test R²: {r2_score(y_test, test_pred):.3f}")
print(f"Test RMSE: {np.sqrt(mean_squared_error(y_test, test_pred)):.4f}")

# Save model and scaler together
joblib.dump({
    'model': model,
    'scaler': scaler,
    'feature_names': X.columns.tolist()
}, model_path)
print(f"\n✅ Model saved to {model_path}")

# Test cases
test_cases = [
    [340, 120, 5, 5.0, 5.0, 9.9, 1],
    [290, 92, 1, 1.0, 1.0, 6.8, 0],
    [320, 110, 3, 3.5, 4.0, 8.5, 1]
]

print("\n🔍 Test Predictions:")
for case in test_cases:
    case_df = pd.DataFrame([case], columns=X.columns)
    case_scaled = scaler.transform(case_df)
    pred = model.predict(case_scaled)[0]
    print(f"Input: {case} -> Prediction: {pred:.1%}")
