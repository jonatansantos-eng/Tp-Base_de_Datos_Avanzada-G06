/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-24
    Objetivo: Verificar que el usuario administrador tenga permisos de CONTROL sobre la base de datos, acceso a tablas sensibles y acceso administrativo. 
*/
USE TP2026;
GO
EXECUTE AS USER=N'usr_admin_test';
IF HAS_PERMS_BY_NAME(N'TP2026',N'DATABASE',N'CONTROL')<>1 THROW 55300,N'El administrador no tiene CONTROL.',1;
EXEC mundial.sp_jugador_ConsultarSensible @id_jugador=NULL;
IF HAS_PERMS_BY_NAME(N'mundial.jugador',N'OBJECT',N'SELECT')<>1 THROW 55301,N'El administrador no puede consultar tablas.',1;
PRINT N'OK ADMIN: CONTROL, lectura sensible y acceso administrativo permitidos.';
REVERT;
GO
