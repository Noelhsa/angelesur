from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.errors import install_error_handlers
from app.routers import (
    cortes,
    health,
    inventario,
    productos,
    proveedores,
    usuarios,
    ventas,
)


app = FastAPI(
    title="Angelesur API",
    version="0.1.0",
    description="API local para conectar Flutter con MariaDB.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1", "http://localhost", "http://127.0.0.1:8000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

install_error_handlers(app)

app.include_router(health.router)
app.include_router(inventario.router)
app.include_router(cortes.router)
app.include_router(usuarios.router)
app.include_router(productos.router)
app.include_router(proveedores.router)
app.include_router(ventas.router)
