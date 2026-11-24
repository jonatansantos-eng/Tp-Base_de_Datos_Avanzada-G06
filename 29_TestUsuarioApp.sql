/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-24
    Objetivo: Test de permisos del usuario app_tp
*/
USE TP2026;
GO
EXECUTE AS USER=N'app_tp';
IF HAS_PERMS_BY_NAME(N'mundial.sp_club_Alta',N'OBJECT',N'EXECUTE')<>1 THROW 56100,N'Falta EXECUTE en alta.',1;
IF HAS_PERMS_BY_NAME(N'mundial.sp_club_Modificar',N'OBJECT',N'EXECUTE')<>1 THROW 56101,N'Falta EXECUTE en modificación.',1;
IF HAS_PERMS_BY_NAME(N'mundial.sp_club_Baja',N'OBJECT',N'EXECUTE')<>1 THROW 56102,N'Falta EXECUTE en baja.',1;
IF HAS_PERMS_BY_NAME(N'mundial.sp_club_Consultar',N'OBJECT',N'EXECUTE')<>1 THROW 56103,N'Falta EXECUTE en consulta.',1;
IF HAS_PERMS_BY_NAME(N'mundial.club',N'OBJECT',N'SELECT')=1 THROW 56104,N'Acceso directo indebido a club.',1;
EXEC mundial.sp_club_Consultar @id_club=NULL;
REVERT;
PRINT N'OK: permisos de app_tp correctos.';
GO
