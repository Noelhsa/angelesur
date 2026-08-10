/*M!999999\- enable the sandbox mode */ 

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

/*!40000 DROP DATABASE IF EXISTS `farmacia_angeles_v2`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `farmacia_angeles_v2` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;

USE `farmacia_angeles_v2`;
DROP TABLE IF EXISTS `compra`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `compra` (
  `idCompra` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `folioProveedor` varchar(80) DEFAULT NULL,
  `idProveedor` bigint(20) unsigned DEFAULT NULL,
  `idUsuario` bigint(20) unsigned NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `subtotal` decimal(10,2) NOT NULL DEFAULT 0.00,
  `descuento` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total` decimal(10,2) NOT NULL DEFAULT 0.00,
  `estatus` enum('REGISTRADA','CANCELADA') NOT NULL DEFAULT 'REGISTRADA',
  `observaciones` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idCompra`),
  KEY `idx_compra_fecha` (`fecha`),
  KEY `idx_compra_proveedor` (`idProveedor`),
  KEY `fk_compra_usuario` (`idUsuario`),
  CONSTRAINT `fk_compra_proveedor` FOREIGN KEY (`idProveedor`) REFERENCES `proveedor` (`idProveedor`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compra_usuario` FOREIGN KEY (`idUsuario`) REFERENCES `usuario` (`idUsuario`) ON UPDATE CASCADE,
  CONSTRAINT `chk_compra_subtotal` CHECK (`subtotal` >= 0),
  CONSTRAINT `chk_compra_descuento` CHECK (`descuento` >= 0),
  CONSTRAINT `chk_compra_total` CHECK (`total` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `compra_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `compra_detalle` (
  `idCompraDetalle` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `idCompra` bigint(20) unsigned NOT NULL,
  `idProducto` bigint(20) unsigned NOT NULL,
  `idInventario` bigint(20) unsigned DEFAULT NULL,
  `cantidad` int(11) NOT NULL,
  `costoUnitario` decimal(10,2) NOT NULL,
  `precioVentaSugerido` decimal(10,2) DEFAULT NULL,
  `fechaCaducidad` date DEFAULT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  PRIMARY KEY (`idCompraDetalle`),
  KEY `idx_compra_detalle_compra` (`idCompra`),
  KEY `idx_compra_detalle_producto` (`idProducto`),
  KEY `fk_compra_detalle_inv` (`idInventario`),
  CONSTRAINT `fk_compra_detalle_compra` FOREIGN KEY (`idCompra`) REFERENCES `compra` (`idCompra`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_compra_detalle_inv` FOREIGN KEY (`idInventario`) REFERENCES `inventario_producto` (`idInventario`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_compra_detalle_producto` FOREIGN KEY (`idProducto`) REFERENCES `producto` (`idProducto`) ON UPDATE CASCADE,
  CONSTRAINT `chk_compra_detalle_cantidad` CHECK (`cantidad` > 0),
  CONSTRAINT `chk_compra_detalle_costo` CHECK (`costoUnitario` >= 0),
  CONSTRAINT `chk_compra_detalle_precio` CHECK (`precioVentaSugerido` is null or `precioVentaSugerido` >= 0),
  CONSTRAINT `chk_compra_detalle_subtotal` CHECK (`subtotal` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `corte_caja`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `corte_caja` (
  `idCorte` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `fechaApertura` datetime NOT NULL DEFAULT current_timestamp(),
  `fechaCierre` datetime DEFAULT NULL,
  `efectivoInicial` decimal(10,2) NOT NULL DEFAULT 0.00,
  `electronicoInicial` decimal(10,2) NOT NULL DEFAULT 0.00,
  `efectivoContado` decimal(10,2) DEFAULT NULL,
  `electronicoContado` decimal(10,2) DEFAULT NULL,
  `diferenciaEfectivo` decimal(10,2) DEFAULT NULL,
  `diferenciaElectronico` decimal(10,2) DEFAULT NULL,
  `usuarioAbre` bigint(20) unsigned NOT NULL,
  `usuarioCierra` bigint(20) unsigned DEFAULT NULL,
  `estado` enum('ABIERTO','CERRADO') NOT NULL DEFAULT 'ABIERTO',
  `observaciones` varchar(255) DEFAULT NULL,
  `corteAbiertoKey` tinyint(4) GENERATED ALWAYS AS (case when `estado` = 'ABIERTO' then 1 else NULL end) STORED,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`idCorte`),
  UNIQUE KEY `uk_un_solo_corte_abierto` (`corteAbiertoKey`),
  KEY `idx_corte_fechas` (`fechaApertura`,`fechaCierre`),
  KEY `idx_corte_estado` (`estado`),
  KEY `fk_corte_abre` (`usuarioAbre`),
  KEY `fk_corte_cierra` (`usuarioCierra`),
  CONSTRAINT `fk_corte_abre` FOREIGN KEY (`usuarioAbre`) REFERENCES `usuario` (`idUsuario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_corte_cierra` FOREIGN KEY (`usuarioCierra`) REFERENCES `usuario` (`idUsuario`) ON UPDATE CASCADE,
  CONSTRAINT `chk_corte_efectivo_inicial` CHECK (`efectivoInicial` >= 0),
  CONSTRAINT `chk_corte_electronico_inicial` CHECK (`electronicoInicial` >= 0),
  CONSTRAINT `chk_corte_efectivo_contado` CHECK (`efectivoContado` is null or `efectivoContado` >= 0),
  CONSTRAINT `chk_corte_electronico_contado` CHECK (`electronicoContado` is null or `electronicoContado` >= 0),
  CONSTRAINT `chk_corte_cierre_estado` CHECK (`estado` = 'ABIERTO' and `fechaCierre` is null or `estado` = 'CERRADO' and `fechaCierre` is not null)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `devolucion_cliente`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `devolucion_cliente` (
  `idDevolucionCliente` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `folio` varchar(40) DEFAULT NULL,
  `idVenta` bigint(20) unsigned NOT NULL,
  `idCorte` bigint(20) unsigned NOT NULL,
  `idUsuario` bigint(20) unsigned NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `motivo` enum('PRODUCTO_EQUIVOCADO','PRODUCTO_DANADO','CADUCADO','ERROR_VENTA','CLIENTE_SE_ARREPINTIO','OTRO') NOT NULL DEFAULT 'OTRO',
  `totalDevuelto` decimal(10,2) NOT NULL DEFAULT 0.00,
  `metodoDevolucion` enum('EFECTIVO','ELECTRONICO','CAMBIO_PRODUCTO','SIN_DEVOLUCION_DINERO') NOT NULL DEFAULT 'EFECTIVO',
  `estatus` enum('REGISTRADA','CANCELADA') NOT NULL DEFAULT 'REGISTRADA',
  `observaciones` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`idDevolucionCliente`),
  UNIQUE KEY `uk_dev_cliente_folio` (`folio`),
  KEY `idx_dev_cliente_venta` (`idVenta`),
  KEY `idx_dev_cliente_corte_fecha` (`idCorte`,`fecha`),
  KEY `idx_dev_cliente_usuario` (`idUsuario`),
  KEY `idx_dev_cliente_estatus` (`estatus`),
  CONSTRAINT `fk_dev_cliente_corte` FOREIGN KEY (`idCorte`) REFERENCES `corte_caja` (`idCorte`) ON UPDATE CASCADE,
  CONSTRAINT `fk_dev_cliente_usuario` FOREIGN KEY (`idUsuario`) REFERENCES `usuario` (`idUsuario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_dev_cliente_venta` FOREIGN KEY (`idVenta`) REFERENCES `venta` (`idVenta`) ON UPDATE CASCADE,
  CONSTRAINT `chk_dev_cliente_total` CHECK (`totalDevuelto` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `devolucion_cliente_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `devolucion_cliente_detalle` (
  `idDevolucionClienteDetalle` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `idDevolucionCliente` bigint(20) unsigned NOT NULL,
  `idVentaDetalle` bigint(20) unsigned NOT NULL,
  `idInventario` bigint(20) unsigned NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precioUnitarioDevuelto` decimal(10,2) NOT NULL,
  `subtotalDevuelto` decimal(10,2) NOT NULL,
  `regresaAInventario` tinyint(1) NOT NULL DEFAULT 1,
  `motivoDetalle` varchar(120) DEFAULT NULL,
  `observaciones` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idDevolucionClienteDetalle`),
  KEY `idx_dev_cliente_det_header` (`idDevolucionCliente`),
  KEY `idx_dev_cliente_det_vdet` (`idVentaDetalle`),
  KEY `idx_dev_cliente_det_inv` (`idInventario`),
  CONSTRAINT `fk_dev_cliente_det_header` FOREIGN KEY (`idDevolucionCliente`) REFERENCES `devolucion_cliente` (`idDevolucionCliente`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_dev_cliente_det_inv` FOREIGN KEY (`idInventario`) REFERENCES `inventario_producto` (`idInventario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_dev_cliente_det_vdet` FOREIGN KEY (`idVentaDetalle`) REFERENCES `venta_detalle` (`idVentaDetalle`) ON UPDATE CASCADE,
  CONSTRAINT `chk_dev_cliente_det_cantidad` CHECK (`cantidad` > 0),
  CONSTRAINT `chk_dev_cliente_det_precio` CHECK (`precioUnitarioDevuelto` >= 0),
  CONSTRAINT `chk_dev_cliente_det_subtotal` CHECK (`subtotalDevuelto` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `devolucion_proveedor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `devolucion_proveedor` (
  `idDevolucionProveedor` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `folio` varchar(40) DEFAULT NULL,
  `idCompra` bigint(20) unsigned DEFAULT NULL,
  `idProveedor` bigint(20) unsigned DEFAULT NULL,
  `idCorte` bigint(20) unsigned NOT NULL,
  `idUsuario` bigint(20) unsigned NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `motivo` enum('PRODUCTO_DANADO','CADUCADO','ERROR_COMPRA','EXCEDENTE','CAMBIO_PRECIO','OTRO') NOT NULL DEFAULT 'OTRO',
  `totalDevolucion` decimal(10,2) NOT NULL DEFAULT 0.00,
  `tipoCompensacion` enum('EFECTIVO','ELECTRONICO','NOTA_CREDITO','REPOSICION_PRODUCTO','SIN_COMPENSACION') NOT NULL DEFAULT 'SIN_COMPENSACION',
  `estatus` enum('REGISTRADA','CANCELADA') NOT NULL DEFAULT 'REGISTRADA',
  `observaciones` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`idDevolucionProveedor`),
  UNIQUE KEY `uk_dev_proveedor_folio` (`folio`),
  KEY `idx_dev_proveedor_compra` (`idCompra`),
  KEY `idx_dev_proveedor_proveedor` (`idProveedor`),
  KEY `idx_dev_proveedor_corte_fecha` (`idCorte`,`fecha`),
  KEY `idx_dev_proveedor_usuario` (`idUsuario`),
  KEY `idx_dev_proveedor_estatus` (`estatus`),
  CONSTRAINT `fk_dev_proveedor_compra` FOREIGN KEY (`idCompra`) REFERENCES `compra` (`idCompra`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_dev_proveedor_corte` FOREIGN KEY (`idCorte`) REFERENCES `corte_caja` (`idCorte`) ON UPDATE CASCADE,
  CONSTRAINT `fk_dev_proveedor_proveedor` FOREIGN KEY (`idProveedor`) REFERENCES `proveedor` (`idProveedor`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_dev_proveedor_usuario` FOREIGN KEY (`idUsuario`) REFERENCES `usuario` (`idUsuario`) ON UPDATE CASCADE,
  CONSTRAINT `chk_dev_proveedor_total` CHECK (`totalDevolucion` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `devolucion_proveedor_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `devolucion_proveedor_detalle` (
  `idDevolucionProveedorDetalle` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `idDevolucionProveedor` bigint(20) unsigned NOT NULL,
  `idCompraDetalle` bigint(20) unsigned DEFAULT NULL,
  `idInventario` bigint(20) unsigned NOT NULL,
  `cantidad` int(11) NOT NULL,
  `costoUnitario` decimal(10,2) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  `motivoDetalle` varchar(120) DEFAULT NULL,
  `observaciones` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idDevolucionProveedorDetalle`),
  KEY `idx_dev_prov_det_header` (`idDevolucionProveedor`),
  KEY `idx_dev_prov_det_cdet` (`idCompraDetalle`),
  KEY `idx_dev_prov_det_inv` (`idInventario`),
  CONSTRAINT `fk_dev_prov_det_cdet` FOREIGN KEY (`idCompraDetalle`) REFERENCES `compra_detalle` (`idCompraDetalle`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_dev_prov_det_header` FOREIGN KEY (`idDevolucionProveedor`) REFERENCES `devolucion_proveedor` (`idDevolucionProveedor`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_dev_prov_det_inv` FOREIGN KEY (`idInventario`) REFERENCES `inventario_producto` (`idInventario`) ON UPDATE CASCADE,
  CONSTRAINT `chk_dev_prov_det_cantidad` CHECK (`cantidad` > 0),
  CONSTRAINT `chk_dev_prov_det_costo` CHECK (`costoUnitario` >= 0),
  CONSTRAINT `chk_dev_prov_det_subtotal` CHECK (`subtotal` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `historial_precio_producto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `historial_precio_producto` (
  `idHistorialPrecio` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `idProducto` bigint(20) unsigned NOT NULL,
  `idInventario` bigint(20) unsigned DEFAULT NULL,
  `precioAnterior` decimal(10,2) DEFAULT NULL,
  `precioNuevo` decimal(10,2) NOT NULL,
  `motivo` varchar(255) DEFAULT NULL,
  `idUsuario` bigint(20) unsigned NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`idHistorialPrecio`),
  KEY `idx_hist_precio_producto_fecha` (`idProducto`,`fecha`),
  KEY `fk_hist_precio_inv` (`idInventario`),
  KEY `fk_hist_precio_usuario` (`idUsuario`),
  CONSTRAINT `fk_hist_precio_inv` FOREIGN KEY (`idInventario`) REFERENCES `inventario_producto` (`idInventario`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_hist_precio_producto` FOREIGN KEY (`idProducto`) REFERENCES `producto` (`idProducto`) ON UPDATE CASCADE,
  CONSTRAINT `fk_hist_precio_usuario` FOREIGN KEY (`idUsuario`) REFERENCES `usuario` (`idUsuario`) ON UPDATE CASCADE,
  CONSTRAINT `chk_hist_precio_nuevo` CHECK (`precioNuevo` >= 0),
  CONSTRAINT `chk_hist_precio_anterior` CHECK (`precioAnterior` is null or `precioAnterior` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `info_medicamento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `info_medicamento` (
  `idInfo` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `idProducto` bigint(20) unsigned NOT NULL,
  `presentacion` varchar(80) DEFAULT NULL,
  `viaAdministracion` enum('CAPSULA','TABLETA','PASTILLA','SUSPENSION','GOTAS','INYECCION','JARABE','CREMA','POMADA','AEROSOL','SOLUCION','OTRO') DEFAULT NULL,
  `edad` enum('PEDIATRICO','INFANTIL','ADULTO','GENERAL') DEFAULT 'GENERAL',
  `requiereReceta` tinyint(1) NOT NULL DEFAULT 0,
  `sustanciaActiva` varchar(150) DEFAULT NULL,
  `dosis` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`idInfo`),
  UNIQUE KEY `uk_info_idProducto` (`idProducto`),
  CONSTRAINT `fk_info_producto` FOREIGN KEY (`idProducto`) REFERENCES `producto` (`idProducto`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inventario_producto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inventario_producto` (
  `idInventario` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `idProducto` bigint(20) unsigned NOT NULL,
  `codigoLote` varchar(80) NOT NULL DEFAULT 'SIN_LOTE',
  `fechaLlegada` datetime NOT NULL DEFAULT current_timestamp(),
  `fechaCaducidad` date DEFAULT NULL,
  `fechaCaducidadKey` date GENERATED ALWAYS AS (ifnull(`fechaCaducidad`,cast('9999-12-31' as date))) STORED,
  `stockInicial` bigint(20) NOT NULL DEFAULT 0,
  `stockActual` bigint(20) NOT NULL DEFAULT 0,
  `costoUnitario` decimal(10,2) NOT NULL DEFAULT 0.00,
  `precioVenta` decimal(10,2) NOT NULL DEFAULT 0.00,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `observaciones` varchar(255) DEFAULT NULL,
  `ubicacionLetra` char(1) DEFAULT NULL,
  `ubicacionNumero` smallint(5) unsigned DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`idInventario`),
  UNIQUE KEY `uk_inventario_lote_precio_costo` (`idProducto`,`codigoLote`,`fechaCaducidadKey`,`costoUnitario`,`precioVenta`),
  KEY `idx_inv_producto_stock` (`idProducto`,`stockActual`),
  KEY `idx_inv_caducidad` (`fechaCaducidad`),
  KEY `idx_inv_precio` (`precioVenta`),
  KEY `idx_inv_ubicacion` (`ubicacionLetra`,`ubicacionNumero`),
  CONSTRAINT `fk_inv_producto` FOREIGN KEY (`idProducto`) REFERENCES `producto` (`idProducto`) ON UPDATE CASCADE,
  CONSTRAINT `chk_inv_stock_inicial` CHECK (`stockInicial` >= 0),
  CONSTRAINT `chk_inv_stock_actual` CHECK (`stockActual` >= 0),
  CONSTRAINT `chk_inv_costo` CHECK (`costoUnitario` >= 0),
  CONSTRAINT `chk_inv_precio` CHECK (`precioVenta` >= 0),
  CONSTRAINT `chk_inv_codigo_lote` CHECK (`codigoLote` <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_inventario_producto_bi_validar_stock_caducidad`
BEFORE INSERT ON `inventario_producto`
FOR EACH ROW
BEGIN
  DECLARE v_tipo_producto VARCHAR(20);
  DECLARE v_maneja_caducidad TINYINT(1) DEFAULT 0;

  SELECT MAX(CAST(`tipo` AS CHAR)), COALESCE(MAX(`manejaCaducidad`), 0)
    INTO v_tipo_producto, v_maneja_caducidad
  FROM `producto`
  WHERE `idProducto` = NEW.`idProducto`;

  IF v_tipo_producto IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No existe el producto indicado para inventario.';
  END IF;

  IF NEW.`codigoLote` IS NULL OR TRIM(NEW.`codigoLote`) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El codigo de lote no puede estar vacio.';
  END IF;

  IF NEW.`stockInicial` IS NULL OR NEW.`stockInicial` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El stock inicial no puede ser negativo.';
  END IF;

  IF NEW.`stockActual` IS NULL OR NEW.`stockActual` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El stock actual no puede ser negativo.';
  END IF;

  IF NEW.`costoUnitario` IS NULL OR NEW.`costoUnitario` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El costo unitario no puede ser negativo.';
  END IF;

  IF NEW.`precioVenta` IS NULL OR NEW.`precioVenta` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El precio de venta no puede ser negativo.';
  END IF;

  IF (v_tipo_producto = 'MEDICAMENTO' OR v_maneja_caducidad = 1) AND NEW.`fechaCaducidad` IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El medicamento o producto con caducidad requiere fecha de caducidad.';
  END IF;

  IF NEW.`fechaCaducidad` IS NOT NULL
     AND NEW.`fechaCaducidad` < CURDATE()
     AND (NEW.`stockInicial` > 0 OR NEW.`stockActual` > 0) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede registrar inventario con caducidad vencida.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_inventario_producto_bu_validar_stock_caducidad`
BEFORE UPDATE ON `inventario_producto`
FOR EACH ROW
BEGIN
  DECLARE v_tipo_producto VARCHAR(20);
  DECLARE v_maneja_caducidad TINYINT(1) DEFAULT 0;

  SELECT MAX(CAST(`tipo` AS CHAR)), COALESCE(MAX(`manejaCaducidad`), 0)
    INTO v_tipo_producto, v_maneja_caducidad
  FROM `producto`
  WHERE `idProducto` = NEW.`idProducto`;

  IF v_tipo_producto IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No existe el producto indicado para inventario.';
  END IF;

  IF NEW.`codigoLote` IS NULL OR TRIM(NEW.`codigoLote`) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El codigo de lote no puede estar vacio.';
  END IF;

  IF NEW.`stockInicial` IS NULL OR NEW.`stockInicial` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El stock inicial no puede ser negativo.';
  END IF;

  IF NEW.`stockActual` IS NULL OR NEW.`stockActual` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El stock actual no puede ser negativo.';
  END IF;

  IF NEW.`costoUnitario` IS NULL OR NEW.`costoUnitario` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El costo unitario no puede ser negativo.';
  END IF;

  IF NEW.`precioVenta` IS NULL OR NEW.`precioVenta` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El precio de venta no puede ser negativo.';
  END IF;

  IF (v_tipo_producto = 'MEDICAMENTO' OR v_maneja_caducidad = 1) AND NEW.`fechaCaducidad` IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El medicamento o producto con caducidad requiere fecha de caducidad.';
  END IF;

  -- Permite dejar stock en 0 o desactivar un lote ya vencido, pero no permite
  -- conservar o aumentar stock vendible con caducidad vencida.
  IF NEW.`fechaCaducidad` IS NOT NULL
     AND NEW.`fechaCaducidad` < CURDATE()
     AND NEW.`stockActual` > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede mantener stock activo con caducidad vencida.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `movimiento_dinero`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `movimiento_dinero` (
  `idMovDin` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `idCorte` bigint(20) unsigned NOT NULL,
  `idUsuario` bigint(20) unsigned NOT NULL,
  `medio` enum('EFECTIVO','ELECTRONICO') NOT NULL,
  `tipo` enum('ENTRADA','SALIDA') NOT NULL,
  `concepto` enum('VENTA_PRODUCTO','SERVICIO_YASTAS','COMPRA_MERCANCIA','DEPOSITO_YASTAS','RETIRO_CAJA','AJUSTE','CANCELACION','APERTURA','DEVOLUCION_CLIENTE','DEVOLUCION_PROVEEDOR','OTRO') NOT NULL,
  `monto` decimal(10,2) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `idVenta` bigint(20) unsigned DEFAULT NULL,
  `idPagoVenta` bigint(20) unsigned DEFAULT NULL,
  `idServicioOperacion` bigint(20) unsigned DEFAULT NULL,
  `idCompra` bigint(20) unsigned DEFAULT NULL,
  `idDevolucionCliente` bigint(20) unsigned DEFAULT NULL,
  `idDevolucionProveedor` bigint(20) unsigned DEFAULT NULL,
  `observaciones` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idMovDin`),
  KEY `idx_movdin_corte_medio_tipo` (`idCorte`,`medio`,`tipo`),
  KEY `idx_movdin_fecha` (`fecha`),
  KEY `idx_movdin_concepto_fecha` (`concepto`,`fecha`),
  KEY `fk_movdin_usuario` (`idUsuario`),
  KEY `fk_movdin_venta` (`idVenta`),
  KEY `fk_movdin_pago_venta` (`idPagoVenta`),
  KEY `fk_movdin_serv` (`idServicioOperacion`),
  KEY `fk_movdin_compra` (`idCompra`),
  KEY `fk_movdin_dev_cliente` (`idDevolucionCliente`),
  KEY `fk_movdin_dev_proveedor` (`idDevolucionProveedor`),
  CONSTRAINT `fk_movdin_compra` FOREIGN KEY (`idCompra`) REFERENCES `compra` (`idCompra`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_movdin_corte` FOREIGN KEY (`idCorte`) REFERENCES `corte_caja` (`idCorte`) ON UPDATE CASCADE,
  CONSTRAINT `fk_movdin_dev_cliente` FOREIGN KEY (`idDevolucionCliente`) REFERENCES `devolucion_cliente` (`idDevolucionCliente`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_movdin_dev_proveedor` FOREIGN KEY (`idDevolucionProveedor`) REFERENCES `devolucion_proveedor` (`idDevolucionProveedor`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_movdin_pago_venta` FOREIGN KEY (`idPagoVenta`) REFERENCES `pago_venta` (`idPagoVenta`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_movdin_serv` FOREIGN KEY (`idServicioOperacion`) REFERENCES `servicio_operacion` (`idServicioOperacion`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_movdin_usuario` FOREIGN KEY (`idUsuario`) REFERENCES `usuario` (`idUsuario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_movdin_venta` FOREIGN KEY (`idVenta`) REFERENCES `venta` (`idVenta`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_movdin_monto` CHECK (`monto` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_movimiento_dinero_bi_validar_corte_y_saldo`
BEFORE INSERT ON `movimiento_dinero`
FOR EACH ROW
BEGIN
  DECLARE v_estado VARCHAR(20);
  DECLARE v_saldo_electronico DECIMAL(12,2) DEFAULT 0.00;

  SELECT MAX(CAST(`estado` AS CHAR))
    INTO v_estado
  FROM `corte_caja`
  WHERE `idCorte` = NEW.`idCorte`;

  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No existe el corte indicado para el movimiento.';
  END IF;

  IF v_estado <> 'ABIERTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede registrar movimiento en un corte cerrado.';
  END IF;

  IF NEW.`medio` = 'ELECTRONICO' AND NEW.`tipo` = 'SALIDA' THEN
    SELECT
      c.`electronicoInicial` + COALESCE(SUM(
        CASE
          WHEN m.`medio` = 'ELECTRONICO' AND m.`tipo` = 'ENTRADA' THEN m.`monto`
          WHEN m.`medio` = 'ELECTRONICO' AND m.`tipo` = 'SALIDA' THEN -m.`monto`
          ELSE 0.00
        END
      ), 0.00)
      INTO v_saldo_electronico
    FROM `corte_caja` c
    LEFT JOIN `movimiento_dinero` m ON m.`idCorte` = c.`idCorte`
    WHERE c.`idCorte` = NEW.`idCorte`
    GROUP BY c.`idCorte`, c.`electronicoInicial`;

    IF v_saldo_electronico < NEW.`monto` THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo electronico insuficiente para registrar la salida.';
    END IF;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `movimiento_inventario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `movimiento_inventario` (
  `idMovInv` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `idUsuario` bigint(20) unsigned NOT NULL,
  `idInventario` bigint(20) unsigned NOT NULL,
  `tipo` enum('ENTRADA','SALIDA','AJUSTE') NOT NULL,
  `motivo` enum('COMPRA','VENTA','CANCELACION','AJUSTE','MERMA','CADUCIDAD','INICIAL','DEVOLUCION_CLIENTE','DEVOLUCION_PROVEEDOR','OTRO') NOT NULL,
  `cantidad` int(11) NOT NULL,
  `stockAntes` bigint(20) NOT NULL,
  `stockDespues` bigint(20) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `idVentaDetalle` bigint(20) unsigned DEFAULT NULL,
  `idCompraDetalle` bigint(20) unsigned DEFAULT NULL,
  `idDevolucionClienteDetalle` bigint(20) unsigned DEFAULT NULL,
  `idDevolucionProveedorDetalle` bigint(20) unsigned DEFAULT NULL,
  `observaciones` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idMovInv`),
  KEY `idx_movinv_inv_fecha` (`idInventario`,`fecha`),
  KEY `idx_movinv_tipo_fecha` (`tipo`,`fecha`),
  KEY `idx_movinv_motivo_fecha` (`motivo`,`fecha`),
  KEY `fk_movinv_usuario` (`idUsuario`),
  KEY `fk_movinv_vdet` (`idVentaDetalle`),
  KEY `fk_movinv_cdet` (`idCompraDetalle`),
  KEY `fk_movinv_dev_cliente_det` (`idDevolucionClienteDetalle`),
  KEY `fk_movinv_dev_proveedor_det` (`idDevolucionProveedorDetalle`),
  CONSTRAINT `fk_movinv_cdet` FOREIGN KEY (`idCompraDetalle`) REFERENCES `compra_detalle` (`idCompraDetalle`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_movinv_dev_cliente_det` FOREIGN KEY (`idDevolucionClienteDetalle`) REFERENCES `devolucion_cliente_detalle` (`idDevolucionClienteDetalle`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_movinv_dev_proveedor_det` FOREIGN KEY (`idDevolucionProveedorDetalle`) REFERENCES `devolucion_proveedor_detalle` (`idDevolucionProveedorDetalle`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_movinv_inventario` FOREIGN KEY (`idInventario`) REFERENCES `inventario_producto` (`idInventario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_movinv_usuario` FOREIGN KEY (`idUsuario`) REFERENCES `usuario` (`idUsuario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_movinv_vdet` FOREIGN KEY (`idVentaDetalle`) REFERENCES `venta_detalle` (`idVentaDetalle`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_movinv_cantidad` CHECK (`cantidad` > 0),
  CONSTRAINT `chk_movinv_stock_antes` CHECK (`stockAntes` >= 0),
  CONSTRAINT `chk_movinv_stock_despues` CHECK (`stockDespues` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `pago_venta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pago_venta` (
  `idPagoVenta` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `idVenta` bigint(20) unsigned NOT NULL,
  `medio` enum('EFECTIVO','ELECTRONICO','TARJETA','TRANSFERENCIA','OTRO') NOT NULL,
  `monto` decimal(10,2) NOT NULL,
  `referencia` varchar(100) DEFAULT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`idPagoVenta`),
  KEY `idx_pago_venta_venta` (`idVenta`),
  KEY `idx_pago_venta_medio_fecha` (`medio`,`fecha`),
  CONSTRAINT `fk_pago_venta` FOREIGN KEY (`idVenta`) REFERENCES `venta` (`idVenta`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_pago_venta_monto` CHECK (`monto` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_pago_venta_bi_validar_corte_abierto`
BEFORE INSERT ON `pago_venta`
FOR EACH ROW
BEGIN
  DECLARE v_estado VARCHAR(20);

  SELECT MAX(CAST(c.`estado` AS CHAR))
    INTO v_estado
  FROM `venta` v
  INNER JOIN `corte_caja` c ON c.`idCorte` = v.`idCorte`
  WHERE v.`idVenta` = NEW.`idVenta`;

  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No existe la venta indicada para el pago.';
  END IF;

  IF v_estado <> 'ABIERTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede registrar pago en un corte cerrado.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `producto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `producto` (
  `idProducto` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `codigoBarras` varchar(64) DEFAULT NULL,
  `nombre` varchar(200) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `tipo` enum('MEDICAMENTO','PRODUCTO') NOT NULL,
  `categoria` varchar(80) DEFAULT NULL,
  `manejaCaducidad` tinyint(1) NOT NULL DEFAULT 0,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`idProducto`),
  UNIQUE KEY `uk_producto_codigoBarras` (`codigoBarras`),
  KEY `idx_producto_nombre` (`nombre`),
  KEY `idx_producto_tipo_activo` (`tipo`,`activo`),
  KEY `idx_producto_categoria` (`categoria`),
  CONSTRAINT `chk_producto_nombre` CHECK (`nombre` <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `proveedor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `proveedor` (
  `idProveedor` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(150) NOT NULL,
  `telefono` varchar(30) DEFAULT NULL,
  `contacto` varchar(120) DEFAULT NULL,
  `direccion` varchar(255) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`idProveedor`),
  UNIQUE KEY `uk_proveedor_nombre` (`nombre`),
  CONSTRAINT `chk_proveedor_nombre` CHECK (`nombre` <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `servicio_operacion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `servicio_operacion` (
  `idServicioOperacion` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `idUsuario` bigint(20) unsigned NOT NULL,
  `idCorte` bigint(20) unsigned NOT NULL,
  `idTarifa` bigint(20) unsigned DEFAULT NULL,
  `tipoServicio` enum('RECARGA','DEPOSITO','RETIRO','PAGO_SERVICIO','CFE','TELMEX','IZZI','INTERNET','OTRO') NOT NULL,
  `nombreServicio` varchar(120) NOT NULL,
  `referenciaOperacion` varchar(120) DEFAULT NULL,
  `montoServicio` decimal(10,2) NOT NULL,
  `comisionCliente` decimal(10,2) NOT NULL DEFAULT 0.00,
  `comisionYastas` decimal(10,2) NOT NULL DEFAULT 0.00,
  `regaliaYastas` decimal(10,2) NOT NULL DEFAULT 0.00,
  `gananciaFarmacia` decimal(10,2) NOT NULL DEFAULT 0.00,
  `totalCobradoCliente` decimal(10,2) NOT NULL,
  `estatus` enum('REALIZADA','CANCELADA','FALLIDA') NOT NULL DEFAULT 'REALIZADA',
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `observaciones` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`idServicioOperacion`),
  KEY `idx_serv_corte_fecha` (`idCorte`,`fecha`),
  KEY `idx_serv_tipo_fecha` (`tipoServicio`,`fecha`),
  KEY `fk_serv_usuario` (`idUsuario`),
  KEY `fk_serv_tarifa` (`idTarifa`),
  CONSTRAINT `fk_serv_corte` FOREIGN KEY (`idCorte`) REFERENCES `corte_caja` (`idCorte`) ON UPDATE CASCADE,
  CONSTRAINT `fk_serv_tarifa` FOREIGN KEY (`idTarifa`) REFERENCES `tarifa_servicio` (`idTarifa`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_serv_usuario` FOREIGN KEY (`idUsuario`) REFERENCES `usuario` (`idUsuario`) ON UPDATE CASCADE,
  CONSTRAINT `chk_serv_monto` CHECK (`montoServicio` >= 0),
  CONSTRAINT `chk_serv_comision_cliente` CHECK (`comisionCliente` >= 0),
  CONSTRAINT `chk_serv_comision_yastas` CHECK (`comisionYastas` >= 0),
  CONSTRAINT `chk_serv_regalia` CHECK (`regaliaYastas` >= 0),
  CONSTRAINT `chk_serv_ganancia` CHECK (`gananciaFarmacia` >= 0),
  CONSTRAINT `chk_serv_total_cliente` CHECK (`totalCobradoCliente` >= 0),
  CONSTRAINT `chk_serv_nombre` CHECK (`nombreServicio` <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_servicio_operacion_bi_validar_corte_abierto`
BEFORE INSERT ON `servicio_operacion`
FOR EACH ROW
BEGIN
  DECLARE v_estado VARCHAR(20);

  SELECT MAX(CAST(`estado` AS CHAR))
    INTO v_estado
  FROM `corte_caja`
  WHERE `idCorte` = NEW.`idCorte`;

  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No existe el corte indicado para el servicio.';
  END IF;

  IF v_estado <> 'ABIERTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede registrar servicio en un corte cerrado.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `tarifa_servicio`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tarifa_servicio` (
  `idTarifa` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tipoServicio` enum('RECARGA','DEPOSITO','RETIRO','PAGO_SERVICIO','CFE','TELMEX','IZZI','INTERNET','OTRO') NOT NULL,
  `nombreServicio` varchar(120) NOT NULL,
  `montoBase` decimal(10,2) NOT NULL DEFAULT 0.00,
  `comisionCliente` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Cargo al cliente',
  `comisionYastas` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Costo cobrado por yastas',
  `regaliaYastas` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Dinero que yastas otorga',
  `gananciaFarmacia` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Ganancia esperada',
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`idTarifa`),
  UNIQUE KEY `uk_tarifa_servicio` (`tipoServicio`,`nombreServicio`,`montoBase`),
  KEY `idx_tarifa_tipo_activo` (`tipoServicio`,`activo`),
  CONSTRAINT `chk_tarifa_monto_base` CHECK (`montoBase` >= 0),
  CONSTRAINT `chk_tarifa_comision_cliente` CHECK (`comisionCliente` >= 0),
  CONSTRAINT `chk_tarifa_comision_yastas` CHECK (`comisionYastas` >= 0),
  CONSTRAINT `chk_tarifa_regalia` CHECK (`regaliaYastas` >= 0),
  CONSTRAINT `chk_tarifa_ganancia` CHECK (`gananciaFarmacia` >= 0),
  CONSTRAINT `chk_tarifa_nombre` CHECK (`nombreServicio` <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `usuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usuario` (
  `idUsuario` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(120) NOT NULL,
  `username` varchar(60) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `password_hash` varchar(255) NOT NULL,
  `rol` enum('JEFE','EMPLEADO') NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`idUsuario`),
  UNIQUE KEY `uk_usuario_username` (`username`),
  KEY `idx_usuario_rol_activo` (`rol`,`activo`),
  CONSTRAINT `chk_usuario_nombre` CHECK (`nombre` <> ''),
  CONSTRAINT `chk_usuario_username` CHECK (`username` <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `venta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `venta` (
  `idVenta` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `folio` varchar(40) DEFAULT NULL,
  `idUsuario` bigint(20) unsigned NOT NULL,
  `idCorte` bigint(20) unsigned NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `subtotal` decimal(10,2) NOT NULL DEFAULT 0.00,
  `descuento` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total` decimal(10,2) NOT NULL DEFAULT 0.00,
  `montoRecibido` decimal(10,2) DEFAULT NULL,
  `cambio` decimal(10,2) DEFAULT NULL,
  `estatus` enum('PAGADA','CANCELADA') NOT NULL DEFAULT 'PAGADA',
  `observaciones` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`idVenta`),
  UNIQUE KEY `uk_venta_folio` (`folio`),
  KEY `idx_venta_corte_fecha` (`idCorte`,`fecha`),
  KEY `idx_venta_fecha` (`fecha`),
  KEY `idx_venta_estatus` (`estatus`),
  KEY `fk_venta_usuario` (`idUsuario`),
  CONSTRAINT `fk_venta_corte` FOREIGN KEY (`idCorte`) REFERENCES `corte_caja` (`idCorte`) ON UPDATE CASCADE,
  CONSTRAINT `fk_venta_usuario` FOREIGN KEY (`idUsuario`) REFERENCES `usuario` (`idUsuario`) ON UPDATE CASCADE,
  CONSTRAINT `chk_venta_subtotal` CHECK (`subtotal` >= 0),
  CONSTRAINT `chk_venta_descuento` CHECK (`descuento` >= 0),
  CONSTRAINT `chk_venta_total` CHECK (`total` >= 0),
  CONSTRAINT `chk_venta_monto_recibido` CHECK (`montoRecibido` is null or `montoRecibido` >= 0),
  CONSTRAINT `chk_venta_cambio` CHECK (`cambio` is null or `cambio` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_venta_bi_validar_corte_abierto`
BEFORE INSERT ON `venta`
FOR EACH ROW
BEGIN
  DECLARE v_estado VARCHAR(20);

  SELECT MAX(CAST(`estado` AS CHAR))
    INTO v_estado
  FROM `corte_caja`
  WHERE `idCorte` = NEW.`idCorte`;

  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No existe el corte indicado para la venta.';
  END IF;

  IF v_estado <> 'ABIERTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede registrar venta en un corte cerrado.';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `venta_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `venta_detalle` (
  `idVentaDetalle` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `idVenta` bigint(20) unsigned NOT NULL,
  `idInventario` bigint(20) unsigned NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precioUnitario` decimal(10,2) NOT NULL,
  `costoUnitario` decimal(10,2) NOT NULL,
  `descuento` decimal(10,2) NOT NULL DEFAULT 0.00,
  `subtotal` decimal(10,2) NOT NULL,
  PRIMARY KEY (`idVentaDetalle`),
  KEY `idx_vdet_venta` (`idVenta`),
  KEY `idx_vdet_inventario` (`idInventario`),
  CONSTRAINT `fk_vdet_inventario` FOREIGN KEY (`idInventario`) REFERENCES `inventario_producto` (`idInventario`) ON UPDATE CASCADE,
  CONSTRAINT `fk_vdet_venta` FOREIGN KEY (`idVenta`) REFERENCES `venta` (`idVenta`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_vdet_cantidad` CHECK (`cantidad` > 0),
  CONSTRAINT `chk_vdet_precio` CHECK (`precioUnitario` >= 0),
  CONSTRAINT `chk_vdet_costo` CHECK (`costoUnitario` >= 0),
  CONSTRAINT `chk_vdet_descuento` CHECK (`descuento` >= 0),
  CONSTRAINT `chk_vdet_subtotal` CHECK (`subtotal` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_venta_detalle_bi_calcular_subtotal`
BEFORE INSERT ON `venta_detalle`
FOR EACH ROW
BEGIN
  DECLARE v_importe DECIMAL(12,2);

  IF NEW.`cantidad` IS NULL OR NEW.`cantidad` <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad de venta debe ser mayor que cero.';
  END IF;

  IF NEW.`precioUnitario` IS NULL OR NEW.`precioUnitario` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El precio unitario no puede ser negativo.';
  END IF;

  IF NEW.`costoUnitario` IS NULL OR NEW.`costoUnitario` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El costo unitario no puede ser negativo.';
  END IF;

  IF NEW.`descuento` IS NULL THEN
    SET NEW.`descuento` = 0.00;
  END IF;

  IF NEW.`descuento` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El descuento de venta no puede ser negativo.';
  END IF;

  SET v_importe = ROUND(NEW.`cantidad` * NEW.`precioUnitario`, 2);

  IF NEW.`descuento` > v_importe THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El descuento no puede ser mayor al importe del detalle.';
  END IF;

  SET NEW.`subtotal` = ROUND(v_importe - NEW.`descuento`, 2);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_venta_detalle_bu_calcular_subtotal`
BEFORE UPDATE ON `venta_detalle`
FOR EACH ROW
BEGIN
  DECLARE v_importe DECIMAL(12,2);

  IF NEW.`cantidad` IS NULL OR NEW.`cantidad` <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad de venta debe ser mayor que cero.';
  END IF;

  IF NEW.`precioUnitario` IS NULL OR NEW.`precioUnitario` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El precio unitario no puede ser negativo.';
  END IF;

  IF NEW.`costoUnitario` IS NULL OR NEW.`costoUnitario` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El costo unitario no puede ser negativo.';
  END IF;

  IF NEW.`descuento` IS NULL THEN
    SET NEW.`descuento` = 0.00;
  END IF;

  IF NEW.`descuento` < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El descuento de venta no puede ser negativo.';
  END IF;

  SET v_importe = ROUND(NEW.`cantidad` * NEW.`precioUnitario`, 2);

  IF NEW.`descuento` > v_importe THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El descuento no puede ser mayor al importe del detalle.';
  END IF;

  SET NEW.`subtotal` = ROUND(v_importe - NEW.`descuento`, 2);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
DROP TABLE IF EXISTS `vw_corte_resumen`;
/*!50001 DROP VIEW IF EXISTS `vw_corte_resumen`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `vw_corte_resumen` AS SELECT
 1 AS `idCorte`,
  1 AS `fechaApertura`,
  1 AS `fechaCierre`,
  1 AS `estado`,
  1 AS `efectivoInicial`,
  1 AS `electronicoInicial`,
  1 AS `efectivoContado`,
  1 AS `electronicoContado`,
  1 AS `usuarioAbre`,
  1 AS `usuarioCierra`,
  1 AS `efectivoSistema`,
  1 AS `electronicoSistema`,
  1 AS `diferenciaEfectivoCalculada`,
  1 AS `diferenciaElectronicoCalculada` */;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `vw_inventario_actual`;
/*!50001 DROP VIEW IF EXISTS `vw_inventario_actual`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `vw_inventario_actual` AS SELECT
 1 AS `idProducto`,
  1 AS `codigoBarras`,
  1 AS `nombre`,
  1 AS `tipo`,
  1 AS `categoria`,
  1 AS `manejaCaducidad`,
  1 AS `idInventario`,
  1 AS `codigoLote`,
  1 AS `fechaLlegada`,
  1 AS `fechaCaducidad`,
  1 AS `stockInicial`,
  1 AS `stockActual`,
  1 AS `costoUnitario`,
  1 AS `precioVenta`,
  1 AS `ubicacionLetra`,
  1 AS `ubicacionNumero`,
  1 AS `ubicacionEstante`,
  1 AS `utilidadUnitariaEstimada`,
  1 AS `inventarioActivo`,
  1 AS `productoActivo` */;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `vw_inventario_disponible_para_venta`;
/*!50001 DROP VIEW IF EXISTS `vw_inventario_disponible_para_venta`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `vw_inventario_disponible_para_venta` AS SELECT
 1 AS `idProducto`,
  1 AS `codigoBarras`,
  1 AS `nombre`,
  1 AS `tipo`,
  1 AS `categoria`,
  1 AS `manejaCaducidad`,
  1 AS `idInventario`,
  1 AS `codigoLote`,
  1 AS `fechaLlegada`,
  1 AS `fechaCaducidad`,
  1 AS `stockInicial`,
  1 AS `stockActual`,
  1 AS `costoUnitario`,
  1 AS `precioVenta`,
  1 AS `ubicacionLetra`,
  1 AS `ubicacionNumero`,
  1 AS `ubicacionEstante`,
  1 AS `utilidadUnitariaEstimada`,
  1 AS `inventarioActivo`,
  1 AS `productoActivo` */;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `vw_productos_por_caducar`;
/*!50001 DROP VIEW IF EXISTS `vw_productos_por_caducar`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `vw_productos_por_caducar` AS SELECT
 1 AS `idProducto`,
  1 AS `codigoBarras`,
  1 AS `nombre`,
  1 AS `tipo`,
  1 AS `categoria`,
  1 AS `manejaCaducidad`,
  1 AS `idInventario`,
  1 AS `codigoLote`,
  1 AS `fechaLlegada`,
  1 AS `fechaCaducidad`,
  1 AS `stockInicial`,
  1 AS `stockActual`,
  1 AS `costoUnitario`,
  1 AS `precioVenta`,
  1 AS `ubicacionLetra`,
  1 AS `ubicacionNumero`,
  1 AS `ubicacionEstante`,
  1 AS `utilidadUnitariaEstimada`,
  1 AS `inventarioActivo`,
  1 AS `productoActivo` */;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `vw_utilidad_ventas`;
/*!50001 DROP VIEW IF EXISTS `vw_utilidad_ventas`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `vw_utilidad_ventas` AS SELECT
 1 AS `idVenta`,
  1 AS `folio`,
  1 AS `fecha`,
  1 AS `idCorte`,
  1 AS `idUsuario`,
  1 AS `estatus`,
  1 AS `subtotalProductos`,
  1 AS `costoProductos`,
  1 AS `utilidadProductos` */;
SET character_set_client = @saved_cs_client;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_obtener_corte_abierto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_obtener_corte_abierto`() RETURNS bigint(20) unsigned
    READS SQL DATA
BEGIN
  DECLARE v_idCorte BIGINT UNSIGNED;

  SELECT MAX(`idCorte`)
    INTO v_idCorte
  FROM `corte_caja`
  WHERE `estado` = 'ABIERTO';

  RETURN v_idCorte;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_puede_vender_inventario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_puede_vender_inventario`(p_idInventario BIGINT UNSIGNED,
  p_cantidad INT
) RETURNS tinyint(1)
    READS SQL DATA
BEGIN
  DECLARE v_resultado TINYINT(1) DEFAULT 0;

  SELECT CASE
    WHEN COUNT(*) = 1 THEN 1
    ELSE 0
  END
    INTO v_resultado
  FROM `inventario_producto` i
  INNER JOIN `producto` p ON p.`idProducto` = i.`idProducto`
  WHERE i.`idInventario` = p_idInventario
    AND p.`activo` = 1
    AND i.`activo` = 1
    AND p_cantidad > 0
    AND i.`stockActual` >= p_cantidad
    AND (i.`fechaCaducidad` IS NULL OR i.`fechaCaducidad` >= CURDATE());

  RETURN v_resultado;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_saldo_corte` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_saldo_corte`(p_idCorte BIGINT UNSIGNED,
  p_medio VARCHAR(20)
) RETURNS decimal(12,2)
    READS SQL DATA
BEGIN
  DECLARE v_existeCorte INT DEFAULT 0;
  DECLARE v_medio VARCHAR(20);
  DECLARE v_inicial DECIMAL(12,2) DEFAULT 0.00;
  DECLARE v_entradas DECIMAL(12,2) DEFAULT 0.00;
  DECLARE v_salidas DECIMAL(12,2) DEFAULT 0.00;

  SET v_medio = UPPER(TRIM(p_medio));

  IF p_idCorte IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El idCorte es obligatorio para calcular el saldo.';
  END IF;

  IF v_medio NOT IN ('EFECTIVO', 'ELECTRONICO') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Medio invalido. Use EFECTIVO o ELECTRONICO.';
  END IF;

  SELECT COUNT(*)
    INTO v_existeCorte
  FROM `corte_caja`
  WHERE `idCorte` = p_idCorte;

  IF v_existeCorte = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No existe el corte indicado.';
  END IF;

  SELECT
    CASE
      WHEN v_medio = 'EFECTIVO' THEN `efectivoInicial`
      WHEN v_medio = 'ELECTRONICO' THEN `electronicoInicial`
    END
    INTO v_inicial
  FROM `corte_caja`
  WHERE `idCorte` = p_idCorte;

  SELECT
    COALESCE(SUM(CASE WHEN `tipo` = 'ENTRADA' THEN `monto` ELSE 0.00 END), 0.00),
    COALESCE(SUM(CASE WHEN `tipo` = 'SALIDA'  THEN `monto` ELSE 0.00 END), 0.00)
    INTO v_entradas, v_salidas
  FROM `movimiento_dinero`
  WHERE `idCorte` = p_idCorte
    AND `medio` = v_medio;

  RETURN ROUND(v_inicial + v_entradas - v_salidas, 2);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_stock_inventario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_stock_inventario`(p_idInventario BIGINT UNSIGNED
) RETURNS bigint(20)
    READS SQL DATA
BEGIN
  DECLARE v_stock BIGINT DEFAULT 0;

  IF p_idInventario IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El idInventario es obligatorio para calcular el stock.';
  END IF;

  SELECT COALESCE(MAX(i.`stockActual`), 0)
    INTO v_stock
  FROM `inventario_producto` i
  INNER JOIN `producto` p
    ON p.`idProducto` = i.`idProducto`
  WHERE i.`idInventario` = p_idInventario
    AND p.`activo` = 1
    AND i.`activo` = 1
    AND i.`stockActual` > 0
    AND (
      i.`fechaCaducidad` IS NULL
      OR i.`fechaCaducidad` >= CURDATE()
    );

  RETURN v_stock;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_stock_producto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_stock_producto`(p_idProducto BIGINT UNSIGNED
) RETURNS bigint(20)
    READS SQL DATA
BEGIN
  DECLARE v_stock BIGINT DEFAULT 0;

  IF p_idProducto IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El idProducto es obligatorio para calcular el stock.';
  END IF;

  SELECT COALESCE(SUM(i.`stockActual`), 0)
    INTO v_stock
  FROM `inventario_producto` i
  INNER JOIN `producto` p
    ON p.`idProducto` = i.`idProducto`
  WHERE i.`idProducto` = p_idProducto
    AND p.`activo` = 1
    AND i.`activo` = 1
    AND i.`stockActual` > 0
    AND (
      i.`fechaCaducidad` IS NULL
      OR i.`fechaCaducidad` >= CURDATE()
    );

  RETURN v_stock;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_abrir_corte` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_abrir_corte`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_efectivoInicial DECIMAL(10,2),
  IN p_electronicoInicial DECIMAL(10,2),
  IN p_observaciones VARCHAR(255),
  OUT p_idCorte BIGINT UNSIGNED
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede abrir corte.';
  END IF;

  IF p_efectivoInicial < 0 OR p_electronicoInicial < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los montos iniciales no pueden ser negativos.';
  END IF;

  IF `fn_obtener_corte_abierto`() IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un corte abierto.';
  END IF;

  INSERT INTO `corte_caja` (
    `efectivoInicial`, `electronicoInicial`, `usuarioAbre`, `observaciones`
  ) VALUES (
    p_efectivoInicial, p_electronicoInicial, p_idUsuario, p_observaciones
  );

  SET p_idCorte = LAST_INSERT_ID();

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_ajustar_inventario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ajustar_inventario`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_idInventario BIGINT UNSIGNED,
  IN p_nuevoStock BIGINT,
  IN p_motivo VARCHAR(20),
  IN p_observaciones VARCHAR(255)
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_stockAntes BIGINT;
  DECLARE v_stockDespues BIGINT;
  DECLARE v_cantidad INT;
  DECLARE v_motivo VARCHAR(20);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede ajustar inventario.';
  END IF;

  IF p_nuevoStock IS NULL OR p_nuevoStock < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nuevo stock no puede ser negativo.';
  END IF;

  SET v_motivo = UPPER(TRIM(p_motivo));

  IF v_motivo NOT IN ('AJUSTE', 'MERMA', 'CADUCIDAD', 'OTRO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Motivo de ajuste invÃ¡lido.';
  END IF;

  SELECT `stockActual`
    INTO v_stockAntes
  FROM `inventario_producto`
  WHERE `idInventario` = p_idInventario
  FOR UPDATE;

  IF v_stockAntes IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inventario inexistente.';
  END IF;

  IF v_stockAntes = p_nuevoStock THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nuevo stock es igual al stock actual.';
  END IF;

  SET v_stockDespues = p_nuevoStock;
  SET v_cantidad = ABS(v_stockDespues - v_stockAntes);

  UPDATE `inventario_producto`
  SET `stockActual` = v_stockDespues
  WHERE `idInventario` = p_idInventario;

  INSERT INTO `movimiento_inventario` (
    `idUsuario`, `idInventario`, `tipo`, `motivo`, `cantidad`, `stockAntes`, `stockDespues`, `observaciones`
  ) VALUES (
    p_idUsuario, p_idInventario, 'AJUSTE', v_motivo, v_cantidad, v_stockAntes, v_stockDespues, p_observaciones
  );

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cambiar_precio_inventario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cambiar_precio_inventario`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_idInventario BIGINT UNSIGNED,
  IN p_precioNuevo DECIMAL(10,2),
  IN p_motivo VARCHAR(255)
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_idProducto BIGINT UNSIGNED;
  DECLARE v_precioAnterior DECIMAL(10,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede cambiar precios.';
  END IF;

  IF p_precioNuevo IS NULL OR p_precioNuevo < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El precio nuevo no puede ser negativo.';
  END IF;

  SELECT `idProducto`, `precioVenta`
    INTO v_idProducto, v_precioAnterior
  FROM `inventario_producto`
  WHERE `idInventario` = p_idInventario
  FOR UPDATE;

  IF v_idProducto IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inventario inexistente.';
  END IF;

  IF v_precioAnterior = p_precioNuevo THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El precio nuevo es igual al precio actual.';
  END IF;

  UPDATE `inventario_producto`
  SET `precioVenta` = p_precioNuevo
  WHERE `idInventario` = p_idInventario;

  INSERT INTO `historial_precio_producto` (
    `idProducto`, `idInventario`, `precioAnterior`, `precioNuevo`, `motivo`, `idUsuario`
  ) VALUES (
    v_idProducto, p_idInventario, v_precioAnterior, p_precioNuevo, p_motivo, p_idUsuario
  );

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cancelar_compra` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancelar_compra`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_idCompra BIGINT UNSIGNED,
  IN p_observaciones VARCHAR(255)
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_estatus VARCHAR(20);
  DECLARE v_rows INT DEFAULT 0;
  DECLARE v_idx INT DEFAULT 1;
  DECLARE v_idCompraDetalle BIGINT UNSIGNED;
  DECLARE v_idInventario BIGINT UNSIGNED;
  DECLARE v_cantidad INT;
  DECLARE v_stockAntes BIGINT;
  DECLARE v_stockDespues BIGINT;
  DECLARE v_idCorte BIGINT UNSIGNED;
  DECLARE v_movRows INT DEFAULT 0;
  DECLARE v_movIdx INT DEFAULT 1;
  DECLARE v_medio VARCHAR(20);
  DECLARE v_tipo VARCHAR(20);
  DECLARE v_monto DECIMAL(10,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_compra_detalle`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_compra_movdin`;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede cancelar compras.';
  END IF;

  SELECT `estatus`
    INTO v_estatus
  FROM `compra`
  WHERE `idCompra` = p_idCompra
  FOR UPDATE;

  IF v_estatus IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Compra inexistente.';
  END IF;

  IF v_estatus = 'CANCELADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La compra ya estÃ¡ cancelada.';
  END IF;

  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_compra_detalle`;
  CREATE TEMPORARY TABLE `tmp_cancelar_compra_detalle` (
    `rn` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `idCompraDetalle` BIGINT UNSIGNED NOT NULL,
    `idInventario` BIGINT UNSIGNED NOT NULL,
    `cantidad` INT NOT NULL
  ) ENGINE=MEMORY;

  INSERT INTO `tmp_cancelar_compra_detalle` (`idCompraDetalle`, `idInventario`, `cantidad`)
  SELECT `idCompraDetalle`, `idInventario`, `cantidad`
  FROM `compra_detalle`
  WHERE `idCompra` = p_idCompra
    AND `idInventario` IS NOT NULL;

  SELECT COUNT(*) INTO v_rows FROM `tmp_cancelar_compra_detalle`;

  WHILE v_idx <= v_rows DO
    SELECT `idCompraDetalle`, `idInventario`, `cantidad`
      INTO v_idCompraDetalle, v_idInventario, v_cantidad
    FROM `tmp_cancelar_compra_detalle`
    WHERE `rn` = v_idx;

    SELECT `stockActual`
      INTO v_stockAntes
    FROM `inventario_producto`
    WHERE `idInventario` = v_idInventario
    FOR UPDATE;

    IF v_stockAntes < v_cantidad THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay stock suficiente para cancelar la compra; parte del inventario ya fue vendido o ajustado.';
    END IF;

    SET v_stockDespues = v_stockAntes - v_cantidad;

    UPDATE `inventario_producto`
    SET `stockActual` = v_stockDespues
    WHERE `idInventario` = v_idInventario;

    INSERT INTO `movimiento_inventario` (
      `idUsuario`, `idInventario`, `tipo`, `motivo`, `cantidad`, `stockAntes`,
      `stockDespues`, `idCompraDetalle`, `observaciones`
    ) VALUES (
      p_idUsuario, v_idInventario, 'SALIDA', 'CANCELACION', v_cantidad, v_stockAntes,
      v_stockDespues, v_idCompraDetalle, CONCAT('CancelaciÃ³n de compra ', p_idCompra)
    );

    SET v_idx = v_idx + 1;
  END WHILE;

  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_compra_movdin`;
  CREATE TEMPORARY TABLE `tmp_cancelar_compra_movdin` (
    `rn` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `medio` VARCHAR(20) NOT NULL,
    `tipo` VARCHAR(20) NOT NULL,
    `monto` DECIMAL(10,2) NOT NULL
  ) ENGINE=MEMORY;

  INSERT INTO `tmp_cancelar_compra_movdin` (`medio`, `tipo`, `monto`)
  SELECT `medio`, `tipo`, `monto`
  FROM `movimiento_dinero`
  WHERE `idCompra` = p_idCompra
    AND `concepto` = 'COMPRA_MERCANCIA';

  SELECT COUNT(*) INTO v_movRows FROM `tmp_cancelar_compra_movdin`;

  IF v_movRows > 0 THEN
    SET v_idCorte = `fn_obtener_corte_abierto`();

    IF v_idCorte IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay corte abierto para revertir el pago de la compra.';
    END IF;

    SELECT `idCorte`
      INTO v_idCorte
    FROM `corte_caja`
    WHERE `idCorte` = v_idCorte AND `estado` = 'ABIERTO'
    FOR UPDATE;
  END IF;

  WHILE v_movIdx <= v_movRows DO
    SELECT `medio`, `tipo`, `monto`
      INTO v_medio, v_tipo, v_monto
    FROM `tmp_cancelar_compra_movdin`
    WHERE `rn` = v_movIdx;

    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idCompra`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, v_medio,
      CASE WHEN v_tipo = 'ENTRADA' THEN 'SALIDA' ELSE 'ENTRADA' END,
      'CANCELACION', v_monto, p_idCompra, CONCAT('Reverso de pago por cancelaciÃ³n de compra ', p_idCompra)
    );

    SET v_movIdx = v_movIdx + 1;
  END WHILE;

  UPDATE `compra`
  SET
    `estatus` = 'CANCELADA',
    `observaciones` = CONCAT(COALESCE(`observaciones`, ''), ' | Cancelada: ', COALESCE(p_observaciones, ''))
  WHERE `idCompra` = p_idCompra;

  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_compra_detalle`;
  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_compra_movdin`;

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cancelar_devolucion_cliente` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancelar_devolucion_cliente`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_idDevolucionCliente BIGINT UNSIGNED,
  IN p_observaciones VARCHAR(255)
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_idCorte BIGINT UNSIGNED;
  DECLARE v_idVenta BIGINT UNSIGNED;
  DECLARE v_estadoCorte VARCHAR(20);
  DECLARE v_estatus VARCHAR(20);
  DECLARE v_folio VARCHAR(40);
  DECLARE v_totalDevuelto DECIMAL(10,2);
  DECLARE v_metodo VARCHAR(40);
  DECLARE v_rows INT DEFAULT 0;
  DECLARE v_idx INT DEFAULT 1;
  DECLARE v_idDevDetalle BIGINT UNSIGNED;
  DECLARE v_idVentaDetalle BIGINT UNSIGNED;
  DECLARE v_idInventario BIGINT UNSIGNED;
  DECLARE v_cantidad INT;
  DECLARE v_regresaAInventario TINYINT(1);
  DECLARE v_stockAntes BIGINT;
  DECLARE v_stockDespues BIGINT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_dev_cliente_det`;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede cancelar devoluciones de clientes.';
  END IF;

  SELECT dc.`idCorte`, dc.`idVenta`, dc.`estatus`, dc.`folio`, dc.`totalDevuelto`,
         dc.`metodoDevolucion`, c.`estado`
    INTO v_idCorte, v_idVenta, v_estatus, v_folio, v_totalDevuelto, v_metodo, v_estadoCorte
  FROM `devolucion_cliente` dc
  INNER JOIN `corte_caja` c ON c.`idCorte` = dc.`idCorte`
  WHERE dc.`idDevolucionCliente` = p_idDevolucionCliente
  FOR UPDATE;

  IF v_estatus IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DevoluciÃ³n de cliente inexistente.';
  END IF;

  IF v_estatus = 'CANCELADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La devoluciÃ³n de cliente ya estÃ¡ cancelada.';
  END IF;

  IF v_estadoCorte <> 'ABIERTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se puede cancelar la devoluciÃ³n mientras su corte estÃ¡ abierto.';
  END IF;

  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_dev_cliente_det`;
  CREATE TEMPORARY TABLE `tmp_cancelar_dev_cliente_det` (
    `rn` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `idDevolucionClienteDetalle` BIGINT UNSIGNED NOT NULL,
    `idVentaDetalle` BIGINT UNSIGNED NOT NULL,
    `idInventario` BIGINT UNSIGNED NOT NULL,
    `cantidad` INT NOT NULL,
    `regresaAInventario` TINYINT(1) NOT NULL
  ) ENGINE=MEMORY;

  INSERT INTO `tmp_cancelar_dev_cliente_det` (
    `idDevolucionClienteDetalle`, `idVentaDetalle`, `idInventario`, `cantidad`, `regresaAInventario`
  )
  SELECT `idDevolucionClienteDetalle`, `idVentaDetalle`, `idInventario`, `cantidad`, `regresaAInventario`
  FROM `devolucion_cliente_detalle`
  WHERE `idDevolucionCliente` = p_idDevolucionCliente;

  SELECT COUNT(*) INTO v_rows FROM `tmp_cancelar_dev_cliente_det`;

  WHILE v_idx <= v_rows DO
    SELECT `idDevolucionClienteDetalle`, `idVentaDetalle`, `idInventario`, `cantidad`, `regresaAInventario`
      INTO v_idDevDetalle, v_idVentaDetalle, v_idInventario, v_cantidad, v_regresaAInventario
    FROM `tmp_cancelar_dev_cliente_det`
    WHERE `rn` = v_idx;

    IF v_regresaAInventario = 1 THEN
      SELECT `stockActual`
        INTO v_stockAntes
      FROM `inventario_producto`
      WHERE `idInventario` = v_idInventario
      FOR UPDATE;

      IF v_stockAntes < v_cantidad THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay stock suficiente para cancelar la devoluciÃ³n; el producto devuelto ya pudo haberse vendido.';
      END IF;

      SET v_stockDespues = v_stockAntes - v_cantidad;

      UPDATE `inventario_producto`
      SET `stockActual` = v_stockDespues
      WHERE `idInventario` = v_idInventario;

      INSERT INTO `movimiento_inventario` (
        `idUsuario`, `idInventario`, `tipo`, `motivo`, `cantidad`, `stockAntes`,
        `stockDespues`, `idVentaDetalle`, `idDevolucionClienteDetalle`, `observaciones`
      ) VALUES (
        p_idUsuario, v_idInventario, 'SALIDA', 'CANCELACION', v_cantidad,
        v_stockAntes, v_stockDespues, v_idVentaDetalle, v_idDevDetalle,
        CONCAT('CancelaciÃ³n de devoluciÃ³n de cliente ', v_folio)
      );
    END IF;

    SET v_idx = v_idx + 1;
  END WHILE;

  IF v_totalDevuelto > 0 AND v_metodo IN ('EFECTIVO','ELECTRONICO') THEN
    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`,
      `idVenta`, `idDevolucionCliente`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, v_metodo, 'ENTRADA', 'CANCELACION', v_totalDevuelto,
      v_idVenta, p_idDevolucionCliente, CONCAT('CancelaciÃ³n de devoluciÃ³n de cliente ', v_folio)
    );
  END IF;

  UPDATE `devolucion_cliente`
  SET `estatus` = 'CANCELADA',
      `observaciones` = CONCAT(COALESCE(`observaciones`, ''), ' | Cancelada: ', COALESCE(p_observaciones, ''))
  WHERE `idDevolucionCliente` = p_idDevolucionCliente;

  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_dev_cliente_det`;

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cancelar_devolucion_proveedor` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancelar_devolucion_proveedor`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_idDevolucionProveedor BIGINT UNSIGNED,
  IN p_observaciones VARCHAR(255)
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_idCorte BIGINT UNSIGNED;
  DECLARE v_idCompra BIGINT UNSIGNED;
  DECLARE v_estadoCorte VARCHAR(20);
  DECLARE v_estatus VARCHAR(20);
  DECLARE v_folio VARCHAR(40);
  DECLARE v_totalDevolucion DECIMAL(10,2);
  DECLARE v_tipoCompensacion VARCHAR(40);
  DECLARE v_rows INT DEFAULT 0;
  DECLARE v_idx INT DEFAULT 1;
  DECLARE v_idDevDetalle BIGINT UNSIGNED;
  DECLARE v_idCompraDetalle BIGINT UNSIGNED;
  DECLARE v_idInventario BIGINT UNSIGNED;
  DECLARE v_cantidad INT;
  DECLARE v_stockAntes BIGINT;
  DECLARE v_stockDespues BIGINT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_dev_prov_det`;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede cancelar devoluciones a proveedores.';
  END IF;

  SELECT dp.`idCorte`, dp.`idCompra`, dp.`estatus`, dp.`folio`, dp.`totalDevolucion`,
         dp.`tipoCompensacion`, c.`estado`
    INTO v_idCorte, v_idCompra, v_estatus, v_folio, v_totalDevolucion, v_tipoCompensacion, v_estadoCorte
  FROM `devolucion_proveedor` dp
  INNER JOIN `corte_caja` c ON c.`idCorte` = dp.`idCorte`
  WHERE dp.`idDevolucionProveedor` = p_idDevolucionProveedor
  FOR UPDATE;

  IF v_estatus IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DevoluciÃ³n a proveedor inexistente.';
  END IF;

  IF v_estatus = 'CANCELADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La devoluciÃ³n a proveedor ya estÃ¡ cancelada.';
  END IF;

  IF v_estadoCorte <> 'ABIERTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se puede cancelar la devoluciÃ³n mientras su corte estÃ¡ abierto.';
  END IF;

  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_dev_prov_det`;
  CREATE TEMPORARY TABLE `tmp_cancelar_dev_prov_det` (
    `rn` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `idDevolucionProveedorDetalle` BIGINT UNSIGNED NOT NULL,
    `idCompraDetalle` BIGINT UNSIGNED DEFAULT NULL,
    `idInventario` BIGINT UNSIGNED NOT NULL,
    `cantidad` INT NOT NULL
  ) ENGINE=MEMORY;

  INSERT INTO `tmp_cancelar_dev_prov_det` (
    `idDevolucionProveedorDetalle`, `idCompraDetalle`, `idInventario`, `cantidad`
  )
  SELECT `idDevolucionProveedorDetalle`, `idCompraDetalle`, `idInventario`, `cantidad`
  FROM `devolucion_proveedor_detalle`
  WHERE `idDevolucionProveedor` = p_idDevolucionProveedor;

  SELECT COUNT(*) INTO v_rows FROM `tmp_cancelar_dev_prov_det`;

  WHILE v_idx <= v_rows DO
    SELECT `idDevolucionProveedorDetalle`, `idCompraDetalle`, `idInventario`, `cantidad`
      INTO v_idDevDetalle, v_idCompraDetalle, v_idInventario, v_cantidad
    FROM `tmp_cancelar_dev_prov_det`
    WHERE `rn` = v_idx;

    SELECT `stockActual`
      INTO v_stockAntes
    FROM `inventario_producto`
    WHERE `idInventario` = v_idInventario
    FOR UPDATE;

    SET v_stockDespues = v_stockAntes + v_cantidad;

    UPDATE `inventario_producto`
    SET `stockActual` = v_stockDespues
    WHERE `idInventario` = v_idInventario;

    INSERT INTO `movimiento_inventario` (
      `idUsuario`, `idInventario`, `tipo`, `motivo`, `cantidad`, `stockAntes`,
      `stockDespues`, `idCompraDetalle`, `idDevolucionProveedorDetalle`, `observaciones`
    ) VALUES (
      p_idUsuario, v_idInventario, 'ENTRADA', 'CANCELACION', v_cantidad,
      v_stockAntes, v_stockDespues, v_idCompraDetalle, v_idDevDetalle,
      CONCAT('CancelaciÃ³n de devoluciÃ³n a proveedor ', v_folio)
    );

    SET v_idx = v_idx + 1;
  END WHILE;

  IF v_totalDevolucion > 0 AND v_tipoCompensacion IN ('EFECTIVO','ELECTRONICO') THEN
    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`,
      `idCompra`, `idDevolucionProveedor`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, v_tipoCompensacion, 'SALIDA', 'CANCELACION',
      v_totalDevolucion, v_idCompra, p_idDevolucionProveedor,
      CONCAT('CancelaciÃ³n de devoluciÃ³n a proveedor ', v_folio)
    );
  END IF;

  UPDATE `devolucion_proveedor`
  SET `estatus` = 'CANCELADA',
      `observaciones` = CONCAT(COALESCE(`observaciones`, ''), ' | Cancelada: ', COALESCE(p_observaciones, ''))
  WHERE `idDevolucionProveedor` = p_idDevolucionProveedor;

  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_dev_prov_det`;

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cancelar_servicio_yastas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancelar_servicio_yastas`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_idServicioOperacion BIGINT UNSIGNED,
  IN p_observaciones VARCHAR(255)
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_idCorte BIGINT UNSIGNED;
  DECLARE v_estadoCorte VARCHAR(20);
  DECLARE v_estatusServicio VARCHAR(20);
  DECLARE v_rows INT DEFAULT 0;
  DECLARE v_idx INT DEFAULT 1;
  DECLARE v_medio VARCHAR(20);
  DECLARE v_tipo VARCHAR(20);
  DECLARE v_tipoInverso VARCHAR(20);
  DECLARE v_monto DECIMAL(10,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_servicio_movdin`;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede cancelar servicios Yastas.';
  END IF;

  SELECT s.`idCorte`, s.`estatus`, c.`estado`
    INTO v_idCorte, v_estatusServicio, v_estadoCorte
  FROM `servicio_operacion` s
  INNER JOIN `corte_caja` c ON c.`idCorte` = s.`idCorte`
  WHERE s.`idServicioOperacion` = p_idServicioOperacion
  FOR UPDATE;

  IF v_idCorte IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Servicio inexistente.';
  END IF;

  IF v_estatusServicio <> 'REALIZADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se pueden cancelar servicios realizados.';
  END IF;

  IF v_estadoCorte <> 'ABIERTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede cancelar un servicio de un corte cerrado.';
  END IF;

  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_servicio_movdin`;
  CREATE TEMPORARY TABLE `tmp_cancelar_servicio_movdin` (
    `rn` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `medio` VARCHAR(20) NOT NULL,
    `tipo` VARCHAR(20) NOT NULL,
    `monto` DECIMAL(10,2) NOT NULL
  ) ENGINE=MEMORY;

  INSERT INTO `tmp_cancelar_servicio_movdin` (`medio`, `tipo`, `monto`)
  SELECT `medio`, `tipo`, `monto`
  FROM `movimiento_dinero`
  WHERE `idServicioOperacion` = p_idServicioOperacion
    AND `concepto` = 'SERVICIO_YASTAS';

  SELECT COUNT(*) INTO v_rows FROM `tmp_cancelar_servicio_movdin`;

  WHILE v_idx <= v_rows DO
    SELECT `medio`, `tipo`, `monto`
      INTO v_medio, v_tipo, v_monto
    FROM `tmp_cancelar_servicio_movdin`
    WHERE `rn` = v_idx;

    SET v_tipoInverso = CASE WHEN v_tipo = 'ENTRADA' THEN 'SALIDA' ELSE 'ENTRADA' END;

    IF v_tipoInverso = 'SALIDA' AND `fn_saldo_corte`(v_idCorte, v_medio) < v_monto THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo insuficiente para cancelar el servicio Yastas.';
    END IF;

    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idServicioOperacion`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, v_medio, v_tipoInverso, 'CANCELACION',
      v_monto, p_idServicioOperacion, CONCAT('CancelaciÃ³n de servicio Yastas ', p_idServicioOperacion)
    );

    SET v_idx = v_idx + 1;
  END WHILE;

  UPDATE `servicio_operacion`
  SET
    `estatus` = 'CANCELADA',
    `observaciones` = CONCAT(COALESCE(`observaciones`, ''), ' | Cancelado: ', COALESCE(p_observaciones, ''))
  WHERE `idServicioOperacion` = p_idServicioOperacion;

  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_servicio_movdin`;

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cancelar_venta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancelar_venta`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_idVenta BIGINT UNSIGNED,
  IN p_observaciones VARCHAR(255)
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_idCorte BIGINT UNSIGNED;
  DECLARE v_estadoCorte VARCHAR(20);
  DECLARE v_estatusVenta VARCHAR(20);
  DECLARE v_folio VARCHAR(40);
  DECLARE v_rows INT DEFAULT 0;
  DECLARE v_idx INT DEFAULT 1;
  DECLARE v_idVentaDetalle BIGINT UNSIGNED;
  DECLARE v_idInventario BIGINT UNSIGNED;
  DECLARE v_cantidad INT;
  DECLARE v_stockAntes BIGINT;
  DECLARE v_stockDespues BIGINT;
  DECLARE v_pagoRows INT DEFAULT 0;
  DECLARE v_pagoIdx INT DEFAULT 1;
  DECLARE v_medioPago VARCHAR(20);
  DECLARE v_medioDinero VARCHAR(20);
  DECLARE v_montoPago DECIMAL(10,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_venta_detalle`;
    DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_venta_pago`;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede cancelar ventas.';
  END IF;

  SELECT v.`idCorte`, v.`estatus`, v.`folio`, c.`estado`
    INTO v_idCorte, v_estatusVenta, v_folio, v_estadoCorte
  FROM `venta` v
  INNER JOIN `corte_caja` c ON c.`idCorte` = v.`idCorte`
  WHERE v.`idVenta` = p_idVenta
  FOR UPDATE;

  IF v_idCorte IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Venta inexistente.';
  END IF;

  IF v_estatusVenta = 'CANCELADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta ya estÃ¡ cancelada.';
  END IF;

  IF v_estadoCorte <> 'ABIERTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede cancelar una venta de un corte cerrado.';
  END IF;

  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_venta_detalle`;
  CREATE TEMPORARY TABLE `tmp_cancelar_venta_detalle` (
    `rn` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `idVentaDetalle` BIGINT UNSIGNED NOT NULL,
    `idInventario` BIGINT UNSIGNED NOT NULL,
    `cantidad` INT NOT NULL
  ) ENGINE=MEMORY;

  INSERT INTO `tmp_cancelar_venta_detalle` (`idVentaDetalle`, `idInventario`, `cantidad`)
  SELECT `idVentaDetalle`, `idInventario`, `cantidad`
  FROM `venta_detalle`
  WHERE `idVenta` = p_idVenta;

  SELECT COUNT(*) INTO v_rows FROM `tmp_cancelar_venta_detalle`;

  WHILE v_idx <= v_rows DO
    SELECT `idVentaDetalle`, `idInventario`, `cantidad`
      INTO v_idVentaDetalle, v_idInventario, v_cantidad
    FROM `tmp_cancelar_venta_detalle`
    WHERE `rn` = v_idx;

    SELECT `stockActual`
      INTO v_stockAntes
    FROM `inventario_producto`
    WHERE `idInventario` = v_idInventario
    FOR UPDATE;

    SET v_stockDespues = v_stockAntes + v_cantidad;

    UPDATE `inventario_producto`
    SET `stockActual` = v_stockDespues
    WHERE `idInventario` = v_idInventario;

    INSERT INTO `movimiento_inventario` (
      `idUsuario`, `idInventario`, `tipo`, `motivo`, `cantidad`, `stockAntes`,
      `stockDespues`, `idVentaDetalle`, `observaciones`
    ) VALUES (
      p_idUsuario, v_idInventario, 'ENTRADA', 'CANCELACION', v_cantidad, v_stockAntes,
      v_stockDespues, v_idVentaDetalle, CONCAT('CancelaciÃ³n de venta ', COALESCE(v_folio, p_idVenta))
    );

    SET v_idx = v_idx + 1;
  END WHILE;

  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_venta_pago`;
  CREATE TEMPORARY TABLE `tmp_cancelar_venta_pago` (
    `rn` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `medio` VARCHAR(20) NOT NULL,
    `monto` DECIMAL(10,2) NOT NULL
  ) ENGINE=MEMORY;

  INSERT INTO `tmp_cancelar_venta_pago` (`medio`, `monto`)
  SELECT `medio`, `monto`
  FROM `pago_venta`
  WHERE `idVenta` = p_idVenta;

  SELECT COUNT(*) INTO v_pagoRows FROM `tmp_cancelar_venta_pago`;

  WHILE v_pagoIdx <= v_pagoRows DO
    SELECT `medio`, `monto`
      INTO v_medioPago, v_montoPago
    FROM `tmp_cancelar_venta_pago`
    WHERE `rn` = v_pagoIdx;

    SET v_medioDinero = CASE WHEN v_medioPago = 'EFECTIVO' THEN 'EFECTIVO' ELSE 'ELECTRONICO' END;

    IF `fn_saldo_corte`(v_idCorte, v_medioDinero) < v_montoPago THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo insuficiente para devolver el pago de la venta cancelada.';
    END IF;

    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idVenta`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, v_medioDinero, 'SALIDA', 'CANCELACION',
      v_montoPago, p_idVenta, CONCAT('DevoluciÃ³n por cancelaciÃ³n de venta ', COALESCE(v_folio, p_idVenta))
    );

    SET v_pagoIdx = v_pagoIdx + 1;
  END WHILE;

  UPDATE `venta`
  SET
    `estatus` = 'CANCELADA',
    `observaciones` = CONCAT(COALESCE(`observaciones`, ''), ' | Cancelada: ', COALESCE(p_observaciones, ''))
  WHERE `idVenta` = p_idVenta;

  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_venta_detalle`;
  DROP TEMPORARY TABLE IF EXISTS `tmp_cancelar_venta_pago`;

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cerrar_corte` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cerrar_corte`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_efectivoContado DECIMAL(10,2),
  IN p_electronicoContado DECIMAL(10,2),
  IN p_observaciones VARCHAR(255)
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_idCorte BIGINT UNSIGNED;
  DECLARE v_efectivoSistema DECIMAL(12,2);
  DECLARE v_electronicoSistema DECIMAL(12,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede cerrar corte.';
  END IF;

  IF p_efectivoContado < 0 OR p_electronicoContado < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los montos contados no pueden ser negativos.';
  END IF;

  SELECT `idCorte`
    INTO v_idCorte
  FROM `corte_caja`
  WHERE `estado` = 'ABIERTO'
  LIMIT 1
  FOR UPDATE;

  IF v_idCorte IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay corte abierto para cerrar.';
  END IF;

  SET v_efectivoSistema = `fn_saldo_corte`(v_idCorte, 'EFECTIVO');
  SET v_electronicoSistema = `fn_saldo_corte`(v_idCorte, 'ELECTRONICO');

  UPDATE `corte_caja`
  SET
    `fechaCierre` = NOW(),
    `efectivoContado` = p_efectivoContado,
    `electronicoContado` = p_electronicoContado,
    `diferenciaEfectivo` = ROUND(p_efectivoContado - v_efectivoSistema, 2),
    `diferenciaElectronico` = ROUND(p_electronicoContado - v_electronicoSistema, 2),
    `usuarioCierra` = p_idUsuario,
    `estado` = 'CERRADO',
    `observaciones` = p_observaciones
  WHERE `idCorte` = v_idCorte;

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_compra` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_compra`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_idProveedor BIGINT UNSIGNED,
  IN p_folioProveedor VARCHAR(80),
  IN p_descuento DECIMAL(10,2),
  IN p_observaciones VARCHAR(255),
  IN p_detalles_json LONGTEXT,
  IN p_medioPago VARCHAR(20),
  IN p_montoPagado DECIMAL(10,2),
  OUT p_idCompra BIGINT UNSIGNED
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_proveedorExiste INT DEFAULT 0;
  DECLARE v_len INT DEFAULT 0;
  DECLARE v_idx INT DEFAULT 0;
  DECLARE v_idProducto BIGINT UNSIGNED;
  DECLARE v_idInventario BIGINT UNSIGNED;
  DECLARE v_cantidad INT;
  DECLARE v_costoUnitario DECIMAL(10,2);
  DECLARE v_precioVenta DECIMAL(10,2);
  DECLARE v_codigoLote VARCHAR(80);
  DECLARE v_fechaCaducidadText VARCHAR(20);
  DECLARE v_fechaCaducidad DATE;
  DECLARE v_productoActivo TINYINT(1);
  DECLARE v_manejaCaducidad TINYINT(1);
  DECLARE v_stockAntes BIGINT;
  DECLARE v_stockDespues BIGINT;
  DECLARE v_subtotalLinea DECIMAL(10,2);
  DECLARE v_subtotalCompra DECIMAL(10,2) DEFAULT 0.00;
  DECLARE v_totalCompra DECIMAL(10,2) DEFAULT 0.00;
  DECLARE v_idCompraDetalle BIGINT UNSIGNED;
  DECLARE v_idCorte BIGINT UNSIGNED;
  DECLARE v_medioDinero VARCHAR(20);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede registrar compras.';
  END IF;

  IF p_descuento IS NULL OR p_descuento < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El descuento de compra no puede ser negativo.';
  END IF;

  IF p_idProveedor IS NOT NULL THEN
    SELECT COUNT(*)
      INTO v_proveedorExiste
    FROM `proveedor`
    WHERE `idProveedor` = p_idProveedor
      AND `activo` = 1;

    IF v_proveedorExiste = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proveedor inexistente o inactivo.';
    END IF;
  END IF;

  IF p_detalles_json IS NULL OR JSON_VALID(p_detalles_json) = 0 OR JSON_LENGTH(p_detalles_json) IS NULL OR JSON_LENGTH(p_detalles_json) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La compra debe incluir al menos un detalle en JSON vÃ¡lido.';
  END IF;

  INSERT INTO `compra` (
    `folioProveedor`, `idProveedor`, `idUsuario`, `subtotal`, `descuento`, `total`, `observaciones`
  ) VALUES (
    p_folioProveedor, p_idProveedor, p_idUsuario, 0.00, p_descuento, 0.00, p_observaciones
  );

  SET p_idCompra = LAST_INSERT_ID();
  SET v_len = JSON_LENGTH(p_detalles_json);

  WHILE v_idx < v_len DO
    SET v_idProducto = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].idProducto'))) AS UNSIGNED);
    SET v_cantidad = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].cantidad'))) AS SIGNED);
    SET v_costoUnitario = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].costoUnitario'))) AS DECIMAL(10,2));
    SET v_precioVenta = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].precioVenta'))) AS DECIMAL(10,2));
    SET v_codigoLote = NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].codigoLote'))), 'null');
    SET v_fechaCaducidadText = NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].fechaCaducidad'))), 'null');

    IF v_codigoLote IS NULL OR TRIM(v_codigoLote) = '' THEN
      SET v_codigoLote = CONCAT('COMPRA-', p_idCompra, '-', LPAD(v_idx + 1, 3, '0'));
    END IF;

    IF v_fechaCaducidadText IS NULL OR TRIM(v_fechaCaducidadText) = '' THEN
      SET v_fechaCaducidad = NULL;
    ELSE
      SET v_fechaCaducidad = STR_TO_DATE(v_fechaCaducidadText, '%Y-%m-%d');
    END IF;

    IF v_idProducto IS NULL OR v_cantidad IS NULL OR v_costoUnitario IS NULL OR v_precioVenta IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Detalle de compra incompleto.';
    END IF;

    IF v_cantidad <= 0 OR v_costoUnitario < 0 OR v_precioVenta < 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad, costo o precio invÃ¡lido en detalle de compra.';
    END IF;

    SELECT `activo`, `manejaCaducidad`
      INTO v_productoActivo, v_manejaCaducidad
    FROM `producto`
    WHERE `idProducto` = v_idProducto
    FOR UPDATE;

    IF v_productoActivo IS NULL OR v_productoActivo <> 1 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Producto inexistente o inactivo en compra.';
    END IF;

    IF v_manejaCaducidad = 1 AND v_fechaCaducidad IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El producto requiere fecha de caducidad.';
    END IF;

    IF v_fechaCaducidad IS NOT NULL AND v_fechaCaducidad < CURDATE() THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede registrar inventario ya caducado.';
    END IF;

    SET v_idInventario = NULL;
    SELECT `idInventario`, `stockActual`
      INTO v_idInventario, v_stockAntes
    FROM `inventario_producto`
    WHERE `idProducto` = v_idProducto
      AND `codigoLote` = v_codigoLote
      AND IFNULL(`fechaCaducidad`, CAST('9999-12-31' AS DATE)) = IFNULL(v_fechaCaducidad, CAST('9999-12-31' AS DATE))
      AND `costoUnitario` = v_costoUnitario
      AND `precioVenta` = v_precioVenta
    LIMIT 1
    FOR UPDATE;

    IF v_idInventario IS NULL THEN
      INSERT INTO `inventario_producto` (
        `idProducto`, `codigoLote`, `fechaCaducidad`, `stockInicial`, `stockActual`,
        `costoUnitario`, `precioVenta`, `observaciones`
      ) VALUES (
        v_idProducto, v_codigoLote, v_fechaCaducidad, v_cantidad, v_cantidad,
        v_costoUnitario, v_precioVenta, CONCAT('Entrada por compra ', p_idCompra)
      );
      SET v_idInventario = LAST_INSERT_ID();
      SET v_stockAntes = 0;
      SET v_stockDespues = v_cantidad;
    ELSE
      SET v_stockDespues = v_stockAntes + v_cantidad;
      UPDATE `inventario_producto`
      SET
        `stockInicial` = `stockInicial` + v_cantidad,
        `stockActual` = v_stockDespues,
        `activo` = 1
      WHERE `idInventario` = v_idInventario;
    END IF;

    SET v_subtotalLinea = ROUND(v_cantidad * v_costoUnitario, 2);
    SET v_subtotalCompra = ROUND(v_subtotalCompra + v_subtotalLinea, 2);

    INSERT INTO `compra_detalle` (
      `idCompra`, `idProducto`, `idInventario`, `cantidad`, `costoUnitario`,
      `precioVentaSugerido`, `fechaCaducidad`, `subtotal`
    ) VALUES (
      p_idCompra, v_idProducto, v_idInventario, v_cantidad, v_costoUnitario,
      v_precioVenta, v_fechaCaducidad, v_subtotalLinea
    );

    SET v_idCompraDetalle = LAST_INSERT_ID();

    INSERT INTO `movimiento_inventario` (
      `idUsuario`, `idInventario`, `tipo`, `motivo`, `cantidad`, `stockAntes`,
      `stockDespues`, `idCompraDetalle`, `observaciones`
    ) VALUES (
      p_idUsuario, v_idInventario, 'ENTRADA', 'COMPRA', v_cantidad, v_stockAntes,
      v_stockDespues, v_idCompraDetalle, CONCAT('Entrada por compra ', p_idCompra)
    );

    SET v_idx = v_idx + 1;
  END WHILE;

  IF p_descuento > v_subtotalCompra THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El descuento no puede ser mayor al subtotal de la compra.';
  END IF;

  SET v_totalCompra = ROUND(v_subtotalCompra - p_descuento, 2);

  UPDATE `compra`
  SET
    `subtotal` = v_subtotalCompra,
    `descuento` = p_descuento,
    `total` = v_totalCompra
  WHERE `idCompra` = p_idCompra;

  IF p_montoPagado IS NOT NULL AND p_montoPagado > 0 THEN
    IF p_montoPagado > v_totalCompra THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto pagado no puede ser mayor al total de la compra.';
    END IF;

    SET v_idCorte = `fn_obtener_corte_abierto`();

    IF v_idCorte IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay corte abierto para registrar el pago de la compra.';
    END IF;

    SELECT `idCorte`
      INTO v_idCorte
    FROM `corte_caja`
    WHERE `idCorte` = v_idCorte AND `estado` = 'ABIERTO'
    FOR UPDATE;

    SET v_medioDinero = UPPER(TRIM(p_medioPago));

    IF v_medioDinero NOT IN ('EFECTIVO', 'ELECTRONICO') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El medio de pago de compra debe ser EFECTIVO o ELECTRONICO.';
    END IF;

    IF `fn_saldo_corte`(v_idCorte, v_medioDinero) < p_montoPagado THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo insuficiente en caja para pagar la compra.';
    END IF;

    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idCompra`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, v_medioDinero, 'SALIDA', 'COMPRA_MERCANCIA',
      p_montoPagado, p_idCompra, CONCAT('Pago de compra ', p_idCompra)
    );
  END IF;

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_devolucion_cliente` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_devolucion_cliente`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_idVenta BIGINT UNSIGNED,
  IN p_metodoDevolucion VARCHAR(40),
  IN p_motivo VARCHAR(40),
  IN p_observaciones VARCHAR(255),
  IN p_detalles_json LONGTEXT,
  OUT p_idDevolucionCliente BIGINT UNSIGNED,
  OUT p_folio VARCHAR(40)
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_idCorte BIGINT UNSIGNED;
  DECLARE v_estadoCorte VARCHAR(20);
  DECLARE v_estatusVenta VARCHAR(20);
  DECLARE v_subtotalVenta DECIMAL(10,2);
  DECLARE v_totalVenta DECIMAL(10,2);
  DECLARE v_factorDescuento DECIMAL(18,6) DEFAULT 1.000000;
  DECLARE v_len INT DEFAULT 0;
  DECLARE v_idx INT DEFAULT 0;
  DECLARE v_idVentaDetalle BIGINT UNSIGNED;
  DECLARE v_idInventario BIGINT UNSIGNED;
  DECLARE v_idInventarioVenta BIGINT UNSIGNED;
  DECLARE v_cantidadVendida INT;
  DECLARE v_cantidadDevuelta INT;
  DECLARE v_cantidadPendiente INT;
  DECLARE v_cantidad INT;
  DECLARE v_regresaAInventario TINYINT(1);
  DECLARE v_motivoDetalle VARCHAR(120);
  DECLARE v_observacionesDetalle VARCHAR(255);
  DECLARE v_precioUnitarioDevuelto DECIMAL(10,2);
  DECLARE v_subtotalDevuelto DECIMAL(10,2);
  DECLARE v_stockAntes BIGINT;
  DECLARE v_stockDespues BIGINT;
  DECLARE v_fechaCaducidad DATE;
  DECLARE v_idDevDetalle BIGINT UNSIGNED;
  DECLARE v_totalDevuelto DECIMAL(10,2) DEFAULT 0.00;
  DECLARE v_metodo VARCHAR(40);
  DECLARE v_motivo VARCHAR(40);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SET p_idDevolucionCliente = NULL;
  SET p_folio = NULL;
  SET v_metodo = UPPER(TRIM(COALESCE(p_metodoDevolucion, '')));
  SET v_motivo = UPPER(TRIM(COALESCE(p_motivo, 'OTRO')));

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede registrar devoluciones de clientes.';
  END IF;

  IF v_metodo NOT IN ('EFECTIVO','ELECTRONICO','CAMBIO_PRODUCTO','SIN_DEVOLUCION_DINERO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MÃ©todo de devoluciÃ³n invÃ¡lido.';
  END IF;

  IF v_motivo NOT IN ('PRODUCTO_EQUIVOCADO','PRODUCTO_DANADO','CADUCADO','ERROR_VENTA','CLIENTE_SE_ARREPINTIO','OTRO') THEN
    SET v_motivo = 'OTRO';
  END IF;

  SET v_idCorte = `fn_obtener_corte_abierto`();

  IF v_idCorte IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay corte abierto para registrar la devoluciÃ³n.';
  END IF;

  SELECT `estado`
    INTO v_estadoCorte
  FROM `corte_caja`
  WHERE `idCorte` = v_idCorte
  FOR UPDATE;

  IF v_estadoCorte <> 'ABIERTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El corte actual no estÃ¡ abierto.';
  END IF;

  SELECT `estatus`, `subtotal`, `total`
    INTO v_estatusVenta, v_subtotalVenta, v_totalVenta
  FROM `venta`
  WHERE `idVenta` = p_idVenta
  FOR UPDATE;

  IF v_estatusVenta IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Venta inexistente.';
  END IF;

  IF v_estatusVenta <> 'PAGADA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se pueden devolver productos de ventas pagadas.';
  END IF;

  IF v_subtotalVenta > 0 THEN
    SET v_factorDescuento = v_totalVenta / v_subtotalVenta;
  ELSE
    SET v_factorDescuento = 1.000000;
  END IF;

  IF p_detalles_json IS NULL OR JSON_VALID(p_detalles_json) = 0
     OR JSON_LENGTH(p_detalles_json) IS NULL OR JSON_LENGTH(p_detalles_json) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La devoluciÃ³n debe incluir al menos un detalle en JSON vÃ¡lido.';
  END IF;

  INSERT INTO `devolucion_cliente` (
    `folio`, `idVenta`, `idCorte`, `idUsuario`, `motivo`, `totalDevuelto`,
    `metodoDevolucion`, `observaciones`
  ) VALUES (
    NULL, p_idVenta, v_idCorte, p_idUsuario, v_motivo, 0.00, v_metodo, p_observaciones
  );

  SET p_idDevolucionCliente = LAST_INSERT_ID();
  SET p_folio = CONCAT('DC', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(p_idDevolucionCliente, 6, '0'));

  UPDATE `devolucion_cliente`
  SET `folio` = p_folio
  WHERE `idDevolucionCliente` = p_idDevolucionCliente;

  SET v_len = JSON_LENGTH(p_detalles_json);

  WHILE v_idx < v_len DO
    SET v_idVentaDetalle = CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].idVentaDetalle'))), 'null') AS UNSIGNED);
    SET v_cantidad = CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].cantidad'))), 'null') AS SIGNED);
    SET v_regresaAInventario = COALESCE(CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].regresaAInventario'))), 'null') AS UNSIGNED), 1);
    SET v_motivoDetalle = NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].motivoDetalle'))), 'null');
    SET v_observacionesDetalle = NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].observaciones'))), 'null');

    IF v_idVentaDetalle IS NULL OR v_cantidad IS NULL OR v_cantidad <= 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Detalle de devoluciÃ³n de cliente invÃ¡lido.';
    END IF;

    IF v_regresaAInventario NOT IN (0,1) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'regresaAInventario debe ser 0 o 1.';
    END IF;

    SET v_idInventarioVenta = NULL;
    SET v_cantidadVendida = NULL;
    SET v_precioUnitarioDevuelto = NULL;
    SET v_stockAntes = NULL;
    SET v_stockDespues = NULL;
    SET v_fechaCaducidad = NULL;

    SELECT `idInventario`, `cantidad`,
           ROUND((`subtotal` / `cantidad`) * v_factorDescuento, 2)
      INTO v_idInventarioVenta, v_cantidadVendida, v_precioUnitarioDevuelto
    FROM `venta_detalle`
    WHERE `idVentaDetalle` = v_idVentaDetalle
      AND `idVenta` = p_idVenta
    FOR UPDATE;

    IF v_idInventarioVenta IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El detalle no pertenece a la venta indicada.';
    END IF;

    SELECT COALESCE(SUM(dcd.`cantidad`), 0)
      INTO v_cantidadDevuelta
    FROM `devolucion_cliente_detalle` dcd
    INNER JOIN `devolucion_cliente` dc
      ON dc.`idDevolucionCliente` = dcd.`idDevolucionCliente`
    WHERE dcd.`idVentaDetalle` = v_idVentaDetalle
      AND dc.`estatus` = 'REGISTRADA';

    SET v_cantidadPendiente = v_cantidadVendida - v_cantidadDevuelta;

    IF v_cantidad > v_cantidadPendiente THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad a devolver supera la cantidad disponible de la venta.';
    END IF;

    SET v_subtotalDevuelto = ROUND(v_cantidad * v_precioUnitarioDevuelto, 2);

    INSERT INTO `devolucion_cliente_detalle` (
      `idDevolucionCliente`, `idVentaDetalle`, `idInventario`, `cantidad`,
      `precioUnitarioDevuelto`, `subtotalDevuelto`, `regresaAInventario`,
      `motivoDetalle`, `observaciones`
    ) VALUES (
      p_idDevolucionCliente, v_idVentaDetalle, v_idInventarioVenta, v_cantidad,
      v_precioUnitarioDevuelto, v_subtotalDevuelto, v_regresaAInventario,
      v_motivoDetalle, v_observacionesDetalle
    );

    SET v_idDevDetalle = LAST_INSERT_ID();

    IF v_regresaAInventario = 1 THEN
      SELECT `stockActual`, `fechaCaducidad`
        INTO v_stockAntes, v_fechaCaducidad
      FROM `inventario_producto`
      WHERE `idInventario` = v_idInventarioVenta
      FOR UPDATE;

      IF v_fechaCaducidad IS NOT NULL AND v_fechaCaducidad < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El producto devuelto estÃ¡ caducado; no debe regresar al inventario vendible.';
      END IF;

      SET v_stockDespues = v_stockAntes + v_cantidad;

      UPDATE `inventario_producto`
      SET `stockActual` = v_stockDespues
      WHERE `idInventario` = v_idInventarioVenta;

      INSERT INTO `movimiento_inventario` (
        `idUsuario`, `idInventario`, `tipo`, `motivo`, `cantidad`, `stockAntes`,
        `stockDespues`, `idVentaDetalle`, `idDevolucionClienteDetalle`, `observaciones`
      ) VALUES (
        p_idUsuario, v_idInventarioVenta, 'ENTRADA', 'DEVOLUCION_CLIENTE', v_cantidad,
        v_stockAntes, v_stockDespues, v_idVentaDetalle, v_idDevDetalle,
        CONCAT('DevoluciÃ³n de cliente ', p_folio)
      );
    END IF;

    SET v_totalDevuelto = ROUND(v_totalDevuelto + v_subtotalDevuelto, 2);
    SET v_idx = v_idx + 1;
  END WHILE;

  UPDATE `devolucion_cliente`
  SET `totalDevuelto` = v_totalDevuelto
  WHERE `idDevolucionCliente` = p_idDevolucionCliente;

  IF v_totalDevuelto > 0 AND v_metodo IN ('EFECTIVO','ELECTRONICO') THEN
    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`,
      `idVenta`, `idDevolucionCliente`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, v_metodo, 'SALIDA', 'DEVOLUCION_CLIENTE', v_totalDevuelto,
      p_idVenta, p_idDevolucionCliente, CONCAT('DevoluciÃ³n de cliente ', p_folio)
    );
  END IF;

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_devolucion_proveedor` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_devolucion_proveedor`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_idCompra BIGINT UNSIGNED,
  IN p_idProveedor BIGINT UNSIGNED,
  IN p_tipoCompensacion VARCHAR(40),
  IN p_motivo VARCHAR(40),
  IN p_observaciones VARCHAR(255),
  IN p_detalles_json LONGTEXT,
  OUT p_idDevolucionProveedor BIGINT UNSIGNED,
  OUT p_folio VARCHAR(40)
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_idCorte BIGINT UNSIGNED;
  DECLARE v_estadoCorte VARCHAR(20);
  DECLARE v_idProveedorFinal BIGINT UNSIGNED;
  DECLARE v_compraExiste INT DEFAULT 0;
  DECLARE v_proveedorExiste INT DEFAULT 0;
  DECLARE v_tipoCompensacion VARCHAR(40);
  DECLARE v_motivo VARCHAR(40);
  DECLARE v_len INT DEFAULT 0;
  DECLARE v_idx INT DEFAULT 0;
  DECLARE v_idCompraDetalle BIGINT UNSIGNED;
  DECLARE v_idCompraDetalleCompra BIGINT UNSIGNED;
  DECLARE v_idInventario BIGINT UNSIGNED;
  DECLARE v_idInventarioCompra BIGINT UNSIGNED;
  DECLARE v_cantidad INT;
  DECLARE v_cantidadComprada INT;
  DECLARE v_cantidadDevuelta INT;
  DECLARE v_cantidadPendiente INT;
  DECLARE v_costoUnitario DECIMAL(10,2);
  DECLARE v_subtotal DECIMAL(10,2);
  DECLARE v_motivoDetalle VARCHAR(120);
  DECLARE v_observacionesDetalle VARCHAR(255);
  DECLARE v_stockAntes BIGINT;
  DECLARE v_stockDespues BIGINT;
  DECLARE v_idDevDetalle BIGINT UNSIGNED;
  DECLARE v_totalDevolucion DECIMAL(10,2) DEFAULT 0.00;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SET p_idDevolucionProveedor = NULL;
  SET p_folio = NULL;
  SET v_tipoCompensacion = UPPER(TRIM(COALESCE(p_tipoCompensacion, 'SIN_COMPENSACION')));
  SET v_motivo = UPPER(TRIM(COALESCE(p_motivo, 'OTRO')));
  SET v_idProveedorFinal = p_idProveedor;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede registrar devoluciones a proveedores.';
  END IF;

  IF v_tipoCompensacion NOT IN ('EFECTIVO','ELECTRONICO','NOTA_CREDITO','REPOSICION_PRODUCTO','SIN_COMPENSACION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de compensaciÃ³n invÃ¡lido.';
  END IF;

  IF v_motivo NOT IN ('PRODUCTO_DANADO','CADUCADO','ERROR_COMPRA','EXCEDENTE','CAMBIO_PRECIO','OTRO') THEN
    SET v_motivo = 'OTRO';
  END IF;

  SET v_idCorte = `fn_obtener_corte_abierto`();

  IF v_idCorte IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay corte abierto para registrar la devoluciÃ³n a proveedor.';
  END IF;

  SELECT `estado`
    INTO v_estadoCorte
  FROM `corte_caja`
  WHERE `idCorte` = v_idCorte
  FOR UPDATE;

  IF v_estadoCorte <> 'ABIERTO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El corte actual no estÃ¡ abierto.';
  END IF;

  IF p_idCompra IS NOT NULL THEN
    SELECT COUNT(*) INTO v_compraExiste
    FROM `compra`
    WHERE `idCompra` = p_idCompra
      AND `estatus` = 'REGISTRADA';

    IF v_compraExiste = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Compra inexistente o cancelada.';
    END IF;

    SELECT COALESCE(`idProveedor`, v_idProveedorFinal)
      INTO v_idProveedorFinal
    FROM `compra`
    WHERE `idCompra` = p_idCompra
    FOR UPDATE;
  END IF;

  IF v_idProveedorFinal IS NOT NULL THEN
    SELECT COUNT(*) INTO v_proveedorExiste
    FROM `proveedor`
    WHERE `idProveedor` = v_idProveedorFinal
      AND `activo` = 1;

    IF v_proveedorExiste = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proveedor inexistente o inactivo.';
    END IF;
  END IF;

  IF p_detalles_json IS NULL OR JSON_VALID(p_detalles_json) = 0
     OR JSON_LENGTH(p_detalles_json) IS NULL OR JSON_LENGTH(p_detalles_json) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La devoluciÃ³n a proveedor debe incluir al menos un detalle en JSON vÃ¡lido.';
  END IF;

  INSERT INTO `devolucion_proveedor` (
    `folio`, `idCompra`, `idProveedor`, `idCorte`, `idUsuario`, `motivo`,
    `totalDevolucion`, `tipoCompensacion`, `observaciones`
  ) VALUES (
    NULL, p_idCompra, v_idProveedorFinal, v_idCorte, p_idUsuario, v_motivo,
    0.00, v_tipoCompensacion, p_observaciones
  );

  SET p_idDevolucionProveedor = LAST_INSERT_ID();
  SET p_folio = CONCAT('DP', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(p_idDevolucionProveedor, 6, '0'));

  UPDATE `devolucion_proveedor`
  SET `folio` = p_folio
  WHERE `idDevolucionProveedor` = p_idDevolucionProveedor;

  SET v_len = JSON_LENGTH(p_detalles_json);

  WHILE v_idx < v_len DO
    SET v_idCompraDetalle = CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].idCompraDetalle'))), 'null') AS UNSIGNED);
    SET v_idInventario = CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].idInventario'))), 'null') AS UNSIGNED);
    SET v_cantidad = CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].cantidad'))), 'null') AS SIGNED);
    SET v_motivoDetalle = NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].motivoDetalle'))), 'null');
    SET v_observacionesDetalle = NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].observaciones'))), 'null');

    IF v_cantidad IS NULL OR v_cantidad <= 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cantidad invÃ¡lida en devoluciÃ³n a proveedor.';
    END IF;

    SET v_idCompraDetalleCompra = NULL;
    SET v_idInventarioCompra = NULL;
    SET v_cantidadComprada = NULL;
    SET v_cantidadDevuelta = 0;
    SET v_cantidadPendiente = NULL;
    SET v_costoUnitario = NULL;
    SET v_stockAntes = NULL;
    SET v_stockDespues = NULL;

    IF v_idCompraDetalle IS NOT NULL THEN
      SELECT `idCompra`, `idInventario`, `cantidad`, `costoUnitario`
        INTO v_idCompraDetalleCompra, v_idInventarioCompra, v_cantidadComprada, v_costoUnitario
      FROM `compra_detalle`
      WHERE `idCompraDetalle` = v_idCompraDetalle
      FOR UPDATE;

      IF v_idCompraDetalleCompra IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Detalle de compra inexistente.';
      END IF;

      IF p_idCompra IS NOT NULL AND v_idCompraDetalleCompra <> p_idCompra THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El detalle de compra no pertenece a la compra indicada.';
      END IF;

      IF v_idInventario IS NULL THEN
        SET v_idInventario = v_idInventarioCompra;
      ELSEIF v_idInventarioCompra IS NOT NULL AND v_idInventario <> v_idInventarioCompra THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El inventario no coincide con el detalle de compra.';
      END IF;

      SELECT COALESCE(SUM(dpd.`cantidad`), 0)
        INTO v_cantidadDevuelta
      FROM `devolucion_proveedor_detalle` dpd
      INNER JOIN `devolucion_proveedor` dp
        ON dp.`idDevolucionProveedor` = dpd.`idDevolucionProveedor`
      WHERE dpd.`idCompraDetalle` = v_idCompraDetalle
        AND dp.`estatus` = 'REGISTRADA';

      SET v_cantidadPendiente = v_cantidadComprada - v_cantidadDevuelta;

      IF v_cantidad > v_cantidadPendiente THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad a devolver supera lo pendiente de ese detalle de compra.';
      END IF;
    END IF;

    IF v_idInventario IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Debe indicar idInventario si no indica idCompraDetalle.';
    END IF;

    IF v_idCompraDetalle IS NULL THEN
      SELECT `costoUnitario`
        INTO v_costoUnitario
      FROM `inventario_producto`
      WHERE `idInventario` = v_idInventario
      FOR UPDATE;

      IF v_costoUnitario IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inventario inexistente.';
      END IF;
    END IF;

    SELECT `stockActual`
      INTO v_stockAntes
    FROM `inventario_producto`
    WHERE `idInventario` = v_idInventario
    FOR UPDATE;

    IF v_stockAntes IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inventario inexistente.';
    END IF;

    IF v_stockAntes < v_cantidad THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para devolver al proveedor.';
    END IF;

    SET v_stockDespues = v_stockAntes - v_cantidad;
    SET v_subtotal = ROUND(v_cantidad * v_costoUnitario, 2);

    INSERT INTO `devolucion_proveedor_detalle` (
      `idDevolucionProveedor`, `idCompraDetalle`, `idInventario`, `cantidad`,
      `costoUnitario`, `subtotal`, `motivoDetalle`, `observaciones`
    ) VALUES (
      p_idDevolucionProveedor, v_idCompraDetalle, v_idInventario, v_cantidad,
      v_costoUnitario, v_subtotal, v_motivoDetalle, v_observacionesDetalle
    );

    SET v_idDevDetalle = LAST_INSERT_ID();

    UPDATE `inventario_producto`
    SET `stockActual` = v_stockDespues
    WHERE `idInventario` = v_idInventario;

    INSERT INTO `movimiento_inventario` (
      `idUsuario`, `idInventario`, `tipo`, `motivo`, `cantidad`, `stockAntes`,
      `stockDespues`, `idCompraDetalle`, `idDevolucionProveedorDetalle`, `observaciones`
    ) VALUES (
      p_idUsuario, v_idInventario, 'SALIDA', 'DEVOLUCION_PROVEEDOR', v_cantidad,
      v_stockAntes, v_stockDespues, v_idCompraDetalle, v_idDevDetalle,
      CONCAT('DevoluciÃ³n a proveedor ', p_folio)
    );

    SET v_totalDevolucion = ROUND(v_totalDevolucion + v_subtotal, 2);
    SET v_idx = v_idx + 1;
  END WHILE;

  UPDATE `devolucion_proveedor`
  SET `totalDevolucion` = v_totalDevolucion
  WHERE `idDevolucionProveedor` = p_idDevolucionProveedor;

  IF v_totalDevolucion > 0 AND v_tipoCompensacion IN ('EFECTIVO','ELECTRONICO') THEN
    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`,
      `idCompra`, `idDevolucionProveedor`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, v_tipoCompensacion, 'ENTRADA', 'DEVOLUCION_PROVEEDOR',
      v_totalDevolucion, p_idCompra, p_idDevolucionProveedor,
      CONCAT('CompensaciÃ³n por devoluciÃ³n a proveedor ', p_folio)
    );
  END IF;

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_movimiento_caja` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_movimiento_caja`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_medio VARCHAR(20),
  IN p_tipo VARCHAR(20),
  IN p_concepto VARCHAR(30),
  IN p_monto DECIMAL(10,2),
  IN p_idCompra BIGINT UNSIGNED,
  IN p_observaciones VARCHAR(255),
  OUT p_idMovDin BIGINT UNSIGNED
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_idCorte BIGINT UNSIGNED;
  DECLARE v_medio VARCHAR(20);
  DECLARE v_tipo VARCHAR(20);
  DECLARE v_concepto VARCHAR(30);
  DECLARE v_compraExiste INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede registrar movimientos manuales de caja.';
  END IF;

  SET v_idCorte = `fn_obtener_corte_abierto`();

  IF v_idCorte IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay corte abierto para registrar movimiento de caja.';
  END IF;

  SELECT `idCorte`
    INTO v_idCorte
  FROM `corte_caja`
  WHERE `idCorte` = v_idCorte AND `estado` = 'ABIERTO'
  FOR UPDATE;

  SET v_medio = UPPER(TRIM(p_medio));
  SET v_tipo = UPPER(TRIM(p_tipo));
  SET v_concepto = UPPER(TRIM(p_concepto));

  IF v_medio NOT IN ('EFECTIVO', 'ELECTRONICO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medio invÃ¡lido. Use EFECTIVO o ELECTRONICO.';
  END IF;

  IF v_tipo NOT IN ('ENTRADA', 'SALIDA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo invÃ¡lido. Use ENTRADA o SALIDA.';
  END IF;

  IF v_concepto NOT IN ('VENTA_PRODUCTO','SERVICIO_YASTAS','COMPRA_MERCANCIA','DEPOSITO_YASTAS','RETIRO_CAJA','AJUSTE','CANCELACION','APERTURA','OTRO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Concepto de movimiento invÃ¡lido.';
  END IF;

  IF p_monto IS NULL OR p_monto <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto del movimiento debe ser mayor que cero.';
  END IF;

  IF p_idCompra IS NOT NULL THEN
    SELECT COUNT(*)
      INTO v_compraExiste
    FROM `compra`
    WHERE `idCompra` = p_idCompra;

    IF v_compraExiste = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La compra relacionada no existe.';
    END IF;
  END IF;

  IF v_tipo = 'SALIDA' AND `fn_saldo_corte`(v_idCorte, v_medio) < p_monto THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo insuficiente para registrar la salida de dinero.';
  END IF;

  INSERT INTO `movimiento_dinero` (
    `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idCompra`, `observaciones`
  ) VALUES (
    v_idCorte, p_idUsuario, v_medio, v_tipo, v_concepto, p_monto, p_idCompra, p_observaciones
  );

  SET p_idMovDin = LAST_INSERT_ID();

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_servicio_yastas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_servicio_yastas`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_idTarifa BIGINT UNSIGNED,
  IN p_montoServicio DECIMAL(10,2),
  IN p_referenciaOperacion VARCHAR(120),
  IN p_observaciones VARCHAR(255),
  OUT p_idServicioOperacion BIGINT UNSIGNED
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_idCorte BIGINT UNSIGNED;
  DECLARE v_tipoServicio VARCHAR(30);
  DECLARE v_nombreServicio VARCHAR(120);
  DECLARE v_montoBase DECIMAL(10,2);
  DECLARE v_comisionCliente DECIMAL(10,2);
  DECLARE v_comisionYastas DECIMAL(10,2);
  DECLARE v_regaliaYastas DECIMAL(10,2);
  DECLARE v_gananciaFarmacia DECIMAL(10,2);
  DECLARE v_montoServicio DECIMAL(10,2);
  DECLARE v_totalCobradoCliente DECIMAL(10,2);
  DECLARE v_salidaElectronico DECIMAL(10,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol <> 'JEFE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo un usuario JEFE puede registrar servicios Yastas.';
  END IF;

  SET v_idCorte = `fn_obtener_corte_abierto`();

  IF v_idCorte IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay corte abierto para registrar el servicio.';
  END IF;

  SELECT `idCorte`
    INTO v_idCorte
  FROM `corte_caja`
  WHERE `idCorte` = v_idCorte AND `estado` = 'ABIERTO'
  FOR UPDATE;

  SELECT `tipoServicio`, `nombreServicio`, `montoBase`, `comisionCliente`,
         `comisionYastas`, `regaliaYastas`, `gananciaFarmacia`
    INTO v_tipoServicio, v_nombreServicio, v_montoBase, v_comisionCliente,
         v_comisionYastas, v_regaliaYastas, v_gananciaFarmacia
  FROM `tarifa_servicio`
  WHERE `idTarifa` = p_idTarifa
    AND `activo` = 1
  FOR UPDATE;

  IF v_tipoServicio IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tarifa de servicio inexistente o inactiva.';
  END IF;

  IF p_montoServicio IS NULL OR p_montoServicio <= 0 THEN
    SET v_montoServicio = v_montoBase;
  ELSE
    SET v_montoServicio = p_montoServicio;
  END IF;

  IF v_montoServicio IS NULL OR v_montoServicio <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto del servicio debe ser mayor que cero.';
  END IF;

  SET v_totalCobradoCliente = ROUND(v_montoServicio + v_comisionCliente, 2);

  INSERT INTO `servicio_operacion` (
    `idUsuario`, `idCorte`, `idTarifa`, `tipoServicio`, `nombreServicio`, `referenciaOperacion`,
    `montoServicio`, `comisionCliente`, `comisionYastas`, `regaliaYastas`, `gananciaFarmacia`,
    `totalCobradoCliente`, `observaciones`
  ) VALUES (
    p_idUsuario, v_idCorte, p_idTarifa, v_tipoServicio, v_nombreServicio, p_referenciaOperacion,
    v_montoServicio, v_comisionCliente, v_comisionYastas, v_regaliaYastas, v_gananciaFarmacia,
    v_totalCobradoCliente, p_observaciones
  );

  SET p_idServicioOperacion = LAST_INSERT_ID();

  IF v_tipoServicio = 'RETIRO' THEN
    IF `fn_saldo_corte`(v_idCorte, 'EFECTIVO') < v_montoServicio THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo efectivo insuficiente para realizar el retiro.';
    END IF;

    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idServicioOperacion`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, 'EFECTIVO', 'SALIDA', 'SERVICIO_YASTAS',
      v_montoServicio, p_idServicioOperacion, CONCAT('Retiro Yastas ', p_idServicioOperacion)
    );

    IF v_comisionCliente > 0 THEN
      INSERT INTO `movimiento_dinero` (
        `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idServicioOperacion`, `observaciones`
      ) VALUES (
        v_idCorte, p_idUsuario, 'EFECTIVO', 'ENTRADA', 'SERVICIO_YASTAS',
        v_comisionCliente, p_idServicioOperacion, CONCAT('ComisiÃ³n cliente retiro Yastas ', p_idServicioOperacion)
      );
    END IF;

    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idServicioOperacion`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, 'ELECTRONICO', 'ENTRADA', 'SERVICIO_YASTAS',
      ROUND(v_montoServicio + v_regaliaYastas, 2), p_idServicioOperacion,
      CONCAT('Entrada electrÃ³nica por retiro Yastas ', p_idServicioOperacion)
    );
  ELSE
    SET v_salidaElectronico = ROUND(v_montoServicio + v_comisionYastas, 2);

    IF `fn_saldo_corte`(v_idCorte, 'ELECTRONICO') < v_salidaElectronico THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo electrÃ³nico insuficiente para realizar el servicio Yastas.';
    END IF;

    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idServicioOperacion`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, 'ELECTRONICO', 'SALIDA', 'SERVICIO_YASTAS',
      v_salidaElectronico, p_idServicioOperacion, CONCAT('Salida electrÃ³nica servicio Yastas ', p_idServicioOperacion)
    );

    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idServicioOperacion`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, 'EFECTIVO', 'ENTRADA', 'SERVICIO_YASTAS',
      v_totalCobradoCliente, p_idServicioOperacion, CONCAT('Cobro efectivo servicio Yastas ', p_idServicioOperacion)
    );

    IF v_regaliaYastas > 0 THEN
      INSERT INTO `movimiento_dinero` (
        `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idServicioOperacion`, `observaciones`
      ) VALUES (
        v_idCorte, p_idUsuario, 'ELECTRONICO', 'ENTRADA', 'SERVICIO_YASTAS',
        v_regaliaYastas, p_idServicioOperacion, CONCAT('RegalÃ­a Yastas ', p_idServicioOperacion)
      );
    END IF;
  END IF;

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_venta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_venta`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_descuentoGeneral DECIMAL(10,2),
  IN p_montoRecibido DECIMAL(10,2),
  IN p_observaciones VARCHAR(255),
  IN p_detalles_json LONGTEXT,
  IN p_pagos_json LONGTEXT,
  OUT p_idVenta BIGINT UNSIGNED,
  OUT p_folio VARCHAR(40)
)
BEGIN
  DECLARE v_rol VARCHAR(20);
  DECLARE v_activo TINYINT(1);
  DECLARE v_idCorte BIGINT UNSIGNED;
  DECLARE v_len INT DEFAULT 0;
  DECLARE v_idx INT DEFAULT 0;
  DECLARE v_idInventario BIGINT UNSIGNED;
  DECLARE v_idProducto BIGINT UNSIGNED;
  DECLARE v_cantidad INT;
  DECLARE v_descuentoLinea DECIMAL(10,2);
  DECLARE v_precioUnitario DECIMAL(10,2);
  DECLARE v_costoUnitario DECIMAL(10,2);
  DECLARE v_stockAntes BIGINT;
  DECLARE v_stockDespues BIGINT;
  DECLARE v_fechaCaducidad DATE;
  DECLARE v_productoActivo TINYINT(1);
  DECLARE v_inventarioActivo TINYINT(1);
  DECLARE v_subtotalLinea DECIMAL(10,2);
  DECLARE v_subtotalVenta DECIMAL(10,2) DEFAULT 0.00;
  DECLARE v_totalVenta DECIMAL(10,2) DEFAULT 0.00;
  DECLARE v_idVentaDetalle BIGINT UNSIGNED;
  DECLARE v_pagosLen INT DEFAULT 0;
  DECLARE v_pagoIdx INT DEFAULT 0;
  DECLARE v_medioPago VARCHAR(20);
  DECLARE v_medioDinero VARCHAR(20);
  DECLARE v_montoPago DECIMAL(10,2);
  DECLARE v_referencia VARCHAR(100);
  DECLARE v_totalPagado DECIMAL(10,2) DEFAULT 0.00;
  DECLARE v_idPagoVenta BIGINT UNSIGNED;
  DECLARE v_montoRecibidoFinal DECIMAL(10,2);
  DECLARE v_cambio DECIMAL(10,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  SELECT `rol`, `activo`
    INTO v_rol, v_activo
  FROM `usuario`
  WHERE `idUsuario` = p_idUsuario
  FOR UPDATE;

  IF v_rol IS NULL OR v_activo <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario inexistente o inactivo.';
  END IF;

  IF v_rol NOT IN ('JEFE', 'EMPLEADO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no tiene permiso para vender.';
  END IF;

  IF p_descuentoGeneral IS NULL OR p_descuentoGeneral < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El descuento general no puede ser negativo.';
  END IF;

  SET v_idCorte = `fn_obtener_corte_abierto`();

  IF v_idCorte IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay corte abierto para registrar la venta.';
  END IF;

  SELECT `idCorte`
    INTO v_idCorte
  FROM `corte_caja`
  WHERE `idCorte` = v_idCorte AND `estado` = 'ABIERTO'
  FOR UPDATE;

  IF p_detalles_json IS NULL OR JSON_VALID(p_detalles_json) = 0 OR JSON_LENGTH(p_detalles_json) IS NULL OR JSON_LENGTH(p_detalles_json) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta debe incluir al menos un detalle en JSON vÃ¡lido.';
  END IF;

  IF p_pagos_json IS NULL OR JSON_VALID(p_pagos_json) = 0 OR JSON_LENGTH(p_pagos_json) IS NULL OR JSON_LENGTH(p_pagos_json) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La venta debe incluir al menos un pago en JSON vÃ¡lido.';
  END IF;

  INSERT INTO `venta` (
    `folio`, `idUsuario`, `idCorte`, `subtotal`, `descuento`, `total`, `observaciones`
  ) VALUES (
    NULL, p_idUsuario, v_idCorte, 0.00, p_descuentoGeneral, 0.00, p_observaciones
  );

  SET p_idVenta = LAST_INSERT_ID();
  SET p_folio = CONCAT('V', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(p_idVenta, 6, '0'));

  UPDATE `venta`
  SET `folio` = p_folio
  WHERE `idVenta` = p_idVenta;

  SET v_len = JSON_LENGTH(p_detalles_json);

  WHILE v_idx < v_len DO
    SET v_idInventario = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].idInventario'))) AS UNSIGNED);
    SET v_cantidad = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].cantidad'))) AS SIGNED);
    SET v_descuentoLinea = COALESCE(CAST(JSON_UNQUOTE(JSON_EXTRACT(p_detalles_json, CONCAT('$[', v_idx, '].descuento'))) AS DECIMAL(10,2)), 0.00);

    IF v_idInventario IS NULL OR v_cantidad IS NULL OR v_cantidad <= 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Detalle de venta invÃ¡lido.';
    END IF;

    IF v_descuentoLinea < 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El descuento de lÃ­nea no puede ser negativo.';
    END IF;

    SET v_idProducto = NULL;

    SELECT i.`idProducto`, i.`stockActual`, i.`precioVenta`, i.`costoUnitario`, i.`fechaCaducidad`,
           i.`activo`, p.`activo`
      INTO v_idProducto, v_stockAntes, v_precioUnitario, v_costoUnitario, v_fechaCaducidad,
           v_inventarioActivo, v_productoActivo
    FROM `inventario_producto` i
    INNER JOIN `producto` p ON p.`idProducto` = i.`idProducto`
    WHERE i.`idInventario` = v_idInventario
    FOR UPDATE;

    IF v_idProducto IS NULL OR v_productoActivo <> 1 OR v_inventarioActivo <> 1 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Producto o inventario inexistente/inactivo.';
    END IF;

    IF v_fechaCaducidad IS NOT NULL AND v_fechaCaducidad < CURDATE() THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede vender producto caducado.';
    END IF;

    IF v_stockAntes < v_cantidad THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para la venta.';
    END IF;

    SET v_subtotalLinea = ROUND((v_cantidad * v_precioUnitario) - v_descuentoLinea, 2);

    IF v_subtotalLinea < 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El descuento de lÃ­nea no puede ser mayor al importe de la lÃ­nea.';
    END IF;

    SET v_stockDespues = v_stockAntes - v_cantidad;

    INSERT INTO `venta_detalle` (
      `idVenta`, `idInventario`, `cantidad`, `precioUnitario`, `costoUnitario`, `descuento`, `subtotal`
    ) VALUES (
      p_idVenta, v_idInventario, v_cantidad, v_precioUnitario, v_costoUnitario, v_descuentoLinea, v_subtotalLinea
    );

    SET v_idVentaDetalle = LAST_INSERT_ID();

    UPDATE `inventario_producto`
    SET `stockActual` = v_stockDespues
    WHERE `idInventario` = v_idInventario;

    INSERT INTO `movimiento_inventario` (
      `idUsuario`, `idInventario`, `tipo`, `motivo`, `cantidad`, `stockAntes`,
      `stockDespues`, `idVentaDetalle`, `observaciones`
    ) VALUES (
      p_idUsuario, v_idInventario, 'SALIDA', 'VENTA', v_cantidad, v_stockAntes,
      v_stockDespues, v_idVentaDetalle, CONCAT('Venta ', p_folio)
    );

    SET v_subtotalVenta = ROUND(v_subtotalVenta + v_subtotalLinea, 2);
    SET v_idx = v_idx + 1;
  END WHILE;

  IF p_descuentoGeneral > v_subtotalVenta THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El descuento general no puede ser mayor al subtotal de la venta.';
  END IF;

  SET v_totalVenta = ROUND(v_subtotalVenta - p_descuentoGeneral, 2);

  SET v_pagosLen = JSON_LENGTH(p_pagos_json);

  WHILE v_pagoIdx < v_pagosLen DO
    SET v_medioPago = UPPER(TRIM(JSON_UNQUOTE(JSON_EXTRACT(p_pagos_json, CONCAT('$[', v_pagoIdx, '].medio')))));
    SET v_montoPago = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_pagos_json, CONCAT('$[', v_pagoIdx, '].monto'))) AS DECIMAL(10,2));
    SET v_referencia = NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p_pagos_json, CONCAT('$[', v_pagoIdx, '].referencia'))), 'null');

    IF v_medioPago NOT IN ('EFECTIVO', 'ELECTRONICO', 'TARJETA', 'TRANSFERENCIA', 'OTRO') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medio de pago invÃ¡lido.';
    END IF;

    IF v_montoPago IS NULL OR v_montoPago <= 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Monto de pago invÃ¡lido.';
    END IF;

    INSERT INTO `pago_venta` (`idVenta`, `medio`, `monto`, `referencia`)
    VALUES (p_idVenta, v_medioPago, v_montoPago, v_referencia);

    SET v_idPagoVenta = LAST_INSERT_ID();
    SET v_medioDinero = CASE WHEN v_medioPago = 'EFECTIVO' THEN 'EFECTIVO' ELSE 'ELECTRONICO' END;

    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idVenta`, `idPagoVenta`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, v_medioDinero, 'ENTRADA', 'VENTA_PRODUCTO',
      v_montoPago, p_idVenta, v_idPagoVenta, CONCAT('Pago de venta ', p_folio)
    );

    SET v_totalPagado = ROUND(v_totalPagado + v_montoPago, 2);
    SET v_pagoIdx = v_pagoIdx + 1;
  END WHILE;

  IF ABS(v_totalPagado - v_totalVenta) > 0.009 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La suma de pagos debe ser igual al total de la venta.';
  END IF;

  IF p_montoRecibido IS NULL THEN
    SET v_montoRecibidoFinal = v_totalVenta;
  ELSE
    SET v_montoRecibidoFinal = p_montoRecibido;
  END IF;

  IF v_montoRecibidoFinal < v_totalVenta THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto recibido no puede ser menor al total de la venta.';
  END IF;

  SET v_cambio = ROUND(v_montoRecibidoFinal - v_totalVenta, 2);

  UPDATE `venta`
  SET
    `subtotal` = v_subtotalVenta,
    `descuento` = p_descuentoGeneral,
    `total` = v_totalVenta,
    `montoRecibido` = v_montoRecibidoFinal,
    `cambio` = v_cambio
  WHERE `idVenta` = p_idVenta;

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

USE `farmacia_angeles_v2`;
/*!50001 DROP VIEW IF EXISTS `vw_corte_resumen`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_corte_resumen` AS select `c`.`idCorte` AS `idCorte`,`c`.`fechaApertura` AS `fechaApertura`,`c`.`fechaCierre` AS `fechaCierre`,`c`.`estado` AS `estado`,`c`.`efectivoInicial` AS `efectivoInicial`,`c`.`electronicoInicial` AS `electronicoInicial`,`c`.`efectivoContado` AS `efectivoContado`,`c`.`electronicoContado` AS `electronicoContado`,`c`.`usuarioAbre` AS `usuarioAbre`,`c`.`usuarioCierra` AS `usuarioCierra`,`c`.`efectivoInicial` + coalesce(sum(case when `m`.`medio` = 'EFECTIVO' and `m`.`tipo` = 'ENTRADA' then `m`.`monto` when `m`.`medio` = 'EFECTIVO' and `m`.`tipo` = 'SALIDA' then -`m`.`monto` else 0 end),0) AS `efectivoSistema`,`c`.`electronicoInicial` + coalesce(sum(case when `m`.`medio` = 'ELECTRONICO' and `m`.`tipo` = 'ENTRADA' then `m`.`monto` when `m`.`medio` = 'ELECTRONICO' and `m`.`tipo` = 'SALIDA' then -`m`.`monto` else 0 end),0) AS `electronicoSistema`,case when `c`.`efectivoContado` is null then NULL else `c`.`efectivoContado` - (`c`.`efectivoInicial` + coalesce(sum(case when `m`.`medio` = 'EFECTIVO' and `m`.`tipo` = 'ENTRADA' then `m`.`monto` when `m`.`medio` = 'EFECTIVO' and `m`.`tipo` = 'SALIDA' then -`m`.`monto` else 0 end),0)) end AS `diferenciaEfectivoCalculada`,case when `c`.`electronicoContado` is null then NULL else `c`.`electronicoContado` - (`c`.`electronicoInicial` + coalesce(sum(case when `m`.`medio` = 'ELECTRONICO' and `m`.`tipo` = 'ENTRADA' then `m`.`monto` when `m`.`medio` = 'ELECTRONICO' and `m`.`tipo` = 'SALIDA' then -`m`.`monto` else 0 end),0)) end AS `diferenciaElectronicoCalculada` from (`corte_caja` `c` left join `movimiento_dinero` `m` on(`m`.`idCorte` = `c`.`idCorte`)) group by `c`.`idCorte`,`c`.`fechaApertura`,`c`.`fechaCierre`,`c`.`estado`,`c`.`efectivoInicial`,`c`.`electronicoInicial`,`c`.`efectivoContado`,`c`.`electronicoContado`,`c`.`usuarioAbre`,`c`.`usuarioCierra` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `vw_inventario_actual`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_inventario_actual` AS select `p`.`idProducto` AS `idProducto`,`p`.`codigoBarras` AS `codigoBarras`,`p`.`nombre` AS `nombre`,`p`.`tipo` AS `tipo`,`p`.`categoria` AS `categoria`,`p`.`manejaCaducidad` AS `manejaCaducidad`,`i`.`idInventario` AS `idInventario`,`i`.`codigoLote` AS `codigoLote`,`i`.`fechaLlegada` AS `fechaLlegada`,`i`.`fechaCaducidad` AS `fechaCaducidad`,`i`.`stockInicial` AS `stockInicial`,`i`.`stockActual` AS `stockActual`,`i`.`costoUnitario` AS `costoUnitario`,`i`.`precioVenta` AS `precioVenta`,`i`.`ubicacionLetra` AS `ubicacionLetra`,`i`.`ubicacionNumero` AS `ubicacionNumero`,case when `i`.`ubicacionLetra` is null or `i`.`ubicacionNumero` is null then NULL else concat(`i`.`ubicacionLetra`,`i`.`ubicacionNumero`) end AS `ubicacionEstante`,`i`.`precioVenta` - `i`.`costoUnitario` AS `utilidadUnitariaEstimada`,`i`.`activo` AS `inventarioActivo`,`p`.`activo` AS `productoActivo` from (`inventario_producto` `i` join `producto` `p` on(`p`.`idProducto` = `i`.`idProducto`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `vw_inventario_disponible_para_venta`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_inventario_disponible_para_venta` AS select `vw_inventario_actual`.`idProducto` AS `idProducto`,`vw_inventario_actual`.`codigoBarras` AS `codigoBarras`,`vw_inventario_actual`.`nombre` AS `nombre`,`vw_inventario_actual`.`tipo` AS `tipo`,`vw_inventario_actual`.`categoria` AS `categoria`,`vw_inventario_actual`.`manejaCaducidad` AS `manejaCaducidad`,`vw_inventario_actual`.`idInventario` AS `idInventario`,`vw_inventario_actual`.`codigoLote` AS `codigoLote`,`vw_inventario_actual`.`fechaLlegada` AS `fechaLlegada`,`vw_inventario_actual`.`fechaCaducidad` AS `fechaCaducidad`,`vw_inventario_actual`.`stockInicial` AS `stockInicial`,`vw_inventario_actual`.`stockActual` AS `stockActual`,`vw_inventario_actual`.`costoUnitario` AS `costoUnitario`,`vw_inventario_actual`.`precioVenta` AS `precioVenta`,`vw_inventario_actual`.`ubicacionLetra` AS `ubicacionLetra`,`vw_inventario_actual`.`ubicacionNumero` AS `ubicacionNumero`,`vw_inventario_actual`.`ubicacionEstante` AS `ubicacionEstante`,`vw_inventario_actual`.`utilidadUnitariaEstimada` AS `utilidadUnitariaEstimada`,`vw_inventario_actual`.`inventarioActivo` AS `inventarioActivo`,`vw_inventario_actual`.`productoActivo` AS `productoActivo` from `vw_inventario_actual` where `vw_inventario_actual`.`productoActivo` = 1 and `vw_inventario_actual`.`inventarioActivo` = 1 and `vw_inventario_actual`.`stockActual` > 0 order by `vw_inventario_actual`.`nombre`,case when `vw_inventario_actual`.`fechaCaducidad` is null then 1 else 0 end,`vw_inventario_actual`.`fechaCaducidad`,`vw_inventario_actual`.`fechaLlegada` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `vw_productos_por_caducar`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_productos_por_caducar` AS select `vw_inventario_actual`.`idProducto` AS `idProducto`,`vw_inventario_actual`.`codigoBarras` AS `codigoBarras`,`vw_inventario_actual`.`nombre` AS `nombre`,`vw_inventario_actual`.`tipo` AS `tipo`,`vw_inventario_actual`.`categoria` AS `categoria`,`vw_inventario_actual`.`manejaCaducidad` AS `manejaCaducidad`,`vw_inventario_actual`.`idInventario` AS `idInventario`,`vw_inventario_actual`.`codigoLote` AS `codigoLote`,`vw_inventario_actual`.`fechaLlegada` AS `fechaLlegada`,`vw_inventario_actual`.`fechaCaducidad` AS `fechaCaducidad`,`vw_inventario_actual`.`stockInicial` AS `stockInicial`,`vw_inventario_actual`.`stockActual` AS `stockActual`,`vw_inventario_actual`.`costoUnitario` AS `costoUnitario`,`vw_inventario_actual`.`precioVenta` AS `precioVenta`,`vw_inventario_actual`.`ubicacionLetra` AS `ubicacionLetra`,`vw_inventario_actual`.`ubicacionNumero` AS `ubicacionNumero`,`vw_inventario_actual`.`ubicacionEstante` AS `ubicacionEstante`,`vw_inventario_actual`.`utilidadUnitariaEstimada` AS `utilidadUnitariaEstimada`,`vw_inventario_actual`.`inventarioActivo` AS `inventarioActivo`,`vw_inventario_actual`.`productoActivo` AS `productoActivo` from `vw_inventario_actual` where `vw_inventario_actual`.`fechaCaducidad` is not null and `vw_inventario_actual`.`stockActual` > 0 and `vw_inventario_actual`.`fechaCaducidad` <= curdate() + interval 90 day order by `vw_inventario_actual`.`fechaCaducidad`,`vw_inventario_actual`.`nombre` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `vw_utilidad_ventas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_utilidad_ventas` AS select `v`.`idVenta` AS `idVenta`,`v`.`folio` AS `folio`,`v`.`fecha` AS `fecha`,`v`.`idCorte` AS `idCorte`,`v`.`idUsuario` AS `idUsuario`,`v`.`estatus` AS `estatus`,sum(`vd`.`subtotal`) AS `subtotalProductos`,sum(`vd`.`cantidad` * `vd`.`costoUnitario`) AS `costoProductos`,sum(`vd`.`subtotal` - `vd`.`cantidad` * `vd`.`costoUnitario`) AS `utilidadProductos` from (`venta` `v` join `venta_detalle` `vd` on(`vd`.`idVenta` = `v`.`idVenta`)) group by `v`.`idVenta`,`v`.`folio`,`v`.`fecha`,`v`.`idCorte`,`v`.`idUsuario`,`v`.`estatus` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;



-- Datos minimos para iniciar la aplicacion por primera vez.
-- Usuario: admin
-- Password: 1234
INSERT INTO `usuario` (`nombre`, `username`, `telefono`, `password_hash`, `rol`, `activo`)
VALUES ('Administrador', 'admin', NULL, '$2b$12$RZf9LgXup3M6iz/hAg00mevLycVt3sjfzVSCYcLWIRI7N1YRETkny', 'JEFE', 1);
