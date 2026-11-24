/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-24
    Objetivo: Verificar que el usuario cargador de resultados tenga los permisos necesarios para ejecutar el modulo firmado, sin acceso a tablas sensibles ni permisos de control sobre la clave simetrica.
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    EXECUTE AS USER=N'usr_resultados_test';

    IF HAS_PERMS_BY_NAME(N'mundial.sp_gol_Alta',N'OBJECT',N'EXECUTE')<>1
        THROW 55400,N'No puede ejecutar sp_gol_Alta.',1;

    IF HAS_PERMS_BY_NAME(N'mundial.sp_reporte_Goleadores',N'OBJECT',N'EXECUTE')<>1
        THROW 55401,N'No puede ejecutar sp_reporte_Goleadores.',1;

    /* Prueba real: debe abrir la clave por la firma y devolver nombres. */
    EXEC mundial.sp_reporte_Goleadores;
    PRINT N'OK 1: reporte firmado ejecutado correctamente.';

    IF HAS_PERMS_BY_NAME(N'mundial.sp_pauta_partido_Alta',N'OBJECT',N'EXECUTE')=1
        THROW 55402,N'Puede gestionar publicidad indebidamente.',1;

    IF HAS_PERMS_BY_NAME(N'mundial.jugador',N'OBJECT',N'SELECT')=1
        THROW 55403,N'Puede consultar jugador directamente.',1;

    IF HAS_PERMS_BY_NAME(N'mundial.sp_jugador_ConsultarSensible',N'OBJECT',N'EXECUTE')=1
        THROW 55404,N'Puede ejecutar la consulta sensible.',1;

    /* Debe carecer de un GRANT directo sobre la clave. */
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
        THROW 55405,N'El rol tiene CONTROL directo sobre la clave.',1;

    REVERT;
    PRINT N'OK RESULTADOS: permisos positivos y negativos correctos.';
END TRY
BEGIN CATCH
    IF USER_NAME()=N'usr_resultados_test' REVERT;
    DECLARE @Numero INT=ERROR_NUMBER(),@Texto NVARCHAR(2048)=ERROR_MESSAGE();
    DECLARE @Final NVARCHAR(2048)=CONCAT(N'Fallo el test de resultados. Error ',@Numero,N': ',@Texto);
    THROW 55499,@Final,1;
END CATCH;
GO
