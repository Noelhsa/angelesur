"""Entry point for the Windows backend executable."""

import os
from pathlib import Path
import sys

import uvicorn


def main():
    base_dir = (
        Path(sys.executable).resolve().parent
        if getattr(sys, "frozen", False)
        else Path(__file__).resolve().parent
    )
    os.chdir(base_dir)

    from app.config import get_settings
    from app.main import app

    settings = get_settings()
    if "--check" in sys.argv:
        print(f"Backend OK: {len(app.routes)} routes; port {settings.api_port}")
        return

    uvicorn.run(
        app,
        host=settings.api_host,
        port=settings.api_port,
        loop="asyncio",
        http="h11",
        ws="none",
    )


if __name__ == "__main__":
    main()
