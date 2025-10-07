#!/usr/bin/env python3

import numpy as np
import pandas as pd
from sklearn.preprocessing import PolynomialFeatures
from sklearn.linear_model import BayesianRidge
from sklearn.metrics import r2_score, mean_squared_error
from sklearn.model_selection import cross_val_score
import json
import os
import glob
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import warnings
warnings.filterwarnings('ignore')


class PolynomialRegressor:
    def __init__(self, max_degree: int = 3, target_r2: float = 0.9):
        self.max_degree = max_degree
        self.target_r2 = target_r2
        self.model = None
        self.poly_features = None
        self.degree = None
        self.coefficients = None
        self.feature_names = None
        self.r2 = None
        self.adjusted_r2 = None
        
    def find_optimal_degree(self, X: np.ndarray, y: np.ndarray) -> int:
        best_degree = 1
        best_score = -np.inf
        best_adj_r2 = -np.inf
        
        n_samples = len(y)
        
        for degree in range(1, self.max_degree + 1):
            poly = PolynomialFeatures(degree=degree, include_bias=False)
            X_poly = poly.fit_transform(X)
            
            model = BayesianRidge(alpha_1=1e-6, alpha_2=1e-6, lambda_1=1e-6, lambda_2=1e-6)
            
            cv_scores = cross_val_score(model, X_poly, y, cv=min(5, n_samples), 
                                       scoring='r2')
            avg_cv_score = np.mean(cv_scores)
            
            model.fit(X_poly, y)
            y_pred = model.predict(X_poly)
            r2 = r2_score(y, y_pred)
            
            n_features = X_poly.shape[1]
            adj_r2 = 1 - (1 - r2) * (n_samples - 1) / (n_samples - n_features - 1)
            
            if adj_r2 > best_adj_r2 and adj_r2 > self.target_r2:
                best_degree = degree
                best_score = avg_cv_score
                best_adj_r2 = adj_r2
                
                if adj_r2 > 0.95 and degree < self.max_degree:
                    if degree > 1:
                        poly_next = PolynomialFeatures(degree=degree+1, include_bias=False)
                        X_poly_next = poly_next.fit_transform(X)
                        model_next = BayesianRidge(alpha_1=1e-6, alpha_2=1e-6, 
                                                  lambda_1=1e-6, lambda_2=1e-6)
                        model_next.fit(X_poly_next, y)
                        y_pred_next = model_next.predict(X_poly_next)
                        r2_next = r2_score(y, y_pred_next)
                        n_features_next = X_poly_next.shape[1]
                        adj_r2_next = 1 - (1 - r2_next) * (n_samples - 1) / (n_samples - n_features_next - 1)
                        
                        if adj_r2_next - adj_r2 < 0.01:
                            break
        
        return best_degree
    
    def fit(self, X: np.ndarray, y: np.ndarray, var_names: List[str]):
        self.degree = self.find_optimal_degree(X, y)
        
        self.poly_features = PolynomialFeatures(degree=self.degree, include_bias=True)
        X_poly = self.poly_features.fit_transform(X)
        
        self.model = BayesianRidge(alpha_1=1e-6, alpha_2=1e-6, lambda_1=1e-6, lambda_2=1e-6)
        self.model.fit(X_poly, y)
        
        y_pred = self.model.predict(X_poly)
        self.r2 = r2_score(y, y_pred)
        
        n_samples = len(y)
        n_features = X_poly.shape[1] - 1
        self.adjusted_r2 = 1 - (1 - self.r2) * (n_samples - 1) / (n_samples - n_features - 1)
        
        self.coefficients = self.model.coef_
        self.intercept = self.model.intercept_
        
        feature_names = ['1']
        powers = self.poly_features.powers_
        for power in powers[1:]:
            term_parts = []
            for i, p in enumerate(power):
                if p > 0:
                    if p == 1:
                        term_parts.append(var_names[i])
                    else:
                        term_parts.append(f"{var_names[i]}^{p}")
            feature_names.append('*'.join(term_parts) if term_parts else '1')
        
        self.feature_names = feature_names
        
        return self
    
    def predict(self, X: np.ndarray) -> np.ndarray:
        X_poly = self.poly_features.transform(X)
        return self.model.predict(X_poly)
    
    def get_residuals(self, X: np.ndarray, y: np.ndarray) -> np.ndarray:
        y_pred = self.predict(X)
        return y - y_pred
    
    def to_swift_equation(self, output_var: str = "result") -> str:
        terms = []
        
        for i, (coef, name) in enumerate(zip(self.coefficients, self.feature_names)):
            if abs(coef) < 1e-10:
                continue
                
            if i == 0:
                terms.append(f"{coef:.6e}")
            else:
                swift_term = name.replace('^', '.power(') + ')' * name.count('^')
                swift_term = swift_term.replace('*', ' * ')
                
                if coef >= 0:
                    terms.append(f"+ {coef:.6e} * {swift_term}")
                else:
                    terms.append(f"- {abs(coef):.6e} * {swift_term}")
        
        if self.intercept != 0:
            if self.intercept >= 0:
                terms.append(f"+ {self.intercept:.6e}")
            else:
                terms.append(f"- {abs(self.intercept):.6e}")
        
        equation = f"let {output_var} = " + " ".join(terms)
        return equation
    
    def to_mathematica_equation(self) -> str:
        terms = []
        
        for i, (coef, name) in enumerate(zip(self.coefficients, self.feature_names)):
            if abs(coef) < 1e-10:
                continue
                
            math_term = name.replace('*', ' ')
            
            if i == 0:
                terms.append(f"{coef}")
            else:
                if coef >= 0:
                    terms.append(f"+ {coef} {math_term}")
                else:
                    terms.append(f"{coef} {math_term}")
        
        if self.intercept != 0:
            if self.intercept >= 0:
                terms.append(f"+ {self.intercept}")
            else:
                terms.append(f"{self.intercept}")
        
        equation = " ".join(terms)
        return equation


class LinearInterpolator:
    def __init__(self):
        self.points = []
        self.equation_type = None
        
    def fit(self, X: np.ndarray, y: np.ndarray, var_name: str):
        self.points = [(X[i][0], y[i]) for i in range(len(y))]
        self.points.sort(key=lambda p: p[0])
        self.var_name = var_name
        
        unique_y = len(set([p[1] for p in self.points]))
        
        if len(self.points) == 2 or unique_y == len(self.points):
            self.equation_type = "linear"
        elif len(self.points) == 3 and unique_y == 2:
            self.equation_type = "discontinuous"
        else:
            self.equation_type = "linear"
        
        return self
    
    def to_swift_equation(self, output_var: str = "factor") -> str:
        if self.equation_type == "linear":
            if len(self.points) >= 2:
                x1, y1 = self.points[0]
                x2, y2 = self.points[-1]
                
                if x2 - x1 != 0:
                    slope = (y2 - y1) / (x2 - x1)
                    intercept = y1 - slope * x1
                    
                    if intercept >= 0:
                        return f"let {output_var} = {slope:.6e} * {self.var_name} + {intercept:.6e}"
                    else:
                        return f"let {output_var} = {slope:.6e} * {self.var_name} - {abs(intercept):.6e}"
                else:
                    return f"let {output_var} = {y1:.6e}"
        
        elif self.equation_type == "discontinuous":
            y_values = [p[1] for p in self.points]
            y_counts = {y: y_values.count(y) for y in set(y_values)}
            
            constant_y = None
            linear_point = None
            
            for y, count in y_counts.items():
                if count == 2:
                    constant_y = y
                    constant_points = [p for p in self.points if p[1] == y]
                    x_min = min(p[0] for p in constant_points)
                    x_max = max(p[0] for p in constant_points)
                else:
                    linear_point = [p for p in self.points if p[1] == y][0]
            
            if constant_y is not None and linear_point:
                x_linear, y_linear = linear_point
                
                if x_linear < x_min:
                    slope = (constant_y - y_linear) / (x_min - x_linear)
                    intercept = y_linear - slope * x_linear
                    
                    swift_code = f"let {output_var}: Double\n"
                    swift_code += f"if {self.var_name} < {x_min} {{\n"
                    if intercept >= 0:
                        swift_code += f"    {output_var} = {slope:.6e} * {self.var_name} + {intercept:.6e}\n"
                    else:
                        swift_code += f"    {output_var} = {slope:.6e} * {self.var_name} - {abs(intercept):.6e}\n"
                    swift_code += f"}} else {{\n"
                    swift_code += f"    {output_var} = {constant_y:.6e}\n"
                    swift_code += f"}}"
                    return swift_code
                    
                elif x_linear > x_max:
                    slope = (y_linear - constant_y) / (x_linear - x_max)
                    intercept = constant_y - slope * x_max
                    
                    swift_code = f"let {output_var}: Double\n"
                    swift_code += f"if {self.var_name} <= {x_max} {{\n"
                    swift_code += f"    {output_var} = {constant_y:.6e}\n"
                    swift_code += f"}} else {{\n"
                    if intercept >= 0:
                        swift_code += f"    {output_var} = {slope:.6e} * {self.var_name} + {intercept:.6e}\n"
                    else:
                        swift_code += f"    {output_var} = {slope:.6e} * {self.var_name} - {abs(intercept):.6e}\n"
                    swift_code += f"}}"
                    return swift_code
        
        return f"let {output_var} = {self.points[0][1]:.6e}"
    
    def to_mathematica_equation(self) -> str:
        if self.equation_type == "linear":
            if len(self.points) >= 2:
                x1, y1 = self.points[0]
                x2, y2 = self.points[-1]
                
                if x2 - x1 != 0:
                    slope = (y2 - y1) / (x2 - x1)
                    intercept = y1 - slope * x1
                    return f"{slope} * {self.var_name} + {intercept}"
                else:
                    return f"{y1}"
        
        elif self.equation_type == "discontinuous":
            y_values = [p[1] for p in self.points]
            y_counts = {y: y_values.count(y) for y in set(y_values)}
            
            constant_y = None
            linear_point = None
            
            for y, count in y_counts.items():
                if count == 2:
                    constant_y = y
                    constant_points = [p for p in self.points if p[1] == y]
                    x_min = min(p[0] for p in constant_points)
                    x_max = max(p[0] for p in constant_points)
                else:
                    linear_point = [p for p in self.points if p[1] == y][0]
            
            if constant_y is not None and linear_point:
                x_linear, y_linear = linear_point
                
                if x_linear < x_min:
                    slope = (constant_y - y_linear) / (x_min - x_linear)
                    intercept = y_linear - slope * x_linear
                    return f"Piecewise[{{{{{slope} * {self.var_name} + {intercept}, {self.var_name} < {x_min}}}, {{{constant_y}, True}}}}]"
                    
                elif x_linear > x_max:
                    slope = (y_linear - constant_y) / (x_linear - x_max)
                    intercept = constant_y - slope * x_max
                    return f"Piecewise[{{{{{constant_y}, {self.var_name} <= {x_max}}}, {{{slope} * {self.var_name} + {intercept}, True}}}}]"
        
        return f"{self.points[0][1]}"


def process_csv_file(filepath: str) -> Dict:
    df = pd.read_csv(filepath)
    
    if df.empty:
        return None
    
    filename = os.path.basename(filepath)
    is_adjustment = 'factor' in filename.lower() or 'contamination' in filename.lower()
    is_vref = 'vref' in filepath.lower()
    
    result = {
        'file': filepath,
        'filename': filename,
        'type': 'adjustment' if is_adjustment else ('vref' if is_vref else 'performance')
    }
    
    value_col = 'value' if 'value' in df.columns else df.columns[-1]
    feature_cols = [col for col in df.columns if col != value_col]
    
    if not feature_cols:
        return None
    
    X = df[feature_cols].values
    y = df[value_col].values
    
    if is_adjustment or len(feature_cols) == 1:
        model = LinearInterpolator()
        model.fit(X, y, feature_cols[0])
        
        result['model'] = model
        result['features'] = feature_cols
        result['equation_swift'] = model.to_swift_equation()
        result['equation_mathematica'] = model.to_mathematica_equation()
        result['r2'] = 1.0
        result['adjusted_r2'] = 1.0
        
    else:
        model = PolynomialRegressor(max_degree=3, target_r2=0.9)
        model.fit(X, y, feature_cols)
        
        result['model'] = model
        result['features'] = feature_cols
        result['degree'] = model.degree
        result['equation_swift'] = model.to_swift_equation()
        result['equation_mathematica'] = model.to_mathematica_equation()
        result['r2'] = model.r2
        result['adjusted_r2'] = model.adjusted_r2
        
        residuals = model.get_residuals(X, y)
        result['residuals'] = residuals.tolist()
        result['X'] = X.tolist()
        result['y'] = y.tolist()
    
    return result


def generate_binned_residuals(results: List[Dict]) -> Dict:
    binned_residuals = {}
    
    for result in results:
        if result and result['type'] == 'performance' and 'residuals' in result:
            # Create key from relative path without .csv extension
            filepath = Path(result['file'])
            relative_path = filepath.relative_to(Path("Data"))
            file_key = str(relative_path.with_suffix('')).replace('\\', '/')
            
            X = np.array(result['X'])
            residuals = np.array(result['residuals'])
            y = np.array(result['y'])
            y_pred = y - residuals
            
            # Calculate overall metrics
            overall_rmse = float(np.sqrt(np.mean(residuals**2)))
            overall_max_error = float(np.max(np.abs(residuals)))
            
            # Create bins for each feature
            bins_dict = {}
            for j, feature in enumerate(result['features']):
                feature_values = X[:, j]
                unique_vals = len(np.unique(feature_values))
                n_bins = min(5, unique_vals)
                
                if n_bins > 1:
                    # Create bins
                    bin_edges = np.percentile(feature_values, np.linspace(0, 100, n_bins + 1))
                    bin_edges = np.unique(bin_edges)  # Remove duplicates
                    
                    feature_bins = []
                    for i in range(len(bin_edges) - 1):
                        mask = (feature_values >= bin_edges[i]) & (feature_values < bin_edges[i + 1])
                        if i == len(bin_edges) - 2:  # Last bin includes the maximum
                            mask = (feature_values >= bin_edges[i]) & (feature_values <= bin_edges[i + 1])
                        
                        if np.any(mask):
                            bin_residuals = residuals[mask]
                            feature_bins.append({
                                'range': [float(bin_edges[i]), float(bin_edges[i + 1])],
                                'rmse': float(np.sqrt(np.mean(bin_residuals**2))),
                                'max_error': float(np.max(np.abs(bin_residuals)))
                            })
                    
                    if feature_bins:
                        bins_dict[feature] = feature_bins
            
            binned_residuals[file_key] = {
                'overall_rmse': overall_rmse,
                'overall_max_error': overall_max_error,
                'bins': bins_dict
            }
    
    return binned_residuals


def main():
    data_dir = Path("Data")
    
    all_csv_files = list(data_dir.rglob("*.csv"))
    print(f"Found {len(all_csv_files)} CSV files to process")
    
    results = []
    swift_equations = []
    mathematica_equations = []
    
    for csv_file in all_csv_files:
        print(f"Processing: {csv_file}")
        result = process_csv_file(str(csv_file))
        
        if result:
            results.append(result)
            
            relative_path = str(csv_file.relative_to(data_dir))
            comment = f"// {relative_path}"
            
            if result['type'] == 'performance':
                comment += f" (degree={result.get('degree', 'N/A')}, R²={result['r2']:.4f}, adj-R²={result['adjusted_r2']:.4f})"
            
            swift_equations.append(comment)
            swift_equations.append(result['equation_swift'])
            swift_equations.append("")
            
            mathematica_equations.append(f"(* {relative_path} *)")
            if result['type'] == 'performance':
                mathematica_equations.append(f"(* degree={result.get('degree', 'N/A')}, R²={result['r2']:.4f}, adj-R²={result['adjusted_r2']:.4f} *)")
            mathematica_equations.append(result['equation_mathematica'])
            mathematica_equations.append("")
    
    with open("equations.swift", "w") as f:
        f.write("// Generated polynomial and linear regression equations\n")
        f.write("// Using Bayesian polynomial regression with max degree 3\n")
        f.write("// Performance tables target adjusted R² > 0.9\n\n")
        f.write("import Foundation\n\n")
        f.write("\n".join(swift_equations))
    
    print("Swift equations saved to equations.swift")
    
    with open("equations_mathematica.txt", "w") as f:
        f.write("(* Generated polynomial and linear regression equations *)\n")
        f.write("(* Using Bayesian polynomial regression with max degree 3 *)\n")
        f.write("(* Performance tables target adjusted R² > 0.9 *)\n\n")
        f.write("\n".join(mathematica_equations))
    
    print("Mathematica equations saved to equations_mathematica.txt")
    
    binned_residuals = generate_binned_residuals(results)
    
    with open("Data/residuals.json", "w") as f:
        json.dump(binned_residuals, f, indent=2)
    
    print("Binned residuals saved to Data/residuals.json")
    
    performance_tables = [r for r in results if r and r['type'] == 'performance']
    if performance_tables:
        avg_r2 = np.mean([r['r2'] for r in performance_tables])
        avg_adj_r2 = np.mean([r['adjusted_r2'] for r in performance_tables])
        print(f"\nPerformance tables average R²: {avg_r2:.4f}")
        print(f"Performance tables average adjusted R²: {avg_adj_r2:.4f}")
        
        low_r2 = [r for r in performance_tables if r['adjusted_r2'] < 0.9]
        if low_r2:
            print(f"\nWarning: {len(low_r2)} tables have adjusted R² < 0.9:")
            for r in low_r2:
                print(f"  - {r['filename']}: adj-R² = {r['adjusted_r2']:.4f}")


if __name__ == "__main__":
    main()