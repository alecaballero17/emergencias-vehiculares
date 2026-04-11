from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    app_name: str = "Emergencias Vehiculares API"
    app_version: str = "1.0.0"
    debug: bool = False

    # Base de datos
    database_url: str = "postgresql://postgres:postgres@localhost:5432/emergencias_vehiculares"

    # JWT
    secret_key: str = "cambiar-esta-clave-secreta-en-produccion"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440

    # OpenAI
    openai_api_key: str = ""

    # Firebase
    firebase_credentials_path: str = "firebase-credentials.json"

    # Uploads
    upload_dir: str = "uploads"
    max_image_size_mb: int = 10
    max_audio_size_mb: int = 25

    # Comisión
    platform_commission_percent: float = 10.0

    model_config = {"env_file": ".env", "extra": "ignore"}


@lru_cache()
def get_settings() -> Settings:
    return Settings()
