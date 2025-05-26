import os
import pandas as pd
import pytesseract
from PIL import Image

# Optional: set tesseract path if not auto-detected
# pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# Load dataset
csv_path = r"C:\Users\ASUS\Documents\GitHub\FYP2025\bookbuddy\data\main_dataset.csv"
images_folder = r"C:\Users\ASUS\Documents\GitHub\FYP2025\bookbuddy\data\book-covers"

df = pd.read_csv(csv_path)

print(f"Loaded {len(df)} records from dataset.")

# Columns expected: 'filename', 'title', 'author'
for idx, row in df.iterrows():
    image_file = os.path.join(images_folder, row['filename'])

    if not os.path.exists(image_file):
        print(f"Image not found: {image_file}")
        continue

    # Load image
    image = Image.open(image_file)

    # OCR
    ocr_text = pytesseract.image_to_string(image)
    ocr_text = ocr_text.lower()

    title = str(row.get('title', '')).lower()
    author = str(row.get('author', '')).lower()

    ocr_text_clean = ocr_text.replace('\n', ' ').replace('\r', '').strip().lower()
    title_found = title in ocr_text_clean
    author_found = author in ocr_text_clean

    print(f"📘 {row['filename']}")
    print(f"→ Ground Truth: {row['title']} by {row['author']}")
    print(f"→ OCR Extracted: {ocr_text.strip()}")
    print(f"→ Match: Title={'✅' if title_found else '❌'}, Author={'✅' if author_found else '❌'}\n")

# Create a new list of results
ocr_results = []

# Reset loop
for idx, row in df.iterrows():
    image_file = os.path.join(images_folder, row['filename'])

    if not os.path.exists(image_file):
        continue

    image = Image.open(image_file)
    ocr_text = pytesseract.image_to_string(image).strip()

    result = {
        "filename": row['filename'],
        "ground_truth_title": row['title'],
        "ground_truth_author": row['author'],
        "ocr_text": ocr_text
    }

    ocr_results.append(result)

# Export to JSON
import json

output_path = os.path.join(os.path.dirname(csv_path), "ocr_results.json")
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(ocr_results, f, indent=2, ensure_ascii=False)

print(f"✅ OCR results exported to: {output_path}")
