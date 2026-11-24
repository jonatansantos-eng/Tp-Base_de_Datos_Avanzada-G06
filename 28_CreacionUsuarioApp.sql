/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-24
    Objetivo: Creacion del usuario para la aplicacion Java
*/
:r C:\TP2026\00_Secretos.local.sql
USE master;
GO
IF SUSER_ID(N'app_tp') IS NULL
    CREATE LOGIN app_tp WITH PASSWORD='$(PasswordApp)',DEFAULT_DATABASE=TP2026,CHECK_POLICY=ON,CHECK_EXPIRATION=OFF;
ELSE
    ALTER LOGIN app_tp WITH PASSWORD='$(PasswordApp)',DEFAULT_DATABASE=TP2026;
GO
USE TP2026;
GO
IF DATABASE_PRINCIPAL_ID(N'app_tp') IS NULL CREATE USER app_tp FOR LOGIN app_tp;
IF DATABASE_PRINCIPAL_ID(N'rol_app_clubes') IS NULL CREATE ROLE rol_app_clubes AUTHORIZATION dbo;
GO
GRANT CONNECT TO app_tp;
GRANT EXECUTE ON OBJECT::mundial.sp_club_Consultar TO rol_app_clubes;
GRANT EXECUTE ON OBJECT::mundial.sp_club_Alta TO rol_app_clubes;
GRANT EXECUTE ON OBJECT::mundial.sp_club_Modificar TO rol_app_clubes;
GRANT EXECUTE ON OBJECT::mundial.sp_club_Baja TO rol_app_clubes;
GRANT EXECUTE ON OBJECT::mundial.sp_pais_Consultar TO rol_app_clubes;
DENY SELECT,INSERT,UPDATE,DELETE ON SCHEMA::mundial TO rol_app_clubes;
IF IS_ROLEMEMBER(N'rol_app_clubes',N'app_tp')<>1 ALTER ROLE rol_app_clubes ADD MEMBER app_tp;
GO
PRINT N'OK: usuario app_tp configurado para ABM de clubes mediante SP.';
GO
