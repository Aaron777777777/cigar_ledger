import json
import firebase_admin
from firebase_admin import credentials, firestore

# Load Firebase credentials
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

# Load your prices.json
with open("assets/data/prices.json", "r") as f:
    cigars = json.load(f)

collection = db.collection("cigars")

for cigar in cigars:
    # Create a clean document ID
    doc_id = cigar["name"].lower().replace(" ", "_").replace(".", "").replace("-", "_")

    collection.document(doc_id).set(cigar)

    print(f"Uploaded: {cigar['name']}")

print("Done.")