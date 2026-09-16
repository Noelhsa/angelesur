ANGELESUR - PRUEBA EN OTRA PC WINDOWS X64

Copiar y extraer toda la carpeta del paquete. No mover solo los archivos .exe.

Contenido:
- Release/angelesur.exe: interfaz, con sus DLL y carpeta data.
- AngelesurBackend/AngelesurBackend.exe: API con Python incluido.
- AngelesurBackend/.env: configuracion local editable.
- base_inicial_limpia.sql: SQL proporcionado para esta prueba.

REQUISITOS EN LA OTRA PC
1. Instalar MariaDB y configurar el servicio para usar el puerto 3307.
2. Instalar Microsoft Visual C++ Redistributable x64 si no esta instalado.
   https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist
3. Importar base_inicial_limpia.sql usando HeidiSQL o el cliente MariaDB
   como administrador de la base (por ejemplo root).
   ATENCION: el SQL BORRA farmacia_angeles_v2 si ya existe. Solo importar
   en una instalacion nueva o despues de respaldar los datos que se necesiten.
   Contiene procedimientos con DEFINER root@localhost; esa cuenta debe existir.
4. Editar AngelesurBackend/.env con las credenciales reales de MariaDB.
   La configuracion de prueba usa root y 1234; deben coincidir con esa PC.
   Mantener ANGELESUR_API_PORT=8000 y ANGELESUR_DB_PORT=3307.

INICIO MANUAL
1. Verificar que el servicio MariaDB este encendido.
2. Abrir AngelesurBackend/AngelesurBackend.exe y mantener su consola abierta.
3. Abrir http://127.0.0.1:8000/health/db en el navegador.
   Debe responder status ok. /health solo comprueba la API, no la base.
4. Abrir Release/angelesur.exe.
5. Iniciar sesion: usuario admin, contrasena 1234, rol JEFE.

Si la API falla, revisar el mensaje de su consola, las credenciales, el puerto
de MariaDB y que no exista otra API ocupando el puerto 8000.
Para ver errores al arrancar, ejecutar el backend desde PowerShell:
  .\AngelesurBackend\AngelesurBackend.exe

No hace falta instalar Flutter ni Python en la otra PC.
Este paquete no instala MariaDB ni crea servicios o tareas automaticas.
La base se importa una sola vez, no cada vez que se abre el programa.
El SQL inicial no copia las ventas ni el inventario de la PC de desarrollo.

RESPALDOS
El rol JEFE tiene el menu Respaldos. Crear respaldo permite elegir un archivo
SQL nuevo. Cargar respaldo reemplaza los datos y requiere confirmacion y la
contrasena del jefe actual. Al terminar se cierra la sesion.
Antes de restaurar se guarda una copia en LocalAppData/Angelesur/Respaldos.
Cerrar otros clientes SQL e instancias de la app durante estas operaciones.
Solo seleccionar SQL propios y de confianza. El SQL contiene instrucciones
ejecutables. No hace falta volver a importar el SQL inicial para actualizar.
Si no se detectan mariadb.exe y mariadb-dump.exe, agregar al .env:
ANGELESUR_MARIADB_BIN=C:\Program Files\MariaDB 11.6\bin
Ajustar esa ruta a la version instalada. Ambos programas vienen con MariaDB.
