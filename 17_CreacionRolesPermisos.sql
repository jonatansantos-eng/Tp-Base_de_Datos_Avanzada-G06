/* Entrega 8 - Roles y permisos granulares | 2026-11-23 */
USE TP2026;
GO
SET NOCOUNT ON;
GO
IF DATABASE_PRINCIPAL_ID(N'rol_administrador_tp') IS NULL CREATE ROLE rol_administrador_tp AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rol_cargador_resultados') IS NULL CREATE ROLE rol_cargador_resultados AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rol_gestor_publicidad') IS NULL CREATE ROLE rol_gestor_publicidad AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rol_consulta_reportes') IS NULL CREATE ROLE rol_consulta_reportes AUTHORIZATION dbo;
GO

/* Bloqueo base: ningun rol operativo accede directamente a tablas. */
DENY SELECT,INSERT,UPDATE,DELETE ON SCHEMA::mundial TO rol_cargador_resultados;
DENY SELECT,INSERT,UPDATE,DELETE ON SCHEMA::mundial TO rol_gestor_publicidad;
DENY SELECT,INSERT,UPDATE,DELETE ON SCHEMA::mundial TO rol_consulta_reportes;
GO

GRANT CONTROL ON DATABASE::TP2026 TO rol_administrador_tp;
GO

/* Resultados deportivos. */
GRANT EXECUTE ON OBJECT::mundial.sp_partido_Alta TO rol_cargador_resultados;
GRANT EXECUTE ON OBJECT::mundial.sp_partido_Modificar TO rol_cargador_resultados;
GRANT EXECUTE ON OBJECT::mundial.sp_partido_Consultar TO rol_cargador_resultados;
GRANT EXECUTE ON OBJECT::mundial.sp_partido_equipo_detalle_Alta TO rol_cargador_resultados;
GRANT EXECUTE ON OBJECT::mundial.sp_alineacion_partido_Alta TO rol_cargador_resultados;
GRANT EXECUTE ON OBJECT::mundial.sp_alineacion_partido_Modificar TO rol_cargador_resultados;
GRANT EXECUTE ON OBJECT::mundial.sp_sustitucion_Alta TO rol_cargador_resultados;
GRANT EXECUTE ON OBJECT::mundial.sp_gol_Alta TO rol_cargador_resultados;
GRANT EXECUTE ON OBJECT::mundial.sp_tarjeta_Alta TO rol_cargador_resultados;
GRANT EXECUTE ON OBJECT::mundial.sp_reporte_Goleadores TO rol_cargador_resultados;
GRANT EXECUTE ON OBJECT::mundial.sp_reporte_Tarjetas TO rol_cargador_resultados;
GRANT EXECUTE ON OBJECT::mundial.sp_reporte_ResultadosEncuentros TO rol_cargador_resultados;
GO

/* Publicidad. */
GRANT EXECUTE ON OBJECT::mundial.sp_anunciante_Alta TO rol_gestor_publicidad;
GRANT EXECUTE ON OBJECT::mundial.sp_anunciante_Modificar TO rol_gestor_publicidad;
GRANT EXECUTE ON OBJECT::mundial.sp_anunciante_Consultar TO rol_gestor_publicidad;
GRANT EXECUTE ON OBJECT::mundial.sp_campania_Alta TO rol_gestor_publicidad;
GRANT EXECUTE ON OBJECT::mundial.sp_campania_Modificar TO rol_gestor_publicidad;
GRANT EXECUTE ON OBJECT::mundial.sp_pieza_publicitaria_Alta TO rol_gestor_publicidad;
GRANT EXECUTE ON OBJECT::mundial.sp_pieza_publicitaria_Modificar TO rol_gestor_publicidad;
GRANT EXECUTE ON OBJECT::mundial.sp_pauta_partido_Alta TO rol_gestor_publicidad;
GRANT EXECUTE ON OBJECT::mundial.sp_pauta_partido_Modificar TO rol_gestor_publicidad;
GRANT EXECUTE ON OBJECT::mundial.sp_reporte_OcupacionPublicitaria TO rol_gestor_publicidad;
GRANT EXECUTE ON OBJECT::mundial.sp_reporte_MatrizPrimeTime TO rol_gestor_publicidad;
GO

/* Solo reportes. */
GRANT EXECUTE ON OBJECT::mundial.sp_reporte_Goleadores TO rol_consulta_reportes;
GRANT EXECUTE ON OBJECT::mundial.sp_reporte_Tarjetas TO rol_consulta_reportes;
GRANT EXECUTE ON OBJECT::mundial.sp_reporte_DesignacionesArbitrales TO rol_consulta_reportes;
GRANT EXECUTE ON OBJECT::mundial.sp_reporte_OcupacionPublicitaria TO rol_consulta_reportes;
GRANT EXECUTE ON OBJECT::mundial.sp_reporte_MatrizPrimeTime TO rol_consulta_reportes;
GRANT EXECUTE ON OBJECT::mundial.sp_reporte_SeleccionesPlantillas TO rol_consulta_reportes;
GRANT EXECUTE ON OBJECT::mundial.sp_reporte_ResultadosEncuentros TO rol_consulta_reportes;
GO

/* Consulta publica de personas para resultados; nunca consulta sensible. */
GRANT EXECUTE ON OBJECT::mundial.sp_jugador_Consultar TO rol_cargador_resultados;
GRANT EXECUTE ON OBJECT::mundial.sp_anunciante_Consultar TO rol_gestor_publicidad;
DENY EXECUTE ON OBJECT::mundial.sp_jugador_ConsultarSensible TO rol_cargador_resultados;
DENY EXECUTE ON OBJECT::mundial.sp_jugador_ConsultarSensible TO rol_gestor_publicidad;
DENY EXECUTE ON OBJECT::mundial.sp_jugador_ConsultarSensible TO rol_consulta_reportes;
DENY EXECUTE ON OBJECT::mundial.sp_anunciante_ConsultarSensible TO rol_cargador_resultados;
DENY EXECUTE ON OBJECT::mundial.sp_anunciante_ConsultarSensible TO rol_gestor_publicidad;
DENY EXECUTE ON OBJECT::mundial.sp_anunciante_ConsultarSensible TO rol_consulta_reportes;
GO

IF DATABASE_PRINCIPAL_ID(N'usr_admin_test') IS NULL CREATE USER usr_admin_test WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usr_resultados_test') IS NULL CREATE USER usr_resultados_test WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usr_publicidad_test') IS NULL CREATE USER usr_publicidad_test WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usr_consulta_test') IS NULL CREATE USER usr_consulta_test WITHOUT LOGIN;
GO
ALTER ROLE rol_administrador_tp ADD MEMBER usr_admin_test;
ALTER ROLE rol_cargador_resultados ADD MEMBER usr_resultados_test;
ALTER ROLE rol_gestor_publicidad ADD MEMBER usr_publicidad_test;
ALTER ROLE rol_consulta_reportes ADD MEMBER usr_consulta_test;
GO

CREATE OR ALTER PROCEDURE dbo.sp_seguridad_asignar_usuario_rol
 @usuario SYSNAME,@rol SYSNAME
AS
BEGIN
 SET NOCOUNT ON;
 IF DATABASE_PRINCIPAL_ID(@usuario) IS NULL THROW 55200,N'El usuario no existe.',1;
 IF @rol NOT IN(N'rol_administrador_tp',N'rol_cargador_resultados',N'rol_gestor_publicidad',N'rol_consulta_reportes') THROW 55201,N'Rol no autorizado.',1;
 DECLARE @sql NVARCHAR(1000)=N'ALTER ROLE '+QUOTENAME(@rol)+N' ADD MEMBER '+QUOTENAME(@usuario)+N';';
 EXEC sys.sp_executesql @sql;
END;
GO
