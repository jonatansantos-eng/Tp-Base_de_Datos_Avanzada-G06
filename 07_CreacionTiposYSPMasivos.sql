/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-23
    Archivo: 07_CreacionTiposYSPMasivos.sql
    Objetivo: Crear los Table-Valued Parameters (TVP) y los Stored Procedures de negocio masivos
              para la manipulacion set-based de datos externos (reutilizacion Entrega 5 / Entrega 6).
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* =========================================================================
   1. DEFINICION DE TABLE-VALUED PARAMETERS (TVP)
   ========================================================================= */

IF TYPE_ID(N'mundial.tipo_partido_importacion') IS NULL
BEGIN
    CREATE TYPE mundial.tipo_partido_importacion AS TABLE
    (
        clave_externa VARCHAR(200) NOT NULL,
        id_fase INT NOT NULL,
        id_sede INT NOT NULL,
        id_seleccion_local INT NOT NULL,
        id_seleccion_visitante INT NOT NULL,
        fecha_hora_utc DATETIME2(0) NOT NULL,
        fecha_hora_local DATETIME2(0) NOT NULL,
        goles_local TINYINT NULL,
        goles_visitante TINYINT NULL,
        asistencia_publico INT NULL,
        estado_partido VARCHAR(20) NOT NULL
    );
END;
GO

IF TYPE_ID(N'mundial.tipo_indicador_importacion') IS NULL
BEGIN
    CREATE TYPE mundial.tipo_indicador_importacion AS TABLE
    (
        clave_externa VARCHAR(200) NULL,
        id_pais INT NOT NULL,
        codigo_indicador VARCHAR(50) NOT NULL,
        anio SMALLINT NOT NULL,
        valor DECIMAL(20,4) NOT NULL,
        unidad VARCHAR(50) NOT NULL,
        fuente VARCHAR(150) NOT NULL
    );
END;
GO

IF TYPE_ID(N'mundial.tipo_arbitro_importacion') IS NULL
BEGIN
    CREATE TYPE mundial.tipo_arbitro_importacion AS TABLE
    (
        clave_externa VARCHAR(200) NOT NULL,
        nombres VARCHAR(100) NOT NULL,
        apellidos VARCHAR(100) NOT NULL,
        id_pais_nacionalidad INT NOT NULL,
        id_confederacion_afiliacion INT NOT NULL,
        fecha_nacimiento DATE NOT NULL,
        categoria VARCHAR(50) NOT NULL
    );
END;
GO

IF TYPE_ID(N'mundial.tipo_tipo_cambio_importacion') IS NULL
BEGIN
    CREATE TYPE mundial.tipo_tipo_cambio_importacion AS TABLE
    (
        id_moneda_origen INT NOT NULL,
        id_moneda_destino INT NOT NULL,
        fecha_cotizacion DATE NOT NULL,
        cotizacion DECIMAL(18,8) NOT NULL,
        fuente VARCHAR(100) NOT NULL
    );
END;
GO

/* =========================================================================
   2. STORED PROCEDURES DE NEGOCIO MASIVOS (SET-BASED)
   ========================================================================= */

/* --- 2.1 Upsert Masivo de Partidos --- */
CREATE OR ALTER PROCEDURE mundial.sp_partido_UpsertMasivo
    @id_fuente INT,
    @id_lote INT,
    @Partidos mundial.tipo_partido_importacion READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM mundial.fuente_importacion WHERE id_fuente = @id_fuente)
        THROW 52001, N'La fuente especificada no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM mundial.lote_importacion WHERE id_lote = @id_lote)
        THROW 52002, N'El lote especificado no existe.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* Actualizacion de partidos existentes por registro externo */
        UPDATE p
        SET p.id_fase = x.id_fase,
            p.id_sede = x.id_sede,
            p.id_seleccion_local = x.id_seleccion_local,
            p.id_seleccion_visitante = x.id_seleccion_visitante,
            p.fecha_hora_utc = x.fecha_hora_utc,
            p.fecha_hora_local = x.fecha_hora_local,
            p.goles_local = x.goles_local,
            p.goles_visitante = x.goles_visitante,
            p.asistencia_publico = x.asistencia_publico,
            p.estado_partido = x.estado_partido
        FROM mundial.partido p
        INNER JOIN mundial.registro_externo r
            ON r.id_registro_destino = p.id_partido
            AND r.id_fuente = @id_fuente
            AND r.entidad_destino = 'PARTIDO'
        INNER JOIN @Partidos x
            ON x.clave_externa = r.clave_externa;

        UPDATE r
        SET r.fecha_ultima_importacion = SYSDATETIME()
        FROM mundial.registro_externo r
        INNER JOIN @Partidos x
            ON x.clave_externa = r.clave_externa
        WHERE r.id_fuente = @id_fuente
          AND r.entidad_destino = 'PARTIDO';

        /* Insercion de partidos nuevos */
        DECLARE @NuevosPartidos TABLE
        (
            clave_externa VARCHAR(200),
            id_partido INT,
            id_local INT,
            id_visitante INT
        );

        ;WITH PartidosFaltantes AS
        (
            SELECT x.*
            FROM @Partidos x
            WHERE NOT EXISTS
            (
                SELECT 1
                FROM mundial.registro_externo r
                WHERE r.id_fuente = @id_fuente
                  AND r.entidad_destino = 'PARTIDO'
                  AND r.clave_externa = x.clave_externa
            )
        )
        MERGE mundial.partido AS target
        USING PartidosFaltantes AS src
        ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT
            (
                id_fase, id_sede, id_seleccion_local, id_seleccion_visitante,
                fecha_hora_utc, fecha_hora_local, goles_local, goles_visitante,
                penales_local, penales_visitante, asistencia_publico, estado_partido
            )
            VALUES
            (
                src.id_fase, src.id_sede, src.id_seleccion_local, src.id_seleccion_visitante,
                src.fecha_hora_utc, src.fecha_hora_local, src.goles_local, src.goles_visitante,
                NULL, NULL, src.asistencia_publico, src.estado_partido
            )
        OUTPUT src.clave_externa, inserted.id_partido, src.id_seleccion_local, src.id_seleccion_visitante
        INTO @NuevosPartidos (clave_externa, id_partido, id_local, id_visitante);

        /* Registrar trazabilidad en registro_externo */
        INSERT INTO mundial.registro_externo
        (
            id_fuente, entidad_destino, clave_externa, id_registro_destino,
            fecha_primera_importacion, fecha_ultima_importacion
        )
        SELECT @id_fuente, 'PARTIDO', np.clave_externa, np.id_partido, SYSDATETIME(), SYSDATETIME()
        FROM @NuevosPartidos np;

        /* Asegurar partido_equipo_detalle para LOCAL y VISITANTE */
        INSERT INTO mundial.partido_equipo_detalle (id_partido, id_seleccion, condicion, esquema_tactico)
        SELECT np.id_partido, np.id_local, 'LOCAL', NULL
        FROM @NuevosPartidos np
        WHERE NOT EXISTS
        (
            SELECT 1 FROM mundial.partido_equipo_detalle d
            WHERE d.id_partido = np.id_partido AND d.condicion = 'LOCAL'
        );

        INSERT INTO mundial.partido_equipo_detalle (id_partido, id_seleccion, condicion, esquema_tactico)
        SELECT np.id_partido, np.id_visitante, 'VISITANTE', NULL
        FROM @NuevosPartidos np
        WHERE NOT EXISTS
        (
            SELECT 1 FROM mundial.partido_equipo_detalle d
            WHERE d.id_partido = np.id_partido AND d.condicion = 'VISITANTE'
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* --- 2.2 Upsert Masivo de Indicadores Economicos --- */
CREATE OR ALTER PROCEDURE mundial.sp_indicador_economico_UpsertMasivo
    @id_fuente INT,
    @id_lote INT,
    @Indicadores mundial.tipo_indicador_importacion READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM mundial.fuente_importacion WHERE id_fuente = @id_fuente)
        THROW 52003, N'La fuente especificada no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM mundial.lote_importacion WHERE id_lote = @id_lote)
        THROW 52004, N'El lote especificado no existe.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* Actualizar existentes por clave natural (id_pais, codigo_indicador, anio, fuente) */
        UPDATE i
        SET i.valor = src.valor,
            i.unidad = src.unidad,
            i.id_lote = @id_lote,
            i.fecha_importacion = SYSDATETIME()
        FROM mundial.indicador_economico_pais i
        INNER JOIN @Indicadores src
            ON src.id_pais = i.id_pais
            AND src.codigo_indicador = i.codigo_indicador
            AND src.anio = i.anio
            AND src.fuente = i.fuente;

        /* Insertar faltantes */
        INSERT INTO mundial.indicador_economico_pais
        (
            id_pais, id_lote, codigo_indicador, anio, valor, unidad, fuente, fecha_importacion
        )
        SELECT src.id_pais, @id_lote, src.codigo_indicador, src.anio, src.valor, src.unidad, src.fuente, SYSDATETIME()
        FROM @Indicadores src
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM mundial.indicador_economico_pais i
            WHERE i.id_pais = src.id_pais
              AND i.codigo_indicador = src.codigo_indicador
              AND i.anio = src.anio
              AND i.fuente = src.fuente
        );

        /* Actualizar PBI per capita representativo en pais */
        UPDATE p
        SET p.pbi_per_capita = x.valor
        FROM mundial.pais p
        CROSS APPLY
        (
            SELECT TOP(1) i.valor
            FROM mundial.indicador_economico_pais i
            WHERE i.id_pais = p.id_pais
              AND i.codigo_indicador = 'NY.GDP.PCAP.CD'
            ORDER BY i.anio DESC
        ) x;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* --- 2.3 Upsert Masivo de Arbitros --- */
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_UpsertMasivo
    @id_fuente INT,
    @id_lote INT,
    @Arbitros mundial.tipo_arbitro_importacion READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM mundial.fuente_importacion WHERE id_fuente = @id_fuente)
        THROW 52005, N'La fuente especificada no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM mundial.lote_importacion WHERE id_lote = @id_lote)
        THROW 52006, N'El lote especificado no existe.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* Actualizar arbitros existentes segun registro_externo */
        UPDATE a
        SET a.nombres = src.nombres,
            a.apellidos = src.apellidos,
            a.id_pais_nacionalidad = src.id_pais_nacionalidad,
            a.id_confederacion_afiliacion = src.id_confederacion_afiliacion,
            a.fecha_nacimiento = src.fecha_nacimiento,
            a.categoria = src.categoria
        FROM mundial.arbitro a
        INNER JOIN mundial.registro_externo r
            ON r.id_registro_destino = a.id_arbitro
            AND r.id_fuente = @id_fuente
            AND r.entidad_destino = 'ARBITRO'
        INNER JOIN @Arbitros src
            ON src.clave_externa = r.clave_externa;

        UPDATE r
        SET r.fecha_ultima_importacion = SYSDATETIME()
        FROM mundial.registro_externo r
        INNER JOIN @Arbitros src
            ON src.clave_externa = r.clave_externa
        WHERE r.id_fuente = @id_fuente
          AND r.entidad_destino = 'ARBITRO';

        /* Insertar arbitros nuevos */
        DECLARE @NuevosArbitros TABLE (clave_externa VARCHAR(200), id_arbitro INT);

        ;WITH ArbitrosFaltantes AS
        (
            SELECT src.*
            FROM @Arbitros src
            WHERE NOT EXISTS
            (
                SELECT 1
                FROM mundial.registro_externo r
                WHERE r.id_fuente = @id_fuente
                  AND r.entidad_destino = 'ARBITRO'
                  AND r.clave_externa = src.clave_externa
            )
        )
        MERGE mundial.arbitro AS target
        USING ArbitrosFaltantes AS src
        ON 1 = 0
        WHEN NOT MATCHED THEN
            INSERT (id_pais_nacionalidad, id_confederacion_afiliacion, nombres, apellidos, fecha_nacimiento, categoria)
            VALUES (src.id_pais_nacionalidad, src.id_confederacion_afiliacion, src.nombres, src.apellidos, src.fecha_nacimiento, src.categoria)
        OUTPUT src.clave_externa, inserted.id_arbitro INTO @NuevosArbitros(clave_externa, id_arbitro);

        INSERT INTO mundial.registro_externo
        (
            id_fuente, entidad_destino, clave_externa, id_registro_destino,
            fecha_primera_importacion, fecha_ultima_importacion
        )
        SELECT @id_fuente, 'ARBITRO', na.clave_externa, na.id_arbitro, SYSDATETIME(), SYSDATETIME()
        FROM @NuevosArbitros na;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* --- 2.4 Upsert Masivo de Tipos de Cambio --- */
CREATE OR ALTER PROCEDURE mundial.sp_tipo_cambio_UpsertMasivo
    @id_fuente INT,
    @id_lote INT,
    @Cotizaciones mundial.tipo_tipo_cambio_importacion READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM mundial.fuente_importacion WHERE id_fuente = @id_fuente)
        THROW 52007, N'La fuente especificada no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM mundial.lote_importacion WHERE id_lote = @id_lote)
        THROW 52008, N'El lote especificado no existe.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        /* Actualizar cotizaciones para el mismo dia y fuente */
        UPDATE tc
        SET tc.cotizacion = src.cotizacion,
            tc.id_lote = @id_lote
        FROM mundial.tipo_cambio tc
        INNER JOIN @Cotizaciones src
            ON src.id_moneda_origen = tc.id_moneda_origen
            AND src.id_moneda_destino = tc.id_moneda_destino
            AND src.fecha_cotizacion = tc.fecha_cotizacion
            AND src.fuente = tc.fuente;

        /* Insertar cotizaciones nuevas */
        INSERT INTO mundial.tipo_cambio
        (
            id_moneda_origen, id_moneda_destino, id_lote, fecha_cotizacion, cotizacion, fuente
        )
        SELECT src.id_moneda_origen, src.id_moneda_destino, @id_lote, src.fecha_cotizacion, src.cotizacion, src.fuente
        FROM @Cotizaciones src
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM mundial.tipo_cambio tc
            WHERE tc.id_moneda_origen = src.id_moneda_origen
              AND tc.id_moneda_destino = src.id_moneda_destino
              AND tc.fecha_cotizacion = src.fecha_cotizacion
              AND tc.fuente = src.fuente
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
