USE TP2026
GO

/*
Integrantes: Quispe Sergio, Lopez Santiago, Coria Lautaro y Santos Jonatan
Descripción:
  Pruebas de éxito y de validación para los procedimientos ABM del archivo
  CreacionSP ABM CAT.sql

Requisitos:
  1. Ejecutar sobre la base de datos del TP, después del DDL y de 02_SP_ABM_Catalogos.sql.
  2. No ejecutar mientras otro proceso esté cargando estos mismos valores de prueba.
  3. Todo el bloque de pruebas exitosas se ejecuta dentro de una transacción que
     termina en ROLLBACK, por lo que no deja los datos de prueba guardados.
  4. Las pruebas de validación comprueban que los SP rechacen datos inválidos.
  5. Si una prueba falla, el script genera un error y se detiene en ese punto.

IMPORTANTE:
  Los procedimientos de baja se prueban con registros creados por este script.
  Las pruebas de baja pueden fallar si el esquema real tiene otras FK no contempladas
  o si los SP/tablas difieren de la versión de referencia.
*/
SET NOCOUNT ON;
GO

/* =========================================================
   PARTE A: PRUEBAS EXITOSAS
   Alta, modificación, consulta y baja para cada catálogo.
   Los cambios se revierten al finalizar.
   ========================================================= */

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @id_grupo INT,
            @id_fase INT,
            @id_idioma INT,
            @id_moneda INT,
            @id_posicion INT,
            @id_rol_ct INT,
            @id_rol_arbitral INT,
            @id_tipo_gol INT,
            @id_tipo_tarjeta INT,
            @id_criterio INT;

    PRINT 'INICIO: pruebas exitosas de ABM de catálogos.';

    -- 1. CONFEDERACIÓN (la PK no es IDENTITY)
    EXEC mundial.sp_confederacion_Alta
        @id_confederacion = 9901,
        @nombre = 'TEST Confederacion',
        @sigla = 'TST';
    EXEC mundial.sp_confederacion_Consultar @id_confederacion = 9901;
    EXEC mundial.sp_confederacion_Modificar
        @id_confederacion = 9901,
        @nombre = 'TEST Confederacion Mod',
        @sigla = 'TSM';
    EXEC mundial.sp_confederacion_Consultar @id_confederacion = 9901;

    -- 2. GRUPO
    EXEC mundial.sp_grupo_Alta @nombre_grupo = 'ZZ_TEST_GRUPO';
    SELECT @id_grupo = id_grupo
    FROM mundial.grupo WHERE nombre_grupo = 'ZZ_TEST_GRUPO';
    IF @id_grupo IS NULL THROW 51000, 'FALLO TEST: no se creó el grupo.', 1;
    EXEC mundial.sp_grupo_Consultar @id_grupo = @id_grupo;
    EXEC mundial.sp_grupo_Modificar
        @id_grupo = @id_grupo,
        @nombre_grupo = 'ZZ_TEST_GRUPO_MOD';
    EXEC mundial.sp_grupo_Consultar @id_grupo = @id_grupo;

    -- 3. FASE
    EXEC mundial.sp_fase_Alta
        @nombre_fase = 'ZZ_TEST_FASE',
        @orden = 9901,
        @permite_alargue = 1,
        @permite_penales = 1;
    SELECT @id_fase = id_fase
    FROM mundial.fase WHERE nombre_fase = 'ZZ_TEST_FASE';
    IF @id_fase IS NULL THROW 51000, 'FALLO TEST: no se creó la fase.', 1;
    EXEC mundial.sp_fase_Consultar @id_fase = @id_fase;
    EXEC mundial.sp_fase_Modificar
        @id_fase = @id_fase,
        @nombre_fase = 'ZZ_TEST_FASE_MOD',
        @orden = 9902,
        @permite_alargue = 0,
        @permite_penales = 0;
    EXEC mundial.sp_fase_Consultar @id_fase = @id_fase;

    -- 4. IDIOMA
    EXEC mundial.sp_idioma_Alta
        @nombre_idioma = 'ZZ Test Idioma',
        @codigo_iso = 'zz_TST';
    SELECT @id_idioma = id_idioma
    FROM mundial.idioma WHERE codigo_iso = 'zz_TST';
    IF @id_idioma IS NULL THROW 51000, 'FALLO TEST: no se creó el idioma.', 1;
    EXEC mundial.sp_idioma_Consultar @id_idioma = @id_idioma;
    EXEC mundial.sp_idioma_Modificar
        @id_idioma = @id_idioma,
        @nombre_idioma = 'ZZ Test Idioma Mod',
        @codigo_iso = 'zz_TSM';
    EXEC mundial.sp_idioma_Consultar @id_idioma = @id_idioma;

    -- 5. MONEDA
    EXEC mundial.sp_moneda_Alta
        @codigo_iso = 'ZZT',
        @descripcion = 'Moneda de prueba';
    SELECT @id_moneda = id_moneda
    FROM mundial.moneda WHERE codigo_iso = 'ZZT';
    IF @id_moneda IS NULL THROW 51000, 'FALLO TEST: no se creó la moneda.', 1;
    EXEC mundial.sp_moneda_Consultar @id_moneda = @id_moneda;
    EXEC mundial.sp_moneda_Modificar
        @id_moneda = @id_moneda,
        @codigo_iso = 'ZZM',
        @descripcion = 'Moneda de prueba modificada';
    EXEC mundial.sp_moneda_Consultar @id_moneda = @id_moneda;

    -- 6. POSICIÓN
    EXEC mundial.sp_posicion_Alta
        @codigo = 'ZZT',
        @descripcion = 'Posición test',
        @linea_campo = 'Prueba';
    SELECT @id_posicion = id_posicion
    FROM mundial.posicion WHERE codigo = 'ZZT';
    IF @id_posicion IS NULL THROW 51000, 'FALLO TEST: no se creó la posición.', 1;
    EXEC mundial.sp_posicion_Consultar @id_posicion = @id_posicion;
    EXEC mundial.sp_posicion_Modificar
        @id_posicion = @id_posicion,
        @codigo = 'ZZM',
        @descripcion = 'Posición test mod',
        @linea_campo = 'Prueba mod';
    EXEC mundial.sp_posicion_Consultar @id_posicion = @id_posicion;

    -- 7. ROL DEL CUERPO TÉCNICO
    EXEC mundial.sp_rol_cuerpo_tecnico_Alta @descripcion = 'ZZ Test CT';
    SELECT @id_rol_ct = id_rol_ct
    FROM mundial.rol_cuerpo_tecnico WHERE descripcion = 'ZZ Test CT';
    IF @id_rol_ct IS NULL THROW 51000, 'FALLO TEST: no se creó el rol de cuerpo técnico.', 1;
    EXEC mundial.sp_rol_cuerpo_tecnico_Consultar @id_rol_ct = @id_rol_ct;
    EXEC mundial.sp_rol_cuerpo_tecnico_Modificar
        @id_rol_ct = @id_rol_ct,
        @descripcion = 'ZZ Test CT Mod';
    EXEC mundial.sp_rol_cuerpo_tecnico_Consultar @id_rol_ct = @id_rol_ct;

    -- 8. ROL ARBITRAL
    EXEC mundial.sp_rol_arbitral_Alta @descripcion = 'ZZ Test Rol Arb';
    SELECT @id_rol_arbitral = id_rol_arbitral
    FROM mundial.rol_arbitral WHERE descripcion = 'ZZ Test Rol Arb';
    IF @id_rol_arbitral IS NULL THROW 51000, 'FALLO TEST: no se creó el rol arbitral.', 1;
    EXEC mundial.sp_rol_arbitral_Consultar @id_rol_arbitral = @id_rol_arbitral;
    EXEC mundial.sp_rol_arbitral_Modificar
        @id_rol_arbitral = @id_rol_arbitral,
        @descripcion = 'ZZ Test Rol Arb Mod';
    EXEC mundial.sp_rol_arbitral_Consultar @id_rol_arbitral = @id_rol_arbitral;

    -- 9. TIPO DE GOL
    EXEC mundial.sp_tipo_gol_Alta @descripcion = 'ZZ Test Gol';
    SELECT @id_tipo_gol = id_tipo_gol
    FROM mundial.tipo_gol WHERE descripcion = 'ZZ Test Gol';
    IF @id_tipo_gol IS NULL THROW 51000, 'FALLO TEST: no se creó el tipo de gol.', 1;
    EXEC mundial.sp_tipo_gol_Consultar @id_tipo_gol = @id_tipo_gol;
    EXEC mundial.sp_tipo_gol_Modificar
        @id_tipo_gol = @id_tipo_gol,
        @descripcion = 'ZZ Test Gol Mod';
    EXEC mundial.sp_tipo_gol_Consultar @id_tipo_gol = @id_tipo_gol;

    -- 10. TIPO DE TARJETA
    EXEC mundial.sp_tipo_tarjeta_Alta @descripcion = 'ZZ Test Tarjeta';
    SELECT @id_tipo_tarjeta = id_tipo_tarjeta
    FROM mundial.tipo_tarjeta WHERE descripcion = 'ZZ Test Tarjeta';
    IF @id_tipo_tarjeta IS NULL THROW 51000, 'FALLO TEST: no se creó el tipo de tarjeta.', 1;
    EXEC mundial.sp_tipo_tarjeta_Consultar @id_tipo_tarjeta = @id_tipo_tarjeta;
    EXEC mundial.sp_tipo_tarjeta_Modificar
        @id_tipo_tarjeta = @id_tipo_tarjeta,
        @descripcion = 'ZZ Test Tarjeta Mod';
    EXEC mundial.sp_tipo_tarjeta_Consultar @id_tipo_tarjeta = @id_tipo_tarjeta;

    -- 11. CRITERIO DE SUSPENSIÓN
    EXEC mundial.sp_criterio_suspension_Alta
        @cantidad_amarillas = 99,
        @fase_aplicable = 'ZZ_TEST_FASE',
        @partidos_suspension = 99;
    SELECT @id_criterio = id_criterio
    FROM mundial.criterio_suspension
    WHERE cantidad_amarillas = 99
      AND fase_aplicable = 'ZZ_TEST_FASE'
      AND partidos_suspension = 99;
    IF @id_criterio IS NULL THROW 51000, 'FALLO TEST: no se creó el criterio de suspensión.', 1;
    EXEC mundial.sp_criterio_suspension_Consultar @id_criterio = @id_criterio;
    EXEC mundial.sp_criterio_suspension_Modificar
        @id_criterio = @id_criterio,
        @cantidad_amarillas = 98,
        @fase_aplicable = 'ZZ_TEST_FASE_MOD',
        @partidos_suspension = 98;
    EXEC mundial.sp_criterio_suspension_Consultar @id_criterio = @id_criterio;

    PRINT 'Pruebas de alta, modificación y consulta completadas.';

    -- Bajas en orden inverso para reducir el riesgo de dependencias entre catálogos.
    EXEC mundial.sp_criterio_suspension_Baja @id_criterio = @id_criterio;
    EXEC mundial.sp_tipo_tarjeta_Baja @id_tipo_tarjeta = @id_tipo_tarjeta;
    EXEC mundial.sp_tipo_gol_Baja @id_tipo_gol = @id_tipo_gol;
    EXEC mundial.sp_rol_arbitral_Baja @id_rol_arbitral = @id_rol_arbitral;
    EXEC mundial.sp_rol_cuerpo_tecnico_Baja @id_rol_ct = @id_rol_ct;
    EXEC mundial.sp_posicion_Baja @id_posicion = @id_posicion;
    EXEC mundial.sp_moneda_Baja @id_moneda = @id_moneda;
    EXEC mundial.sp_idioma_Baja @id_idioma = @id_idioma;
    EXEC mundial.sp_fase_Baja @id_fase = @id_fase;
    EXEC mundial.sp_grupo_Baja @id_grupo = @id_grupo;
    EXEC mundial.sp_confederacion_Baja @id_confederacion = 9901;

    PRINT 'Pruebas de baja completadas.';

    ROLLBACK TRANSACTION;
    PRINT 'ÉXITO: todas las pruebas exitosas finalizaron; los datos se revirtieron con ROLLBACK.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @MensajeExito NVARCHAR(2048) = ERROR_MESSAGE();
    PRINT 'ERROR en la sección de pruebas exitosas: ' + @MensajeExito;
    THROW;
END CATCH;
GO

/* =========================================================
   PARTE B: PRUEBAS DE VALIDACIONES
   Cada caso debe ser rechazado por el procedimiento.
   Si el SP acepta un dato inválido, el test falla.
   ========================================================= */

PRINT 'INICIO: pruebas de validaciones.';

-- Prueba 1: alta de confederación con nombre vacío.
BEGIN TRY
    EXEC mundial.sp_confederacion_Alta
        @id_confederacion = 9901,
        @nombre = '',
        @sigla = 'TV1';
    THROW 51000, 'FALLO TEST: se aceptó una confederación con nombre vacío.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51000 THROW;
    IF ERROR_NUMBER() NOT IN (50001, 50002) THROW;
    PRINT 'OK validación 1: confederación con nombre vacío rechazada.';
END CATCH;
GO

-- Prueba 2: alta de grupo con nombre vacío.
BEGIN TRY
    EXEC mundial.sp_grupo_Alta @nombre_grupo = '';
    THROW 51000, 'FALLO TEST: se aceptó un grupo con nombre vacío.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51000 THROW;
    IF ERROR_NUMBER() NOT IN (50001, 50002) THROW;
    PRINT 'OK validación 2: grupo con nombre vacío rechazado.';
END CATCH;
GO

-- Prueba 3: alta de fase con orden cero.
BEGIN TRY
    EXEC mundial.sp_fase_Alta
        @nombre_fase = 'ZZ_TEST_FASE_INVALIDA',
        @orden = 0,
        @permite_alargue = 0,
        @permite_penales = 0;
    THROW 51000, 'FALLO TEST: se aceptó una fase con orden cero.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51000 THROW;
    IF ERROR_NUMBER() NOT IN (50001, 50002) THROW;
    PRINT 'OK validación 3: fase con orden cero rechazada.';
END CATCH;
GO

-- Prueba 4: alta de idioma con código vacío.
BEGIN TRY
    EXEC mundial.sp_idioma_Alta
        @nombre_idioma = 'ZZ Test Idioma Inválido',
        @codigo_iso = '';
    THROW 51000, 'FALLO TEST: se aceptó un idioma con código vacío.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51000 THROW;
    IF ERROR_NUMBER() NOT IN (50001, 50002) THROW;
    PRINT 'OK validación 4: idioma con código vacío rechazado.';
END CATCH;
GO

-- Prueba 5: alta de moneda con descripción vacía.
BEGIN TRY
    EXEC mundial.sp_moneda_Alta
        @codigo_iso = 'ZTV',
        @descripcion = '';
    THROW 51000, 'FALLO TEST: se aceptó una moneda con descripción vacía.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51000 THROW;
    IF ERROR_NUMBER() NOT IN (50001, 50002) THROW;
    PRINT 'OK validación 5: moneda con descripción vacía rechazada.';
END CATCH;
GO

-- Prueba 6: alta de posición con código vacío.
BEGIN TRY
    EXEC mundial.sp_posicion_Alta
        @codigo = '',
        @descripcion = 'Posición inválida',
        @linea_campo = 'Defensa';
    THROW 51000, 'FALLO TEST: se aceptó una posición con código vacío.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51000 THROW;
    IF ERROR_NUMBER() NOT IN (50001, 50002) THROW;
    PRINT 'OK validación 6: posición con código vacío rechazada.';
END CATCH;
GO

-- Prueba 7: alta de rol del cuerpo técnico con descripción vacía.
BEGIN TRY
    EXEC mundial.sp_rol_cuerpo_tecnico_Alta @descripcion = '';
    THROW 51000, 'FALLO TEST: se aceptó un rol de cuerpo técnico vacío.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51000 THROW;
    IF ERROR_NUMBER() NOT IN (50001, 50002) THROW;
    PRINT 'OK validación 7: rol de cuerpo técnico vacío rechazado.';
END CATCH;
GO

-- Prueba 8: alta de rol arbitral con descripción vacía.
BEGIN TRY
    EXEC mundial.sp_rol_arbitral_Alta @descripcion = '';
    THROW 51000, 'FALLO TEST: se aceptó un rol arbitral vacío.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51000 THROW;
    IF ERROR_NUMBER() NOT IN (50001, 50002) THROW;
    PRINT 'OK validación 8: rol arbitral vacío rechazado.';
END CATCH;
GO

-- Prueba 9: alta de tipo de gol con descripción vacía.
BEGIN TRY
    EXEC mundial.sp_tipo_gol_Alta @descripcion = '';
    THROW 51000, 'FALLO TEST: se aceptó un tipo de gol vacío.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51000 THROW;
    IF ERROR_NUMBER() NOT IN (50001, 50002) THROW;
    PRINT 'OK validación 9: tipo de gol vacío rechazado.';
END CATCH;
GO

-- Prueba 10: alta de tipo de tarjeta con descripción vacía.
BEGIN TRY
    EXEC mundial.sp_tipo_tarjeta_Alta @descripcion = '';
    THROW 51000, 'FALLO TEST: se aceptó un tipo de tarjeta vacío.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51000 THROW;
    IF ERROR_NUMBER() NOT IN (50001, 50002) THROW;
    PRINT 'OK validación 10: tipo de tarjeta vacío rechazado.';
END CATCH;
GO

-- Prueba 11: criterio de suspensión con cantidad de amarillas igual a cero.
BEGIN TRY
    EXEC mundial.sp_criterio_suspension_Alta
        @cantidad_amarillas = 0,
        @fase_aplicable = 'ZZ_TEST',
        @partidos_suspension = 1;
    THROW 51000, 'FALLO TEST: se aceptó un criterio con cero amarillas.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51000 THROW;
    IF ERROR_NUMBER() NOT IN (50001, 50002) THROW;
    PRINT 'OK validación 11: criterio con cero amarillas rechazado.';
END CATCH;
GO

-- Prueba 12: criterio de suspensión con partidos de suspensión igual a cero.
BEGIN TRY
    EXEC mundial.sp_criterio_suspension_Alta
        @cantidad_amarillas = 1,
        @fase_aplicable = 'ZZ_TEST',
        @partidos_suspension = 0;
    THROW 51000, 'FALLO TEST: se aceptó un criterio con cero partidos de suspensión.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51000 THROW;
    IF ERROR_NUMBER() NOT IN (50001, 50002) THROW;
    PRINT 'OK validación 12: criterio con cero partidos de suspensión rechazado.';
END CATCH;
GO

PRINT 'FIN: todas las pruebas de validación finalizaron correctamente.';
GO


/* ==========================================================
   PARTE A: PRUEBAS EXITOSAS (se revierten al final)
   ========================================================== */
IF EXISTS (SELECT 1 FROM mundial.confederacion WHERE id_confederacion = 9907)
   OR EXISTS (SELECT 1 FROM mundial.pais WHERE codigo_iso IN ('ZZ1','ZZ2'))
   OR EXISTS (SELECT 1 FROM mundial.grupo WHERE nombre_grupo='ZZT_GRUPO')
   OR EXISTS (SELECT 1 FROM mundial.fase WHERE nombre_fase='ZZT_FASE')
BEGIN
    THROW 51010, 'Hay datos de prueba ZZT preexistentes. Limpiar esos datos o use otra base de pruebas antes de ejecutar este script.', 1;
END;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE
      @id_conf INT = 9907,
      @id_grupo INT, @id_fase INT, @id_idioma INT, @id_idioma2 INT, @id_moneda INT,
      @id_posicion INT, @id_rol_ct INT, @id_rol_arbitral INT,
      @id_tipo_gol INT, @id_tipo_tarjeta INT, @id_criterio INT,
      @id_pais1 INT, @id_pais2 INT, @id_sel1 INT, @id_sel2 INT,
      @id_club INT, @id_ct INT, @id_ciudad INT, @id_anunciante INT,
      @id_arbitro INT, @id_jugador1 INT, @id_jugador2 INT, @id_sede INT,
      @id_campania INT, @id_partido INT, @id_pieza INT, @id_espacio INT,
      @id_conv1 INT, @id_conv2 INT, @id_novedad INT, @id_sustitucion INT,
      @id_gol INT, @id_tarjeta INT, @id_suspension INT, @id_pauta INT,
      @id_detalle1 INT, @id_detalle2 INT, @id_designacion INT, @id_informe INT,
      @id_alineacion INT;

    PRINT 'INICIO: pruebas exitosas de los ABM de las 26 tablas restantes.';

    /* Catálogos mínimos de apoyo: también se crean mediante sus SP. */
    EXEC mundial.sp_confederacion_Alta @id_confederacion=@id_conf, @nombre='ZZT Confed', @sigla='ZZT';
    EXEC mundial.sp_grupo_Alta @nombre_grupo='ZZT_GRUPO';
    SELECT @id_grupo=id_grupo FROM mundial.grupo WHERE nombre_grupo='ZZT_GRUPO';
    EXEC mundial.sp_fase_Alta @nombre_fase='ZZT_FASE', @orden=9907, @permite_alargue=1, @permite_penales=1;
    SELECT @id_fase=id_fase FROM mundial.fase WHERE nombre_fase='ZZT_FASE';
    EXEC mundial.sp_idioma_Alta @nombre_idioma='ZZT Idioma', @codigo_iso='zz-ZZ';
    SELECT @id_idioma=id_idioma FROM mundial.idioma WHERE codigo_iso='zz-ZZ';
    EXEC mundial.sp_idioma_Alta @nombre_idioma='ZZT Idioma 2', @codigo_iso='zz-Z2';
    SELECT @id_idioma2=id_idioma FROM mundial.idioma WHERE codigo_iso='zz-Z2';
    EXEC mundial.sp_moneda_Alta @codigo_iso='ZZT', @descripcion='Moneda de prueba';
    SELECT @id_moneda=id_moneda FROM mundial.moneda WHERE codigo_iso='ZZT';
    EXEC mundial.sp_posicion_Alta @codigo='ZZT', @descripcion='Posicion test', @linea_campo='Defensa';
    SELECT @id_posicion=id_posicion FROM mundial.posicion WHERE codigo='ZZT';
    EXEC mundial.sp_rol_cuerpo_tecnico_Alta @descripcion='Rol test';
    SELECT @id_rol_ct=id_rol_ct FROM mundial.rol_cuerpo_tecnico WHERE descripcion='Rol test';
    EXEC mundial.sp_rol_arbitral_Alta @descripcion='Rol arbitral test';
    SELECT @id_rol_arbitral=id_rol_arbitral FROM mundial.rol_arbitral WHERE descripcion='Rol arbitral test';
    EXEC mundial.sp_tipo_gol_Alta @descripcion='Gol de prueba';
    SELECT @id_tipo_gol=id_tipo_gol FROM mundial.tipo_gol WHERE descripcion='Gol de prueba';
    EXEC mundial.sp_tipo_tarjeta_Alta @descripcion='Tarjeta test';
    SELECT @id_tipo_tarjeta=id_tipo_tarjeta FROM mundial.tipo_tarjeta WHERE descripcion='Tarjeta test';
    EXEC mundial.sp_criterio_suspension_Alta @cantidad_amarillas=3, @fase_aplicable='ZZT', @partidos_suspension=1;
    SELECT @id_criterio=id_criterio FROM mundial.criterio_suspension WHERE fase_aplicable='ZZT';

    /* 1. PAIS */
    EXEC mundial.sp_pais_Alta @id_confederacion=@id_conf, @nombre='ZZT Pais Uno', @codigo_iso='ZZ1', @huso_horario_estandar='UTC-03', @huso_horario_minutos_utc=-180, @pbi_per_capita=1000, @codigo_moneda='ZZT';
    SELECT @id_pais1=id_pais FROM mundial.pais WHERE codigo_iso='ZZ1';
    EXEC mundial.sp_pais_Alta @id_confederacion=@id_conf, @nombre='ZZT Pais Dos', @codigo_iso='ZZ2', @huso_horario_estandar='UTC-03', @huso_horario_minutos_utc=-180, @pbi_per_capita=2000, @codigo_moneda='ZZT';
    SELECT @id_pais2=id_pais FROM mundial.pais WHERE codigo_iso='ZZ2';
    EXEC mundial.sp_pais_Consultar @id_pais=@id_pais1;
    EXEC mundial.sp_pais_Modificar @id_pais=@id_pais1, @id_confederacion=@id_conf, @nombre='ZZT Pais Uno M', @codigo_iso='ZZ1', @huso_horario_estandar='UTC-03', @huso_horario_minutos_utc=-180, @pbi_per_capita=1100, @codigo_moneda='ZZT';
    EXEC mundial.sp_pais_Consultar @id_pais=@id_pais1;

    /* 2. SELECCION */
    EXEC mundial.sp_seleccion_Alta @id_pais=@id_pais1, @id_grupo=@id_grupo;
    SELECT @id_sel1=id_seleccion FROM mundial.seleccion WHERE id_pais=@id_pais1 AND id_grupo=@id_grupo;
    EXEC mundial.sp_seleccion_Alta @id_pais=@id_pais2, @id_grupo=@id_grupo;
    SELECT @id_sel2=MAX(id_seleccion) FROM mundial.seleccion WHERE id_pais=@id_pais2 AND id_grupo=@id_grupo;
    EXEC mundial.sp_seleccion_Consultar @id_seleccion=@id_sel1;
    EXEC mundial.sp_seleccion_Modificar @id_seleccion=@id_sel1, @id_pais=@id_pais1, @id_grupo=@id_grupo;
    EXEC mundial.sp_seleccion_Consultar @id_seleccion=@id_sel1;

    /* 3. CLUB */
    EXEC mundial.sp_club_Alta @id_pais=@id_pais1, @nombre_club='ZZT Club';
    SELECT @id_club=id_club FROM mundial.club WHERE nombre_club='ZZT Club';
    EXEC mundial.sp_club_Consultar @id_club=@id_club;
    EXEC mundial.sp_club_Modificar @id_club=@id_club, @id_pais=@id_pais1, @nombre_club='ZZT Club M';
    EXEC mundial.sp_club_Consultar @id_club=@id_club;

    /* 4. CUERPO TECNICO */
    EXEC mundial.sp_cuerpo_tecnico_Alta @id_seleccion=@id_sel1, @id_pais_nacionalidad=@id_pais1, @id_rol_ct=@id_rol_ct, @nombres='ZZT Nombre', @apellidos='ZZT Apellido';
    SELECT @id_ct=id_miembro_ct FROM mundial.cuerpo_tecnico WHERE nombres='ZZT Nombre' AND apellidos='ZZT Apellido';
    EXEC mundial.sp_cuerpo_tecnico_Consultar @id_miembro_ct=@id_ct;
    EXEC mundial.sp_cuerpo_tecnico_Modificar @id_miembro_ct=@id_ct, @id_seleccion=@id_sel1, @id_pais_nacionalidad=@id_pais1, @id_rol_ct=@id_rol_ct, @nombres='ZZT Nombre M', @apellidos='ZZT Apellido';
    EXEC mundial.sp_cuerpo_tecnico_Consultar @id_miembro_ct=@id_ct;

    /* 5. CIUDAD */
    EXEC mundial.sp_ciudad_Alta @id_pais=@id_pais1, @nombre='ZZT Ciudad';
    SELECT @id_ciudad=id_ciudad FROM mundial.ciudad WHERE nombre='ZZT Ciudad';
    EXEC mundial.sp_ciudad_Consultar @id_ciudad=@id_ciudad;
    EXEC mundial.sp_ciudad_Modificar @id_ciudad=@id_ciudad, @id_pais=@id_pais1, @nombre='ZZT Ciudad M';
    EXEC mundial.sp_ciudad_Consultar @id_ciudad=@id_ciudad;

    /* 6. ANUNCIANTE */
    EXEC mundial.sp_anunciante_Alta @id_pais_origen=@id_pais1, @razon_social='ZZT Anunciante', @identificador_fiscal='ZZT-FISCAL-01', @email_contacto='test@example.invalid';
    SELECT @id_anunciante=id_anunciante FROM mundial.anunciante WHERE identificador_fiscal='ZZT-FISCAL-01';
    EXEC mundial.sp_anunciante_Consultar @id_anunciante=@id_anunciante;
    EXEC mundial.sp_anunciante_Modificar @id_anunciante=@id_anunciante, @id_pais_origen=@id_pais1, @razon_social='ZZT Anunciante M', @identificador_fiscal='ZZT-FISCAL-01', @email_contacto='test2@example.invalid';
    EXEC mundial.sp_anunciante_Consultar @id_anunciante=@id_anunciante;

    /* 7. ARBITRO */
    EXEC mundial.sp_arbitro_Alta @id_pais_nacionalidad=@id_pais1, @id_confederacion=@id_conf, @nombres='ZZT Arbitro', @apellidos='ZZT Apellido', @fecha_nacimiento='1980-01-01', @categoria='Internacional';
    SELECT @id_arbitro=id_arbitro FROM mundial.arbitro WHERE nombres='ZZT Arbitro' AND apellidos='ZZT Apellido';
    EXEC mundial.sp_arbitro_Consultar @id_arbitro=@id_arbitro;
    EXEC mundial.sp_arbitro_Modificar @id_arbitro=@id_arbitro, @id_pais_nacionalidad=@id_pais1, @id_confederacion=@id_conf, @nombres='ZZT Arbitro M', @apellidos='ZZT Apellido', @fecha_nacimiento='1980-01-01', @categoria='Internacional';
    EXEC mundial.sp_arbitro_Consultar @id_arbitro=@id_arbitro;

    /* 8. ARBITRO_IDIOMA (PK compuesta) */
    EXEC mundial.sp_arbitro_idioma_Alta @id_arbitro=@id_arbitro, @id_idioma=@id_idioma;
    EXEC mundial.sp_arbitro_idioma_Consultar @id_arbitro=@id_arbitro, @id_idioma=@id_idioma;
    EXEC mundial.sp_arbitro_idioma_Modificar @id_arbitro_original=@id_arbitro, @id_idioma_original=@id_idioma, @id_arbitro_nuevo=@id_arbitro, @id_idioma_nuevo=@id_idioma2;
    EXEC mundial.sp_arbitro_idioma_Consultar @id_arbitro=@id_arbitro, @id_idioma=@id_idioma2;

    /* 9. JUGADORES (dos, para sustitución y alineaciones) */
    EXEC mundial.sp_jugador_Alta @id_pais_nacionalidad=@id_pais1, @id_club=@id_club, @id_posicion_habitual=@id_posicion, @nombres='ZZT Jugador Uno', @apellidos='Prueba', @fecha_nacimiento='2000-01-01', @doc_identidad='ZZT-DOC-01';
    SELECT @id_jugador1=id_jugador FROM mundial.jugador WHERE doc_identidad='ZZT-DOC-01';
    EXEC mundial.sp_jugador_Alta @id_pais_nacionalidad=@id_pais2, @id_club=@id_club, @id_posicion_habitual=@id_posicion, @nombres='ZZT Jugador Dos', @apellidos='Prueba', @fecha_nacimiento='2001-01-01', @doc_identidad='ZZT-DOC-02';
    SELECT @id_jugador2=id_jugador FROM mundial.jugador WHERE doc_identidad='ZZT-DOC-02';
    EXEC mundial.sp_jugador_Consultar @id_jugador=@id_jugador1;
    EXEC mundial.sp_jugador_Modificar @id_jugador=@id_jugador1, @id_pais_nacionalidad=@id_pais1, @id_club=@id_club, @id_posicion_habitual=@id_posicion, @nombres='ZZT Jugador Uno M', @apellidos='Prueba', @fecha_nacimiento='2000-01-01', @doc_identidad='ZZT-DOC-01';
    EXEC mundial.sp_jugador_Consultar @id_jugador=@id_jugador1;

    /* 10. SEDE / ESTADIO */
    EXEC mundial.sp_sede_estadio_Alta @id_ciudad=@id_ciudad, @nombre_estadio='ZZT Estadio', @capacidad=50000, @huso_horario='UTC-03', @latitud=-34.60, @longitud=-58.40;
    SELECT @id_sede=id_sede FROM mundial.sede_estadio WHERE nombre_estadio='ZZT Estadio';
    EXEC mundial.sp_sede_estadio_Consultar @id_sede=@id_sede;
    EXEC mundial.sp_sede_estadio_Modificar @id_sede=@id_sede, @id_ciudad=@id_ciudad, @nombre_estadio='ZZT Estadio M', @capacidad=51000, @huso_horario='UTC-03', @latitud=-34.60, @longitud=-58.40;
    EXEC mundial.sp_sede_estadio_Consultar @id_sede=@id_sede;

    /* 11. CAMPAÑA */
    EXEC mundial.sp_campania_Alta @id_anunciante=@id_anunciante, @nombre_campania='ZZT Campania', @fecha_inicio='2026-01-01', @fecha_fin='2026-12-31', @presupuesto_total=100000;
    SELECT @id_campania=id_campania FROM mundial.campania WHERE nombre_campania='ZZT Campania';
    EXEC mundial.sp_campania_Consultar @id_campania=@id_campania;
    EXEC mundial.sp_campania_Modificar @id_campania=@id_campania, @id_anunciante=@id_anunciante, @nombre_campania='ZZT Campania M', @fecha_inicio='2026-01-01', @fecha_fin='2026-12-31', @presupuesto_total=110000;
    EXEC mundial.sp_campania_Consultar @id_campania=@id_campania;

    /* 12. PARTIDO */
    EXEC mundial.sp_partido_Alta @id_fase=@id_fase, @id_sede=@id_sede, @id_seleccion_local=@id_sel1, @id_seleccion_visitante=@id_sel2, @fecha_hora_utc='2026-11-01T20:00:00', @fecha_hora_local='2026-11-01T17:00:00', @goles_local=1, @goles_visitante=0, @penales_local=NULL, @penales_visitante=NULL, @asistencia_publico=40000, @estado_partido='Programado';
    SELECT @id_partido=id_partido FROM mundial.partido WHERE id_sede=@id_sede AND id_seleccion_local=@id_sel1 AND id_seleccion_visitante=@id_sel2;
    EXEC mundial.sp_partido_Consultar @id_partido=@id_partido;
    EXEC mundial.sp_partido_Modificar @id_partido=@id_partido, @id_fase=@id_fase, @id_sede=@id_sede, @id_seleccion_local=@id_sel1, @id_seleccion_visitante=@id_sel2, @fecha_hora_utc='2026-11-01T20:00:00', @fecha_hora_local='2026-11-01T17:00:00', @goles_local=2, @goles_visitante=0, @penales_local=NULL, @penales_visitante=NULL, @asistencia_publico=41000, @estado_partido='Finalizado';
    EXEC mundial.sp_partido_Consultar @id_partido=@id_partido;

    /* 13. PIEZA PUBLICITARIA */
    EXEC mundial.sp_pieza_publicitaria_Alta @id_campania=@id_campania, @titulo='ZZT Pieza', @idioma='ZZT Idioma', @formato='Video', @duracion_segundos=30;
    SELECT @id_pieza=id_pieza FROM mundial.pieza_publicitaria WHERE titulo='ZZT Pieza';
    EXEC mundial.sp_pieza_publicitaria_Consultar @id_pieza=@id_pieza;
    EXEC mundial.sp_pieza_publicitaria_Modificar @id_pieza=@id_pieza, @id_campania=@id_campania, @titulo='ZZT Pieza M', @idioma='ZZT Idioma', @formato='Video', @duracion_segundos=30;
    EXEC mundial.sp_pieza_publicitaria_Consultar @id_pieza=@id_pieza;

    /* 14. PIEZA_PAIS_OBJETIVO (PK compuesta) */
    EXEC mundial.sp_pieza_pais_objetivo_Alta @id_pieza=@id_pieza, @id_pais=@id_pais1;
    EXEC mundial.sp_pieza_pais_objetivo_Consultar @id_pieza=@id_pieza, @id_pais=@id_pais1;
    EXEC mundial.sp_pieza_pais_objetivo_Modificar @id_pieza_original=@id_pieza, @id_pais_original=@id_pais1, @id_pieza_nuevo=@id_pieza, @id_pais_nuevo=@id_pais2;
    EXEC mundial.sp_pieza_pais_objetivo_Consultar @id_pieza=@id_pieza, @id_pais=@id_pais2;

    /* 15. ESPACIO PUBLICITARIO */
    EXEC mundial.sp_espacio_publicitario_Alta @id_sede=@id_sede, @numero_espacio=9907;
    SELECT @id_espacio=id_espacio FROM mundial.espacio_publicitario WHERE id_sede=@id_sede AND numero_espacio=9907;
    EXEC mundial.sp_espacio_publicitario_Consultar @id_espacio=@id_espacio;
    EXEC mundial.sp_espacio_publicitario_Modificar @id_espacio=@id_espacio, @id_sede=@id_sede, @numero_espacio=9908;
    EXEC mundial.sp_espacio_publicitario_Consultar @id_espacio=@id_espacio;

    /* 16. CONVOCATORIAS */
    EXEC mundial.sp_convocatoria_Alta @id_seleccion=@id_sel1, @id_jugador=@id_jugador1, @dorsal=91, @fecha_convocatoria='2026-10-27', @estado_convocatoria='Convocado';
    SELECT @id_conv1=id_convocatoria FROM mundial.convocatoria WHERE id_seleccion=@id_sel1 AND id_jugador=@id_jugador1 AND dorsal=91;
    EXEC mundial.sp_convocatoria_Alta @id_seleccion=@id_sel2, @id_jugador=@id_jugador2, @dorsal=92, @fecha_convocatoria='2026-10-27', @estado_convocatoria='Convocado';
    SELECT @id_conv2=id_convocatoria FROM mundial.convocatoria WHERE id_seleccion=@id_sel2 AND id_jugador=@id_jugador2 AND dorsal=92;
    EXEC mundial.sp_convocatoria_Consultar @id_convocatoria=@id_conv1;
    EXEC mundial.sp_convocatoria_Modificar @id_convocatoria=@id_conv1, @id_seleccion=@id_sel1, @id_jugador=@id_jugador1, @dorsal=91, @fecha_convocatoria='2026-10-27', @estado_convocatoria='Confirmado';
    EXEC mundial.sp_convocatoria_Consultar @id_convocatoria=@id_conv1;

    /* 17. NOVEDAD CONVOCATORIA */
    EXEC mundial.sp_novedad_convocatoria_Alta @id_convocatoria_baja=@id_conv1, @id_convocatoria_alta=@id_conv2, @motivo='Cambio de prueba', @fecha_cambio='2026-10-27T10:00:00', @dictamen_medico='Apto';
    SELECT @id_novedad=id_novedad FROM mundial.novedad_convocatoria WHERE id_convocatoria_baja=@id_conv1 AND id_convocatoria_alta=@id_conv2;
    EXEC mundial.sp_novedad_convocatoria_Consultar @id_novedad=@id_novedad;
    EXEC mundial.sp_novedad_convocatoria_Modificar @id_novedad=@id_novedad, @id_convocatoria_baja=@id_conv1, @id_convocatoria_alta=@id_conv2, @motivo='Cambio de prueba M', @fecha_cambio='2026-10-27T10:30:00', @dictamen_medico='Apto';
    EXEC mundial.sp_novedad_convocatoria_Consultar @id_novedad=@id_novedad;

    /* 18. SUSTITUCION */
    EXEC mundial.sp_sustitucion_Alta @id_partido=@id_partido, @id_seleccion=@id_sel1, @id_jugador_sale=@id_jugador1, @id_jugador_entra=@id_jugador2, @minuto=60, @minuto_adicional=0, @periodo='Segundo tiempo', @numero_ventana=1, @motivo='Prueba';
    SELECT @id_sustitucion=id_sustitucion FROM mundial.sustitucion WHERE id_partido=@id_partido AND id_jugador_sale=@id_jugador1 AND id_jugador_entra=@id_jugador2;
    EXEC mundial.sp_sustitucion_Consultar @id_sustitucion=@id_sustitucion;
    EXEC mundial.sp_sustitucion_Modificar @id_sustitucion=@id_sustitucion, @id_partido=@id_partido, @id_seleccion=@id_sel1, @id_jugador_sale=@id_jugador1, @id_jugador_entra=@id_jugador2, @minuto=61, @minuto_adicional=0, @periodo='Segundo tiempo', @numero_ventana=1, @motivo='Prueba M';
    EXEC mundial.sp_sustitucion_Consultar @id_sustitucion=@id_sustitucion;

    /* 19. GOL */
    EXEC mundial.sp_gol_Alta @id_partido=@id_partido, @id_seleccion=@id_sel1, @id_jugador_autor=@id_jugador1, @id_jugador_asistente=@id_jugador2, @id_tipo_gol=@id_tipo_gol, @minuto=25, @minuto_adicional=0, @periodo='Primer tiempo';
    SELECT @id_gol=id_gol FROM mundial.gol WHERE id_partido=@id_partido AND id_jugador_autor=@id_jugador1;
    EXEC mundial.sp_gol_Consultar @id_gol=@id_gol;
    EXEC mundial.sp_gol_Modificar @id_gol=@id_gol, @id_partido=@id_partido, @id_seleccion=@id_sel1, @id_jugador_autor=@id_jugador1, @id_jugador_asistente=@id_jugador2, @id_tipo_gol=@id_tipo_gol, @minuto=26, @minuto_adicional=0, @periodo='Primer tiempo';
    EXEC mundial.sp_gol_Consultar @id_gol=@id_gol;

    /* 20. TARJETA */
    EXEC mundial.sp_tarjeta_Alta @id_partido=@id_partido, @id_seleccion=@id_sel1, @id_jugador=@id_jugador1, @id_tipo_tarjeta=@id_tipo_tarjeta, @minuto=30, @minuto_adicional=0, @periodo='Primer tiempo', @motivo='Prueba', @tipo_expulsion='Ninguna';
    SELECT @id_tarjeta=id_tarjeta FROM mundial.tarjeta WHERE id_partido=@id_partido AND id_jugador=@id_jugador1;
    EXEC mundial.sp_tarjeta_Consultar @id_tarjeta=@id_tarjeta;
    EXEC mundial.sp_tarjeta_Modificar @id_tarjeta=@id_tarjeta, @id_partido=@id_partido, @id_seleccion=@id_sel1, @id_jugador=@id_jugador1, @id_tipo_tarjeta=@id_tipo_tarjeta, @minuto=31, @minuto_adicional=0, @periodo='Primer tiempo', @motivo='Prueba M', @tipo_expulsion='Ninguna';
    EXEC mundial.sp_tarjeta_Consultar @id_tarjeta=@id_tarjeta;

    /* 21. SUSPENSION */
    EXEC mundial.sp_suspension_jugador_Alta @id_criterio=@id_criterio, @id_jugador=@id_jugador1, @id_partido_origen=@id_partido, @id_partido_suspendido=@id_partido, @motivo='Suspension test', @partidos_sancion=1, @cumplida=0;
    SELECT @id_suspension=id_suspension FROM mundial.suspension_jugador WHERE id_criterio=@id_criterio AND id_jugador=@id_jugador1 AND id_partido_origen=@id_partido;
    EXEC mundial.sp_suspension_jugador_Consultar @id_suspension=@id_suspension;
    EXEC mundial.sp_suspension_jugador_Modificar @id_suspension=@id_suspension, @id_criterio=@id_criterio, @id_jugador=@id_jugador1, @id_partido_origen=@id_partido, @id_partido_suspendido=@id_partido, @motivo='Suspension test M', @partidos_sancion=1, @cumplida=0;
    EXEC mundial.sp_suspension_jugador_Consultar @id_suspension=@id_suspension;

    /* 22. PAUTA_PARTIDO */
    EXEC mundial.sp_pauta_partido_Alta @id_partido=@id_partido, @id_espacio=@id_espacio, @id_pieza=@id_pieza, @id_moneda=@id_moneda, @tarifa_base_usd=1000, @tipo_cambio_aplicado=1, @tarifa_final=1000, @es_prime_time=1, @estado_facturacion='Pendiente';
    SELECT @id_pauta=id_pauta FROM mundial.pauta_partido WHERE id_partido=@id_partido AND id_espacio=@id_espacio;
    EXEC mundial.sp_pauta_partido_Consultar @id_pauta=@id_pauta;
    EXEC mundial.sp_pauta_partido_Modificar @id_pauta=@id_pauta, @id_partido=@id_partido, @id_espacio=@id_espacio, @id_pieza=@id_pieza, @id_moneda=@id_moneda, @tarifa_base_usd=1100, @tipo_cambio_aplicado=1, @tarifa_final=1100, @es_prime_time=1, @estado_facturacion='Facturable';
    EXEC mundial.sp_pauta_partido_Consultar @id_pauta=@id_pauta;

    /* 23. PARTIDO_EQUIPO_DETALLE */
    EXEC mundial.sp_partido_equipo_detalle_Alta @id_partido=@id_partido, @id_seleccion=@id_sel1, @condicion='Local', @esquema_tactico='4-3-3';
    SELECT @id_detalle1=id_partido_equipo FROM mundial.partido_equipo_detalle WHERE id_partido=@id_partido AND id_seleccion=@id_sel1;
    EXEC mundial.sp_partido_equipo_detalle_Alta @id_partido=@id_partido, @id_seleccion=@id_sel2, @condicion='Visitante', @esquema_tactico='4-4-2';
    SELECT @id_detalle2=MAX(id_partido_equipo) FROM mundial.partido_equipo_detalle WHERE id_partido=@id_partido AND id_seleccion=@id_sel2;
    EXEC mundial.sp_partido_equipo_detalle_Consultar @id_partido_equipo=@id_detalle1;
    EXEC mundial.sp_partido_equipo_detalle_Modificar @id_partido_equipo=@id_detalle1, @id_partido=@id_partido, @id_seleccion=@id_sel1, @condicion='Local M', @esquema_tactico='4-2-3-1';
    EXEC mundial.sp_partido_equipo_detalle_Consultar @id_partido_equipo=@id_detalle1;

    /* 24. DESIGNACION ARBITRAL */
    EXEC mundial.sp_designacion_arbitral_Alta @id_partido=@id_partido, @id_arbitro=@id_arbitro, @id_rol_arbitral=@id_rol_arbitral;
    SELECT @id_designacion=id_designacion FROM mundial.designacion_arbitral WHERE id_partido=@id_partido AND id_arbitro=@id_arbitro;
    EXEC mundial.sp_designacion_arbitral_Consultar @id_designacion=@id_designacion;
    EXEC mundial.sp_designacion_arbitral_Modificar @id_designacion=@id_designacion, @id_partido=@id_partido, @id_arbitro=@id_arbitro, @id_rol_arbitral=@id_rol_arbitral;
    EXEC mundial.sp_designacion_arbitral_Consultar @id_designacion=@id_designacion;

    /* 25. INFORME ARBITRAL */
    EXEC mundial.sp_informe_arbitral_Alta @id_designacion=@id_designacion, @fecha_informe='2026-11-02', @observaciones='Informe test', @calificacion=8.5, @sanciones_pos_partido='Ninguna';
    SELECT @id_informe=id_informe FROM mundial.informe_arbitral WHERE id_designacion=@id_designacion;
    EXEC mundial.sp_informe_arbitral_Consultar @id_informe=@id_informe;
    EXEC mundial.sp_informe_arbitral_Modificar @id_informe=@id_informe, @id_designacion=@id_designacion, @fecha_informe='2026-11-02', @observaciones='Informe test M', @calificacion=9.0, @sanciones_pos_partido='Ninguna';
    EXEC mundial.sp_informe_arbitral_Consultar @id_informe=@id_informe;

    /* 26. ALINEACION_PARTIDO */
    EXEC mundial.sp_alineacion_partido_Alta @id_partido_equipo=@id_detalle1, @id_jugador=@id_jugador1, @id_posicion_campo=@id_posicion, @dorsal=91, @es_titular=1, @minuto_regreso=NULL, @minuto_salida=NULL;
    SELECT @id_alineacion=id_alineacion FROM mundial.alineacion_partido WHERE id_partido_equipo=@id_detalle1 AND id_jugador=@id_jugador1;
    EXEC mundial.sp_alineacion_partido_Consultar @id_alineacion=@id_alineacion;
    EXEC mundial.sp_alineacion_partido_Modificar @id_alineacion=@id_alineacion, @id_partido_equipo=@id_detalle1, @id_jugador=@id_jugador1, @id_posicion_campo=@id_posicion, @dorsal=91, @es_titular=1, @minuto_regreso=NULL, @minuto_salida=80;
    EXEC mundial.sp_alineacion_partido_Consultar @id_alineacion=@id_alineacion;

    PRINT 'Verificación final de los registros de prueba antes de las bajas.';
    SELECT 'pais' AS tabla, COUNT(*) AS registros FROM mundial.pais WHERE codigo_iso IN ('ZZ1','ZZ2')
    UNION ALL SELECT 'seleccion', COUNT(*) FROM mundial.seleccion WHERE id_seleccion IN (@id_sel1,@id_sel2)
    UNION ALL SELECT 'jugador', COUNT(*) FROM mundial.jugador WHERE id_jugador IN (@id_jugador1,@id_jugador2)
    UNION ALL SELECT 'partido', COUNT(*) FROM mundial.partido WHERE id_partido=@id_partido
    UNION ALL SELECT 'pauta_partido', COUNT(*) FROM mundial.pauta_partido WHERE id_pauta=@id_pauta;

    /* Bajas en orden inverso a las dependencias FK. */
    EXEC mundial.sp_alineacion_partido_Baja @id_alineacion=@id_alineacion;
    EXEC mundial.sp_informe_arbitral_Baja @id_informe=@id_informe;
    EXEC mundial.sp_designacion_arbitral_Baja @id_designacion=@id_designacion;
    EXEC mundial.sp_partido_equipo_detalle_Baja @id_partido_equipo=@id_detalle2;
    EXEC mundial.sp_partido_equipo_detalle_Baja @id_partido_equipo=@id_detalle1;
    EXEC mundial.sp_pauta_partido_Baja @id_pauta=@id_pauta;
    EXEC mundial.sp_suspension_jugador_Baja @id_suspension=@id_suspension;
    EXEC mundial.sp_tarjeta_Baja @id_tarjeta=@id_tarjeta;
    EXEC mundial.sp_gol_Baja @id_gol=@id_gol;
    EXEC mundial.sp_sustitucion_Baja @id_sustitucion=@id_sustitucion;
    EXEC mundial.sp_novedad_convocatoria_Baja @id_novedad=@id_novedad;
    EXEC mundial.sp_convocatoria_Baja @id_convocatoria=@id_conv2;
    EXEC mundial.sp_convocatoria_Baja @id_convocatoria=@id_conv1;
    EXEC mundial.sp_espacio_publicitario_Baja @id_espacio=@id_espacio;
    EXEC mundial.sp_pieza_pais_objetivo_Baja @id_pieza=@id_pieza, @id_pais=@id_pais2;
    EXEC mundial.sp_pieza_publicitaria_Baja @id_pieza=@id_pieza;
    EXEC mundial.sp_partido_Baja @id_partido=@id_partido;
    EXEC mundial.sp_campania_Baja @id_campania=@id_campania;
    EXEC mundial.sp_sede_estadio_Baja @id_sede=@id_sede;
    EXEC mundial.sp_jugador_Baja @id_jugador=@id_jugador2;
    EXEC mundial.sp_jugador_Baja @id_jugador=@id_jugador1;
    EXEC mundial.sp_arbitro_idioma_Baja @id_arbitro=@id_arbitro, @id_idioma=@id_idioma2;
    EXEC mundial.sp_arbitro_Baja @id_arbitro=@id_arbitro;
    EXEC mundial.sp_cuerpo_tecnico_Baja @id_miembro_ct=@id_ct;
    EXEC mundial.sp_club_Baja @id_club=@id_club;
    EXEC mundial.sp_ciudad_Baja @id_ciudad=@id_ciudad;
    EXEC mundial.sp_anunciante_Baja @id_anunciante=@id_anunciante;
    EXEC mundial.sp_seleccion_Baja @id_seleccion=@id_sel2;
    EXEC mundial.sp_seleccion_Baja @id_seleccion=@id_sel1;
    EXEC mundial.sp_pais_Baja @id_pais=@id_pais2;
    EXEC mundial.sp_pais_Baja @id_pais=@id_pais1;

    /* Bajas de catálogos creados por este test. */
    EXEC mundial.sp_criterio_suspension_Baja @id_criterio=@id_criterio;
    EXEC mundial.sp_tipo_tarjeta_Baja @id_tipo_tarjeta=@id_tipo_tarjeta;
    EXEC mundial.sp_tipo_gol_Baja @id_tipo_gol=@id_tipo_gol;
    EXEC mundial.sp_rol_arbitral_Baja @id_rol_arbitral=@id_rol_arbitral;
    EXEC mundial.sp_rol_cuerpo_tecnico_Baja @id_rol_ct=@id_rol_ct;
    EXEC mundial.sp_posicion_Baja @id_posicion=@id_posicion;
    EXEC mundial.sp_moneda_Baja @id_moneda=@id_moneda;
    EXEC mundial.sp_idioma_Baja @id_idioma=@id_idioma2;
    EXEC mundial.sp_idioma_Baja @id_idioma=@id_idioma;
    EXEC mundial.sp_fase_Baja @id_fase=@id_fase;
    EXEC mundial.sp_grupo_Baja @id_grupo=@id_grupo;
    EXEC mundial.sp_confederacion_Baja @id_confederacion=@id_conf;

    ROLLBACK TRANSACTION;
    PRINT 'OK: pruebas exitosas completadas; ROLLBACK aplicado, sin persistir datos de prueba.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @ErrorExito NVARCHAR(2048) = ERROR_MESSAGE();
    PRINT 'ERROR en las pruebas exitosas: ' + @ErrorExito;
    THROW;
END CATCH;
GO

/* ==========================================================
   PARTE B: PRUEBAS NEGATIVAS
   Cada baja debe rechazar una clave que no existe.
   ========================================================== */
PRINT 'INICIO: pruebas de rechazo de identificadores inexistentes.';

DECLARE @CasosNegativos TABLE (tabla VARCHAR(50), prueba VARCHAR(100), ejecutada BIT DEFAULT 0);

/* Se prueban explícitamente los 24 ABM con PK simple. */
BEGIN TRY EXEC mundial.sp_pais_Baja @id_pais=-999999; THROW 51000, 'FALLO: pais aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: pais'; END CATCH;
BEGIN TRY EXEC mundial.sp_seleccion_Baja @id_seleccion=-999999; THROW 51000, 'FALLO: seleccion aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: seleccion'; END CATCH;
BEGIN TRY EXEC mundial.sp_club_Baja @id_club=-999999; THROW 51000, 'FALLO: club aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: club'; END CATCH;
BEGIN TRY EXEC mundial.sp_cuerpo_tecnico_Baja @id_miembro_ct=-999999; THROW 51000, 'FALLO: cuerpo_tecnico aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: cuerpo_tecnico'; END CATCH;
BEGIN TRY EXEC mundial.sp_ciudad_Baja @id_ciudad=-999999; THROW 51000, 'FALLO: ciudad aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: ciudad'; END CATCH;
BEGIN TRY EXEC mundial.sp_anunciante_Baja @id_anunciante=-999999; THROW 51000, 'FALLO: anunciante aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: anunciante'; END CATCH;
BEGIN TRY EXEC mundial.sp_arbitro_Baja @id_arbitro=-999999; THROW 51000, 'FALLO: arbitro aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: arbitro'; END CATCH;
BEGIN TRY EXEC mundial.sp_jugador_Baja @id_jugador=-999999; THROW 51000, 'FALLO: jugador aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: jugador'; END CATCH;
BEGIN TRY EXEC mundial.sp_sede_estadio_Baja @id_sede=-999999; THROW 51000, 'FALLO: sede_estadio aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: sede_estadio'; END CATCH;
BEGIN TRY EXEC mundial.sp_campania_Baja @id_campania=-999999; THROW 51000, 'FALLO: campania aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: campania'; END CATCH;
BEGIN TRY EXEC mundial.sp_partido_Baja @id_partido=-999999; THROW 51000, 'FALLO: partido aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: partido'; END CATCH;
BEGIN TRY EXEC mundial.sp_pieza_publicitaria_Baja @id_pieza=-999999; THROW 51000, 'FALLO: pieza_publicitaria aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: pieza_publicitaria'; END CATCH;
BEGIN TRY EXEC mundial.sp_espacio_publicitario_Baja @id_espacio=-999999; THROW 51000, 'FALLO: espacio_publicitario aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: espacio_publicitario'; END CATCH;
BEGIN TRY EXEC mundial.sp_convocatoria_Baja @id_convocatoria=-999999; THROW 51000, 'FALLO: convocatoria aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: convocatoria'; END CATCH;
BEGIN TRY EXEC mundial.sp_novedad_convocatoria_Baja @id_novedad=-999999; THROW 51000, 'FALLO: novedad_convocatoria aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: novedad_convocatoria'; END CATCH;
BEGIN TRY EXEC mundial.sp_sustitucion_Baja @id_sustitucion=-999999; THROW 51000, 'FALLO: sustitucion aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: sustitucion'; END CATCH;
BEGIN TRY EXEC mundial.sp_gol_Baja @id_gol=-999999; THROW 51000, 'FALLO: gol aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: gol'; END CATCH;
BEGIN TRY EXEC mundial.sp_tarjeta_Baja @id_tarjeta=-999999; THROW 51000, 'FALLO: tarjeta aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: tarjeta'; END CATCH;
BEGIN TRY EXEC mundial.sp_suspension_jugador_Baja @id_suspension=-999999; THROW 51000, 'FALLO: suspension_jugador aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: suspension_jugador'; END CATCH;
BEGIN TRY EXEC mundial.sp_pauta_partido_Baja @id_pauta=-999999; THROW 51000, 'FALLO: pauta_partido aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: pauta_partido'; END CATCH;
BEGIN TRY EXEC mundial.sp_partido_equipo_detalle_Baja @id_partido_equipo=-999999; THROW 51000, 'FALLO: partido_equipo_detalle aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: partido_equipo_detalle'; END CATCH;
BEGIN TRY EXEC mundial.sp_designacion_arbitral_Baja @id_designacion=-999999; THROW 51000, 'FALLO: designacion_arbitral aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: designacion_arbitral'; END CATCH;
BEGIN TRY EXEC mundial.sp_informe_arbitral_Baja @id_informe=-999999; THROW 51000, 'FALLO: informe_arbitral aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: informe_arbitral'; END CATCH;
BEGIN TRY EXEC mundial.sp_alineacion_partido_Baja @id_alineacion=-999999; THROW 51000, 'FALLO: alineacion_partido aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: alineacion_partido'; END CATCH;

/* PK compuestas */
BEGIN TRY EXEC mundial.sp_arbitro_idioma_Baja @id_arbitro=-999999, @id_idioma=-999999; THROW 51000, 'FALLO: arbitro_idioma aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: arbitro_idioma'; END CATCH;
BEGIN TRY EXEC mundial.sp_pieza_pais_objetivo_Baja @id_pieza=-999999, @id_pais=-999999; THROW 51000, 'FALLO: pieza_pais_objetivo aceptó una baja inexistente.', 1; END TRY BEGIN CATCH IF ERROR_NUMBER() NOT IN (50102) THROW; ELSE PRINT 'OK validación: pieza_pais_objetivo'; END CATCH;


