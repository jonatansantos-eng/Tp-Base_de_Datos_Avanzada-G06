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
    Crear vistas orientadas a BI para consumo desde Metabase.
*/

USE TP2026;
GO

SET NOCOUNT ON;
GO

/* 1. ESQUEMA BI */

IF SCHEMA_ID(N'bi') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA bi AUTHORIZATION dbo');
END;
GO

/* 2. KPI GENERALES */

CREATE OR ALTER VIEW bi.vw_resumen_general
AS
SELECT
    (SELECT COUNT(*) FROM mundial.seleccion)
        AS cantidad_selecciones,

    (SELECT COUNT(*) FROM mundial.partido)
        AS cantidad_partidos,

    (SELECT COUNT(*) FROM mundial.gol)
        AS cantidad_goles,

    (SELECT COUNT(*) FROM mundial.tarjeta)
        AS cantidad_tarjetas,

    (SELECT COUNT(*) FROM mundial.sede_estadio)
        AS cantidad_sedes,

    (SELECT COUNT(*) FROM mundial.anunciante)
        AS cantidad_anunciantes,

    (
        SELECT ISNULL(SUM(capacidad),0)
        FROM mundial.sede_estadio
    )
        AS capacidad_total_estadios;
GO

/* 3. RESULTADOS DE PARTIDOS */

CREATE OR ALTER VIEW bi.vw_resultados
AS
SELECT
    p.id_partido,

    f.nombre_fase,

    p.fecha_hora_local,

    se.nombre_estadio,

    pl.nombre
        AS seleccion_local,

    pv.nombre
        AS seleccion_visitante,

    ISNULL(p.goles_local,0)
        AS goles_local,

    ISNULL(p.goles_visitante,0)
        AS goles_visitante,

    CASE
        WHEN ISNULL(p.goles_local,0) >
             ISNULL(p.goles_visitante,0)
            THEN pl.nombre

        WHEN ISNULL(p.goles_visitante,0) >
             ISNULL(p.goles_local,0)
            THEN pv.nombre

        ELSE 'EMPATE'
    END AS resultado
FROM mundial.partido p
INNER JOIN mundial.fase f
    ON f.id_fase = p.id_fase
INNER JOIN mundial.sede_estadio se
    ON se.id_sede = p.id_sede

INNER JOIN mundial.seleccion sl
    ON sl.id_seleccion = p.id_seleccion_local

INNER JOIN mundial.pais pl
    ON pl.id_pais = sl.id_pais

INNER JOIN mundial.seleccion sv
    ON sv.id_seleccion = p.id_seleccion_visitante

INNER JOIN mundial.pais pv
    ON pv.id_pais = sv.id_pais;
GO

/* 4. GOLES POR SELECCION */

CREATE OR ALTER VIEW bi.vw_goles_por_seleccion
AS
SELECT
    pa.nombre AS seleccion,
    COUNT(g.id_gol) AS goles
FROM mundial.gol g

INNER JOIN mundial.seleccion s
    ON s.id_seleccion =
       g.id_seleccion_beneficiada

INNER JOIN mundial.pais pa
    ON pa.id_pais = s.id_pais

GROUP BY
    pa.nombre;
GO

/* 5. TARJETAS POR SELECCION */

CREATE OR ALTER VIEW bi.vw_tarjetas_por_seleccion
AS
SELECT
    pa.nombre AS seleccion,

    SUM
    (
        CASE
            WHEN UPPER(tt.descripcion)
                 LIKE '%AMARILLA%'
            THEN 1
            ELSE 0
        END
    ) AS amarillas,

    SUM
    (
        CASE
            WHEN UPPER(tt.descripcion)
                 LIKE '%ROJA%'
            THEN 1
            ELSE 0
        END
    ) AS rojas
FROM mundial.tarjeta t

INNER JOIN mundial.tipo_tarjeta tt
    ON tt.id_tipo_tarjeta =
       t.id_tipo_tarjeta

INNER JOIN mundial.jugador j
    ON j.id_jugador =
       t.id_jugador

INNER JOIN mundial.convocatoria c
    ON c.id_jugador =
       j.id_jugador

INNER JOIN mundial.seleccion s
    ON s.id_seleccion =
       c.id_seleccion

INNER JOIN mundial.pais pa
    ON pa.id_pais =
       s.id_pais

GROUP BY
    pa.nombre;
GO

/* 6. DESIGANACIONES ARBITRALES */

CREATE OR ALTER VIEW bi.vw_designaciones_arbitrales
AS
SELECT
    a.id_arbitro,

    a.categoria,

    p.nombre
        AS nacionalidad,

    COUNT(DISTINCT da.id_partido)
        AS partidos_asignados
FROM mundial.arbitro a

INNER JOIN mundial.pais p
    ON p.id_pais =
       a.id_pais_nacionalidad

LEFT JOIN mundial.designacion_arbitral da
    ON da.id_arbitro =
       a.id_arbitro

GROUP BY
    a.id_arbitro,
    a.categoria,
    p.nombre;
GO

/* 7. ESTADIOS / SEDES */

CREATE OR ALTER VIEW bi.vw_sedes
AS
SELECT
    id_sede,
    id_ciudad,
    nombre_estadio,
    capacidad,
    huso_horario,
    latitud,
    longitud
FROM mundial.sede_estadio;
GO

/* 8. MAPA */

CREATE OR ALTER VIEW bi.vw_mapa_sedes
AS
SELECT
    id_sede,
    id_ciudad,
    nombre_estadio,
    capacidad,
    huso_horario,
    latitud,
    longitud
FROM mundial.sede_estadio
WHERE latitud IS NOT NULL
  AND longitud IS NOT NULL;
GO

/* 9. ANUNCIANTES */

CREATE OR ALTER VIEW bi.vw_anunciantes
AS
SELECT
    a.id_anunciante,
    a.razon_social,
    p.nombre AS pais
FROM mundial.anunciante a

INNER JOIN mundial.pais p
    ON p.id_pais =
       a.id_pais_origen;
GO

/* 10. PARTIDOS POR FASE */

CREATE OR ALTER VIEW bi.vw_partidos_por_fase
AS
SELECT
    f.nombre_fase,
    COUNT(*) AS cantidad_partidos
FROM mundial.partido p
INNER JOIN mundial.fase f
    ON f.id_fase = p.id_fase
GROUP BY
    f.nombre_fase;
GO

PRINT N'OK: Objetos BI creados correctamente.';
GO