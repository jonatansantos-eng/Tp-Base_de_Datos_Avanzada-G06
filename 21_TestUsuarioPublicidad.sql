/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-24
    Objetivo: Verificar que el usuario gestor de publicidad tenga permisos para ejecutar el modulo firmado, sin acceso a tablas sensibles ni permisos de control sobre la clave simetrica. 
*/
USE TP2026;
GO
EXECUTE AS USER=N'usr_publicidad_test';
IF HAS_PERMS_BY_NAME(N'mundial.sp_pauta_partido_Alta',N'OBJECT',N'EXECUTE')<>1 THROW 55500,N'No puede gestionar pautas.',1;
IF HAS_PERMS_BY_NAME(N'mundial.sp_gol_Alta',N'OBJECT',N'EXECUTE')=1 THROW 55501,N'Puede registrar goles indebidamente.',1;
IF HAS_PERMS_BY_NAME(N'mundial.anunciante',N'OBJECT',N'SELECT')=1 THROW 55502,N'Puede leer anunciantes directamente.',1;
IF HAS_PERMS_BY_NAME(N'mundial.sp_anunciante_ConsultarSensible',N'OBJECT',N'EXECUTE')=1 THROW 55503,N'Puede leer datos fiscales sensibles.',1;
EXEC mundial.sp_reporte_OcupacionPublicitaria;
PRINT N'OK PUBLICIDAD: permisos positivos y negativos correctos.';
REVERT;
GO
