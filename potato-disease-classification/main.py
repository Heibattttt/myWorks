from fastapi import FastAPI, UploadFile,File
import uvicorn
import numpy as np
from io import BytesIO
from PIL import Image
import tensorflow as tf
from pydantic import BaseModel
import requests
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI()


class PredictionResponse(BaseModel):
    class_: str
    confidence: float


origins = [
    "http://localhost",
    "http://localhost:3000",
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


model_tf = tf.keras.models.load_model("model.keras")
class_names = ['Early Blight', 'Late Blight', 'Healthy']

@app.get("/ping")
async def ping():
    return {"message": "Hello  World"}

def read_files_as_image(data) -> np.ndarray:
    image = Image.open(BytesIO(data))
    image = np.array(image)

    return image

@app.post("/prediction", response_model=PredictionResponse)
async def predict(
    file: UploadFile=File(...)
):
    image = read_files_as_image(await file.read())
    img_batch=np.expand_dims(image, axis=0)
    
    prediction = model_tf.predict(img_batch)

    predicted_class = class_names[np.argmax(prediction[0])]
    confidence = float(np.max(prediction[0]))

    return PredictionResponse(
        class_=predicted_class,
        confidence=float(np.max(prediction[0]))
    )





if __name__ == "__main__":
   uvicorn.run(app, host="localhost", port=8000)    
