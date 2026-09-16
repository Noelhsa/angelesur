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
- `GET /inventario/actual`: lee `vw_inventario_actual` con paginacion (`pagina`, `limite`) y filtros por busqueda, categoria y estado de stock.
- `GET /inventario/{idInventario}`: obtiene un lote de inventario.
- `GET /inventario/caducidad`: lee `vw_productos_por_caducar`.
- `GET /inventario/movimientos`: lista movimientos de inventario.
- `GET /inventario/historial-precios`: lista cambios de precio.
- `PATCH /inventario/{idInventario}/datos-lote`: actualiza lote, caducidad, precio de venta y ubicacion del registro de inventario.
- `PATCH /inventario/{idInventario}/ubicacion`: actualiza la ubicacion de estante del lote.
- `POST /inventario/ajuste`: llama `sp_ajustar_inventario`.
- `POST /inventario/precio`: llama `sp_cambiar_precio_inventario`.
- `GET /usuarios`: lista usuarios activos.
- `GET /usuarios/{idUsuario}`: obtiene un usuario.
- `POST /usuarios`: crea un usuario con contrasena hasheada.
- `PATCH /usuarios/{idUsuario}/estado`: activa o desactiva un usuario.
- `POST /auth/login`: valida `username` y `password`.
- `GET /productos`: lista productos paginados con filtros por busqueda, tipo, categoria y estado.
- `GET /productos/{idProducto}`: obtiene un producto con datos de medicamento si aplica.
- `POST /productos`: crea producto o medicamento.
- `PATCH /productos/{idProducto}`: actualiza producto o medicamento.
- `PATCH /productos/{idProducto}/estado`: activa o desactiva un producto.
- `GET /proveedores`: lista proveedores activos.
- `GET /proveedores/{idProveedor}`: obtiene un proveedor.
- `POST /proveedores`: crea proveedor.
- `PATCH /proveedores/{idProveedor}`: actualiza proveedor.
- `PATCH /proveedores/{idProveedor}/estado`: activa o desactiva un proveedor.
- `GET /compras`: lista compras paginadas con filtros por busqueda, estatus y proveedor.
- `GET /compras/{idCompra}`: obtiene compra con detalles.
- `POST /compras`: llama `sp_registrar_compra`.
- `POST /compras/{idCompra}/cancelar`: llama `sp_cancelar_compra`.
- `GET /caja/movimientos`: lista movimientos de dinero.
- `GET /caja/movimientos/{idMovDin}`: obtiene un movimiento de dinero.
- `POST /caja/movimiento`: llama `sp_registrar_movimiento_caja`.
- `GET /caja/saldo/actual`: lee el resumen del corte abierto.
- `GET /ventas`: lista ventas.
- `GET /ventas/{idVenta}`: obtiene venta con detalles y pagos.
- `GET /ventas/{idVenta}/pagos`: lista pagos de una venta.
- `POST /ventas/{idVenta}/cancelar`: llama `sp_cancelar_venta`.
- `GET /servicios-yastas/tarifas`: lista tarifas Yastas.
- `GET /servicios-yastas/tarifas/{idTarifa}`: obtiene una tarifa.
- `POST /servicios-yastas/tarifas`: crea tarifa.
- `PATCH /servicios-yastas/tarifas/{idTarifa}`: actualiza tarifa.
- `PATCH /servicios-yastas/tarifas/{idTarifa}/estado`: activa o desactiva tarifa.
- `GET /servicios-yastas`: lista operaciones Yastas.
- `GET /servicios-yastas/{idServicioOperacion}`: obtiene una operacion.
- `POST /servicios-yastas`: llama `sp_registrar_servicio_yastas`.
- `POST /servicios-yastas/{idServicioOperacion}/cancelar`: llama `sp_cancelar_servicio_yastas`.
- `GET /devoluciones/clientes`: lista devoluciones de clientes.
- `GET /devoluciones/clientes/{idDevolucionCliente}`: obtiene devolucion de cliente.
- `POST /devoluciones/clientes`: llama `sp_registrar_devolucion_cliente`.
- `POST /devoluciones/clientes/{idDevolucionCliente}/cancelar`: llama `sp_cancelar_devolucion_cliente`.
- `GET /devoluciones/proveedores`: lista devoluciones a proveedor.
- `GET /devoluciones/proveedores/{idDevolucionProveedor}`: obtiene devolucion a proveedor.
- `POST /devoluciones/proveedores`: llama `sp_registrar_devolucion_proveedor`.
- `POST /devoluciones/proveedores/{idDevolucionProveedor}/cancelar`: llama `sp_cancelar_devolucion_proveedor`.
- `GET /cortes/resumen`: lista cortes paginados con saldos, totales, usuarios de apertura/cierre y filtros por busqueda, estado y fechas. Acepta `pagina` y `limite`, y devuelve `items`, `total`, `totalPaginas`, `hayAnterior` y `haySiguiente`.
- `GET /cortes/actual`: lee el corte abierto desde `vw_corte_resumen`.
- `GET /cortes/{idCorte}`: obtiene resumen, totales y movimientos del corte.
- `GET /cortes/{idCorte}/movimientos`: lista movimientos de un corte.
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

## Migraciones

Los cambios incrementales de estructura de base se guardan en `backend/migrations`.

- `20260720_inventario_ubicacion_estante.sql`: agrega `ubicacionLetra` y `ubicacionNumero` a `inventario_producto`, y expone `ubicacionEstante` en las vistas de inventario.

## Ejecutable del backend para Windows

Desde la raiz del repositorio, con las dependencias del backend instaladas:

```powershell
.\backend\.venv\Scripts\python.exe -m pip install pyinstaller==6.22.3
.\backend\.venv\Scripts\python.exe -m PyInstaller --noconfirm --onedir --name AngelesurBackend --distpath build/distribucion --workpath build/pyinstaller --specpath build --paths backend --collect-submodules uvicorn --collect-submodules pymysql backend/run_backend.py
Copy-Item backend/.env.distribucion build/distribucion/AngelesurBackend/.env
.\build\distribucion\AngelesurBackend\AngelesurBackend.exe --check
```

Distribuir toda la carpeta `AngelesurBackend`, incluida `_internal`, junto con
la carpeta `Release` de Flutter. El ejecutable lee `.env` junto a su propio
archivo, independientemente del directorio desde el que se abra. Ajustar las
credenciales de MariaDB en la PC de destino. `--check` comprueba la carga de
la aplicacion sin iniciar el servidor ni conectarse a la base de datos.

La guia de prueba en otra PC esta en `README_distribucion.txt`. El SQL de
instalacion se distribuye por separado y no se importa automaticamente.

## Respaldos desde la aplicacion

El menu Respaldos esta disponible para JEFE. `POST /respaldos/crear` y
`POST /respaldos/restaurar` requieren username, password y una ruta absoluta
de la PC local; restaurar requiere tambien `confirmar: true`. Cada operacion
verifica las credenciales contra MariaDB. No se almacena la contrasena.

Se necesitan `mariadb.exe` y `mariadb-dump.exe`, incluidos con MariaDB.
Se buscan en PATH y en Program Files/MariaDB*/bin. Para otra ubicacion, definir
`ANGELESUR_MARIADB_BIN` en el .env del backend. El usuario de base de datos
necesita permisos para exportar/importar datos, vistas, triggers, eventos y
rutinas, ademas de crear/eliminar la base al restaurar. Los SQL con DEFINER
requieren que existan sus cuentas de origen y permisos suficientes.

La aplicacion elige archivos SQL locales, no envia rutas a otro servidor.
Solo cargar respaldos propios y de confianza: contienen SQL ejecutable.
La copia previa se guarda en LocalAppData/Angelesur/Respaldos, configurable con
`ANGELESUR_BACKUP_DIR`. Una importacion fallida intenta restaurar esa copia.
Si tambien falla la recuperacion, la API bloquea las operaciones hasta que se
recupere manualmente la base y se reinicie la API. Conservar esa copia.

Ejecutar la API con un solo worker (configuracion predeterminada). El bloqueo
de mantenimiento cubre las solicitudes de esa API; cerrar otras instancias,
clientes SQL y herramientas externas durante la restauracion. Tras restaurar
correctamente se cierra la sesion de la app. No importar SQL incompletos ni
respaldos de versiones de esquema incompatibles.
