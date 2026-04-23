from app.config import get_settings
import os

settings = get_settings()
print(f"CWD: {os.getcwd()}")
print(f"GEMINI_API_KEY (masked): {settings.gemini_api_key[:5]}...{settings.gemini_api_key[-5:] if settings.gemini_api_key else ''}")
print(f"OPENAI_API_KEY (masked): {settings.openai_api_key[:5]}...{settings.openai_api_key[-5:] if settings.openai_api_key else ''}")
