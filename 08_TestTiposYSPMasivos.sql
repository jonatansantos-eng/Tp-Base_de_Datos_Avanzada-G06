/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-23
    Objetivo: Pruebas unitarias de los Table-Valued Parameters y Stored Procedures masivos de negocio.
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'--- Iniciando pruebas de Tipos y SPs Masivos ---';

/* 1. Verificar existencia de los tipos tabla */
DECLARE @tipos TABLE(nombre SYSNAME);
INSERT INTO @tipos VALUES
    ('tipo_partido_importacion'),
    ('tipo_indicador_importacion'),
    ('tipo_arbitro_importacion'),
    ('tipo_tipo_cambio_importacion');

IF EXISTS (SELECT 1 FROM @tipos WHERE TYPE_ID(N'mundial.' + nombre) IS NULL)
BEGIN
    SELECT nombre AS [Tipo Faltante] FROM @tipos WHERE TYPE_ID(N'mundial.' + nombre) IS NULL;
    THROW 52100, N'Faltan tipos tabla requeridos.', 1;
END;

/* 2. Verificar existencia de los SPs masivos */
DECLARE @sps TABLE(nombre SYSNAME);
INSERT INTO @sps VALUES
    ('mundial.sp_partido_UpsertMasivo'),
    ('mundial.sp_indicador_economico_UpsertMasivo'),
    ('mundial.sp_arbitro_UpsertMasivo'),
    ('mundial.sp_tipo_cambio_UpsertMasivo');

IF EXISTS (SELECT 1 FROM @sps WHERE OBJECT_ID(nombre, 'P') IS NULL)
BEGIN
    SELECT nombre AS [SP Masivo Faltante] FROM @sps WHERE OBJECT_ID(nombre, 'P') IS NULL;
    THROW 52101, N'Faltan SPs masivos requeridos.', 1;
END;

/* 3. Prueba con TVP vacio para validar ejecucion y transaccion sin errores */
DECLARE @f INT = (SELECT TOP 1 id_fuente FROM mundial.fuente_importacion);
IF @f IS NULL
BEGIN
    INSERT INTO mundial.fuente_importacion (nombre, tipo_fuente, formato, descripcion, activa)
    VALUES ('Fuente Test Masivo', 'API', 'JSON', 'Fuente para tests masivos', 1);
    SET @f = SCOPE_IDENTITY();
END;

DECLARE @l INT = (SELECT TOP 1 id_lote FROM mundial.lote_importacion WHERE id_fuente = @f);
IF @l IS NULL
BEGIN
    INSERT INTO mundial.lote_importacion (id_fuente, entidad_destino, estado_lote)
    VALUES (@f, 'TEST', 'COMPLETADO');
    SET @l = SCOPE_IDENTITY();
END;

DECLARE @partidos mundial.tipo_partido_importacion;
EXEC mundial.sp_partido_UpsertMasivo @id_fuente = @f, @id_lote = @l, @Partidos = @partidos;

DECLARE @indicadores mundial.tipo_indicador_importacion;
EXEC mundial.sp_indicador_economico_UpsertMasivo @id_fuente = @f, @id_lote = @l, @Indicadores = @indicadores;

DECLARE @arbitros mundial.tipo_arbitro_importacion;
EXEC mundial.sp_arbitro_UpsertMasivo @id_fuente = @f, @id_lote = @l, @Arbitros = @arbitros;

DECLARE @cotizaciones mundial.tipo_tipo_cambio_importacion;
EXEC mundial.sp_tipo_cambio_UpsertMasivo @id_fuente = @f, @id_lote = @l, @Cotizaciones = @cotizaciones;

PRINT N'OK: Tipos TVP y SPs Masivos creados y testeados exitosamente.';
GO
