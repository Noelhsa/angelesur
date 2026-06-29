from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pymysql.err import MySQLError


def install_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(MySQLError)
    async def mysql_error_handler(_, exc: MySQLError):
        message = _extract_mysql_message(exc)
        return JSONResponse(status_code=400, content={"detail": message})


def _extract_mysql_message(exc: MySQLError) -> str:
    if len(exc.args) >= 2:
        return str(exc.args[1])
    if exc.args:
        return str(exc.args[0])
    return "Error de base de datos"
