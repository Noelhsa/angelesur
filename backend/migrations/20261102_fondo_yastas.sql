-- Requiere 20261102_descuento_electronico_yastas.sql. Aplicar con respaldo y app cerrada.
ALTER TABLE corte_caja ADD COLUMN IF NOT EXISTS fondoYastasInicial DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (fondoYastasInicial >= 0);
ALTER TABLE corte_caja ADD COLUMN IF NOT EXISTS porcentajeDescuentoFondo DECIMAL(5,2) NOT NULL DEFAULT 3.50 CHECK (porcentajeDescuentoFondo >= 0 AND porcentajeDescuentoFondo < 100);
ALTER TABLE servicio_operacion ADD COLUMN IF NOT EXISTS montoElectronicoPropio DECIMAL(10,2) NULL CHECK (montoElectronicoPropio >= 0);
ALTER TABLE servicio_operacion ADD COLUMN IF NOT EXISTS montoFondoYastas DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (montoFondoYastas >= 0);
ALTER TABLE servicio_operacion MODIFY COLUMN observaciones TEXT NULL;

DELIMITER ;;
CREATE OR REPLACE FUNCTION fn_fondo_yastas_disponible(p_corte BIGINT UNSIGNED)
RETURNS DECIMAL(10,2) READS SQL DATA
BEGIN
  DECLARE v_fondo DECIMAL(10,2);
  SELECT c.fondoYastasInicial - COALESCE((SELECT SUM(s.montoFondoYastas)
    FROM servicio_operacion s WHERE s.idCorte = c.idCorte AND s.estatus = 'REALIZADA'), 0)
  INTO v_fondo FROM corte_caja c WHERE c.idCorte = p_corte;
  RETURN v_fondo;
END
;;
CREATE OR REPLACE PROCEDURE `sp_abrir_corte_fondo`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_efectivoInicial DECIMAL(10,2),
  IN p_electronicoInicial DECIMAL(10,2),
  IN p_fondoYastas DECIMAL(10,2),
  IN p_porcentajeFondo DECIMAL(5,2),
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

  IF p_fondoYastas IS NULL OR p_fondoYastas < 0 OR p_porcentajeFondo IS NULL OR p_porcentajeFondo < 0 OR p_porcentajeFondo >= 100 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fondo o porcentaje de fondo invalido.';
  END IF;

  IF p_efectivoInicial < 0 OR p_electronicoInicial < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los montos iniciales no pueden ser negativos.';
  END IF;

  IF `fn_obtener_corte_abierto`() IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un corte abierto.';
  END IF;

  INSERT INTO `corte_caja` (
    `fondoYastasInicial`, `porcentajeDescuentoFondo`, `efectivoInicial`, `electronicoInicial`, `usuarioAbre`, `observaciones`
  ) VALUES (
    p_fondoYastas, p_porcentajeFondo, p_efectivoInicial, p_electronicoInicial, p_idUsuario, p_observaciones
  );

  SET p_idCorte = LAST_INSERT_ID();

  COMMIT;
END
;;
CREATE OR REPLACE PROCEDURE `sp_registrar_servicio_yastas_fondo`(
  IN p_idUsuario BIGINT UNSIGNED,
  IN p_idTarifa BIGINT UNSIGNED,
  IN p_montoServicio DECIMAL(10,2),
  IN p_referenciaOperacion VARCHAR(120),
  IN p_observaciones VARCHAR(255),
  IN p_porcentajeElegido DECIMAL(5,2),
  IN p_corteConfirmado BIGINT UNSIGNED,
  IN p_propioConfirmado DECIMAL(10,2),
  IN p_fondoConfirmado DECIMAL(10,2),
  IN p_salidaConfirmada DECIMAL(10,2),
  OUT p_idServicioOperacion BIGINT UNSIGNED
)
BEGIN
  DECLARE v_propio DECIMAL(10,2);
  DECLARE v_fondo DECIMAL(10,2);
  DECLARE v_usoPropio DECIMAL(10,2) DEFAULT 0;
  DECLARE v_usoFondo DECIMAL(10,2) DEFAULT 0;
  DECLARE v_porcentajeFondo DECIMAL(5,2);
  DECLARE v_nota TEXT;
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
  SET v_propio = fn_saldo_corte(v_idCorte, 'ELECTRONICO');
  SET v_fondo = fn_fondo_yastas_disponible(v_idCorte);
  SELECT porcentajeDescuentoFondo INTO v_porcentajeFondo FROM corte_caja WHERE idCorte = v_idCorte;
  IF p_corteConfirmado IS NOT NULL AND (p_corteConfirmado <> v_idCorte OR p_propioConfirmado IS NULL OR p_fondoConfirmado IS NULL OR p_propioConfirmado <> v_propio OR p_fondoConfirmado <> v_fondo) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los saldos cambiaron. Revisa nuevamente la operacion Yastas.';
  END IF;
  IF v_tipoServicio <> 'RETIRO' THEN
    SET v_salidaElectronico = v_montoServicio + v_comisionYastas - ROUND(v_montoServicio * v_porcentaje / 100, 2);
    IF v_porcentaje > 0 AND v_salidaElectronico > v_propio THEN
      IF v_propio > 0 THEN
        IF p_porcentajeElegido IS NULL OR p_corteConfirmado IS NULL THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La operacion usa ambos saldos. Selecciona el porcentaje y confirma.';
        END IF;
        IF p_porcentajeElegido <> v_porcentaje AND p_porcentajeElegido <> v_porcentajeFondo THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Selecciona el porcentaje normal o el del fondo.';
        END IF;
        SET v_porcentaje = p_porcentajeElegido;
      ELSE
        SET v_porcentaje = v_porcentajeFondo;
      END IF;
    END IF;
    SET v_salidaElectronico = v_montoServicio + v_comisionYastas - ROUND(v_montoServicio * v_porcentaje / 100, 2);
    IF p_salidaConfirmada IS NOT NULL AND p_salidaConfirmada <> v_salidaElectronico THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La tarifa cambio. Revisa nuevamente la operacion Yastas.';
    END IF;
    SET v_usoPropio = LEAST(v_propio, v_salidaElectronico);
    SET v_usoFondo = v_salidaElectronico - v_usoPropio;
    IF v_salidaElectronico <= 0 OR v_usoFondo > v_fondo THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo propio y fondo Yastas insuficientes.';
    END IF;
  END IF;
  SET v_nota = p_observaciones;
  IF v_usoFondo > 0 THEN
    SET v_nota = CONCAT(COALESCE(p_observaciones, ''),
      ' | Yastas: saldo propio $', v_usoPropio, '; fondo $', v_usoFondo,
      '; descuento ', v_porcentaje, '%',
      IF(v_usoPropio > 0 AND p_porcentajeElegido IS NOT NULL, ' elegido por el usuario.', '.'));
  END IF;
  SET v_descuento = ROUND(v_montoServicio * v_porcentaje / 100, 2);

  SET v_totalCobradoCliente = ROUND(v_montoServicio + v_comisionCliente, 2);

  INSERT INTO `servicio_operacion` (
    `idUsuario`, `idCorte`, `idTarifa`, `tipoServicio`, `nombreServicio`, `referenciaOperacion`,
    `montoServicio`, `comisionCliente`, `comisionYastas`, `regaliaYastas`, `gananciaFarmacia`,
    `montoElectronicoPropio`, `montoFondoYastas`, `totalCobradoCliente`, `observaciones`, `porcentajeDescuentoElectronico`, `descuentoElectronico`
  ) VALUES (
    p_idUsuario, v_idCorte, p_idTarifa, v_tipoServicio, v_nombreServicio, p_referenciaOperacion,
    v_montoServicio, v_comisionCliente, v_comisionYastas, v_regaliaYastas, v_gananciaFarmacia,
    v_usoPropio, v_usoFondo, v_totalCobradoCliente, v_nota, v_porcentaje, v_descuento
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

    IF `fn_saldo_corte`(v_idCorte, 'ELECTRONICO') < v_usoPropio THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo electrÃ³nico insuficiente para realizar el servicio Yastas.';
    END IF;

    IF v_usoPropio > 0 THEN
    INSERT INTO `movimiento_dinero` (
      `idCorte`, `idUsuario`, `medio`, `tipo`, `concepto`, `monto`, `idServicioOperacion`, `observaciones`
    ) VALUES (
      v_idCorte, p_idUsuario, 'ELECTRONICO', 'SALIDA', 'SERVICIO_YASTAS',
      v_usoPropio, p_idServicioOperacion, CONCAT('Salida electrónica servicio Yastas ', p_idServicioOperacion)
    );
    END IF;

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
END
;;
CREATE OR REPLACE PROCEDURE sp_registrar_servicio_yastas(
 IN p_usuario BIGINT UNSIGNED, IN p_tarifa BIGINT UNSIGNED, IN p_monto DECIMAL(10,2),
 IN p_referencia VARCHAR(120), IN p_observaciones VARCHAR(255), OUT p_operacion BIGINT UNSIGNED)
BEGIN
 CALL sp_registrar_servicio_yastas_fondo(p_usuario,p_tarifa,p_monto,p_referencia,p_observaciones,NULL,NULL,NULL,NULL,NULL,p_operacion);
END
;;
DELIMITER ;
