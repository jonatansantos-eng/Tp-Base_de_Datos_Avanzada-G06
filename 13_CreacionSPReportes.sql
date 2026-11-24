/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-23
    Objetivo: Implementar los 7 Stored Procedures de reportes analiticos requeridos en la Entrega 7.
              Incluye 2 reportes con retorno nativo XML (FOR XML PATH) y matriz cruzada Prime Time (PIVOT).
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* REPORTE 1: GOLEADORES POR SELECCION, FASE Y TORNEO */

CREATE OR ALTER PROCEDURE mundial.sp_reporte_Goleadores
    @id_fase INT = NULL,
    @id_seleccion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        DENSE_RANK() OVER(ORDER BY COUNT(g.id_gol) DESC) AS Ranking,
        CONCAT(j.nombres, ' ', j.apellidos) AS Jugador,
        p.nombre AS Seleccion,
        pos.descripcion AS Posicion,
        c.dorsal AS Dorsal,
        f.nombre_fase AS Fase,
        COUNT(g.id_gol) AS GolesTotales,
        SUM(CASE WHEN tg.descripcion = 'JUGADA' AND g.es_gol_en_contra = 0 THEN 1 ELSE 0 END) AS GolesJugada,
        SUM(CASE WHEN tg.descripcion = 'PENAL' THEN 1 ELSE 0 END) AS GolesPenal,
        SUM(CASE WHEN tg.descripcion = 'TIRO_LIBRE' THEN 1 ELSE 0 END) AS GolesTiroLibre,
        SUM(CASE WHEN g.es_gol_en_contra = 1 THEN 1 ELSE 0 END) AS GolesEnContra
    FROM mundial.gol g
    JOIN mundial.partido pt ON pt.id_partido = g.id_partido
    JOIN mundial.fase f ON f.id_fase = pt.id_fase
    JOIN mundial.jugador j ON j.id_jugador = g.id_jugador_autor
    JOIN mundial.posicion pos ON pos.id_posicion = j.id_posicion_habitual
    JOIN mundial.seleccion s ON s.id_seleccion = g.id_seleccion_beneficiada
    JOIN mundial.pais p ON p.id_pais = s.id_pais
    LEFT JOIN mundial.convocatoria c ON c.id_seleccion = s.id_seleccion AND c.id_jugador = j.id_jugador
    JOIN mundial.tipo_gol tg ON tg.id_tipo_gol = g.id_tipo_gol
    WHERE (@id_fase IS NULL OR pt.id_fase = @id_fase)
      AND (@id_seleccion IS NULL OR s.id_seleccion = @id_seleccion)
    GROUP BY
        j.id_jugador, j.nombres, j.apellidos, p.nombre, pos.descripcion, c.dorsal, f.nombre_fase
    ORDER BY
        GolesTotales DESC, Ranking, Jugador;
END;
GO

/* =========================================================================
   REPORTE 2: TARJETAS (AMARILLAS Y ROJAS) Y SUSPENSIONES ACTIVAS (RETORNO XML)
   ========================================================================= */

CREATE OR ALTER PROCEDURE mundial.sp_reporte_Tarjetas
    @id_seleccion INT = NULL,
    @solo_con_suspension BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.nombre AS [@pais],
        p.codigo_iso AS [@codigo_iso],
        cf.sigla AS [@confederacion],
        (
            SELECT
                j.id_jugador AS [@id],
                CONCAT(j.nombres, ' ', j.apellidos) AS [@nombre_completo],
                c.dorsal AS [@dorsal],
                ISNULL(SUM(CASE WHEN tt.descripcion = 'AMARILLA' THEN 1 ELSE 0 END), 0) AS [@amarillas],
                ISNULL(SUM(CASE WHEN tt.descripcion = 'ROJA' THEN 1 ELSE 0 END), 0) AS [@rojas],
                (
                    SELECT
                        sj.id_suspension AS [@id_suspension],
                        sj.motivo AS [@motivo],
                        sj.partidos_sancion AS [@partidos_sancion],
                        sj.partidos_cumplidos AS [@partidos_cumplidos],
                        pt.fecha_hora_local AS [@partido_origen_fecha]
                    FROM mundial.suspension_jugador sj
                    JOIN mundial.partido pt ON pt.id_partido = sj.id_partido_origen
                    WHERE sj.id_jugador = j.id_jugador
                      AND sj.cumplida = 0
                    FOR XML PATH('SuspensionActiva'), TYPE
                ) AS [SuspensionesActivas]
            FROM mundial.convocatoria c
            JOIN mundial.jugador j ON j.id_jugador = c.id_jugador
            LEFT JOIN mundial.tarjeta t ON t.id_jugador = j.id_jugador
            LEFT JOIN mundial.tipo_tarjeta tt ON tt.id_tipo_tarjeta = t.id_tipo_tarjeta
            WHERE c.id_seleccion = s.id_seleccion
              AND (
                  @solo_con_suspension = 0
                  OR EXISTS (SELECT 1 FROM mundial.suspension_jugador sj WHERE sj.id_jugador = j.id_jugador AND sj.cumplida = 0)
              )
            GROUP BY j.id_jugador, j.nombres, j.apellidos, c.dorsal
            HAVING (COUNT(t.id_tarjeta) > 0 OR EXISTS (SELECT 1 FROM mundial.suspension_jugador sj WHERE sj.id_jugador = j.id_jugador AND sj.cumplida = 0))
            ORDER BY [@rojas] DESC, [@amarillas] DESC, [@dorsal]
            FOR XML PATH('Jugador'), TYPE
        ) AS [JugadoresSancionados]
    FROM mundial.seleccion s
    JOIN mundial.pais p ON p.id_pais = s.id_pais
    JOIN mundial.confederacion cf ON cf.id_confederacion = p.id_confederacion
    WHERE (@id_seleccion IS NULL OR s.id_seleccion = @id_seleccion)
    FOR XML PATH('Seleccion'), ROOT('ReporteDisciplinarioTorneo');
END;
GO

/* REPORTE 3: DESIGNACIONES ARBITRALES Y SANCIONES SENALADAS */

CREATE OR ALTER PROCEDURE mundial.sp_reporte_DesignacionesArbitrales
    @id_arbitro INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.id_arbitro,
        CONCAT(a.nombres, ' ', a.apellidos) AS Arbitro,
        p.nombre AS Nacionalidad,
        c.sigla AS Confederacion,
        a.categoria AS Categoria,
        COUNT(DISTINCT da.id_partido) AS PartidosTotalesAsignados,
        SUM(CASE WHEN ra.descripcion = 'ARBITRO_PRINCIPAL' THEN 1 ELSE 0 END) AS PartidosComoPrincipal,
        SUM(CASE WHEN ra.descripcion IN ('ASISTENTE_1', 'ASISTENTE_2') THEN 1 ELSE 0 END) AS PartidosComoAsistente,
        SUM(CASE WHEN ra.descripcion = 'CUARTO_ARBITRO' THEN 1 ELSE 0 END) AS PartidosComoCuarto,
        SUM(CASE WHEN ra.descripcion = 'VAR' THEN 1 ELSE 0 END) AS PartidosComoVAR,
        ISNULL(tarjetas.AmarillasMostradas, 0) AS AmarillasSenaladas,
        ISNULL(tarjetas.RojasMostradas, 0) AS RojasSenaladas,
        ISNULL(tarjetas.TotalTarjetas, 0) AS TotalTarjetasSenaladas
    FROM mundial.arbitro a
    JOIN mundial.pais p ON p.id_pais = a.id_pais_nacionalidad
    JOIN mundial.confederacion c ON c.id_confederacion = a.id_confederacion_afiliacion
    LEFT JOIN mundial.designacion_arbitral da ON da.id_arbitro = a.id_arbitro
    LEFT JOIN mundial.rol_arbitral ra ON ra.id_rol_arbitral = da.id_rol_arbitral
    OUTER APPLY
    (
        SELECT
            SUM(CASE WHEN tt.descripcion = 'AMARILLA' THEN 1 ELSE 0 END) AS AmarillasMostradas,
            SUM(CASE WHEN tt.descripcion = 'ROJA' THEN 1 ELSE 0 END) AS RojasMostradas,
            COUNT(t.id_tarjeta) AS TotalTarjetas
        FROM mundial.designacion_arbitral da_prin
        JOIN mundial.rol_arbitral ra_p ON ra_p.id_rol_arbitral = da_prin.id_rol_arbitral AND ra_p.descripcion = 'ARBITRO_PRINCIPAL'
        JOIN mundial.tarjeta t ON t.id_partido = da_prin.id_partido
        JOIN mundial.tipo_tarjeta tt ON tt.id_tipo_tarjeta = t.id_tipo_tarjeta
        WHERE da_prin.id_arbitro = a.id_arbitro
    ) tarjetas
    WHERE (@id_arbitro IS NULL OR a.id_arbitro = @id_arbitro)
    GROUP BY
        a.id_arbitro, a.nombres, a.apellidos, p.nombre, c.sigla, a.categoria,
        tarjetas.AmarillasMostradas, tarjetas.RojasMostradas, tarjetas.TotalTarjetas
    ORDER BY
        PartidosComoPrincipal DESC, PartidosTotalesAsignados DESC, Arbitro;
END;
GO

/* REPORTE 4: OCUPACION PUBLICITARIA POR SEDE Y PARTIDO (INGRESOS GENERADOS) */

CREATE OR ALTER PROCEDURE mundial.sp_reporte_OcupacionPublicitaria
    @id_sede INT = NULL,
    @id_partido INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        se.nombre_estadio AS SedeEstadio,
        cd.nombre AS Ciudad,
        p.id_partido AS NroPartido,
        f.nombre_fase AS Fase,
        CONCAT(pl.nombre, ' vs ', pv.nombre) AS Encuentro,
        p.fecha_hora_local AS FechaHoraLocal,
        MAX(CASE WHEN ep.numero_espacio = 1 THEN CONCAT(anc.razon_social, ' (', pz.titulo, ')') END) AS Espacio_1,
        MAX(CASE WHEN ep.numero_espacio = 2 THEN CONCAT(anc.razon_social, ' (', pz.titulo, ')') END) AS Espacio_2,
        MAX(CASE WHEN ep.numero_espacio = 3 THEN CONCAT(anc.razon_social, ' (', pz.titulo, ')') END) AS Espacio_3,
        MAX(CASE WHEN ep.numero_espacio = 4 THEN CONCAT(anc.razon_social, ' (', pz.titulo, ')') END) AS Espacio_4,
        COUNT(pp.id_pauta) AS EspaciosOcupados,
        SUM(pp.tarifa_base_usd) AS TotalIngreso_USD,
        SUM(pp.tarifa_final) AS TotalIngresoFacturado,
        SUM(CASE WHEN pp.es_prime_time = 1 THEN 1 ELSE 0 END) AS CantidadPautasPrimeTime
    FROM mundial.partido p
    JOIN mundial.fase f ON f.id_fase = p.id_fase
    JOIN mundial.sede_estadio se ON se.id_sede = p.id_sede
    JOIN mundial.ciudad cd ON cd.id_ciudad = se.id_ciudad
    JOIN mundial.seleccion sl ON sl.id_seleccion = p.id_seleccion_local
    JOIN mundial.pais pl ON pl.id_pais = sl.id_pais
    JOIN mundial.seleccion sv ON sv.id_seleccion = p.id_seleccion_visitante
    JOIN mundial.pais pv ON pv.id_pais = sv.id_pais
    LEFT JOIN mundial.pauta_partido pp ON pp.id_partido = p.id_partido
    LEFT JOIN mundial.espacio_publicitario ep ON ep.id_espacio = pp.id_espacio
    LEFT JOIN mundial.pieza_publicitaria pz ON pz.id_pieza = pp.id_pieza
    LEFT JOIN mundial.campania cmp ON cmp.id_campania = pz.id_campania
    LEFT JOIN mundial.anunciante anc ON anc.id_anunciante = cmp.id_anunciante
    WHERE (@id_sede IS NULL OR p.id_sede = @id_sede)
      AND (@id_partido IS NULL OR p.id_partido = @id_partido)
    GROUP BY
        se.nombre_estadio, cd.nombre, p.id_partido, f.nombre_fase, pl.nombre, pv.nombre, p.fecha_hora_local
    ORDER BY
        p.id_partido;
END;
GO

/* REPORTE 5: MATRIZ DE PRIME TIME (PIVOT PARTIDO VS MERCADOS/PAISES)
   Horario Prime Time definido: hora local del mercado entre 19:00 y 23:00.
*/

CREATE OR ALTER PROCEDURE mundial.sp_reporte_MatrizPrimeTime
    @id_partido INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    /* Mercados representativos con offsets estandar respecto a UTC:
       ARG: UTC-3 | BRA: UTC-3 | USA (NY): UTC-5 | MEX: UTC-6 | FRA: UTC+2 | GER: UTC+2 | GBR: UTC+1 | JPN: UTC+9 */

    ;WITH CalculoMercados AS
    (
        SELECT
            p.id_partido,
            f.nombre_fase,
            CONCAT(pl.codigo_iso, ' vs ', pv.codigo_iso) AS Partido,
            p.fecha_hora_utc,
            mercado.Mercado,
            CASE
                WHEN DATEPART(HOUR, DATEADD(HOUR, mercado.OffsetUTC, p.fecha_hora_utc)) BETWEEN 19 AND 23
                THEN CONCAT('SI (', FORMAT(DATEADD(HOUR, mercado.OffsetUTC, p.fecha_hora_utc), 'HH:mm'), ')')
                ELSE CONCAT('NO (', FORMAT(DATEADD(HOUR, mercado.OffsetUTC, p.fecha_hora_utc), 'HH:mm'), ')')
            END AS EstadoPrimeTime
        FROM mundial.partido p
        JOIN mundial.fase f ON f.id_fase = p.id_fase
        JOIN mundial.seleccion sl ON sl.id_seleccion = p.id_seleccion_local
        JOIN mundial.pais pl ON pl.id_pais = sl.id_pais
        JOIN mundial.seleccion sv ON sv.id_seleccion = p.id_seleccion_visitante
        JOIN mundial.pais pv ON pv.id_pais = sv.id_pais
        CROSS JOIN (
            VALUES
            ('ARG', -3),
            ('BRA', -3),
            ('USA', -5),
            ('MEX', -6),
            ('FRA', 2),
            ('GER', 2),
            ('GBR', 1),
            ('JPN', 9)
        ) mercado(Mercado, OffsetUTC)
        WHERE (@id_partido IS NULL OR p.id_partido = @id_partido)
    )
    SELECT
        id_partido AS NroPartido,
        nombre_fase AS Fase,
        Partido,
        fecha_hora_utc AS FechaHoraUTC,
        ISNULL([ARG], 'NO') AS [ARG (UTC-3)],
        ISNULL([BRA], 'NO') AS [BRA (UTC-3)],
        ISNULL([USA], 'NO') AS [USA (UTC-5)],
        ISNULL([MEX], 'NO') AS [MEX (UTC-6)],
        ISNULL([FRA], 'NO') AS [FRA (UTC+2)],
        ISNULL([GER], 'NO') AS [GER (UTC+2)],
        ISNULL([GBR], 'NO') AS [GBR (UTC+1)],
        ISNULL([JPN], 'NO') AS [JPN (UTC+9)]
    FROM CalculoMercados
    PIVOT
    (
        MAX(EstadoPrimeTime)
        FOR Mercado IN ([ARG], [BRA], [USA], [MEX], [FRA], [GER], [GBR], [JPN])
    ) pvt
    ORDER BY NroPartido;
END;
GO

/* REPORTE 6: SELECCIONES Y PLANTILLAS (VECTOR ANIDADO DE CONVOCADOS EN XML) */

CREATE OR ALTER PROCEDURE mundial.sp_reporte_SeleccionesPlantillas
    @id_seleccion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.nombre AS [@pais],
        p.codigo_iso AS [@codigo_iso],
        cf.sigla AS [@confederacion],
        g.nombre_grupo AS [@grupo],
        COUNT(c.id_convocatoria) AS [@total_convocados],
        (
            SELECT
                c2.dorsal AS [@dorsal],
                CONCAT(j.nombres, ' ', j.apellidos) AS [@nombre_completo],
                pos.descripcion AS [@posicion],
                pos.linea_campo AS [@linea_campo],
                cl.nombre_club AS [@club_origen],
                j.fecha_nacimiento AS [@fecha_nacimiento],
                j.doc_identidad AS [@documento]
            FROM mundial.convocatoria c2
            JOIN mundial.jugador j ON j.id_jugador = c2.id_jugador
            JOIN mundial.posicion pos ON pos.id_posicion = j.id_posicion_habitual
            JOIN mundial.club cl ON cl.id_club = j.id_club
            WHERE c2.id_seleccion = s.id_seleccion
            ORDER BY c2.dorsal
            FOR XML PATH('Jugador'), TYPE
        ) AS [PlantillaConvocados]
    FROM mundial.seleccion s
    JOIN mundial.pais p ON p.id_pais = s.id_pais
    JOIN mundial.confederacion cf ON cf.id_confederacion = p.id_confederacion
    LEFT JOIN mundial.grupo g ON g.id_grupo = s.id_grupo
    LEFT JOIN mundial.convocatoria c ON c.id_seleccion = s.id_seleccion
    WHERE (@id_seleccion IS NULL OR s.id_seleccion = @id_seleccion)
    GROUP BY s.id_seleccion, p.nombre, p.codigo_iso, cf.sigla, g.nombre_grupo
    ORDER BY p.nombre
    FOR XML PATH('Seleccion'), ROOT('TorneoMundialFIFA2026');
END;
GO

/* REPORTE 7: RESULTADOS DE LOS ENCUENTROS (FORMATO ILUSTRATIVO) */

CREATE OR ALTER PROCEDURE mundial.sp_reporte_ResultadosEncuentros
    @id_fase INT = NULL,
    @id_sede INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.id_partido AS [ID],
        f.nombre_fase AS [Fase],
        FORMAT(p.fecha_hora_local, 'dd/MM/yyyy HH:mm') AS [Fecha y Hora Local],
        se.nombre_estadio AS [Estadio],
        cd.nombre AS [Ciudad],
        CONCAT(
            UPPER(pl.nombre),
            ' [ ',
            ISNULL(CAST(p.goles_local AS VARCHAR(10)), '-'),
            ' ]  vs  [ ',
            ISNULL(CAST(p.goles_visitante AS VARCHAR(10)), '-'),
            ' ] ',
            UPPER(pv.nombre),
            CASE
                WHEN p.penales_local IS NOT NULL AND p.penales_visitante IS NOT NULL
                THEN CONCAT(' (Penales: ', p.penales_local, ' - ', p.penales_visitante, ')')
                ELSE ''
            END
        ) AS [Marcador Final],
        CASE
            WHEN p.goles_local > p.goles_visitante THEN pl.nombre
            WHEN p.goles_visitante > p.goles_local THEN pv.nombre
            WHEN p.penales_local > p.penales_visitante THEN pl.nombre
            WHEN p.penales_visitante > p.penales_local THEN pv.nombre
            ELSE 'Empate'
        END AS [Ganador],
        ISNULL(FORMAT(p.asistencia_publico, '#,0'), 'Sin datos') AS [Asistencia Espectadores],
        p.estado_partido AS [Estado],
        ISNULL(goles.DetalleGoles, 'Sin goles registrados') AS [Goleadores del Partido]
    FROM mundial.partido p
    JOIN mundial.fase f ON f.id_fase = p.id_fase
    JOIN mundial.sede_estadio se ON se.id_sede = p.id_sede
    JOIN mundial.ciudad cd ON cd.id_ciudad = se.id_ciudad
    JOIN mundial.seleccion sl ON sl.id_seleccion = p.id_seleccion_local
    JOIN mundial.pais pl ON pl.id_pais = sl.id_pais
    JOIN mundial.seleccion sv ON sv.id_seleccion = p.id_seleccion_visitante
    JOIN mundial.pais pv ON pv.id_pais = sv.id_pais
    OUTER APPLY
    (
        SELECT STRING_AGG(
            CONCAT(j.apellidos, ' (', g.minuto, ''')', CASE WHEN g.es_gol_en_contra = 1 THEN ' [EC]' ELSE '' END),
            ', '
        ) WITHIN GROUP (ORDER BY g.minuto) AS DetalleGoles
        FROM mundial.gol g
        JOIN mundial.jugador j ON j.id_jugador = g.id_jugador_autor
        WHERE g.id_partido = p.id_partido
    ) goles
    WHERE (@id_fase IS NULL OR p.id_fase = @id_fase)
      AND (@id_sede IS NULL OR p.id_sede = @id_sede)
    ORDER BY p.id_partido;
END;
GO
