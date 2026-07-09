from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    db_host: str = "127.0.0.1"
    db_port: int = 3307
    db_user: str = "root"
    db_password: str = "1234"
    db_name: str = "farmacia_angeles_v2"
    api_host: str = "127.0.0.1"
    api_port: int = 8000

    model_config = SettingsConfigDict(
        env_file=".env",
        env_prefix="ANGELESUR_",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
