/* Test rol administrador */
USE TP2026;
GO
EXECUTE AS USER=N'usr_admin_test';
IF HAS_PERMS_BY_NAME(N'TP2026',N'DATABASE',N'CONTROL')<>1 THROW 55300,N'El administrador no tiene CONTROL.',1;
EXEC mundial.sp_jugador_ConsultarSensible @id_jugador=NULL;
IF HAS_PERMS_BY_NAME(N'mundial.jugador',N'OBJECT',N'SELECT')<>1 THROW 55301,N'El administrador no puede consultar tablas.',1;
PRINT N'OK ADMIN: CONTROL, lectura sensible y acceso administrativo permitidos.';
REVERT;
GO
