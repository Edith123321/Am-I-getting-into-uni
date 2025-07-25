import pandas as pd
import joblib
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split

# Load data
data = pd.read_csv('Admission_Prediction.csv')
data.rename(columns={'Chance of Admit ': 'Chance of Admit'}, inplace=True)

# Preprocess
X = data.drop(['Serial No.', 'Chance of Admit'], axis=1)
y = data['Chance of Admit']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)

# Train model
model = Pipeline([
    ('scaler', StandardScaler()),
    ('regressor', RandomForestRegressor(n_estimators=100, random_state=42))
])
model.fit(X_train, y_train)

# Save model
joblib.dump(model, '../backend/models/university_admission_predictor.pkl')
print("Model trained and saved!")