/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-24
    Objetivo: Crear un usuario dedicado para Metabase con permisos de solo lectura sobre el esquema BI, bloqueando el acceso al esquema operativo para garantizar seguridad y separación de roles.
*/

:r C:\TP2026\00_Secretos.local.sql

/* LOGIN DE SERVIDOR */

USE master;
GO

IF SUSER_ID(N'metabase_tp') IS NULL
BEGIN
    CREATE LOGIN metabase_tp
    WITH
        PASSWORD = '$(PasswordMetabase)',
        DEFAULT_DATABASE = TP2026,
        CHECK_POLICY = ON,
        CHECK_EXPIRATION = OFF;
END;
GO

/* USUARIO DE BASE */

USE TP2026;
GO

IF DATABASE_PRINCIPAL_ID(N'metabase_tp') IS NULL
BEGIN
    CREATE USER metabase_tp
    FOR LOGIN metabase_tp;
END;
GO

/* ROL EXCLUSIVO PARA BI */

IF DATABASE_PRINCIPAL_ID(N'rol_metabase_lectura') IS NULL
BEGIN
    CREATE ROLE rol_metabase_lectura;
END;
GO

/* PERMISOS SOBRE EL ESQUEMA BI */

GRANT SELECT
ON SCHEMA::bi
TO rol_metabase_lectura;
GO

/* BLOQUEO DEL ESQUEMA OPERATIVO */

DENY SELECT
ON SCHEMA::mundial
TO rol_metabase_lectura;
GO

/* ASIGNAR USUARIO AL ROL */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members drm
    INNER JOIN sys.database_principals r
        ON r.principal_id = drm.role_principal_id
    INNER JOIN sys.database_principals u
        ON u.principal_id = drm.member_principal_id
    WHERE r.name = N'rol_metabase_lectura'
      AND u.name = N'metabase_tp'
)
BEGIN
    ALTER ROLE rol_metabase_lectura
    ADD MEMBER metabase_tp;
END;
GO

/* PERMISO DE CONEXION */

GRANT CONNECT
TO metabase_tp;
GO

/* VERIFICACION */

SELECT
    dp.name AS usuario,
    dp.type_desc
FROM sys.database_principals dp
WHERE dp.name = N'metabase_tp';
GO

SELECT
    USER_NAME(member_principal_id) AS usuario,
    USER_NAME(role_principal_id) AS rol
FROM sys.database_role_members
WHERE member_principal_id =
      USER_ID(N'metabase_tp');
GO

PRINT N'OK: Usuario de Metabase configurado correctamente.';
GO