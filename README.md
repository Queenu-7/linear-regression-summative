# Crop Yield Prediction System

## 1. Mission and Problem

My mission is to help smallholder farmers in Africa plan better by predicting their expected crop yield.
Many farmers struggle to estimate how much they will harvest, which makes planning farming activities and resources difficult.
I built a model that predicts yield (tonnes per hectare) from country, crop, season, farming system, planting and harvest months, year and area.
Predictions are delivered through a FastAPI backend and a Flutter mobile app.

## 2. Dataset

The dataset used in this project contains **10,000 records** covering **31 African countries** and different crop types. It includes 8 input features:

- country
- product
- season_name
- crop_production_system
- planting_month
- harvest_month
- harvest_year
- area

The target variable is yield which represents the crop yield in tonnes per hectare (t/ha).

- **Source:** HarvestStat Africa (FEWS NET), via the CircuitNotion dataset on Hugging Face
- **File used:** `hvstat_africa_data_v1.0.csv`
  The original file (`hvstat_africa_data_v1.0.csv`) has **203,125 records**. After cleaning (removing missing, zero or negative values, yields above 50 t/ha, years before 1995 and areas above 5,000,000 ha) **159,999 records** remained, and a sample of **10,000 records** was used to train the model. The data covers **31 African countries** and different crop types. It includes 8 input features:
- **Link:** https://huggingface.co/datasets/CircuitNotion/africa-crop-yield

## 3. Public API (Swagger UI)

The API is publicly available through Swagger UI where you can test the prediction and retraining endpoints.

**Test the API here:** https://crop-yield-api-ai2s.onrender.com/docs

- `POST /predict` returns a yield prediction. Example input: Rwanda, Maize, Season A, production system `none`, planting month 9, harvest month 1, harvest year 2026, area 1500.
- `POST /retrain` accepts a CSV file and retrains the model on the original data plus the new rows.

> The API runs on Render's free tier so the first request after a period of inactivity can take about 50 seconds.

## 4. Video Demo

**Watch the demo on YouTube:** https://youtu.be/3LL1Az1wzDw

## 5. How to run the mobile app

**Requirements:** [Flutter SDK](https://docs.flutter.dev/get-started/install), Android Studio (or the Android SDK platform-tools) and an Android phone with USB debugging enabled (or an emulator).

1. Clone the repository:
   ```bash
   git clone https://github.com/Queenu-7/linear-regression-summative.git
   ```
2. Open the flutter app folder:
   ```bash
   cd linear-regression-summative/summative/FlutterApp
   ```
3. Install the dependencies:
   ```bash
   flutter pub get
   ```
4. Connect your phone with USB (or start an emulator) and check that it is detected:
   ```bash
   flutter devices
   ```
5. Run the app:
   ```bash
   flutter run
   ```
6. In the app enter the farm details (EX: Rwanda, Maize, Season A, 1500 hectares) and tap **Predict**. the App sends the requests to the deployed API and shows the predicted yield.

This app calls `https://crop-yield-api-ai2s.onrender.com/predict` so it needs an internet connection. The first prediction may be slow while the server wakes up.




