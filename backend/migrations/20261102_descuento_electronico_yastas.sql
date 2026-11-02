-- Aplicar con la aplicacion cerrada y respaldo previo. No modifica tarifas ni operaciones existentes.
ALTER TABLE `tarifa_servicio` ADD COLUMN IF NOT EXISTS `porcentajeDescuentoElectronico` DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (`porcentajeDescuentoElectronico` >= 0 AND `porcentajeDescuentoElectronico` < 100);
ALTER TABLE `servicio_operacion` ADD COLUMN IF NOT EXISTS `porcentajeDescuentoElectronico` DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (`porcentajeDescuentoElectronico` >= 0 AND `porcentajeDescuentoElectronico` < 100);
ALTER TABLE `servicio_operacion` ADD COLUMN IF NOT EXISTS `descuentoElectronico` DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (`descuentoElectronico` >= 0);
DELIMITER ;;
CREATE OR REPLACE PROCEDURE `sp_registrar_servicio_yastas`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_idTarifa BIGINT UNSIGNED,
  IN p_montoServicio DECIMAL(10,2),
  IN p_referenciaOperacion VARCHAR(120),
  IN p_observaciones VARCHAR(255),
  OUT p_idServicioOperacion BIGINT UNSIGNED
)
BEGIN
  DECLARE v_porcentaje DECIMAL(5,2);
  DECLARE v_descuento DECIMAL(10,2);
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
         `comisionYastas`, `regaliaYastas`, `gananciaFarmacia`, `porcentajeDescuentoElectronico`
    INTO v_tipoServicio, v_nombreServicio, v_montoBase, v_comisionCliente,
         v_comisionYastas, v_regaliaYastas, v_gananciaFarmacia, v_porcentaje
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

  IF v_tipoServicio = 'RETIRO' AND v_porcentaje <> 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El descuento electronico no aplica a retiros.';
  END IF;
  SET v_descuento = ROUND(v_montoServicio * v_porcentaje / 100, 2);

  SET v_totalCobradoCliente = ROUND(v_montoServicio + v_comisionCliente, 2);

  INSERT INTO `servicio_operacion` (
    `idUsuario`, `idCorte`, `idTarifa`, `tipoServicio`, `nombreServicio`, `referenciaOperacion`,
    `montoServicio`, `comisionCliente`, `comisionYastas`, `regaliaYastas`, `gananciaFarmacia`,
    `totalCobradoCliente`, `observaciones`, `porcentajeDescuentoElectronico`, `descuentoElectronico`
  ) VALUES (
    p_idUsuario, v_idCorte, p_idTarifa, v_tipoServicio, v_nombreServicio, p_referenciaOperacion,
    v_montoServicio, v_comisionCliente, v_comisionYastas, v_regaliaYastas, v_gananciaFarmacia,
    v_totalCobradoCliente, p_observaciones, v_porcentaje, v_descuento
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
      CONCAT('Entrada electrónica por retiro Yastas ', p_idServicioOperacion)
    );
  ELSE
    SET v_salidaElectronico = ROUND(v_montoServicio + v_comisionYastas - v_descuento, 2);

    IF `fn_saldo_corte`(v_idCorte, 'ELECTRONICO') < v_salidaElectronico THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo electrÃ³nico insuficiente para realizar el servicio Yastas.';
    END IF;

    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idServicioOperacion`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, 'ELECTRONICO', 'SALIDA', 'SERVICIO_YASTAS',
      v_salidaElectronico, p_idServicioOperacion, CONCAT('Salida electrónica servicio Yastas ', p_idServicioOperacion)
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
