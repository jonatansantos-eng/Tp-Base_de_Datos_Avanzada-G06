/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-24
    Objetivo: Firmar el Stored Procedure sp_reporte_Goleadores y verificar que el rol no tenga permisos directos sobre la clave simetrica. Realizar una prueba funcional real del modulo firmado.
*/

USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* Validaciones previas. */
IF DATABASE_PRINCIPAL_ID(N'usr_firma_descifrado') IS NULL
    THROW 55710, N'No existe usr_firma_descifrado. Ejecute primero 18_FirmaSPCifrado.sql.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name=N'SK_DatosPersonales')
    THROW 55711, N'No existe SK_DatosPersonales.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name=N'Cert_DatosPersonales')
    THROW 55712, N'No existe Cert_DatosPersonales.', 1;
GO

/*
   Quitar DENY explicito. REVOKE no concede permisos: solamente elimina la
   denegacion. Los roles continuan sin GRANT directo sobre la clave.
*/
REVOKE CONTROL ON SYMMETRIC KEY::SK_DatosPersonales FROM rol_cargador_resultados;
REVOKE CONTROL ON SYMMETRIC KEY::SK_DatosPersonales FROM rol_gestor_publicidad;
REVOKE CONTROL ON SYMMETRIC KEY::SK_DatosPersonales FROM rol_consulta_reportes;
GO

/* Permisos que se agregan exclusivamente al ejecutar modulos firmados. */
GRANT CONTROL ON SYMMETRIC KEY::SK_DatosPersonales TO usr_firma_descifrado;
GRANT CONTROL ON CERTIFICATE::Cert_DatosPersonales TO usr_firma_descifrado;
GO

/* Verificar que el reporte este firmado. */
IF NOT EXISTS
(
    SELECT 1
    FROM sys.crypt_properties AS cp
    INNER JOIN sys.certificates AS c
        ON c.thumbprint=cp.thumbprint
    WHERE cp.major_id=OBJECT_ID(N'mundial.sp_reporte_Goleadores')
      AND c.name=N'Cert_FirmaDescifrado'
)
BEGIN
    ADD SIGNATURE TO OBJECT::mundial.sp_reporte_Goleadores
        BY CERTIFICATE Cert_FirmaDescifrado;
END;
GO

/* Verificar que el rol no tenga GRANT o GRANT_WITH_GRANT_OPTION directo. */
IF EXISTS
(
    SELECT 1
    FROM sys.database_permissions AS dp
    WHERE dp.grantee_principal_id=DATABASE_PRINCIPAL_ID(N'rol_cargador_resultados')
      AND dp.class_desc=N'SYMMETRIC_KEYS'
      AND dp.major_id=KEY_ID(N'SK_DatosPersonales')
      AND dp.permission_name=N'CONTROL'
      AND dp.state IN ('G','W')
)
    THROW 55713, N'rol_cargador_resultados tiene CONTROL directo sobre la clave.', 1;
GO

/* Prueba funcional real del modulo firmado. */
BEGIN TRY
    EXECUTE AS USER=N'usr_resultados_test';
    EXEC mundial.sp_reporte_Goleadores;
    REVERT;
    PRINT N'OK: usr_resultados_test ejecuto el reporte firmado sin permiso directo sobre la clave.';
END TRY
BEGIN CATCH
    IF USER_NAME()=N'usr_resultados_test' REVERT;
    DECLARE @Mensaje NVARCHAR(2048)=CONCAT(N'Fallo la prueba del modulo firmado. Error ',ERROR_NUMBER(),N': ',ERROR_MESSAGE());
    THROW 55714,@Mensaje,1;
END CATCH;
GO
