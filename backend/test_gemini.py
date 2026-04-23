import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
print(f"Clave: {api_key[:12]}...")
genai.configure(api_key=api_key)

MODELS = [
    "gemini-2.5-flash-lite",
    "gemini-flash-latest",
    "gemini-pro-latest",
]

for model_name in MODELS:
    try:
        model = genai.GenerativeModel(model_name)
        response = model.generate_content("Responde solo: OK")
        print(f"[OK] {model_name}: {response.text.strip()}")
    except Exception as e:
        err = str(e)[:100]
        print(f"[FAIL] {model_name}: {err}")
