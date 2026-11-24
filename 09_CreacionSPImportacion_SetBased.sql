/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-23
    Archivo: 09_CreacionSPImportacion_SetBased.sql
    Objetivo: Procedimientos almacenados para la importacion de fuentes externas (CSV, XML, JSON, Scraping)
              con validacion en Staging y delegacion a la capa de negocio masiva (TVP).
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* 1. GESTION DE LOTES */

CREATE OR ALTER PROCEDURE mundial.sp_importacion_iniciar_lote
    @id_fuente INT,
    @archivo VARCHAR(260),
    @entidad VARCHAR(128),
    @hash VARCHAR(128) = NULL,
    @id_lote INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @e NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.fuente_importacion WHERE id_fuente = @id_fuente AND activa = 1)
        SET @e += N'Fuente inexistente o inactiva. ';
    IF NULLIF(LTRIM(RTRIM(@archivo)), '') IS NULL
        SET @e += N'Archivo obligatorio. ';
    IF @archivo LIKE '%..%'
        SET @e += N'No se permiten rutas relativas. ';
    IF @hash IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.lote_importacion WHERE hash_archivo = @hash AND estado_lote IN ('COMPLETADO', 'PARCIAL'))
        SET @e += N'El archivo ya fue procesado. ';
    IF LEN(@e) > 0 THROW 53101, @e, 1;

    INSERT INTO mundial.lote_importacion
    (
        id_fuente, nombre_archivo, entidad_destino, fecha_inicio, estado_lote,
        cantidad_leidos, cantidad_insertados, cantidad_actualizados, cantidad_rechazados, hash_archivo
    )
    VALUES
    (
        @id_fuente, @archivo, @entidad, SYSDATETIME(), 'EN_PROCESO',
        0, 0, 0, 0, @hash
    );
    SET @id_lote = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_importacion_finalizar_lote
    @id_lote INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @l INT = (SELECT COUNT(*) FROM mundial.detalle_importacion WHERE id_lote = @id_lote),
            @i INT = (SELECT COUNT(*) FROM mundial.detalle_importacion WHERE id_lote = @id_lote AND tipo_operacion = 'INSERT'),
            @u INT = (SELECT COUNT(*) FROM mundial.detalle_importacion WHERE id_lote = @id_lote AND tipo_operacion = 'UPDATE'),
            @r INT = (SELECT COUNT(*) FROM mundial.detalle_importacion WHERE id_lote = @id_lote AND estado_registro = 'RECHAZADO');

    UPDATE mundial.lote_importacion
    SET fecha_fin = SYSDATETIME(),
        cantidad_leidos = @l,
        cantidad_insertados = @i,
        cantidad_actualizados = @u,
        cantidad_rechazados = @r,
        estado_lote = CASE
            WHEN @l = 0 OR @r = @l THEN 'FALLIDO'
            WHEN @r > 0 THEN 'PARCIAL'
            ELSE 'COMPLETADO'
        END
    WHERE id_lote = @id_lote;
END;
GO

/* 2. IMPORTACION DE PARTIDOS (CSV) -> TVP -> sp_partido_UpsertMasivo */

CREATE OR ALTER PROCEDURE mundial.sp_importar_partidos_csv
    @id_fuente INT,
    @archivo NVARCHAR(260),
    @hash VARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF LOWER(RIGHT(@archivo, 4)) <> '.csv'
        THROW 53102, N'Formato esperado: CSV.', 1;

    DECLARE @id_lote INT, @sql NVARCHAR(MAX), @archivo_vc VARCHAR(260) = CONVERT(VARCHAR(260), @archivo);
    EXEC mundial.sp_importacion_iniciar_lote @id_fuente, @archivo_vc, 'PARTIDO', @hash, @id_lote OUTPUT;

    BEGIN TRY
        CREATE TABLE #raw_partidos
        (
            clave_externa NVARCHAR(200),
            fase NVARCHAR(100),
            estadio NVARCHAR(200),
            pais_local_iso NVARCHAR(20),
            pais_visitante_iso NVARCHAR(20),
            fecha_hora_utc NVARCHAR(100),
            fecha_hora_local NVARCHAR(100),
            goles_local NVARCHAR(30),
            goles_visitante NVARCHAR(30),
            asistencia_publico NVARCHAR(30),
            estado_partido NVARCHAR(50)
        );

        SET @sql = N'BULK INSERT #raw_partidos FROM ' + QUOTENAME(@archivo, '''') + N' WITH (FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK);';
        EXEC sys.sp_executesql @sql;

        INSERT INTO mundial.stg_partido
        (
            id_lote, numero_fila, clave_externa, fase, estadio, pais_local_iso,
            pais_visitante_iso, fecha_hora_utc, fecha_hora_local, goles_local,
            goles_visitante, asistencia_publico, estado_partido
        )
        SELECT @id_lote, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), * FROM #raw_partidos;

        INSERT INTO mundial.detalle_importacion (id_lote, numero_fila, clave_externa, estado_registro, datos_originales)
        SELECT id_lote, numero_fila, clave_externa, 'PENDIENTE',
               CONCAT_WS('|', clave_externa, fase, estadio, pais_local_iso, pais_visitante_iso, fecha_hora_utc)
        FROM mundial.stg_partido
        WHERE id_lote = @id_lote;

        /* Validaciones */
        INSERT INTO mundial.error_importacion (id_detalle_importacion, codigo_error, campo_error, descripcion_error, valor_recibido)
        SELECT d.id_detalle_importacion, x.codigo, x.campo, x.mensaje, x.valor
        FROM mundial.stg_partido s
        JOIN mundial.detalle_importacion d ON d.id_lote = s.id_lote AND d.numero_fila = s.numero_fila
        CROSS APPLY
        (
            VALUES
            ('CLAVE', 'clave_externa', CASE WHEN NULLIF(s.clave_externa, '') IS NULL THEN 'Clave externa obligatoria.' END, s.clave_externa),
            ('FASE', 'fase', CASE WHEN NOT EXISTS (SELECT 1 FROM mundial.fase f WHERE f.nombre_fase = s.fase) THEN 'Fase inexistente.' END, s.fase),
            ('SEDE', 'estadio', CASE WHEN NOT EXISTS (SELECT 1 FROM mundial.sede_estadio e WHERE e.nombre_estadio = s.estadio) THEN 'Estadio inexistente.' END, s.estadio),
            ('LOCAL', 'pais_local_iso', CASE WHEN NOT EXISTS (SELECT 1 FROM mundial.pais p JOIN mundial.seleccion q ON q.id_pais = p.id_pais WHERE p.codigo_iso = s.pais_local_iso) THEN 'Seleccion local inexistente.' END, s.pais_local_iso),
            ('VISITANTE', 'pais_visitante_iso', CASE WHEN NOT EXISTS (SELECT 1 FROM mundial.pais p JOIN mundial.seleccion q ON q.id_pais = p.id_pais WHERE p.codigo_iso = s.pais_visitante_iso) THEN 'Seleccion visitante inexistente.' END, s.pais_visitante_iso),
            ('EQUIPOS', 'selecciones', CASE WHEN s.pais_local_iso = s.pais_visitante_iso THEN 'Las selecciones deben ser diferentes.' END, CONCAT(s.pais_local_iso, '/', s.pais_visitante_iso)),
            ('FECHAUTC', 'fecha_hora_utc', CASE WHEN TRY_CONVERT(DATETIME2(0), s.fecha_hora_utc, 126) IS NULL THEN 'Fecha UTC invalida.' END, s.fecha_hora_utc),
            ('FECHALOCAL', 'fecha_hora_local', CASE WHEN TRY_CONVERT(DATETIME2(0), s.fecha_hora_local, 126) IS NULL THEN 'Fecha local invalida.' END, s.fecha_hora_local),
            ('GOLESL', 'goles_local', CASE WHEN NULLIF(s.goles_local, '') IS NOT NULL AND TRY_CONVERT(TINYINT, s.goles_local) IS NULL THEN 'Goles local invalidos.' END, s.goles_local),
            ('GOLESV', 'goles_visitante', CASE WHEN NULLIF(s.goles_visitante, '') IS NOT NULL AND TRY_CONVERT(TINYINT, s.goles_visitante) IS NULL THEN 'Goles visitante invalidos.' END, s.goles_visitante),
            ('ASIST', 'asistencia_publico', CASE WHEN NULLIF(s.asistencia_publico, '') IS NOT NULL AND TRY_CONVERT(INT, s.asistencia_publico) IS NULL THEN 'Asistencia invalida.' END, s.asistencia_publico),
            ('ESTADO', 'estado_partido', CASE WHEN s.estado_partido NOT IN ('PROGRAMADO','EN_CURSO','FINALIZADO','SUSPENDIDO','CANCELADO') THEN 'Estado invalido.' END, s.estado_partido)
        ) x(codigo, campo, mensaje, valor)
        WHERE s.id_lote = @id_lote AND x.mensaje IS NOT NULL;

        /* Actualizar estado de detalle */
        UPDATE d
        SET estado_registro = CASE WHEN e.id_detalle_importacion IS NULL THEN 'VALIDO' ELSE 'RECHAZADO' END,
            fecha_procesamiento = SYSDATETIME()
        FROM mundial.detalle_importacion d
        LEFT JOIN (SELECT DISTINCT id_detalle_importacion FROM mundial.error_importacion) e
            ON e.id_detalle_importacion = d.id_detalle_importacion
        WHERE d.id_lote = @id_lote;

        /* Poblado de TVP y llamada al SP masivo */
        DECLARE @tvp_partidos mundial.tipo_partido_importacion;

        INSERT INTO @tvp_partidos
        (
            clave_externa, id_fase, id_sede, id_seleccion_local, id_seleccion_visitante,
            fecha_hora_utc, fecha_hora_local, goles_local, goles_visitante, asistencia_publico, estado_partido
        )
        SELECT
            s.clave_externa, f.id_fase, se.id_sede, sl.id_seleccion, sv.id_seleccion,
            TRY_CONVERT(DATETIME2(0), s.fecha_hora_utc, 126),
            TRY_CONVERT(DATETIME2(0), s.fecha_hora_local, 126),
            TRY_CONVERT(TINYINT, NULLIF(s.goles_local, '')),
            TRY_CONVERT(TINYINT, NULLIF(s.goles_visitante, '')),
            TRY_CONVERT(INT, NULLIF(s.asistencia_publico, '')),
            s.estado_partido
        FROM mundial.stg_partido s
        JOIN mundial.detalle_importacion d ON d.id_lote = s.id_lote AND d.numero_fila = s.numero_fila AND d.estado_registro = 'VALIDO'
        JOIN mundial.fase f ON f.nombre_fase = s.fase
        JOIN mundial.sede_estadio se ON se.nombre_estadio = s.estadio
        JOIN mundial.pais pl ON pl.codigo_iso = s.pais_local_iso
        JOIN mundial.seleccion sl ON sl.id_pais = pl.id_pais
        JOIN mundial.pais pv ON pv.codigo_iso = s.pais_visitante_iso
        JOIN mundial.seleccion sv ON sv.id_pais = pv.id_pais
        WHERE s.id_lote = @id_lote;

        /* Invocar SP Masivo de la capa de negocio */
        EXEC mundial.sp_partido_UpsertMasivo @id_fuente = @id_fuente, @id_lote = @id_lote, @Partidos = @tvp_partidos;

        /* Actualizar tipo_operacion en detalle */
        UPDATE d
        SET tipo_operacion = CASE
                WHEN r.fecha_primera_importacion = r.fecha_ultima_importacion THEN 'INSERT'
                ELSE 'UPDATE'
            END,
            estado_registro = 'PROCESADO'
        FROM mundial.detalle_importacion d
        JOIN mundial.stg_partido s ON s.id_lote = d.id_lote AND s.numero_fila = d.numero_fila
        JOIN mundial.registro_externo r ON r.id_fuente = @id_fuente AND r.entidad_destino = 'PARTIDO' AND r.clave_externa = s.clave_externa
        WHERE d.id_lote = @id_lote AND d.estado_registro = 'VALIDO';

        UPDATE mundial.detalle_importacion
        SET tipo_operacion = 'RECHAZADO'
        WHERE id_lote = @id_lote AND estado_registro = 'RECHAZADO';

        EXEC mundial.sp_importacion_finalizar_lote @id_lote;
        SELECT * FROM mundial.lote_importacion WHERE id_lote = @id_lote;
    END TRY
    BEGIN CATCH
        UPDATE mundial.lote_importacion SET fecha_fin = SYSDATETIME(), estado_lote = 'FALLIDO' WHERE id_lote = @id_lote;
        THROW;
    END CATCH;
END;
GO

/* 3. IMPORTACION DE PBI (XML) -> TVP -> sp_indicador_economico_UpsertMasivo */

CREATE OR ALTER PROCEDURE mundial.sp_importar_pbi_xml
    @id_fuente INT,
    @archivo NVARCHAR(260),
    @hash VARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF LOWER(RIGHT(@archivo, 4)) <> '.xml'
        THROW 53103, N'Formato esperado: XML.', 1;

    DECLARE @id_lote INT, @sql NVARCHAR(MAX), @xml XML, @archivo_vc VARCHAR(260) = CONVERT(VARCHAR(260), @archivo);
    EXEC mundial.sp_importacion_iniciar_lote @id_fuente, @archivo_vc, 'INDICADOR_ECONOMICO', @hash, @id_lote OUTPUT;

    BEGIN TRY
        CREATE TABLE #raw_xml (contenido VARBINARY(MAX));
        SET @sql = N'INSERT INTO #raw_xml SELECT BulkColumn FROM OPENROWSET(BULK ' + QUOTENAME(@archivo, '''') + N', SINGLE_BLOB) x;';
        EXEC sys.sp_executesql @sql;

        SELECT @xml = CONVERT(XML, contenido) FROM #raw_xml;

        INSERT INTO mundial.stg_indicador_economico
        (
            id_lote, numero_fila, clave_externa, codigo_pais, codigo_indicador, anio, valor, unidad, fuente
        )
        SELECT
            @id_lote,
            ROW_NUMBER() OVER(ORDER BY (SELECT NULL)),
            n.value('@key', 'NVARCHAR(200)'),
            n.value('@country', 'NVARCHAR(20)'),
            n.value('@indicator', 'NVARCHAR(50)'),
            n.value('@year', 'NVARCHAR(20)'),
            n.value('@value', 'NVARCHAR(100)'),
            n.value('@unit', 'NVARCHAR(50)'),
            n.value('@source', 'NVARCHAR(150)')
        FROM @xml.nodes('/indicators/record') t(n);

        INSERT INTO mundial.detalle_importacion (id_lote, numero_fila, clave_externa, estado_registro, datos_originales)
        SELECT id_lote, numero_fila, clave_externa, 'PENDIENTE',
               CONCAT_WS('|', codigo_pais, codigo_indicador, anio, valor, unidad, fuente)
        FROM mundial.stg_indicador_economico
        WHERE id_lote = @id_lote;

        /* Validaciones */
        INSERT INTO mundial.error_importacion (id_detalle_importacion, codigo_error, campo_error, descripcion_error, valor_recibido)
        SELECT d.id_detalle_importacion, x.codigo, x.campo, x.mensaje, x.valor
        FROM mundial.stg_indicador_economico s
        JOIN mundial.detalle_importacion d ON d.id_lote = s.id_lote AND d.numero_fila = s.numero_fila
        CROSS APPLY
        (
            VALUES
            ('PAIS', 'codigo_pais', CASE WHEN NOT EXISTS (SELECT 1 FROM mundial.pais p WHERE p.codigo_iso = s.codigo_pais) THEN 'Pais inexistente.' END, s.codigo_pais),
            ('ANIO', 'anio', CASE WHEN TRY_CONVERT(SMALLINT, s.anio) NOT BETWEEN 1900 AND 2100 THEN 'Anio invalido.' END, s.anio),
            ('VALOR', 'valor', CASE WHEN TRY_CONVERT(DECIMAL(20,4), s.valor) IS NULL OR TRY_CONVERT(DECIMAL(20,4), s.valor) < 0 THEN 'Valor invalido.' END, s.valor),
            ('INDICADOR', 'codigo_indicador', CASE WHEN NULLIF(s.codigo_indicador, '') IS NULL THEN 'Indicador obligatorio.' END, s.codigo_indicador),
            ('FUENTE', 'fuente', CASE WHEN NULLIF(s.fuente, '') IS NULL THEN 'Fuente obligatoria.' END, s.fuente)
        ) x(codigo, campo, mensaje, valor)
        WHERE s.id_lote = @id_lote AND x.mensaje IS NOT NULL;

        UPDATE d
        SET estado_registro = CASE WHEN e.id_detalle_importacion IS NULL THEN 'VALIDO' ELSE 'RECHAZADO' END,
            fecha_procesamiento = SYSDATETIME()
        FROM mundial.detalle_importacion d
        LEFT JOIN (SELECT DISTINCT id_detalle_importacion FROM mundial.error_importacion) e
            ON e.id_detalle_importacion = d.id_detalle_importacion
        WHERE d.id_lote = @id_lote;

        /* Poblado de TVP y llamada al SP masivo */
        DECLARE @tvp_indicadores mundial.tipo_indicador_importacion;

        INSERT INTO @tvp_indicadores
        (
            clave_externa, id_pais, codigo_indicador, anio, valor, unidad, fuente
        )
        SELECT
            s.clave_externa, p.id_pais, s.codigo_indicador,
            TRY_CONVERT(SMALLINT, s.anio),
            TRY_CONVERT(DECIMAL(20,4), s.valor),
            s.unidad, s.fuente
        FROM mundial.stg_indicador_economico s
        JOIN mundial.detalle_importacion d ON d.id_lote = s.id_lote AND d.numero_fila = s.numero_fila AND d.estado_registro = 'VALIDO'
        JOIN mundial.pais p ON p.codigo_iso = s.codigo_pais
        WHERE s.id_lote = @id_lote;

        /* Identificar pre-existencia para clasificar operacion en detalle */
        SELECT s.id_stg_indicador,
               CASE WHEN i.id_indicador IS NOT NULL THEN 'UPDATE' ELSE 'INSERT' END AS operacion
        INTO #op_indicadores
        FROM mundial.stg_indicador_economico s
        JOIN mundial.detalle_importacion d ON d.id_lote = s.id_lote AND d.numero_fila = s.numero_fila AND d.estado_registro = 'VALIDO'
        JOIN mundial.pais p ON p.codigo_iso = s.codigo_pais
        LEFT JOIN mundial.indicador_economico_pais i
            ON i.id_pais = p.id_pais AND i.codigo_indicador = s.codigo_indicador AND i.anio = TRY_CONVERT(SMALLINT, s.anio) AND i.fuente = s.fuente
        WHERE s.id_lote = @id_lote;

        EXEC mundial.sp_indicador_economico_UpsertMasivo @id_fuente = @id_fuente, @id_lote = @id_lote, @Indicadores = @tvp_indicadores;

        UPDATE d
        SET tipo_operacion = op.operacion,
            estado_registro = 'PROCESADO'
        FROM mundial.detalle_importacion d
        JOIN mundial.stg_indicador_economico s ON s.id_lote = d.id_lote AND s.numero_fila = d.numero_fila
        JOIN #op_indicadores op ON op.id_stg_indicador = s.id_stg_indicador
        WHERE d.id_lote = @id_lote AND d.estado_registro = 'VALIDO';

        UPDATE mundial.detalle_importacion
        SET tipo_operacion = 'RECHAZADO'
        WHERE id_lote = @id_lote AND estado_registro = 'RECHAZADO';

        EXEC mundial.sp_importacion_finalizar_lote @id_lote;
        SELECT * FROM mundial.lote_importacion WHERE id_lote = @id_lote;
    END TRY
    BEGIN CATCH
        UPDATE mundial.lote_importacion SET fecha_fin = SYSDATETIME(), estado_lote = 'FALLIDO' WHERE id_lote = @id_lote;
        THROW;
    END CATCH;
END;
GO

/* 4. IMPORTACION DE ARBITROS (SCRAPING CSV) -> TVP -> sp_arbitro_UpsertMasivo */

CREATE OR ALTER PROCEDURE mundial.sp_importar_arbitros_csv
    @id_fuente INT,
    @archivo NVARCHAR(260),
    @hash VARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF LOWER(RIGHT(@archivo, 4)) <> '.csv'
        THROW 53104, N'Formato esperado: CSV.', 1;

    DECLARE @id_lote INT, @sql NVARCHAR(MAX), @archivo_vc VARCHAR(260) = CONVERT(VARCHAR(260), @archivo);
    EXEC mundial.sp_importacion_iniciar_lote @id_fuente, @archivo_vc, 'ARBITRO', @hash, @id_lote OUTPUT;

    BEGIN TRY
        CREATE TABLE #raw_arbitros
        (
            clave_externa NVARCHAR(200),
            nombres NVARCHAR(200),
            apellidos NVARCHAR(200),
            codigo_pais NVARCHAR(20),
            confederacion NVARCHAR(100),
            categoria NVARCHAR(100),
            fecha_nacimiento NVARCHAR(100),
            ediciones_mundial NVARCHAR(500)
        );

        SET @sql = N'BULK INSERT #raw_arbitros FROM ' + QUOTENAME(@archivo, '''') + N' WITH (FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK);';
        EXEC sys.sp_executesql @sql;

        INSERT INTO mundial.stg_arbitro
        (
            id_lote, numero_fila, clave_externa, nombres, apellidos, codigo_pais,
            confederacion, categoria, fecha_nacimiento, ediciones_mundial
        )
        SELECT @id_lote, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), * FROM #raw_arbitros;

        INSERT INTO mundial.detalle_importacion (id_lote, numero_fila, clave_externa, estado_registro, datos_originales)
        SELECT id_lote, numero_fila, clave_externa, 'PENDIENTE',
               CONCAT_WS('|', clave_externa, nombres, apellidos, codigo_pais, confederacion, categoria, fecha_nacimiento)
        FROM mundial.stg_arbitro
        WHERE id_lote = @id_lote;

        /* Validaciones */
        INSERT INTO mundial.error_importacion (id_detalle_importacion, codigo_error, campo_error, descripcion_error, valor_recibido)
        SELECT d.id_detalle_importacion, x.codigo, x.campo, x.mensaje, x.valor
        FROM mundial.stg_arbitro s
        JOIN mundial.detalle_importacion d ON d.id_lote = s.id_lote AND d.numero_fila = s.numero_fila
        CROSS APPLY
        (
            VALUES
            ('CLAVE', 'clave_externa', CASE WHEN NULLIF(s.clave_externa, '') IS NULL THEN 'Clave externa obligatoria.' END, s.clave_externa),
            ('NOMBRES', 'nombres', CASE WHEN NULLIF(s.nombres, '') IS NULL THEN 'Nombres obligatorios.' END, s.nombres),
            ('APELLIDOS', 'apellidos', CASE WHEN NULLIF(s.apellidos, '') IS NULL THEN 'Apellidos obligatorios.' END, s.apellidos),
            ('PAIS', 'codigo_pais', CASE WHEN NOT EXISTS (SELECT 1 FROM mundial.pais p WHERE p.codigo_iso = s.codigo_pais) THEN 'Pais inexistente.' END, s.codigo_pais),
            ('CONFEDERACION', 'confederacion', CASE WHEN NOT EXISTS (SELECT 1 FROM mundial.confederacion c WHERE c.sigla = s.confederacion OR c.nombre = s.confederacion) THEN 'Confederacion inexistente.' END, s.confederacion),
            ('FECHANAC', 'fecha_nacimiento', CASE WHEN TRY_CONVERT(DATE, s.fecha_nacimiento, 126) IS NULL THEN 'Fecha de nacimiento invalida.' END, s.fecha_nacimiento),
            ('CATEGORIA', 'categoria', CASE WHEN NULLIF(s.categoria, '') IS NULL THEN 'Categoria obligatoria.' END, s.categoria)
        ) x(codigo, campo, mensaje, valor)
        WHERE s.id_lote = @id_lote AND x.mensaje IS NOT NULL;

        UPDATE d
        SET estado_registro = CASE WHEN e.id_detalle_importacion IS NULL THEN 'VALIDO' ELSE 'RECHAZADO' END,
            fecha_procesamiento = SYSDATETIME()
        FROM mundial.detalle_importacion d
        LEFT JOIN (SELECT DISTINCT id_detalle_importacion FROM mundial.error_importacion) e
            ON e.id_detalle_importacion = d.id_detalle_importacion
        WHERE d.id_lote = @id_lote;

        /* Poblado de TVP y llamada a SP masivo */
        DECLARE @tvp_arbitros mundial.tipo_arbitro_importacion;

        INSERT INTO @tvp_arbitros
        (
            clave_externa, nombres, apellidos, id_pais_nacionalidad, id_confederacion_afiliacion,
            fecha_nacimiento, categoria
        )
        SELECT
            s.clave_externa, s.nombres, s.apellidos, p.id_pais, c.id_confederacion,
            TRY_CONVERT(DATE, s.fecha_nacimiento, 126),
            s.categoria
        FROM mundial.stg_arbitro s
        JOIN mundial.detalle_importacion d ON d.id_lote = s.id_lote AND d.numero_fila = s.numero_fila AND d.estado_registro = 'VALIDO'
        JOIN mundial.pais p ON p.codigo_iso = s.codigo_pais
        JOIN mundial.confederacion c ON c.sigla = s.confederacion OR c.nombre = s.confederacion
        WHERE s.id_lote = @id_lote;

        EXEC mundial.sp_arbitro_UpsertMasivo @id_fuente = @id_fuente, @id_lote = @id_lote, @Arbitros = @tvp_arbitros;

        UPDATE d
        SET tipo_operacion = CASE
                WHEN r.fecha_primera_importacion = r.fecha_ultima_importacion THEN 'INSERT'
                ELSE 'UPDATE'
            END,
            estado_registro = 'PROCESADO'
        FROM mundial.detalle_importacion d
        JOIN mundial.stg_arbitro s ON s.id_lote = d.id_lote AND s.numero_fila = d.numero_fila
        JOIN mundial.registro_externo r ON r.id_fuente = @id_fuente AND r.entidad_destino = 'ARBITRO' AND r.clave_externa = s.clave_externa
        WHERE d.id_lote = @id_lote AND d.estado_registro = 'VALIDO';

        UPDATE mundial.detalle_importacion
        SET tipo_operacion = 'RECHAZADO'
        WHERE id_lote = @id_lote AND estado_registro = 'RECHAZADO';

        EXEC mundial.sp_importacion_finalizar_lote @id_lote;
        SELECT * FROM mundial.lote_importacion WHERE id_lote = @id_lote;
    END TRY
    BEGIN CATCH
        UPDATE mundial.lote_importacion SET fecha_fin = SYSDATETIME(), estado_lote = 'FALLIDO' WHERE id_lote = @id_lote;
        THROW;
    END CATCH;
END;
GO

/* 5. IMPORTACION DE TIPOS DE CAMBIO (API JSON) -> TVP -> sp_tipo_cambio_UpsertMasivo */

CREATE OR ALTER PROCEDURE mundial.sp_importar_tipo_cambio_json
    @id_fuente INT,
    @archivo NVARCHAR(260),
    @hash VARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF LOWER(RIGHT(@archivo, 5)) <> '.json'
        THROW 53105, N'Formato esperado: JSON.', 1;

    DECLARE @id_lote INT, @sql NVARCHAR(MAX), @json NVARCHAR(MAX), @archivo_vc VARCHAR(260) = CONVERT(VARCHAR(260), @archivo);
    EXEC mundial.sp_importacion_iniciar_lote @id_fuente, @archivo_vc, 'TIPO_CAMBIO', @hash, @id_lote OUTPUT;

    BEGIN TRY
        CREATE TABLE #raw_json (contenido VARCHAR(MAX));
        SET @sql = N'INSERT INTO #raw_json SELECT BulkColumn FROM OPENROWSET(BULK ' + QUOTENAME(@archivo, '''') + N', SINGLE_CLOB) x;';
        EXEC sys.sp_executesql @sql;

        SELECT @json = CONVERT(NVARCHAR(MAX), contenido) FROM #raw_json;

        /* Parsear estructura Frankfurter: { "amount": 1.0, "base": "USD", "date": "2026-11-20", "rates": { "EUR": 0.95, ... } } */
        INSERT INTO mundial.stg_tipo_cambio
        (
            id_lote, numero_fila, moneda_origen, moneda_destino, fecha_cotizacion, cotizacion, fuente
        )
        SELECT
            @id_lote,
            ROW_NUMBER() OVER(ORDER BY (SELECT NULL)),
            JSON_VALUE(@json, '$.base'),
            r.[key],
            JSON_VALUE(@json, '$.date'),
            r.[value],
            'API Frankfurter'
        FROM OPENJSON(@json, '$.rates') r;

        INSERT INTO mundial.detalle_importacion (id_lote, numero_fila, clave_externa, estado_registro, datos_originales)
        SELECT id_lote, numero_fila, CONCAT_WS('_', moneda_origen, moneda_destino, fecha_cotizacion), 'PENDIENTE',
               CONCAT_WS('|', moneda_origen, moneda_destino, fecha_cotizacion, cotizacion, fuente)
        FROM mundial.stg_tipo_cambio
        WHERE id_lote = @id_lote;

        /* Validaciones */
        INSERT INTO mundial.error_importacion (id_detalle_importacion, codigo_error, campo_error, descripcion_error, valor_recibido)
        SELECT d.id_detalle_importacion, x.codigo, x.campo, x.mensaje, x.valor
        FROM mundial.stg_tipo_cambio s
        JOIN mundial.detalle_importacion d ON d.id_lote = s.id_lote AND d.numero_fila = s.numero_fila
        CROSS APPLY
        (
            VALUES
            ('ORIGEN', 'moneda_origen', CASE WHEN NOT EXISTS (SELECT 1 FROM mundial.moneda m WHERE m.codigo_iso = s.moneda_origen) THEN 'Moneda origen inexistente.' END, s.moneda_origen),
            ('DESTINO', 'moneda_destino', CASE WHEN NOT EXISTS (SELECT 1 FROM mundial.moneda m WHERE m.codigo_iso = s.moneda_destino) THEN 'Moneda destino inexistente.' END, s.moneda_destino),
            ('FECHA', 'fecha_cotizacion', CASE WHEN TRY_CONVERT(DATE, s.fecha_cotizacion, 126) IS NULL THEN 'Fecha cotizacion invalida.' END, s.fecha_cotizacion),
            ('COTIZACION', 'cotizacion', CASE WHEN TRY_CONVERT(DECIMAL(18,8), s.cotizacion) IS NULL OR TRY_CONVERT(DECIMAL(18,8), s.cotizacion) <= 0 THEN 'Cotizacion invalida.' END, s.cotizacion)
        ) x(codigo, campo, mensaje, valor)
        WHERE s.id_lote = @id_lote AND x.mensaje IS NOT NULL;

        UPDATE d
        SET estado_registro = CASE WHEN e.id_detalle_importacion IS NULL THEN 'VALIDO' ELSE 'RECHAZADO' END,
            fecha_procesamiento = SYSDATETIME()
        FROM mundial.detalle_importacion d
        LEFT JOIN (SELECT DISTINCT id_detalle_importacion FROM mundial.error_importacion) e
            ON e.id_detalle_importacion = d.id_detalle_importacion
        WHERE d.id_lote = @id_lote;

        /* Poblado de TVP y llamada a SP masivo */
        DECLARE @tvp_cambio mundial.tipo_tipo_cambio_importacion;

        INSERT INTO @tvp_cambio
        (
            id_moneda_origen, id_moneda_destino, fecha_cotizacion, cotizacion, fuente
        )
        SELECT
            mo.id_moneda, md.id_moneda,
            TRY_CONVERT(DATE, s.fecha_cotizacion, 126),
            TRY_CONVERT(DECIMAL(18,8), s.cotizacion),
            s.fuente
        FROM mundial.stg_tipo_cambio s
        JOIN mundial.detalle_importacion d ON d.id_lote = s.id_lote AND d.numero_fila = s.numero_fila AND d.estado_registro = 'VALIDO'
        JOIN mundial.moneda mo ON mo.codigo_iso = s.moneda_origen
        JOIN mundial.moneda md ON md.codigo_iso = s.moneda_destino
        WHERE s.id_lote = @id_lote;

        SELECT s.id_stg_tipo_cambio,
               CASE WHEN tc.id_tipo_cambio IS NOT NULL THEN 'UPDATE' ELSE 'INSERT' END AS operacion
        INTO #op_cambio
        FROM mundial.stg_tipo_cambio s
        JOIN mundial.detalle_importacion d ON d.id_lote = s.id_lote AND d.numero_fila = s.numero_fila AND d.estado_registro = 'VALIDO'
        JOIN mundial.moneda mo ON mo.codigo_iso = s.moneda_origen
        JOIN mundial.moneda md ON md.codigo_iso = s.moneda_destino
        LEFT JOIN mundial.tipo_cambio tc
            ON tc.id_moneda_origen = mo.id_moneda AND tc.id_moneda_destino = md.id_moneda
            AND tc.fecha_cotizacion = TRY_CONVERT(DATE, s.fecha_cotizacion, 126) AND tc.fuente = s.fuente
        WHERE s.id_lote = @id_lote;

        EXEC mundial.sp_tipo_cambio_UpsertMasivo @id_fuente = @id_fuente, @id_lote = @id_lote, @Cotizaciones = @tvp_cambio;

        UPDATE d
        SET tipo_operacion = op.operacion,
            estado_registro = 'PROCESADO'
        FROM mundial.detalle_importacion d
        JOIN mundial.stg_tipo_cambio s ON s.id_lote = d.id_lote AND s.numero_fila = d.numero_fila
        JOIN #op_cambio op ON op.id_stg_tipo_cambio = s.id_stg_tipo_cambio
        WHERE d.id_lote = @id_lote AND d.estado_registro = 'VALIDO';

        UPDATE mundial.detalle_importacion
        SET tipo_operacion = 'RECHAZADO'
        WHERE id_lote = @id_lote AND estado_registro = 'RECHAZADO';

        EXEC mundial.sp_importacion_finalizar_lote @id_lote;
        SELECT * FROM mundial.lote_importacion WHERE id_lote = @id_lote;
    END TRY
    BEGIN CATCH
        UPDATE mundial.lote_importacion SET fecha_fin = SYSDATETIME(), estado_lote = 'FALLIDO' WHERE id_lote = @id_lote;
        THROW;
    END CATCH;
END;
GO
