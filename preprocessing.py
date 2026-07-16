"""
preprocessing.py
Modul preprocessing gambar untuk BatikVerse Nusantara Flask App.
Mengikuti standar preprocessing MobileNetV2 (224x224, RGB, preprocess_input).
"""

import numpy as np
from PIL import Image
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input

IMAGE_SIZE = (224, 224)


def load_image(image_path):
    """Memuat gambar dari path dan mengonversinya ke mode RGB."""
    return Image.open(image_path).convert("RGB")


def resize_image(image, target_size=IMAGE_SIZE):
    """Mengubah ukuran gambar ke ukuran standar input model."""
    return image.resize(target_size)


def preprocess_image(image_path):
    """
    Pipeline lengkap preprocessing gambar untuk prediksi:
      1. Load image
      2. Convert ke RGB
      3. Resize ke 224x224
      4. Preprocessing MobileNetV2 (preprocess_input)

    Mengembalikan array NumPy dengan shape (1, 224, 224, 3).
    """
    image = load_image(image_path)
    image = resize_image(image)
    image_array = np.array(image, dtype=np.float32)
    image_array = np.expand_dims(image_array, axis=0)
    image_array = preprocess_input(image_array)
    return image_array
