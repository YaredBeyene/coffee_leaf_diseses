from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import tensorflow as tf
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
import numpy as np
import io
from PIL import Image
import uvicorn  # Import uvicorn to run FastAPI directly from python

app = FastAPI(title="Coffee Leaf Disease Detection API")

# Enable CORS to allow the Flutter app to communicate with this backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# 1. Load the trained .h5 model
MODEL_PATH = "coffee_disease_model.h5"
try:
    model = load_model(MODEL_PATH)
except Exception as e:
    print(f"Error loading model: {e}")

# Disease class names matching your trained model
CLASSES = ["Cercospora", "Healthy", "Miner", "Phoma", "Rust"] 

@app.get("/")
def home():
    return {"message": "Coffee Leaf Disease Detection API is running!"}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    # Check if the uploaded file is an image
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Uploaded file is not an image.")
    
    try:
        # 2. Read the uploaded image file
        contents = await file.read()
        img = Image.open(io.BytesIO(contents)).convert("RGB")
        
        # 3. Resize image to match model's expected input shape (128x128)
        img = img.resize((128, 128))
        
        # Convert to numpy array and normalize pixel values
        x = image.img_to_array(img)
        x = np.expand_dims(x, axis=0)
        x = x / 255.0  

        # 4. Perform prediction using the TensorFlow model
        predictions = model.predict(x)
        predicted_class_index = np.argmax(predictions[0])
        confidence = float(np.max(predictions[0]))

        # Get the corresponding disease class name
        result_class = CLASSES[predicted_class_index] if predicted_class_index < len(CLASSES) else "Unknown"

        # 5. Return the result as JSON to the Flutter app
        return {
            "class": result_class,
            "confidence": round(confidence * 100, 2)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == '__main__':
    print("Starting Coffee Disease Prediction Server...")
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
    