/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-23
    Archivo: 10_TestSPImportacion_SetBased.sql
    Objetivo: Pruebas integrales de importacion masiva (CSV de partidos, XML de PBI, CSV de arbitros, JSON de tipo de cambio).
              Demostracion de Upsert, errores parciales y control de hashes duplicados.
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'--- Iniciando pruebas de importacion masiva set-based ---';

/* 1. Asegurar catalogos minimos para que las importaciones puedan resolver referencias */
IF NOT EXISTS (SELECT 1 FROM mundial.confederacion WHERE sigla = 'CONMEBOL')
    INSERT INTO mundial.confederacion (nombre, sigla) VALUES ('Confederacion Sudamericana de Futbol', 'CONMEBOL');
IF NOT EXISTS (SELECT 1 FROM mundial.confederacion WHERE sigla = 'UEFA')
    INSERT INTO mundial.confederacion (nombre, sigla) VALUES ('Union of European Football Associations', 'UEFA');
IF NOT EXISTS (SELECT 1 FROM mundial.confederacion WHERE sigla = 'CONCACAF')
    INSERT INTO mundial.confederacion (nombre, sigla) VALUES ('Confederation of North, Central America and Caribbean Association Football', 'CONCACAF');

DECLARE @id_conmebol INT = (SELECT id_confederacion FROM mundial.confederacion WHERE sigla = 'CONMEBOL');
DECLARE @id_uefa INT = (SELECT id_confederacion FROM mundial.confederacion WHERE sigla = 'UEFA');
DECLARE @id_concacaf INT = (SELECT id_confederacion FROM mundial.confederacion WHERE sigla = 'CONCACAF');

IF NOT EXISTS (SELECT 1 FROM mundial.pais WHERE codigo_iso = 'ARG')
    INSERT INTO mundial.pais (id_confederacion, nombre, codigo_iso, huso_horario_estandar, pbi_per_capita, codigo_moneda)
    VALUES (@id_conmebol, 'Argentina', 'ARG', 'America/Argentina/Buenos_Aires', 13000.00, 'ARS');

IF NOT EXISTS (SELECT 1 FROM mundial.pais WHERE codigo_iso = 'BRA')
    INSERT INTO mundial.pais (id_confederacion, nombre, codigo_iso, huso_horario_estandar, pbi_per_capita, codigo_moneda)
    VALUES (@id_conmebol, 'Brasil', 'BRA', 'America/Sao_Paulo', 8900.00, 'BRL');

IF NOT EXISTS (SELECT 1 FROM mundial.pais WHERE codigo_iso = 'FRA')
    INSERT INTO mundial.pais (id_confederacion, nombre, codigo_iso, huso_horario_estandar, pbi_per_capita, codigo_moneda)
    VALUES (@id_uefa, 'Francia', 'FRA', 'Europe/Paris', 43000.00, 'EUR');

IF NOT EXISTS (SELECT 1 FROM mundial.pais WHERE codigo_iso = 'USA')
    INSERT INTO mundial.pais (id_confederacion, nombre, codigo_iso, huso_horario_estandar, pbi_per_capita, codigo_moneda)
    VALUES (@id_concacaf, 'Estados Unidos', 'USA', 'America/New_York', 70000.00, 'USD');

DECLARE @id_p_arg INT = (SELECT id_pais FROM mundial.pais WHERE codigo_iso = 'ARG');
DECLARE @id_p_bra INT = (SELECT id_pais FROM mundial.pais WHERE codigo_iso = 'BRA');
DECLARE @id_p_fra INT = (SELECT id_pais FROM mundial.pais WHERE codigo_iso = 'FRA');
DECLARE @id_p_usa INT = (SELECT id_pais FROM mundial.pais WHERE codigo_iso = 'USA');

IF NOT EXISTS (SELECT 1 FROM mundial.ciudad WHERE id_pais = @id_p_usa AND nombre = 'East Rutherford')
    INSERT INTO mundial.ciudad (id_pais, nombre) VALUES (@id_p_usa, 'East Rutherford');

DECLARE @id_ciudad_metlife INT = (SELECT id_ciudad FROM mundial.ciudad WHERE id_pais = @id_p_usa AND nombre = 'East Rutherford');

IF NOT EXISTS (SELECT 1 FROM mundial.sede_estadio WHERE nombre_estadio = 'MetLife Stadium')
    INSERT INTO mundial.sede_estadio (id_ciudad, nombre_estadio, capacidad, huso_horario, latitud, longitud)
    VALUES (@id_ciudad_metlife, 'MetLife Stadium', 82500, 'America/New_York', 40.812800, -74.074200);

IF NOT EXISTS (SELECT 1 FROM mundial.reglamento_sustitucion WHERE nombre = 'Reglamento FIFA 2026')
    INSERT INTO mundial.reglamento_sustitucion (nombre, maximo_cambios, maximo_ventanas, cambios_adicionales_suplementario, ventanas_adicionales_suplementario, entretiempo_computa_ventana, intervalo_suplementario_computa_ventana, fecha_vigencia_desde, activo)
    VALUES ('Reglamento FIFA 2026', 5, 3, 1, 1, 0, 0, '2026-01-01', 1);

DECLARE @id_reglamento INT = (SELECT id_reglamento_sustitucion FROM mundial.reglamento_sustitucion WHERE nombre = 'Reglamento FIFA 2026');

IF NOT EXISTS (SELECT 1 FROM mundial.fase WHERE nombre_fase = 'Fase de Grupos')
    INSERT INTO mundial.fase (id_reglamento_sustitucion, nombre_fase, orden, permite_alargue, permite_penales)
    VALUES (@id_reglamento, 'Fase de Grupos', 1, 0, 0);

IF NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_pais = @id_p_arg)
    INSERT INTO mundial.seleccion (id_pais) VALUES (@id_p_arg);
IF NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_pais = @id_p_bra)
    INSERT INTO mundial.seleccion (id_pais) VALUES (@id_p_bra);
IF NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_pais = @id_p_fra)
    INSERT INTO mundial.seleccion (id_pais) VALUES (@id_p_fra);

IF NOT EXISTS (SELECT 1 FROM mundial.moneda WHERE codigo_iso = 'USD')
    INSERT INTO mundial.moneda (codigo_iso, descripcion) VALUES ('USD', 'Dolar Estadounidense');
IF NOT EXISTS (SELECT 1 FROM mundial.moneda WHERE codigo_iso = 'EUR')
    INSERT INTO mundial.moneda (codigo_iso, descripcion) VALUES ('EUR', 'Euro');
IF NOT EXISTS (SELECT 1 FROM mundial.moneda WHERE codigo_iso = 'BRL')
    INSERT INTO mundial.moneda (codigo_iso, descripcion) VALUES ('BRL', 'Real Brasileno');
IF NOT EXISTS (SELECT 1 FROM mundial.moneda WHERE codigo_iso = 'GBP')
    INSERT INTO mundial.moneda (codigo_iso, descripcion) VALUES ('GBP', 'Libra Esterlina');

/* 2. Fuentes de importacion */
DECLARE @f_partidos INT = (SELECT id_fuente FROM mundial.fuente_importacion WHERE nombre = 'Dataset partidos CSV');
IF @f_partidos IS NULL
BEGIN
    INSERT INTO mundial.fuente_importacion (nombre, tipo_fuente, formato, descripcion, activa)
    VALUES ('Dataset partidos CSV', 'ARCHIVO', 'CSV', 'Dataset de fixture y partidos', 1);
    SET @f_partidos = SCOPE_IDENTITY();
END;

DECLARE @f_pbi INT = (SELECT id_fuente FROM mundial.fuente_importacion WHERE nombre = 'API PBI XML');
IF @f_pbi IS NULL
BEGIN
    INSERT INTO mundial.fuente_importacion (nombre, tipo_fuente, formato, descripcion, activa)
    VALUES ('API PBI XML', 'API', 'XML', 'API Indicadores Banco Mundial', 1);
    SET @f_pbi = SCOPE_IDENTITY();
END;

DECLARE @f_arbitros INT = (SELECT id_fuente FROM mundial.fuente_importacion WHERE nombre = 'Scraping Arbitros Wikipedia');
IF @f_arbitros IS NULL
BEGIN
    INSERT INTO mundial.fuente_importacion (nombre, tipo_fuente, formato, descripcion, activa)
    VALUES ('Scraping Arbitros Wikipedia', 'SCRAPING', 'CSV', 'Scraping de arbitros de Wikipedia', 1);
    SET @f_arbitros = SCOPE_IDENTITY();
END;

DECLARE @f_tc INT = (SELECT id_fuente FROM mundial.fuente_importacion WHERE nombre = 'API Frankfurter JSON');
IF @f_tc IS NULL
BEGIN
    INSERT INTO mundial.fuente_importacion (nombre, tipo_fuente, formato, descripcion, activa)
    VALUES ('API Frankfurter JSON', 'API', 'JSON', 'API de tipos de cambio Frankfurter', 1);
    SET @f_tc = SCOPE_IDENTITY();
END;

PRINT N'OK: Catalogos y fuentes de importacion listos.';
GO

/* 3. Ejecucion de pruebas con rutas reales desde C:\Importaciones\ */
DECLARE @f_partidos INT = (SELECT id_fuente FROM mundial.fuente_importacion WHERE nombre = 'Dataset partidos CSV');
DECLARE @f_pbi INT = (SELECT id_fuente FROM mundial.fuente_importacion WHERE nombre = 'API PBI XML');
DECLARE @f_arbitros INT = (SELECT id_fuente FROM mundial.fuente_importacion WHERE nombre = 'Scraping Arbitros Wikipedia');
DECLARE @f_tc INT = (SELECT id_fuente FROM mundial.fuente_importacion WHERE nombre = 'API Frankfurter JSON');

DECLARE @ruta_partidos NVARCHAR(260) = N'C:\Importaciones\import_partidos.csv';
DECLARE @ruta_pbi NVARCHAR(260) = N'C:\Importaciones\import_pbi.xml';
DECLARE @ruta_arbitros NVARCHAR(260) = N'C:\Importaciones\arbitros_scraping.csv';
DECLARE @ruta_tc NVARCHAR(260) = N'C:\Importaciones\tipos_cambio.json';

/* Limpiar ejecuciones previas de este test para permitir re-ejecucion idempotente */
DELETE e FROM mundial.error_importacion e
WHERE e.id_detalle_importacion IN (
    SELECT d.id_detalle_importacion FROM mundial.detalle_importacion d
    JOIN mundial.lote_importacion l ON l.id_lote = d.id_lote
    WHERE l.hash_archivo IN ('HASH-CSV-PARTIDOS-01', 'HASH-XML-PBI-01', 'HASH-CSV-ARBITROS-01', 'HASH-JSON-TC-01', 'HASH-TEST-RECHAZO-DUPLICADO')
);
DELETE d FROM mundial.detalle_importacion d
WHERE d.id_lote IN (
    SELECT l.id_lote FROM mundial.lote_importacion l
    WHERE l.hash_archivo IN ('HASH-CSV-PARTIDOS-01', 'HASH-XML-PBI-01', 'HASH-CSV-ARBITROS-01', 'HASH-JSON-TC-01', 'HASH-TEST-RECHAZO-DUPLICADO')
);
DELETE FROM mundial.indicador_economico_pais WHERE id_lote IN (SELECT id_lote FROM mundial.lote_importacion WHERE hash_archivo = 'HASH-XML-PBI-01');
DELETE FROM mundial.tipo_cambio WHERE id_lote IN (SELECT id_lote FROM mundial.lote_importacion WHERE hash_archivo = 'HASH-JSON-TC-01');
DELETE FROM mundial.stg_partido WHERE id_lote IN (SELECT id_lote FROM mundial.lote_importacion WHERE hash_archivo = 'HASH-CSV-PARTIDOS-01');
DELETE FROM mundial.stg_indicador_economico WHERE id_lote IN (SELECT id_lote FROM mundial.lote_importacion WHERE hash_archivo = 'HASH-XML-PBI-01');
DELETE FROM mundial.stg_arbitro WHERE id_lote IN (SELECT id_lote FROM mundial.lote_importacion WHERE hash_archivo = 'HASH-CSV-ARBITROS-01');
DELETE FROM mundial.stg_tipo_cambio WHERE id_lote IN (SELECT id_lote FROM mundial.lote_importacion WHERE hash_archivo = 'HASH-JSON-TC-01');
DELETE FROM mundial.lote_importacion WHERE hash_archivo IN ('HASH-CSV-PARTIDOS-01', 'HASH-XML-PBI-01', 'HASH-CSV-ARBITROS-01', 'HASH-JSON-TC-01', 'HASH-TEST-RECHAZO-DUPLICADO');

PRINT N'--- Ejecutando importacion de Partidos (CSV) ---';
EXEC mundial.sp_importar_partidos_csv @id_fuente = @f_partidos, @archivo = @ruta_partidos, @hash = 'HASH-CSV-PARTIDOS-01';

PRINT N'--- Ejecutando importacion de Indicadores PBI (XML Banco Mundial) ---';
EXEC mundial.sp_importar_pbi_xml @id_fuente = @f_pbi, @archivo = @ruta_pbi, @hash = 'HASH-XML-PBI-01';

PRINT N'--- Ejecutando importacion de Arbitros (CSV Scraping Wikipedia) ---';
EXEC mundial.sp_importar_arbitros_csv @id_fuente = @f_arbitros, @archivo = @ruta_arbitros, @hash = 'HASH-CSV-ARBITROS-01';

PRINT N'--- Ejecutando importacion de Tipos de Cambio (JSON API Frankfurter) ---';
EXEC mundial.sp_importar_tipo_cambio_json @id_fuente = @f_tc, @archivo = @ruta_tc, @hash = 'HASH-JSON-TC-01';

/* 4. Resumen de lotes y demostracion de errores parciales */
PRINT N'--- Estado final de los lotes procesados ---';
SELECT id_lote, entidad_destino, estado_lote, cantidad_leidos, cantidad_insertados, cantidad_actualizados, cantidad_rechazados, hash_archivo
FROM mundial.lote_importacion
WHERE hash_archivo IN ('HASH-CSV-PARTIDOS-01', 'HASH-XML-PBI-01', 'HASH-CSV-ARBITROS-01', 'HASH-JSON-TC-01');

PRINT N'--- Errores parciales detectados y registrados en error_importacion ---';
SELECT d.id_lote, d.clave_externa, e.codigo_error, e.campo_error, e.descripcion_error, e.valor_recibido
FROM mundial.error_importacion e
JOIN mundial.detalle_importacion d ON d.id_detalle_importacion = e.id_detalle_importacion
WHERE d.id_lote IN (
    SELECT id_lote FROM mundial.lote_importacion
    WHERE hash_archivo IN ('HASH-CSV-PARTIDOS-01', 'HASH-XML-PBI-01', 'HASH-CSV-ARBITROS-01', 'HASH-JSON-TC-01')
);

/* 5. Verificacion de control de duplicados (Prueba de rechazo de hash) */
BEGIN TRY
    EXEC mundial.sp_importacion_iniciar_lote @f_partidos, @ruta_partidos, 'PARTIDO', 'HASH-CSV-PARTIDOS-01', @id_lote = 0;
    THROW 53999, N'FALLO: Se permitio iniciar un lote con hash duplicado.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 53999 THROW;
    IF ERROR_NUMBER() = 53101
        PRINT N'OK: Control de archivo duplicado por hash verificado correctamente (Error 53101 capturado: El archivo ya fue procesado).';
    ELSE
        THROW;
END CATCH;
GO

PRINT N'OK: Pruebas de SPs de importacion set-based finalizadas.';
GO
