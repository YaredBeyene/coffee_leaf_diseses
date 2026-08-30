from flask import Flask, request, jsonify
from flask_cors import CORS
import tensorflow as tf
from tensorflow.keras.models import load_model
import numpy as np
from PIL import Image
import io

app = Flask(__name__)
CORS(app)  # Enables CORS for communication with the Flutter app

# 1. Load the trained .h5 model (using your actual file name: coffee_disease_model.h5)
MODEL_PATH = 'coffee_disease_model.h5'
model = load_model(MODEL_PATH)

# Disease class names (update these labels to match your model's training classes)
class_names = ['Healthy', 'Coffee Leaf Rust', 'Cercospora Leaf Spot', 'Phoma'] 

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400
    
    file = request.files['file']
    
    try:
        # 2. Read the uploaded image and resize it to match the model input size (e.g., 224x224)
        image = Image.open(io.BytesIO(file.read()))
        image = image.resize((224, 224)) 
        image_array = np.array(image) / 255.0  # Normalize pixel values
        image_array = np.expand_dims(image_array, axis=0)
        
        # 3. Run prediction using the TensorFlow model
        predictions = model.predict(image_array)
        predicted_class_index = np.argmax(predictions[0])
        confidence = float(np.max(predictions[0])) * 100
        
        result = class_names[predicted_class_index]
        
        # 4. Return the predicted disease and confidence score back to the Flutter app
        return jsonify({
            'disease': result,
            'confidence': f"{confidence:.2f}%"
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)