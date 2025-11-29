# upload_to_database.py — The one that actually works

import shutil
import firebase_admin
from firebase_admin import credentials, firestore
import os

# ================================== PATHS ======================================
if not os.path.exists("../database_files/serviceAccountKey.json"):
    print("ERROR: serviceAccountKey.json not found in ../database_files/")
    print("Keep your keys safe — never commit them!")
    exit(1)

cred = credentials.Certificate("../database_files/serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()


RAW = "extracted_texts"
FOLDER = "lessons_2025"
COLLECTION = "lessons"

# ================================== TRANSFER FILES ======================================
# Create destination folder if it doesn't exist
os.makedirs(FOLDER, exist_ok=True)

for filename in os.listdir(RAW):
    src = os.path.join(RAW, filename)
    dst = os.path.join(FOLDER, filename)
    
    if os.path.isfile(src):   # ignore subfolders
        shutil.copy2(src, dst)


# ================================== PARSE FILES ======================================
def parse(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        lines = [line.rstrip() for line in f.readlines()]

    topic = "Untitled"
    passage = ""
    blocks = []
    outline_points = []
    i = 0

    def add_section(heading_text, stop_conditions):
        nonlocal i
        blocks.append({"type": "heading", "text": heading_text})
        i += 1
        text = []
        while i < len(lines):
            next_line = lines[i].strip().lower()
            if any(next_line.startswith(cond) for cond in stop_conditions) or next_line == "":
                break
            text.append(lines[i])
            i += 1
        t = "\n".join(text).strip()
        if t:
            blocks.append({"type": "text", "text": t})

    while i < len(lines):
        line = lines[i].strip()

        # TOPIC: collect topic
        if line.lower().startswith("topic:"):
            topic = line[(line.find(":")+1):].strip()
        
        # BIBLE PASSAGE: collect passage
        elif line.lower().startswith("bible passage:"):
            passage = line[(line.find(":")+1):].strip()
        
        # INTRODUCTION: collect until next section
        elif line.lower().startswith("introduction"):
            #add_section("Introduction", ["memory verse", "lesson outline", "outline", "1. "])
            #continue

            blocks.append({"type": "heading", "text": "Introduction"})
            i += 1
            while i < len(lines) and lines[i].strip() not in ["Memory Verse", "Lesson Outline"] and not lines[i].lower().startswith("outline") and not lines[i].lower().startswith("lesson outline") and not lines[i].lower().startswith("1. ") and (i+1 >= len(lines) or not lines[i+1].lower().startswith("2. ")):
                blocks.append({"type": "text", "text": lines[i]})
                i += 1
            continue

        # MEMORY VERSE: collect until next section
        elif line.lower().startswith("memory verse") or line.lower().startswith("memory verses"):
            i += 1
            verse = []
            while i < len(lines) and lines[i].strip() not in ["Lesson Outline"] and not lines[i].lower().startswith("introduction"):
                verse.append(lines[i])
                i += 1
            v = "\n".join(verse).strip()
            if v: blocks.append({"type": "memory_verse", "text": v})
            continue

        # LESSON OUTLINE: collect points
        elif line.lower().startswith("lesson outline") or line.lower().startswith("outline"):
            blocks.append({"type": "heading", "text": "Lesson Outline"})
            i += 1
            while i < len(lines):
                l = lines[i].strip()
                if not l or l[0].isalpha() or l in ["Prayer", "Conclusion"]:
                    break
                clean = l.lstrip("0123456789. )•-–—*").strip()
                clean = clean.title()
                if clean:
                    outline_points.append(clean)
                i += 1
            if outline_points:
                blocks.append({"type": "numbered_list", "items": outline_points[:]})
            continue
        #print(f"Pro: {outline_points}")

        # MAIN EXPLANATION: heading = exact match from outline
        if outline_points != []:
            while line in outline_points or line.lower().startswith(outline_points[0].lower()):
                if line in outline_points:
                    remove_line = line
                elif line.lower().startswith(outline_points[0].lower()):
                    remove_line = outline_points[0]
                line = line.title()
                blocks.append({"type": "heading", "text": line})
                outline_points.remove(remove_line)  # prevent reuse
                i += 1
                text = []

                #print(f"Processing section: {line}")
                ##print(f"Remaining outline points: {outline_points}")

                while i < len(lines):
                    next_line = lines[i].strip()
                    if next_line in outline_points or next_line.lower().startswith(("prayer:", "conclusion:")) or next_line == "":
                        break
                    text.append(lines[i])
                    #print(f"Pro: {text}")
                    i += 1
                t = "\n".join(text).strip()
                if t: blocks.append({"type": "text", "text": t})
                #print(f"Added text block for section: {line}")
                ##print(f"Current blocks: {blocks}")
                if outline_points == []:
                    break
                continue             

        # Conclusion
        if line.lower().startswith("conclusion"):
            add_section("Conclusion", ["prayer:", "questions", "further"])
            continue

        #    blocks.append({"type": "heading", "text": "Conclusion"})
        #    i += 1
        #    text = []
        #    while i < len(lines):
        #        next_line = lines[i].strip()
        #        if next_line.lower().startswith("prayer:") or next_line.lower().startswith("questions") or next_line.lower().startswith("further") or next_line.lower() == "":
        #            break
        #        text.append(lines[i])
        #        i += 1
        #    t = "\n".join(text).strip()
        #    if t: blocks.append({"type": "text", "text": t})
        #    continue

        # Questions
        if line.lower().startswith("questions"):
            add_section("Questions", ["prayer:", "further"])
            continue

        #    blocks.append({"type": "heading", "text": "Questions"})
        #    i += 1
        #    text = []
        #    while i < len(lines):
        #        next_line = lines[i].strip()
        #        if next_line.lower().startswith("prayer:") or next_line.lower().startswith("further") or next_line.lower() == "":
        #            break
        #        text.append(lines[i])
        #        i += 1
        #    t = "\n".join(text).strip()
        #    if t: blocks.append({"type": "text", "text": t})
        #    continue

        # Questions
        if line.lower().startswith("further readings"):
            add_section("Further Readings", ["prayer:"])
            continue

        #    blocks.append({"type": "heading", "text": "Further Readings"})
        #    i += 1
        #    text = []
        #    while i < len(lines):
        #        next_line = lines[i].strip()
        #        if next_line.lower().startswith("prayer:") or next_line.lower() == "":
        #            break
        #        text.append(lines[i])
        #        i += 1
        #    t = "\n".join(text).strip()
        #    if t: blocks.append({"type": "text", "text": t})
        #    continue

        # Assignment
        if line.lower().startswith("assignment"):
            add_section("Assignment", ["prayer:"])
            continue
    
        #    blocks.append({"type": "heading", "text": "Assignment"})
        #    i += 1
        #    text = []
        #    while i < len(lines):
        #        next_line = lines[i].strip()
        #        if next_line.lower().startswith("prayer:") or next_line.lower() == "":
        #            break
        #        text.append(lines[i])
        #        i += 1
        #    t = "\n".join(text).strip()
        #    if t: blocks.append({"type": "text", "text": t})
        #    continue


        if line.lower().startswith("prayer"):
            i += 1
            prayer = "\n".join(lines[i:]).strip()
            if prayer: blocks.append({"type": "prayer", "text": prayer})
            break

        i += 1

    return {"topic": topic, "biblePassage": passage, "blocks": blocks}

# ================================== UPLOAD FILES ======================================
for filename in sorted(os.listdir(FOLDER)):
    if not filename.endswith(".txt"): continue
    date = filename[:10]
    kind = "teen" if "_teen" in filename else "adult" if "_adult" in filename else None
    if not kind: continue

    data = parse(os.path.join(FOLDER, filename))
    db.collection(COLLECTION).document(date).set({kind: data}, merge=True)
    print(f"{kind.upper()} → {date}")

print("Done.")
