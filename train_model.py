import os
import pytesseract
from PIL import Image
import pandas as pd

# 🔧 CONFIG
IMAGE_DIR = r"C:\Users\ASUS\book-covers-dataset"
CSV_PATH = r"C:\Users\ASUS\Documents\GitHub\FYP2025\bookbuddy\data\main_dataset.csv"

# 📖 Load book metadata from CSV
def load_books_from_csv(csv_path):
    df = pd.read_csv(csv_path)
    return df[['name', 'author', 'img_paths']].dropna()

# 🔍 Match extracted text with book entries
def match_with_dataset(extracted_text, book_df):
    extracted_text = extracted_text.lower()
    matches = []
    for _, row in book_df.iterrows():
        title = str(row['name']).lower()
        author = str(row['author']).lower()
        if title in extracted_text or author in extracted_text:
            matches.append(row.to_dict())
    return matches

# 🔠 Perform OCR on a single image
def extract_text_from_image(image_path):
    try:
        image = Image.open(image_path)
        text = pytesseract.image_to_string(image)
        return text.lower()
    except Exception as e:
        print(f"Error reading {image_path}: {e}")
        return ""

# 🚀 Main logic
def main():
    book_df = load_books_from_csv(CSV_PATH)
    results = []

    print(f"📂 Scanning folder: {IMAGE_DIR}")
    for filename in os.listdir(IMAGE_DIR):
        if filename.lower().endswith((".jpg", ".jpeg", ".png")):
            image_path = os.path.join(IMAGE_DIR, filename)
            print(f"\n📷 Processing: {filename}")
            extracted_text = extract_text_from_image(image_path)
            print(f"📝 Extracted Text: {extracted_text.strip()}")

            matches = match_with_dataset(extracted_text, book_df)
            if matches:
                print(f"✅ Matches Found:")
                for match in matches:
                    print(f"  → {match['name']} by {match['author']}")
                results.append({"image": filename, "matches": matches})
            else:
                print("❌ No match found.")

    # Save results to file
    output_path = "ocr_results_from_csv.json"
    import json
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Done. Results saved to {output_path}")

if __name__ == "__main__":
    main()
