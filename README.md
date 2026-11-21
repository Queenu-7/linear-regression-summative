# Crop Yield Prediction System

## 1. Mission and Problem

My mission is to help smallholder farmers in Africa make better farming decisions by predictions their expected crop yields. Many farmers struggle to estimate how much they will harvest making it difficult to plan their farming activities and resources. I developed this model that predicts crop yield (tonnes per hectare) using details such as country, crop type, season, planting and harvesting months, year, farming system and cultivated area. The system delivers predictions via FastAPI backend and Flutter app.

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

- **Source:**
- **Link:**

## 3. Public API (Swagger UI)

The API is publicly avaliable through Swagger UI where you can test the prediction and retraining endpoints.

Test the API here: ** **

- `POST / predict` returns a yield prediction. Example input: Rwanda, Maize, Season A, production system `none`, planting month 9, harvest month 1, harvest year 2026, area 1500.
- `POST /retrain` accepts a CSV file and retrains the model on the original data plus the new rows.

> The API runs on Render's free tier so the first request after a period of inactivity can take about 50 seconds.

## 4. Video Demo

Watch the demo on Youtube: ** **

## 5. How to run the mobile app

**Requirements:** [Flutter SDK] ()

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

This app calls `` so it needs an internet connection. The first prediction may be slow while the server wakes up.





