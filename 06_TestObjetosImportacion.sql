/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-23
    Archivo: 06_TestObjetosImportacion.sql
    Objetivo: Verificar la existencia e integridad de los objetos auxiliares de importacion y staging.
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @o TABLE(nombre SYSNAME);
INSERT INTO @o VALUES
    ('mundial.registro_externo'),
    ('mundial.stg_partido'),
    ('mundial.stg_indicador_economico'),
    ('mundial.indicador_economico_pais'),
    ('mundial.stg_arbitro'),
    ('mundial.tipo_cambio'),
    ('mundial.stg_tipo_cambio');

IF EXISTS (SELECT 1 FROM @o WHERE OBJECT_ID(nombre, 'U') IS NULL)
BEGIN
    SELECT nombre AS [Objeto Faltante] FROM @o WHERE OBJECT_ID(nombre, 'U') IS NULL;
    THROW 53000, N'Faltan objetos de importacion o staging.', 1;
END;

PRINT N'OK: Todos los objetos de importacion y staging estan correctamente creados.';
GO
