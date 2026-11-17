/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-16
    Test de objetos auxiliares */
USE TP2026;
GO
DECLARE @o TABLE(nombre SYSNAME);
INSERT @o VALUES('mundial.registro_externo'),('mundial.stg_partido'),('mundial.stg_indicador_economico'),('mundial.indicador_economico_pais');
IF EXISTS(SELECT 1 FROM @o WHERE OBJECT_ID(nombre,'U') IS NULL)
BEGIN SELECT * FROM @o WHERE OBJECT_ID(nombre,'U') IS NULL; THROW 53000,N'Faltan objetos de importacion.',1; END;
IF EXISTS(SELECT 1 FROM sys.sql_modules WHERE definition LIKE '%CURSOR%' OR definition LIKE '%FETCH NEXT%')
 THROW 53001,N'Se detectaron cursores.',1;
PRINT N'OK: objetos presentes y sin cursores.';
GO
