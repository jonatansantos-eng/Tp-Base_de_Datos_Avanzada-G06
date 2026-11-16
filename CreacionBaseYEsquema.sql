/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-XX-XX
    Objetivo:
    Crear la base de datos TP2026 y los esquemas funcionales
    necesarios para el proyecto.
*/

USE master;
GO

IF DB_ID(N'TP2026') IS NULL
BEGIN
    CREATE DATABASE TP2026;
END;
GO

USE TP2026;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'mundial'
)
BEGIN
    EXEC(N'CREATE SCHEMA mundial AUTHORIZATION dbo;');
END;
GO
