from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse

from app.errors import install_error_handlers
from app.routers import (
    caja,
    compras,
    cortes,
    devoluciones,
    health,
    inventario,
    productos,
    proveedores,
    respaldos,
    servicios_yastas,
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

# The packaged API runs one worker. Admission is decided before awaiting so a
# backup starts only when all earlier requests have completed.
app.state.solicitudes_activas = 0
app.state.respaldo_en_curso = False
app.state.recuperacion_requerida = None


@app.middleware("http")
async def mantenimiento_respaldos(request, call_next):
    if app.state.recuperacion_requerida:
        return JSONResponse(status_code=503, content={"detail": app.state.recuperacion_requerida})
    exclusivo = request.url.path in {"/respaldos/crear", "/respaldos/restaurar"} and request.method == "POST"
    if app.state.respaldo_en_curso or (exclusivo and app.state.solicitudes_activas):
        return JSONResponse(status_code=503, content={"detail": "Sistema ocupado. Espera a que termine la operacion e intenta nuevamente."})
    app.state.solicitudes_activas += 1
    if exclusivo:
        app.state.respaldo_en_curso = True
    try:
        return await call_next(request)
    finally:
        app.state.solicitudes_activas -= 1
        if exclusivo:
            app.state.respaldo_en_curso = False


app.include_router(respaldos.router)

app.include_router(health.router)
app.include_router(caja.router)
app.include_router(devoluciones.router)
app.include_router(inventario.router)
app.include_router(cortes.router)
app.include_router(usuarios.router)
app.include_router(productos.router)
app.include_router(proveedores.router)
app.include_router(compras.router)
app.include_router(servicios_yastas.router)
app.include_router(ventas.router)
