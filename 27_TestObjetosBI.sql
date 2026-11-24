/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-24

    Objetivo:
    Verificar la existencia, estructura, contenido y permisos de los objetos
    del esquema bi consumidos por Metabase.
*/

USE TP2026;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    /* 1. Verificar esquema BI */

    IF SCHEMA_ID(N'bi') IS NULL
    BEGIN
        THROW 56200,
              N'No existe el esquema bi.',
              1;
    END;

    PRINT N'OK 1: el esquema bi existe.';

    /* 2. Verificar vistas requeridas */

    DECLARE @VistasEsperadas TABLE
    (
        nombre SYSNAME NOT NULL PRIMARY KEY
    );

    INSERT INTO @VistasEsperadas(nombre)
    VALUES
        (N'vw_resumen_general'),
        (N'vw_resultados'),
        (N'vw_goles_por_seleccion'),
        (N'vw_tarjetas_por_seleccion'),
        (N'vw_designaciones_arbitrales'),
        (N'vw_sedes'),
        (N'vw_mapa_sedes'),
        (N'vw_anunciantes'),
        (N'vw_partidos_por_fase');

    IF EXISTS
    (
        SELECT 1
        FROM @VistasEsperadas AS e
        WHERE OBJECT_ID
        (
            N'bi.' + QUOTENAME(e.nombre),
            N'V'
        ) IS NULL
    )
    BEGIN
        SELECT
            e.nombre AS vista_faltante
        FROM @VistasEsperadas AS e
        WHERE OBJECT_ID
        (
            N'bi.' + QUOTENAME(e.nombre),
            N'V'
        ) IS NULL
        ORDER BY e.nombre;

        THROW 56201,
              N'Faltan una o mas vistas requeridas del esquema bi.',
              1;
    END;

    PRINT N'OK 2: existen las 9 vistas BI requeridas.';

    /* 3. Verificar columnas esenciales */

    DECLARE @ColumnasEsperadas TABLE
    (
        vista SYSNAME NOT NULL,
        columna SYSNAME NOT NULL,
        PRIMARY KEY (vista, columna)
    );

    INSERT INTO @ColumnasEsperadas(vista, columna)
    VALUES
        (N'vw_resumen_general', N'cantidad_selecciones'),
        (N'vw_resumen_general', N'cantidad_partidos'),
        (N'vw_resumen_general', N'cantidad_goles'),
        (N'vw_resumen_general', N'cantidad_tarjetas'),
        (N'vw_resumen_general', N'cantidad_sedes'),
        (N'vw_resumen_general', N'cantidad_anunciantes'),
        (N'vw_resultados', N'id_partido'),
        (N'vw_resultados', N'nombre_fase'),
        (N'vw_resultados', N'nombre_estadio'),
        (N'vw_resultados', N'seleccion_local'),
        (N'vw_resultados', N'seleccion_visitante'),
        (N'vw_resultados', N'goles_local'),
        (N'vw_resultados', N'goles_visitante'),
        (N'vw_resultados', N'resultado'),
        (N'vw_goles_por_seleccion', N'seleccion'),
        (N'vw_goles_por_seleccion', N'goles'),
        (N'vw_tarjetas_por_seleccion', N'seleccion'),
        (N'vw_tarjetas_por_seleccion', N'amarillas'),
        (N'vw_tarjetas_por_seleccion', N'rojas'),
        (N'vw_mapa_sedes', N'nombre_estadio'),
        (N'vw_mapa_sedes', N'latitud'),
        (N'vw_mapa_sedes', N'longitud');

    IF EXISTS
    (
        SELECT 1
        FROM @ColumnasEsperadas AS e
        WHERE COL_LENGTH
        (
            N'bi.' + e.vista,
            e.columna
        ) IS NULL
    )
    BEGIN
        SELECT
            e.vista,
            e.columna AS columna_faltante
        FROM @ColumnasEsperadas AS e
        WHERE COL_LENGTH
        (
            N'bi.' + e.vista,
            e.columna
        ) IS NULL
        ORDER BY e.vista, e.columna;

        THROW 56202,
              N'Faltan columnas esenciales en las vistas BI.',
              1;
    END;

    PRINT N'OK 3: las vistas contienen las columnas esenciales.';

    /* 4. Verificar datos representativos */

    DECLARE @ErroresDatos NVARCHAR(2048) = N'';

    IF NOT EXISTS
    (
        SELECT 1
        FROM bi.vw_resumen_general
        WHERE cantidad_selecciones > 0
          AND cantidad_partidos > 0
          AND cantidad_goles > 0
          AND cantidad_sedes > 0
    )
    BEGIN
        SET @ErroresDatos +=
            N'El resumen general no contiene indicadores representativos. ';
    END;

    IF NOT EXISTS (SELECT 1 FROM bi.vw_resultados)
    BEGIN
        SET @ErroresDatos +=
            N'La vista de resultados no contiene filas. ';
    END;

    IF NOT EXISTS (SELECT 1 FROM bi.vw_goles_por_seleccion)
    BEGIN
        SET @ErroresDatos +=
            N'La vista de goles por seleccion no contiene filas. ';
    END;

    IF NOT EXISTS (SELECT 1 FROM bi.vw_tarjetas_por_seleccion)
    BEGIN
        SET @ErroresDatos +=
            N'La vista de tarjetas por seleccion no contiene filas. ';
    END;

    IF NOT EXISTS (SELECT 1 FROM bi.vw_partidos_por_fase)
    BEGIN
        SET @ErroresDatos +=
            N'La vista de partidos por fase no contiene filas. ';
    END;

    IF LEN(@ErroresDatos) > 0
    BEGIN
        THROW 56203,
              @ErroresDatos,
              1;
    END;

    PRINT N'OK 4: las vistas contienen datos representativos.';

    /* 5. Verificar geolocalizacion */

    IF EXISTS
    (
        SELECT 1
        FROM bi.vw_mapa_sedes
        WHERE latitud IS NULL
           OR longitud IS NULL
           OR latitud NOT BETWEEN -90 AND 90
           OR longitud NOT BETWEEN -180 AND 180
    )
    BEGIN
        THROW 56204,
              N'Hay coordenadas nulas o fuera de rango en vw_mapa_sedes.',
              1;
    END;

    IF (SELECT COUNT(*) FROM bi.vw_mapa_sedes) < 2
    BEGIN
        THROW 56205,
              N'No hay suficientes sedes para un mapa representativo.',
              1;
    END;

    PRINT N'OK 5: coordenadas validas para el mapa de Metabase.';

    /* 6. Verificar usuario y rol Metabase */

    IF DATABASE_PRINCIPAL_ID(N'metabase_tp') IS NULL
    BEGIN
        THROW 56206,
              N'No existe el usuario metabase_tp en TP2026.',
              1;
    END;

    IF DATABASE_PRINCIPAL_ID(N'rol_metabase_lectura') IS NULL
    BEGIN
        THROW 56207,
              N'No existe rol_metabase_lectura.',
              1;
    END;

    IF IS_ROLEMEMBER
    (
        N'rol_metabase_lectura',
        N'metabase_tp'
    ) <> 1
    BEGIN
        THROW 56208,
              N'metabase_tp no pertenece a rol_metabase_lectura.',
              1;
    END;

    PRINT N'OK 6: usuario y rol de Metabase configurados.';

    /* 7. Prueba real de permisos con EXECUTE AS */

    EXECUTE AS USER = N'metabase_tp';

    IF HAS_PERMS_BY_NAME
    (
        N'bi.vw_resumen_general',
        N'OBJECT',
        N'SELECT'
    ) <> 1
    BEGIN
        THROW 56209,
              N'metabase_tp no puede consultar las vistas BI.',
              1;
    END;

    IF HAS_PERMS_BY_NAME
    (
        N'mundial.club',
        N'OBJECT',
        N'SELECT'
    ) = 1
    BEGIN
        THROW 56210,
              N'metabase_tp puede consultar tablas operativas directamente.',
              1;
    END;

    IF HAS_PERMS_BY_NAME
    (
        N'bi.vw_resultados',
        N'OBJECT',
        N'UPDATE'
    ) = 1
    BEGIN
        THROW 56211,
              N'metabase_tp tiene permiso de modificacion sobre BI.',
              1;
    END;

    /* Consultas reales bajo el usuario de Metabase. */
    SELECT *
    FROM bi.vw_resumen_general;

    SELECT TOP (5) *
    FROM bi.vw_resultados
    ORDER BY fecha_hora_local, id_partido;

    SELECT TOP (5) *
    FROM bi.vw_mapa_sedes
    ORDER BY nombre_estadio;

    REVERT;

    PRINT N'OK 7: Metabase puede leer bi y no puede acceder directamente a mundial.';

    /* 8. Resumen de objetos para evidencia */

    SELECT
        s.name AS esquema,
        v.name AS vista,
        COUNT(c.column_id) AS cantidad_columnas
    FROM sys.views AS v
    INNER JOIN sys.schemas AS s
        ON s.schema_id = v.schema_id
    INNER JOIN sys.columns AS c
        ON c.object_id = v.object_id
    WHERE s.name = N'bi'
    GROUP BY s.name, v.name
    ORDER BY v.name;

    PRINT N'FIN: todos los objetos BI y permisos fueron validados correctamente.';
END TRY
BEGIN CATCH
    IF USER_NAME() = N'metabase_tp'
    BEGIN
        REVERT;
    END;

    DECLARE
        @NumeroError INT = ERROR_NUMBER(),
        @MensajeError NVARCHAR(2048) = ERROR_MESSAGE(),
        @MensajeFinal NVARCHAR(2048);

    SET @MensajeFinal = CONCAT
    (
        N'Fallo 27_TestObjetosBI.sql. Error ',
        @NumeroError,
        N': ',
        @MensajeError
    );

    THROW 56299,
          @MensajeFinal,
          1;
END CATCH;
GO
