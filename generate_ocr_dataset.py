import os
import pandas as pd
import pytesseract
from PIL import Image
import json

# Set Tesseract path
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# Load dataset
csv_path = r"C:\Users\ASUS\Documents\GitHub\FYP2025\bookbuddy\data\main_dataset.csv"
images_folder = r"C:\Users\ASUS\Documents\GitHub\FYP2025\bookbuddy\data"

df = pd.read_csv(csv_path)

print(f"Loaded {len(df)} records from dataset.")

# Main OCR loop
ocr_results = []

for idx, row in df.iterrows():
    image_path = os.path.join(images_folder, row['cover-image-url'])

    if not os.path.exists(image_path):
        print(f"❌ Image not found: {image_path}")
        continue

    image = Image.open(image_path)
    ocr_text = pytesseract.image_to_string(image).strip()

    title = str(row.get('title', '')).lower()
    author = str(row.get('author', '')).lower()
    ocr_text_clean = ocr_text.lower().replace('\n', ' ').replace('\r', '').strip()

    title_found = title in ocr_text_clean
    author_found = author in ocr_text_clean

    print(f"📘 {row['cover-image-url']}")
    print(f"→ Title: {row['title']} | Author: {row['author']}")
    print(f"→ OCR: {ocr_text.strip()}")
    print(f"→ Match: Title={'✅' if title_found else '❌'}, Author={'✅' if author_found else '❌'}\n")

    ocr_results.append({
        "cover-image-url": row['cover-image-url'],
        "ground_truth_title": row['title'],
        "ground_truth_author": row['author'],
        "ocr_text": ocr_text
    })

# Export OCR results
output_path = os.path.join(os.path.dirname(csv_path), "ocr_results.json")
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(ocr_results, f, indent=2, ensure_ascii=False)

print(f"✅ OCR results exported to: {output_path}")
