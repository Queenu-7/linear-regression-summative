import os

import joblib
import pandas as pd
from fastapi import HTTPException
from sklearn.base import clone

FEATURES = ["country", "product", "season_name", "crop_production_system",
            "planting_month", "harvest_month", "harvest_year", "area"]
TARGET = "yield"

MIN_YEAR, MAX_YEAR = 1995, 2035
MAX_AREA = 5000000


def retrain_model(file, pipeline, model_path, train_path):
    """Retrain on the original data + the uploaded CSV.
    Returns (new_pipeline, result_dict)."""

    # 1. Check uploaded file
    if not file.filename or not file.filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Please upload a .csv file.")

    try:
        new_data = pd.read_csv(file.file)
    except Exception:
        raise HTTPException(status_code=400, detail="Could not read the CSV file.")

    # 2. Check required columns
    needed = FEATURES + [TARGET]
    missing = [col for col in needed if col not in new_data.columns]
    if missing:
        raise HTTPException(status_code=400, detail=f"Missing columns: {missing}")

    # 3. Clean uploaded data
    new_data = new_data[needed].copy()

    for col in ["planting_month", "harvest_month", "harvest_year", "area", "yield"]:
        new_data[col] = pd.to_numeric(new_data[col], errors="coerce")

    new_data = new_data.dropna()

    new_data = new_data[
        (new_data["yield"] > 0)
        & (new_data["yield"] <= 50)
        & (new_data["area"] > 0)
        & (new_data["area"] <= MAX_AREA)
        & new_data["planting_month"].between(1, 12)
        & new_data["harvest_month"].between(1, 12)
        & new_data["harvest_year"].between(MIN_YEAR, MAX_YEAR)
    ]

    if len(new_data) == 0:
        raise HTTPException(status_code=400, detail="No valid rows found in the uploaded CSV.")

    # 4. Load original training data
    if not os.path.exists(train_path):
        raise HTTPException(status_code=500, detail="Original training data not found.")

    try:
        old_data = pd.read_csv(train_path)
        combined = pd.concat([old_data[needed], new_data], ignore_index=True)

        # 5. Fresh model pipeline, retrained on everything
        new_pipeline = clone(pipeline)
        new_pipeline.fit(combined[FEATURES], combined[TARGET])

        # 6. Save the new model
        temp_model_path = model_path + ".tmp"
        joblib.dump(new_pipeline, temp_model_path, compress=3)
        os.replace(temp_model_path, model_path)

        # 7. Update the training dataset
        temp_data_path = train_path + ".tmp"
        combined.to_csv(temp_data_path, index=False)
        os.replace(temp_data_path, train_path)

        result = {
            "message": "Model retrained and saved successfully.",
            "model_type": type(new_pipeline.named_steps["model"]).__name__,
            "method": "Full retraining on original data + new uploaded data",
            "original_rows": len(old_data),
            "new_rows_used": len(new_data),
            "total_training_rows": len(combined),
        }
        return new_pipeline, result

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Retraining failed: {str(e)}")