#!/usr/bin/env python3
"""
Generate polynomial regression models for SF50 performance data.

This script:
1. Reads CSV data files
2. Fits polynomial regression models (degree 2 by default)
3. Generates Swift code for the regression equations
4. Calculates residuals and statistical metrics (RMSE, max error, binned RMSE)
5. Creates visualization plots for model validation
6. Updates residuals.json with new data
"""

import pandas as pd
import numpy as np
from sklearn.preprocessing import PolynomialFeatures
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error, r2_score
import matplotlib.pyplot as plt
from pathlib import Path
import json
from typing import Dict, List, Tuple


class RegressionGenerator:
    """Generate regression models from CSV data."""

    def __init__(self, csv_path: str, degree: int = 2):
        """
        Initialize with CSV file path.

        Args:
            csv_path: Path to CSV file
            degree: Polynomial degree for regression
        """
        self.csv_path = Path(csv_path)
        self.degree = degree
        self.df = pd.read_csv(csv_path)
        self.model = None
        self.poly_features = None
        self.X = None
        self.y = None
        self.y_pred = None
        self.residuals = None

    def prepare_data(self, input_cols: List[str], output_col: str):
        """Prepare data for regression."""
        self.X = self.df[input_cols].values
        self.y = self.df[output_col].values

    def fit(self):
        """Fit polynomial regression model."""
        self.poly_features = PolynomialFeatures(degree=self.degree, include_bias=False)
        X_poly = self.poly_features.fit_transform(self.X)

        self.model = LinearRegression()
        self.model.fit(X_poly, self.y)

        self.y_pred = self.model.predict(X_poly)
        self.residuals = self.y - self.y_pred

    def get_swift_code(self, input_names: List[str]) -> str:
        """Generate Swift code for the regression equation."""
        if self.model is None:
            raise ValueError("Model not fitted yet")

        # Get feature names
        feature_names = self.poly_features.get_feature_names_out(input_names)
        coefficients = self.model.coef_
        intercept = self.model.intercept_

        # Generate Swift code
        lines = []
        lines.append("let value =")

        for i, (coef, feature) in enumerate(zip(coefficients, feature_names)):
            # Convert feature name to Swift expression
            swift_expr = feature
            for input_name in input_names:
                # Replace x0, x1, x2 with actual variable names
                swift_expr = swift_expr.replace(f'x{input_names.index(input_name)}', input_name)

            # Handle powers
            if '^' in swift_expr:
                parts = swift_expr.split(' ')
                new_parts = []
                for part in parts:
                    if '^' in part:
                        base, exp = part.split('^')
                        new_parts.append(f'pow({base}, {exp})')
                    else:
                        new_parts.append(part)
                swift_expr = ' * '.join(new_parts)

            # Format coefficient in scientific notation
            if coef >= 0:
                sign = '+'
            else:
                sign = '-'

            coef_str = f"{abs(coef):.6e}"

            if i == 0:
                lines.append(f"  {coef_str} * {swift_expr}")
            else:
                lines.append(f"  {sign} {coef_str} * {swift_expr}")

        # Add intercept
        if intercept >= 0:
            sign = '+'
        else:
            sign = '-'
        lines.append(f"  {sign} {abs(intercept):.6e}")

        return '\n'.join(lines)

    def calculate_metrics(self) -> Dict:
        """Calculate statistical metrics."""
        rmse = np.sqrt(mean_squared_error(self.y, self.y_pred))
        max_error = np.max(np.abs(self.residuals))
        r2 = r2_score(self.y, self.y_pred)

        return {
            'rmse': rmse,
            'max_error': max_error,
            'r2': r2,
            'mean_residual': np.mean(self.residuals),
            'std_residual': np.std(self.residuals)
        }

    def calculate_binned_rmse(self, input_cols: List[str], n_bins: int = 4) -> Dict:
        """Calculate RMSE for binned ranges of each input variable."""
        bins_data = {}

        for i, col in enumerate(input_cols):
            col_values = self.X[:, i]
            bin_edges = np.linspace(col_values.min(), col_values.max(), n_bins + 1)

            bin_list = []
            for j in range(n_bins):
                mask = (col_values >= bin_edges[j]) & (col_values < bin_edges[j + 1])
                if j == n_bins - 1:  # Include upper bound in last bin
                    mask = (col_values >= bin_edges[j]) & (col_values <= bin_edges[j + 1])

                if np.sum(mask) > 0:
                    bin_residuals = self.residuals[mask]
                    bin_rmse = np.sqrt(np.mean(bin_residuals ** 2))
                    bin_max_error = np.max(np.abs(bin_residuals))

                    bin_list.append({
                        'range': [float(bin_edges[j]), float(bin_edges[j + 1])],
                        'rmse': float(bin_rmse),
                        'max_error': float(bin_max_error)
                    })

            bins_data[col] = bin_list

        return bins_data

    def plot_validation(self, output_col: str, save_path: str = None):
        """Create validation plots."""
        fig, axes = plt.subplots(2, 2, figsize=(14, 10))
        fig.suptitle(f'Regression Validation: {self.csv_path.name}', fontsize=16)

        # Predicted vs Actual
        ax = axes[0, 0]
        ax.scatter(self.y, self.y_pred, alpha=0.5, s=20)
        min_val = min(self.y.min(), self.y_pred.min())
        max_val = max(self.y.max(), self.y_pred.max())
        ax.plot([min_val, max_val], [min_val, max_val], 'r--', lw=2, label='Perfect fit')
        ax.set_xlabel(f'Actual {output_col}')
        ax.set_ylabel(f'Predicted {output_col}')
        ax.set_title('Predicted vs Actual')
        ax.legend()
        ax.grid(True, alpha=0.3)

        # Residuals distribution
        ax = axes[0, 1]
        ax.hist(self.residuals, bins=50, edgecolor='black', alpha=0.7)
        ax.axvline(0, color='r', linestyle='--', lw=2)
        ax.set_xlabel('Residual')
        ax.set_ylabel('Frequency')
        ax.set_title('Residual Distribution')
        ax.grid(True, alpha=0.3)

        # Residuals vs Predicted
        ax = axes[1, 0]
        ax.scatter(self.y_pred, self.residuals, alpha=0.5, s=20)
        ax.axhline(0, color='r', linestyle='--', lw=2)
        ax.set_xlabel(f'Predicted {output_col}')
        ax.set_ylabel('Residual')
        ax.set_title('Residuals vs Predicted')
        ax.grid(True, alpha=0.3)

        # Q-Q plot
        ax = axes[1, 1]
        from scipy import stats
        stats.probplot(self.residuals, dist="norm", plot=ax)
        ax.set_title('Q-Q Plot')
        ax.grid(True, alpha=0.3)

        # Add metrics text
        metrics = self.calculate_metrics()
        metrics_text = (
            f"RMSE: {metrics['rmse']:.4f}\n"
            f"Max Error: {metrics['max_error']:.4f}\n"
            f"R²: {metrics['r2']:.6f}\n"
            f"Mean Residual: {metrics['mean_residual']:.4e}\n"
            f"Std Residual: {metrics['std_residual']:.4f}"
        )
        fig.text(0.02, 0.02, metrics_text, fontsize=10, family='monospace',
                bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))

        plt.tight_layout()

        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
            print(f"Saved plot to {save_path}")

        return fig


def process_enroute_climb_data():
    """Process enroute climb data (normal and ice contaminated)."""
    results = {}

    base_path = Path("SF50 Shared/Data/g1/enroute climb")

    for condition in ['normal', 'ice contaminated']:
        condition_path = base_path / condition

        for metric in ['gradient', 'rate', 'speed']:
            csv_path = condition_path / f'{metric}.csv'

            if not csv_path.exists():
                print(f"Warning: {csv_path} not found, skipping...")
                continue

            print(f"\n{'='*60}")
            print(f"Processing: {csv_path}")
            print('='*60)

            # Create regression generator
            rg = RegressionGenerator(str(csv_path), degree=2)
            rg.prepare_data(['pressure_alt_ft', 'oat_c', 'weight_lb'], 'value')
            rg.fit()

            # Generate Swift code
            swift_code = rg.get_swift_code(['altitude', 'temperature', 'weight'])
            print("\nSwift code:")
            print(swift_code)

            # Calculate metrics
            metrics = rg.calculate_metrics()
            print(f"\nMetrics:")
            print(f"  RMSE: {metrics['rmse']:.4f}")
            print(f"  Max Error: {metrics['max_error']:.4f}")
            print(f"  R²: {metrics['r2']:.6f}")

            # Calculate binned RMSE
            bins = rg.calculate_binned_rmse(['pressure_alt_ft', 'oat_c', 'weight_lb'])

            # Create plot
            plot_path = f"Data/plots/enroute_climb_{condition.replace(' ', '_')}_{metric}.png"
            Path("Data/plots").mkdir(exist_ok=True)
            rg.plot_validation('value', plot_path)
            plt.close()

            # Store results
            key = f"g1/enroute climb/{condition}/{metric}"
            results[key] = {
                'overall_rmse': float(metrics['rmse']),
                'overall_max_error': float(metrics['max_error']),
                'bins': {
                    'altitude': bins['pressure_alt_ft'],
                    'temperature': bins['oat_c'],
                    'weight': bins['weight_lb']
                }
            }

    return results


def process_time_fuel_distance_data():
    """Process time/fuel/distance to climb data."""
    results = {}

    base_path = Path("SF50 Shared/Data/g1/time fuel distance to climb")

    for metric in ['time', 'fuel', 'distance']:
        csv_path = base_path / f'{metric}.csv'

        if not csv_path.exists():
            print(f"Warning: {csv_path} not found, skipping...")
            continue

        print(f"\n{'='*60}")
        print(f"Processing: {csv_path}")
        print('='*60)

        # Create regression generator
        rg = RegressionGenerator(str(csv_path), degree=2)
        rg.prepare_data(['altitude_ft', 'oat_c', 'weight_lb'], 'value')
        rg.fit()

        # Generate Swift code
        swift_code = rg.get_swift_code(['altitude', 'temperature', 'weight'])
        print("\nSwift code:")
        print(swift_code)

        # Calculate metrics
        metrics = rg.calculate_metrics()
        print(f"\nMetrics:")
        print(f"  RMSE: {metrics['rmse']:.4f}")
        print(f"  Max Error: {metrics['max_error']:.4f}")
        print(f"  R²: {metrics['r2']:.6f}")

        # Calculate binned RMSE
        bins = rg.calculate_binned_rmse(['altitude_ft', 'oat_c', 'weight_lb'])

        # Create plot
        plot_path = f"Data/plots/time_fuel_distance_{metric}.png"
        Path("Data/plots").mkdir(exist_ok=True)
        rg.plot_validation('value', plot_path)
        plt.close()

        # Store results
        key = f"g1/time fuel distance to climb/{metric}"
        results[key] = {
            'overall_rmse': float(metrics['rmse']),
            'overall_max_error': float(metrics['max_error']),
            'bins': {
                'altitude': bins['altitude_ft'],
                'temperature': bins['oat_c'],
                'weight': bins['weight_lb']
            }
        }

    return results


def update_residuals_json(new_results: Dict):
    """Update residuals.json with new data."""
    residuals_path = Path("SF50 Shared/Data/residuals.json")

    # Load existing data
    if residuals_path.exists():
        with open(residuals_path, 'r') as f:
            residuals_data = json.load(f)
    else:
        residuals_data = {}

    # Update with new results
    residuals_data.update(new_results)

    # Save back to file
    with open(residuals_path, 'w') as f:
        json.dump(residuals_data, f, indent=2)

    print(f"\nUpdated {residuals_path} with {len(new_results)} new entries")


def main():
    """Main execution."""
    print("SF50 Regression Model Generator")
    print("=" * 60)

    # Process enroute climb data
    print("\n\nPROCESSING ENROUTE CLIMB DATA")
    print("=" * 60)
    enroute_results = process_enroute_climb_data()

    # Process time/fuel/distance data
    print("\n\nPROCESSING TIME/FUEL/DISTANCE DATA")
    print("=" * 60)
    tfd_results = process_time_fuel_distance_data()

    # Combine all results
    all_results = {**enroute_results, **tfd_results}

    # Update residuals.json
    update_residuals_json(all_results)

    print("\n" + "=" * 60)
    print("COMPLETE!")
    print("=" * 60)
    print(f"\nGenerated {len(all_results)} regression models")
    print(f"Plots saved to Data/plots/")
    print(f"Updated SF50 Shared/Data/residuals.json")


if __name__ == '__main__':
    main()
