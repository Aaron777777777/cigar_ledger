import json
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

project = Path.home() / "Projects/cigar_ledger"
key_path = project / "serviceAccountKey.json"
config_path = project / "tools/firestore_config/cigar_ledger_app_config.json"

if not key_path.exists():
    raise FileNotFoundError("Missing serviceAccountKey.json in project root")

cred = credentials.Certificate(str(key_path))

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

with open(config_path, "r", encoding="utf-8") as f:
    data = json.load(f)

db = firestore.client()
db.collection("app_config").document("cigar_ledger").set(data, merge=True)

print("Uploaded app_config/cigar_ledger")
