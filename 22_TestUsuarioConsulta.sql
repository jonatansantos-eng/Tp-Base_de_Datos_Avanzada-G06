/* Test rol solo consulta */
USE TP2026;
GO
EXECUTE AS USER=N'usr_consulta_test';
IF HAS_PERMS_BY_NAME(N'mundial.sp_reporte_Goleadores',N'OBJECT',N'EXECUTE')<>1 THROW 55600,N'No puede ejecutar reportes.',1;
IF HAS_PERMS_BY_NAME(N'mundial.sp_partido_Alta',N'OBJECT',N'EXECUTE')=1 THROW 55601,N'Puede dar de alta partidos indebidamente.',1;
IF HAS_PERMS_BY_NAME(N'mundial.partido',N'OBJECT',N'SELECT')=1 THROW 55602,N'Puede leer tablas directamente.',1;
IF HAS_PERMS_BY_NAME(N'mundial.jugador',N'OBJECT',N'UPDATE')=1 THROW 55603,N'Puede modificar jugadores.',1;
IF HAS_PERMS_BY_NAME(N'mundial.sp_jugador_ConsultarSensible',N'OBJECT',N'EXECUTE')=1 THROW 55604,N'Puede leer datos sensibles.',1;
EXEC mundial.sp_reporte_ResultadosEncuentros;
PRINT N'OK CONSULTA: reportes permitidos y escritura/lectura directa rechazadas.';
REVERT;
GO
