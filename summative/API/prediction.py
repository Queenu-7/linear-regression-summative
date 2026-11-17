import os
import joblib
import pandas as pd
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator
from sklearn.linear_model import SGDRegressor

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "best_model.pkl")
TRAIN_PATH = os.path.join(BASE_DIR, "train_data.csv")

pipeline = joblib.load(MODEL_PATH)

FEATURES = ["country", "product", "season_name", "crop_production_system",
            "planting_month", "harvest_month", "harvest_year", "area"]
TARGET = "yield"

ALLOWED = {
    "country": ['Angola', 'Benin', 'Burkina Faso', 'Burundi', 'Cameroon',
                'Central African Republic', 'Chad', 'DRC', 'Ethiopia', 'Ghana',
                'Kenya', 'Lesotho', 'Liberia', 'Madagascar', 'Malawi', 'Mali',
                'Mauritania', 'Mozambique', 'Niger', 'Nigeria', 'Rwanda',
                'Senegal', 'Somalia', 'South Africa', 'South Sudan', 'Sudan',
                'Tanzania, United Republic of', 'Togo', 'Uganda', 'Zambia',
                'Zimbabwe'],
    "product": ['Avocado', 'Bambara groundnut', 'Banana', 'Barley', 'Bean (Hyacinth)',
                'Beans (Rosecoco)', 'Beans (White)', 'Beans (mixed)', 'Beet',
                'Bush Bean', 'Cabbage', 'Canola Seed', 'Capsicum Chinense', 'Carrots',
                'Cashew (unshelled)', 'Cassava', 'Celery', 'Cereal Crops', 'Chick Peas',
                'Chili Pepper', 'Coffee', 'Coriander', 'Cotton', 'Cotton (Acala)',
                'Cotton (American)', 'Cottonseed', 'Cowpea', 'Cucumber', 'Eggplant',
                'Ethiopian Cabbage', 'Fava Bean', 'Fenugreek', 'Field Peas', 'Fonio',
                'Garlic', 'Geocarpa groundnut', 'Ginger', 'Goussi', 'Green Bean',
                'Green Peppers', 'Groundnuts (In Shell)', 'Hops', 'Jute', 'Kale',
                'Lemon', 'Lentils', 'Lettuce', 'Linseed', 'Macadamia', 'Maize',
                'Maize (Yellow)', 'Mango', 'Melon', 'Millet', 'Molokhia', 'Mung bean',
                'Neug', 'Oats', 'Okras', 'Onions', 'Orange', 'Pam Nut', 'Papaya',
                'Paprika', 'Pea', 'Pepper', 'Pigeon Pea', 'Pineapple', 'Pole Bean',
                'Potato', 'Pyrethrum', 'Rape', 'Rice', 'Sesame Seed', 'Sorghum',
                'Sorghum (Red)', 'Sorrel', 'Soybean', 'Squash',
                'Squash and Melon Seeds', 'Sugarcane', 'Sunflower Seed',
                'Sweet Potatoes', 'Taro', 'Tea', 'Teff', 'Tobacco', 'Tomato',
                'Velvet Bean', 'Virginia Peanut', 'Watermelon', 'Wheat', 'Yams'],
    "season_name": ['Annual', 'Deyr', 'Dry', 'Gu', 'Long', 'Main', 'Meher', 'Other',
                    'Season A', 'Season B', 'Season C', 'Summer', 'Wet'],
    "crop_production_system": ['All (PS)', 'Commercial (PS)', 'Other',
                               'Rainfed (PS)', 'irrigated', 'none'],
}

MIN_YEAR, MAX_YEAR = 1995, 2035
MAX_AREA = 5000000

class PredictionInput(BaseModel):
    country: str = Field(..., description="Country name, e.g. Rwanda")
    product: str = Field(..., description="Crop name, e.g. Maize")
    season_name: str = Field(..., description="Season, e.g. Season A")
    crop_production_system: str = Field(..., description="Farming system, e.g. none")
    planting_month: int = Field(..., ge=1, le=12, description="Month number 1-12")
    harvest_month: int = Field(..., ge=1, le=12, description="Month number 1-12")
    harvest_year: int = Field(..., ge=MIN_YEAR, le=MAX_YEAR, description="Year of harvest")
    area: float = Field(..., gt=0, le=MAX_AREA, description="Cultivated area in hectares")

    @field_validator("country", "product", "season_name", "crop_production_system")
    @classmethod
    def check_category(cls, value, info):
        if value not in ALLOWED[info.field_name]:
            raise ValueError(
                f"'{value}' is not a valid {info.field_name}. "
                f"Allowed values: {ALLOWED[info.field_name]}"
            )
        return value

    model_config = {
        "json_schema_extra": {
            "example": {
                "country": "Rwanda",
                "product": "Maize",
                "season_name": "Season A",
                "crop_production_system": "none",
                "planting_month": 9,
                "harvest_month": 1,
                "harvest_year": 2026,
                "area": 1500.0,
            }
        }
    }

app = FastAPI(title="Crop Yield Prediction API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://crop-yield-api-ai2s.onrender.com",
        "http://localhost:5000",
        "http://127.0.0.1:5000"
    ],
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
    allow_credentials=False,
)

@app.get("/")
def home():
    return {"message": "Crop Yield Prediction API is running. Open /docs to try it."}

@app.post("/predict")
def predict(data: PredictionInput):
    row = pd.DataFrame([data.model_dump()])[FEATURES]

    prediction = float(pipeline.predict(row)[0])
    prediction = max(prediction, 0.0)

    return {"predicted_yield_t_per_ha": round(prediction, 2)}

@app.post("/retrain")
def retrain(file: UploadFile = File(...)):
    global pipeline

    if not file.filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Please upload a .csv file.")

    try:
        new_data = pd.read_csv(file.file)
    except Exception:
        raise HTTPException(status_code=400, detail="Could not read the CSV file.")

    needed = FEATURES + [TARGET]
    missing = [col for col in needed if col not in new_data.columns]

    if missing:
        raise HTTPException(status_code=400, detail=f"Missing columns: {missing}")

    new_data = new_data[needed].dropna()

    new_data = new_data[
        (new_data[TARGET] > 0) & (new_data[TARGET] <= 50)
        & (new_data["area"] > 0) & (new_data["area"] <= MAX_AREA)
        & new_data["planting_month"].between(1, 12)
        & new_data["harvest_month"].between(1, 12)
    ]

    if len(new_data) == 0:
        raise HTTPException(status_code=400, detail="No valid rows found in the file.")

    model = pipeline.named_steps["model"]

    if isinstance(model, SGDRegressor):

        new_X = pipeline.named_steps["preprocess"].transform(new_data[FEATURES])
        model.partial_fit(new_X, new_data[TARGET])

        method = "partial_fit on the new rows"

    else:

        if not os.path.exists(TRAIN_PATH):
            raise HTTPException(status_code=500, detail="Original training data not found.")

        old_data = pd.read_csv(TRAIN_PATH)
        combined = pd.concat([old_data, new_data], ignore_index=True)

        pipeline.fit(combined[FEATURES], combined[TARGET])
        combined.to_csv(TRAIN_PATH, index=False)

        method = "refit on original data + new rows"

    joblib.dump(pipeline, MODEL_PATH, compress=3)

    return {
        "message": "Model updated and saved successfully.",
        "model_type": type(model).__name__,
        "method": method,
        "new_rows_used": len(new_data),
    }