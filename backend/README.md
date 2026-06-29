# Backend Angelesur

API local para conectar la app Flutter con MariaDB.

La base `farmacia_angeles_v2` concentra la logica de negocio en vistas, funciones, triggers y procedimientos almacenados. Por eso esta API no debe reimplementar ventas, compras, cortes o devoluciones manualmente: debe llamar los `CALL sp_...` definidos en la base.

## Arquitectura local

- Flutter: interfaz de escritorio.
- Backend FastAPI: servicio local en `http://127.0.0.1:8000`.
- MariaDB: servidor local en la misma laptop.
- Base: `farmacia_angeles_v2`.

## Preparacion

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
```

Edita `.env` con el usuario y contrasena local de MariaDB.

## Ejecutar

```powershell
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

## Endpoints iniciales

- `GET /health`: confirma que la API responde.
- `GET /health/db`: confirma conexion a MariaDB.
- `GET /inventario/disponible`: lee `vw_inventario_disponible_para_venta`.
- `GET /inventario/actual`: lee `vw_inventario_actual`.
- `GET /inventario/caducidad`: lee `vw_productos_por_caducar`.
- `GET /usuarios`: lista usuarios activos.
- `GET /usuarios/{idUsuario}`: obtiene un usuario.
- `POST /usuarios`: crea un usuario con contrasena hasheada.
- `PATCH /usuarios/{idUsuario}/estado`: activa o desactiva un usuario.
- `POST /auth/login`: valida `username` y `password`.
- `GET /cortes/actual`: lee el corte abierto desde `vw_corte_resumen`.
- `POST /cortes/abrir`: llama `sp_abrir_corte`.
- `POST /cortes/cerrar`: llama `sp_cerrar_corte`.
- `POST /ventas`: llama `sp_registrar_venta`.

## Usuario de prueba local

Durante la primera prueba local se creo, si la tabla estaba vacia:

- Usuario: `admin`
- Contrasena: `1234`
- Rol: `JEFE`

## Nota importante

MariaDB no es una base embebida como SQLite. Para que la app "lleve todo adentro", el instalador final tendra que incluir o preparar un MariaDB local, cargar `BaseActual.sql`, iniciar el servicio local y luego arrancar esta API junto con Flutter.
