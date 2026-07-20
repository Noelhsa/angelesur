ALTER TABLE `inventario_producto`
  ADD COLUMN IF NOT EXISTS `ubicacionLetra` CHAR(1) NULL AFTER `observaciones`;

ALTER TABLE `inventario_producto`
  ADD COLUMN IF NOT EXISTS `ubicacionNumero` SMALLINT UNSIGNED NULL AFTER `ubicacionLetra`;

ALTER TABLE `inventario_producto`
  ADD INDEX IF NOT EXISTS `idx_inv_ubicacion` (`ubicacionLetra`, `ubicacionNumero`);

CREATE OR REPLACE VIEW `vw_inventario_actual` AS
SELECT
  p.`idProducto`,
  p.`codigoBarras`,
  p.`nombre`,
  p.`tipo`,
  p.`categoria`,
  p.`manejaCaducidad`,
  i.`idInventario`,
  i.`codigoLote`,
  i.`fechaLlegada`,
  i.`fechaCaducidad`,
  i.`stockInicial`,
  i.`stockActual`,
  i.`costoUnitario`,
  i.`precioVenta`,
  i.`ubicacionLetra`,
  i.`ubicacionNumero`,
  CASE
    WHEN i.`ubicacionLetra` IS NULL OR i.`ubicacionNumero` IS NULL THEN NULL
    ELSE CONCAT(i.`ubicacionLetra`, i.`ubicacionNumero`)
  END AS `ubicacionEstante`,
  (i.`precioVenta` - i.`costoUnitario`) AS `utilidadUnitariaEstimada`,
  i.`activo` AS `inventarioActivo`,
  p.`activo` AS `productoActivo`
FROM `inventario_producto` i
INNER JOIN `producto` p ON p.`idProducto` = i.`idProducto`;

CREATE OR REPLACE VIEW `vw_inventario_disponible_para_venta` AS
SELECT *
FROM `vw_inventario_actual`
WHERE `productoActivo` = 1
  AND `inventarioActivo` = 1
  AND `stockActual` > 0
ORDER BY
  `nombre`,
  CASE WHEN `fechaCaducidad` IS NULL THEN 1 ELSE 0 END,
  `fechaCaducidad`,
  `fechaLlegada`;

CREATE OR REPLACE VIEW `vw_productos_por_caducar` AS
SELECT *
FROM `vw_inventario_actual`
WHERE `fechaCaducidad` IS NOT NULL
  AND `stockActual` > 0
  AND `fechaCaducidad` <= DATE_ADD(CURDATE(), INTERVAL 90 DAY)
ORDER BY `fechaCaducidad`, `nombre`;
