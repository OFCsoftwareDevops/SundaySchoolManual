# ultimate_rccg_ocr_final.py  ← This one finally works, no more errors

import io
import os
from PIL import Image
import pillow_heif
from google.cloud import vision
import requests

# ========================== SECRETS (safe outside repo) ==========================
if not os.path.exists("../database_files/vision-key.json"):
    print("ERROR: vision-key.json not found in ../database_files/")
    exit(1)

if not os.path.exists("../database_files/cohere_key.txt"):
    print("ERROR: cohere_key.txt not found in ../database_files/")
    exit(1)

with open("../database_files/cohere_key.txt", "r") as f:
    COHERE_KEY = f.read().strip()

vision_client = vision.ImageAnnotatorClient.from_service_account_json("../database_files/vision-key.json")

# ================================== PATHS ======================================
IMAGE_ROOT   = "images"          # images/adult/2025-01-05/1.jpg, etc.
OUTPUT_ROOT  = "extracted_texts" # → 2025-01-05_adult.txt, 2025-01-05_teen.txt
os.makedirs(OUTPUT_ROOT, exist_ok=True)

# ================================== HEIC to JPEG ======================================
def convert_heic_to_jpg(heic_path):
    """Convert HEIC/HEIF → JPEG in memory (no temp files)"""
    heif_file = pillow_heif.read_heif(heic_path)
    image = Image.frombytes(
        heif_file.mode,
        heif_file.size,
        heif_file.data,
        "raw",
        heif_file.mode,
        heif_file.stride,
    )
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=95)
    buffer.seek(0)
    return buffer.read()
    
# ============================= COHERE CLEANER (NO LIES) =========================
def clean_with_cohere(raw_text):
    payload = {
        "model": "command-r-08-2024",
        "messages": [
            {"role": "system", "content": 
             """"You are a robot that transcribes text from a picture to text form, with accuracy. "
            Your ONLY job is to take the raw text below and return it in this EXACT plain-text structure format describe below.
            While doing so, read sentences fix broken OCR words (no more than one word per line) and join split lines. "
            DO NOT REPHRASE, summarize, or improve any sentences. "
            DO NOT change any Bible verse. "
            For the LESSON Outline numbered points, Dont forget to write "LESSON OUTLINE" before the numbered points. "
            Ensure sentences on lines are continued properly. Without having to place every line break for every new line. "
            DO NOT move any text. "
            Return the exact same content, readable. "
            Examples: 'd ur' → 'our', 'till c' → 'till', '200-L due' → '200-Lesson due'.

            Use this structure.

            TOPIC: ...
            BIBLE PASSAGE: ...
            MEMORY VERSE: ...

            INTRODUCTION:
            ...

            LESSON OUTLINE:
            1. ...
            2. ...

            [POINT 1 TITLE]
            [full text]

            [POINT 2 TITLE]
            [full text]

            CONCLUSION:
            [only if the word "CONCLUSION" appears in the text]
            
            QUESTIONS:
            [only if the word "QUESTIONS" appears in the text]
            
            FURTHER READINGS:
            [only if the word "FURTHER READINGS" appears in the text]

            ASSIGNMENT:
            [only if the word "ASSIGNMENT" appears in the text]
            """},
            {"role": "user", "content": raw_text}
        ],
        "temperature": 0.0,
        "max_tokens": 3000
    }

    response = requests.post(
        "https://api.cohere.ai/v2/chat",
        headers={"Authorization": f"Bearer {COHERE_KEY}", "Content-Type": "application/json"},
        json=payload
    )
    
    response.raise_for_status()

    # Cohere v2 returns content as list → safely extract all text
    content_list = response.json()["message"]["content"]
    clean_text = " ".join(item["text"] for item in content_list if item.get("text"))
    return clean_text.strip()

# =============================== MAIN PIPELINE ================================
print("Starting Ultimate RCCG OCR Pipeline (Zero Hallucinations Mode)\n")
# MAIN LOOP — exactly how you wanted it
for category in ["adult", "teen"]:
    path = os.path.join(IMAGE_ROOT, category)
    if not os.path.exists(path): continue

    for date_folder in sorted(os.listdir(path)):
        full_path = os.path.join(path, date_folder)
        if not os.path.isdir(full_path): continue

        images = sorted([f for f in os.listdir(full_path)
                          if f.lower().endswith(('.jpg','.jpeg','.png','.heic','.heif'))])

        if not images:
            continue

        combined = ""
        raw_combined = ""   # ← NEW: collect all raw OCR text first
        for img in images:
            img_path = os.path.join(full_path, img)
            print(f"  OCR → {img}")

            if img.lower().endswith(('.heic', '.heif')):
                content = convert_heic_to_jpg(img_path)
            else:
                with open(img_path, "rb") as f:
                    content = f.read()

            ocr = vision_client.text_detection(image=vision.Image(content=content))
            raw = ocr.text_annotations[0].description if ocr.text_annotations else ""
            raw_combined += raw + "\n\n---PAGE---\n\n"   # ← just pile up raw text

        # ← NEW: send in chunks if too big (avoids 502)
        import textwrap
        chunks = textwrap.wrap(raw_combined, 12000, break_long_words=False, replace_whitespace=False)
        formatted_parts = []
        for i, chunk in enumerate(chunks):
            print(f"  Cohere chunk {i+1}/{len(chunks)}...")
            formatted_parts.append(clean_with_cohere(chunk))

        combined = "\n\n".join(formatted_parts)

        suffix = "_adult" if category == "adult" else "_teen"
        out_file = os.path.join(OUTPUT_ROOT, f"{date_folder}{suffix}.txt")
        with open(out_file, "w", encoding="utf-8") as f:
            f.write(combined.strip())

        print(f"DONE → {out_file}")

print("All finished. Go upload.")

