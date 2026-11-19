/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-16
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* 1. Contrato: deben existir 172 procedimientos, cuatro por cada una de las 43 tablas. */
DECLARE @Esperados TABLE(esquema SYSNAME, procedimiento SYSNAME, PRIMARY KEY(esquema,procedimiento));
INSERT INTO @Esperados(esquema,procedimiento) VALUES
    (N'mundial',N'sp_confederacion_Alta'),
    (N'mundial',N'sp_confederacion_Modificar'),
    (N'mundial',N'sp_confederacion_Baja'),
    (N'mundial',N'sp_confederacion_Consultar'),
    (N'mundial',N'sp_pais_Alta'),
    (N'mundial',N'sp_pais_Modificar'),
    (N'mundial',N'sp_pais_Baja'),
    (N'mundial',N'sp_pais_Consultar'),
    (N'mundial',N'sp_ciudad_Alta'),
    (N'mundial',N'sp_ciudad_Modificar'),
    (N'mundial',N'sp_ciudad_Baja'),
    (N'mundial',N'sp_ciudad_Consultar'),
    (N'mundial',N'sp_sede_estadio_Alta'),
    (N'mundial',N'sp_sede_estadio_Modificar'),
    (N'mundial',N'sp_sede_estadio_Baja'),
    (N'mundial',N'sp_sede_estadio_Consultar'),
    (N'mundial',N'sp_grupo_Alta'),
    (N'mundial',N'sp_grupo_Modificar'),
    (N'mundial',N'sp_grupo_Baja'),
    (N'mundial',N'sp_grupo_Consultar'),
    (N'mundial',N'sp_reglamento_sustitucion_Alta'),
    (N'mundial',N'sp_reglamento_sustitucion_Modificar'),
    (N'mundial',N'sp_reglamento_sustitucion_Baja'),
    (N'mundial',N'sp_reglamento_sustitucion_Consultar'),
    (N'mundial',N'sp_fase_Alta'),
    (N'mundial',N'sp_fase_Modificar'),
    (N'mundial',N'sp_fase_Baja'),
    (N'mundial',N'sp_fase_Consultar'),
    (N'mundial',N'sp_seleccion_Alta'),
    (N'mundial',N'sp_seleccion_Modificar'),
    (N'mundial',N'sp_seleccion_Baja'),
    (N'mundial',N'sp_seleccion_Consultar'),
    (N'mundial',N'sp_club_Alta'),
    (N'mundial',N'sp_club_Modificar'),
    (N'mundial',N'sp_club_Baja'),
    (N'mundial',N'sp_club_Consultar'),
    (N'mundial',N'sp_posicion_Alta'),
    (N'mundial',N'sp_posicion_Modificar'),
    (N'mundial',N'sp_posicion_Baja'),
    (N'mundial',N'sp_posicion_Consultar'),
    (N'mundial',N'sp_jugador_Alta'),
    (N'mundial',N'sp_jugador_Modificar'),
    (N'mundial',N'sp_jugador_Baja'),
    (N'mundial',N'sp_jugador_Consultar'),
    (N'mundial',N'sp_rol_cuerpo_tecnico_Alta'),
    (N'mundial',N'sp_rol_cuerpo_tecnico_Modificar'),
    (N'mundial',N'sp_rol_cuerpo_tecnico_Baja'),
    (N'mundial',N'sp_rol_cuerpo_tecnico_Consultar'),
    (N'mundial',N'sp_cuerpo_tecnico_Alta'),
    (N'mundial',N'sp_cuerpo_tecnico_Modificar'),
    (N'mundial',N'sp_cuerpo_tecnico_Baja'),
    (N'mundial',N'sp_cuerpo_tecnico_Consultar'),
    (N'mundial',N'sp_convocatoria_Alta'),
    (N'mundial',N'sp_convocatoria_Modificar'),
    (N'mundial',N'sp_convocatoria_Baja'),
    (N'mundial',N'sp_convocatoria_Consultar'),
    (N'mundial',N'sp_novedad_convocatoria_Alta'),
    (N'mundial',N'sp_novedad_convocatoria_Modificar'),
    (N'mundial',N'sp_novedad_convocatoria_Baja'),
    (N'mundial',N'sp_novedad_convocatoria_Consultar'),
    (N'mundial',N'sp_partido_Alta'),
    (N'mundial',N'sp_partido_Modificar'),
    (N'mundial',N'sp_partido_Baja'),
    (N'mundial',N'sp_partido_Consultar'),
    (N'mundial',N'sp_partido_equipo_detalle_Alta'),
    (N'mundial',N'sp_partido_equipo_detalle_Modificar'),
    (N'mundial',N'sp_partido_equipo_detalle_Baja'),
    (N'mundial',N'sp_partido_equipo_detalle_Consultar'),
    (N'mundial',N'sp_alineacion_partido_Alta'),
    (N'mundial',N'sp_alineacion_partido_Modificar'),
    (N'mundial',N'sp_alineacion_partido_Baja'),
    (N'mundial',N'sp_alineacion_partido_Consultar'),
    (N'mundial',N'sp_sustitucion_Alta'),
    (N'mundial',N'sp_sustitucion_Modificar'),
    (N'mundial',N'sp_sustitucion_Baja'),
    (N'mundial',N'sp_sustitucion_Consultar'),
    (N'mundial',N'sp_tipo_gol_Alta'),
    (N'mundial',N'sp_tipo_gol_Modificar'),
    (N'mundial',N'sp_tipo_gol_Baja'),
    (N'mundial',N'sp_tipo_gol_Consultar'),
    (N'mundial',N'sp_gol_Alta'),
    (N'mundial',N'sp_gol_Modificar'),
    (N'mundial',N'sp_gol_Baja'),
    (N'mundial',N'sp_gol_Consultar'),
    (N'mundial',N'sp_tipo_tarjeta_Alta'),
    (N'mundial',N'sp_tipo_tarjeta_Modificar'),
    (N'mundial',N'sp_tipo_tarjeta_Baja'),
    (N'mundial',N'sp_tipo_tarjeta_Consultar'),
    (N'mundial',N'sp_tarjeta_Alta'),
    (N'mundial',N'sp_tarjeta_Modificar'),
    (N'mundial',N'sp_tarjeta_Baja'),
    (N'mundial',N'sp_tarjeta_Consultar'),
    (N'mundial',N'sp_criterio_suspension_Alta'),
    (N'mundial',N'sp_criterio_suspension_Modificar'),
    (N'mundial',N'sp_criterio_suspension_Baja'),
    (N'mundial',N'sp_criterio_suspension_Consultar'),
    (N'mundial',N'sp_suspension_jugador_Alta'),
    (N'mundial',N'sp_suspension_jugador_Modificar'),
    (N'mundial',N'sp_suspension_jugador_Baja'),
    (N'mundial',N'sp_suspension_jugador_Consultar'),
    (N'mundial',N'sp_cumplimiento_suspension_Alta'),
    (N'mundial',N'sp_cumplimiento_suspension_Modificar'),
    (N'mundial',N'sp_cumplimiento_suspension_Baja'),
    (N'mundial',N'sp_cumplimiento_suspension_Consultar'),
    (N'mundial',N'sp_arbitro_Alta'),
    (N'mundial',N'sp_arbitro_Modificar'),
    (N'mundial',N'sp_arbitro_Baja'),
    (N'mundial',N'sp_arbitro_Consultar'),
    (N'mundial',N'sp_idioma_Alta'),
    (N'mundial',N'sp_idioma_Modificar'),
    (N'mundial',N'sp_idioma_Baja'),
    (N'mundial',N'sp_idioma_Consultar'),
    (N'mundial',N'sp_arbitro_idioma_Alta'),
    (N'mundial',N'sp_arbitro_idioma_Modificar'),
    (N'mundial',N'sp_arbitro_idioma_Baja'),
    (N'mundial',N'sp_arbitro_idioma_Consultar'),
    (N'mundial',N'sp_rol_arbitral_Alta'),
    (N'mundial',N'sp_rol_arbitral_Modificar'),
    (N'mundial',N'sp_rol_arbitral_Baja'),
    (N'mundial',N'sp_rol_arbitral_Consultar'),
    (N'mundial',N'sp_designacion_arbitral_Alta'),
    (N'mundial',N'sp_designacion_arbitral_Modificar'),
    (N'mundial',N'sp_designacion_arbitral_Baja'),
    (N'mundial',N'sp_designacion_arbitral_Consultar'),
    (N'mundial',N'sp_informe_arbitral_Alta'),
    (N'mundial',N'sp_informe_arbitral_Modificar'),
    (N'mundial',N'sp_informe_arbitral_Baja'),
    (N'mundial',N'sp_informe_arbitral_Consultar'),
    (N'mundial',N'sp_anunciante_Alta'),
    (N'mundial',N'sp_anunciante_Modificar'),
    (N'mundial',N'sp_anunciante_Baja'),
    (N'mundial',N'sp_anunciante_Consultar'),
    (N'mundial',N'sp_campania_Alta'),
    (N'mundial',N'sp_campania_Modificar'),
    (N'mundial',N'sp_campania_Baja'),
    (N'mundial',N'sp_campania_Consultar'),
    (N'mundial',N'sp_pieza_publicitaria_Alta'),
    (N'mundial',N'sp_pieza_publicitaria_Modificar'),
    (N'mundial',N'sp_pieza_publicitaria_Baja'),
    (N'mundial',N'sp_pieza_publicitaria_Consultar'),
    (N'mundial',N'sp_pieza_pais_objetivo_Alta'),
    (N'mundial',N'sp_pieza_pais_objetivo_Modificar'),
    (N'mundial',N'sp_pieza_pais_objetivo_Baja'),
    (N'mundial',N'sp_pieza_pais_objetivo_Consultar'),
    (N'mundial',N'sp_espacio_publicitario_Alta'),
    (N'mundial',N'sp_espacio_publicitario_Modificar'),
    (N'mundial',N'sp_espacio_publicitario_Baja'),
    (N'mundial',N'sp_espacio_publicitario_Consultar'),
    (N'mundial',N'sp_moneda_Alta'),
    (N'mundial',N'sp_moneda_Modificar'),
    (N'mundial',N'sp_moneda_Baja'),
    (N'mundial',N'sp_moneda_Consultar'),
    (N'mundial',N'sp_pauta_partido_Alta'),
    (N'mundial',N'sp_pauta_partido_Modificar'),
    (N'mundial',N'sp_pauta_partido_Baja'),
    (N'mundial',N'sp_pauta_partido_Consultar'),
    (N'mundial',N'sp_fuente_importacion_Alta'),
    (N'mundial',N'sp_fuente_importacion_Modificar'),
    (N'mundial',N'sp_fuente_importacion_Baja'),
    (N'mundial',N'sp_fuente_importacion_Consultar'),
    (N'mundial',N'sp_lote_importacion_Alta'),
    (N'mundial',N'sp_lote_importacion_Modificar'),
    (N'mundial',N'sp_lote_importacion_Baja'),
    (N'mundial',N'sp_lote_importacion_Consultar'),
    (N'mundial',N'sp_detalle_importacion_Alta'),
    (N'mundial',N'sp_detalle_importacion_Modificar'),
    (N'mundial',N'sp_detalle_importacion_Baja'),
    (N'mundial',N'sp_detalle_importacion_Consultar'),
    (N'mundial',N'sp_error_importacion_Alta'),
    (N'mundial',N'sp_error_importacion_Modificar'),
    (N'mundial',N'sp_error_importacion_Baja'),
    (N'mundial',N'sp_error_importacion_Consultar');

IF EXISTS
(
    SELECT 1
    FROM @Esperados AS e
    WHERE OBJECT_ID
    (
        QUOTENAME(e.esquema)
        + N'.'
        + QUOTENAME(e.procedimiento),
        N'P'
    ) IS NULL
)
BEGIN
    SELECT
        e.esquema,
        e.procedimiento AS procedimiento_faltante
    FROM @Esperados AS e
    WHERE OBJECT_ID
    (
        QUOTENAME(e.esquema)
        + N'.'
        + QUOTENAME(e.procedimiento),
        N'P'
    ) IS NULL
    ORDER BY
        e.esquema,
        e.procedimiento;

    THROW 52000, N'Faltan procedimientos ABM.', 1;
END;

PRINT N'OK 1: existen los 172 procedimientos esperados.';
GO

/* 2. Prueba integral exitosa, revertida al final. */
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @id_conf INT,@id_pais INT,@id_grupo INT,@id_reg INT,@id_fase INT,
            @id_sel1 INT,@id_sel2 INT,@id_ciudad INT,@id_sede INT,@id_partido INT,
            @id_idioma INT,@id_moneda INT,@id_fuente INT,@id_lote INT;

    EXEC mundial.sp_confederacion_Alta 'Confederacion Test ABM','TST';
    SELECT @id_conf=id_confederacion FROM mundial.confederacion WHERE sigla='TST';
    IF @id_conf IS NULL THROW 52001,N'No se creó confederación.',1;
    EXEC mundial.sp_confederacion_Modificar @id_conf,'Confederacion Test Mod','TSM';
    IF NOT EXISTS(SELECT 1 FROM mundial.confederacion WHERE id_confederacion=@id_conf AND sigla='TSM') THROW 52002,N'No se modificó confederación.',1;

    EXEC mundial.sp_pais_Alta @id_conf,'Pais Test Uno','ZT1','Argentina Standard Time',1000,'ZZZ';
    SELECT @id_pais=id_pais FROM mundial.pais WHERE codigo_iso='ZT1';
    EXEC mundial.sp_grupo_Alta 'Grupo Test Z';
    SELECT @id_grupo=id_grupo FROM mundial.grupo WHERE nombre_grupo='Grupo Test Z';
    EXEC mundial.sp_reglamento_sustitucion_Alta 'Regla Test',5,3,1,1,0,0,'2026-01-01',NULL,1;
    SELECT @id_reg=id_reglamento_sustitucion FROM mundial.reglamento_sustitucion WHERE nombre='Regla Test';
    EXEC mundial.sp_fase_Alta @id_reg,'Fase Test',99,1,1;
    SELECT @id_fase=id_fase FROM mundial.fase WHERE nombre_fase='Fase Test';
    EXEC mundial.sp_seleccion_Alta @id_pais,@id_grupo;
    SELECT @id_sel1=id_seleccion FROM mundial.seleccion WHERE id_pais=@id_pais;

    EXEC mundial.sp_pais_Alta @id_conf,'Pais Test Dos','ZT2','Argentina Standard Time',2000,'ZZZ';
    DECLARE @id_pais2 INT=(SELECT id_pais FROM mundial.pais WHERE codigo_iso='ZT2');
    EXEC mundial.sp_seleccion_Alta @id_pais2,@id_grupo;
    SELECT @id_sel2=id_seleccion FROM mundial.seleccion WHERE id_pais=@id_pais2;
    EXEC mundial.sp_ciudad_Alta @id_pais,'Ciudad Test';
    SELECT @id_ciudad=id_ciudad FROM mundial.ciudad WHERE id_pais=@id_pais AND nombre='Ciudad Test';
    EXEC mundial.sp_sede_estadio_Alta @id_ciudad,'Estadio Test',50000,'Argentina Standard Time',-34.603700,-58.381600;
    SELECT @id_sede=id_sede FROM mundial.sede_estadio WHERE nombre_estadio='Estadio Test';
    EXEC mundial.sp_partido_Alta @id_fase,@id_sede,@id_sel1,@id_sel2,'2026-11-20T20:00:00','2026-11-20T17:00:00',NULL,NULL,NULL,NULL,NULL,'PROGRAMADO';
    SELECT @id_partido=id_partido FROM mundial.partido WHERE id_sede=@id_sede;
    IF @id_partido IS NULL THROW 52003,N'No se creó partido.',1;

    EXEC mundial.sp_idioma_Alta 'Idioma Test','zz-ZZ';
    SELECT @id_idioma=id_idioma FROM mundial.idioma WHERE codigo_iso='zz-ZZ';
    EXEC mundial.sp_moneda_Alta 'ZZZ','Moneda Test';
    SELECT @id_moneda=id_moneda FROM mundial.moneda WHERE codigo_iso='ZZZ';

    EXEC mundial.sp_fuente_importacion_Alta 'Fuente Test','ARCHIVO','CSV',NULL,'Prueba',NULL,1;
    SELECT @id_fuente=id_fuente FROM mundial.fuente_importacion WHERE nombre='Fuente Test';
    EXEC mundial.sp_lote_importacion_Alta @id_fuente,'test.csv','pais','2026-11-16T20:00:00',NULL,'PENDIENTE',0,0,0,0,'HASH-TEST-001';
    SELECT @id_lote=id_lote FROM mundial.lote_importacion WHERE hash_archivo='HASH-TEST-001';
    IF @id_lote IS NULL THROW 52004,N'No se creó lote.',1;

    ROLLBACK TRANSACTION;
    PRINT N'OK 2: altas y modificaciones representativas ejecutadas; ROLLBACK aplicado.';
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* 3. Validaciones negativas y códigos uniformes. */
BEGIN TRY
    EXEC mundial.sp_grupo_Alta '';
    THROW 52999,N'FALLO: se aceptó nombre vacío.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=52999 THROW;
    IF ERROR_NUMBER()<>51001 THROW;
    PRINT N'OK 3: nombre vacío rechazado.';
END CATCH;
GO

BEGIN TRY
    EXEC mundial.sp_ciudad_Alta -999999,'Ciudad inválida';
    THROW 52999,N'FALLO: se aceptó FK inexistente.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=52999 THROW;
    IF ERROR_NUMBER()<>51001 THROW;
    PRINT N'OK 4: FK inexistente rechazada.';
END CATCH;
GO

BEGIN TRY
    EXEC mundial.sp_partido_Baja -999999;
    THROW 52999,N'FALLO: se aceptó baja inexistente.',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()=52999 THROW;
    IF ERROR_NUMBER()<>51003 THROW;
    PRINT N'OK 5: baja inexistente rechazada.';
END CATCH;
GO

/* 4. Verificación de columnas obsoletas en definiciones. */
IF EXISTS(
 SELECT 1 FROM sys.sql_modules
 WHERE definition LIKE '%huso_horario_minutos_utc%'
    OR definition LIKE '%id_partido_suspendido%'
    OR definition LIKE '%minuto_regreso%'
    OR definition LIKE '%sanciones_pos_partido%'
)
 THROW 52010,N'Hay procedimientos que usan columnas obsoletas.',1;
PRINT N'OK 6: no hay referencias a columnas obsoletas.';
GO

PRINT N'FIN: pruebas estructurales y funcionales ABM completadas.';
GO
