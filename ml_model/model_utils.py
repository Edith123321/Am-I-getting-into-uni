from sklearn.base import BaseEstimator, TransformerMixin

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
        X.columns = X.columns.str.strip()
        missing = set(self.expected_columns) - set(X.columns)
        if missing:
            raise ValueError(f"Missing columns: {missing}")
        for col, (min_val, max_val) in self.expected_columns.items():
            if not X[col].between(min_val, max_val).all():
                bad = X[~X[col].between(min_val, max_val)][col]
                raise ValueError(f"Invalid {col}: {bad.values}")
        return X