-- Aplicar sobre la base de Angelesur despues de realizar un respaldo.
-- Las presentaciones antiguas NO permiten deducir una via clinica segura.
-- Conservarlas en el respaldo y dejar la via pendiente (NULL) para su revision.
-- La presentacion del medicamento permanece intacta. Se puede ejecutar de nuevo.
ALTER TABLE `info_medicamento`
  MODIFY COLUMN `viaAdministracion` VARCHAR(80) NULL DEFAULT NULL;

UPDATE `info_medicamento`
SET `viaAdministracion` = NULL
WHERE `viaAdministracion` IS NOT NULL AND `viaAdministracion` NOT IN (
  'ORAL','SUBLINGUAL','RECTAL','INTRAVENOSA','INTRAMUSCULAR','SUBCUTANEA',
  'INTRADERMICA','TOPICA','INHALATORIA','OFTALMICA','OTICA','NASAL','VAGINAL'
);

ALTER TABLE `info_medicamento`
  MODIFY COLUMN `viaAdministracion` ENUM(
    'ORAL','SUBLINGUAL','RECTAL','INTRAVENOSA','INTRAMUSCULAR','SUBCUTANEA',
    'INTRADERMICA','TOPICA','INHALATORIA','OFTALMICA','OTICA','NASAL','VAGINAL'
  ) NULL DEFAULT NULL;
