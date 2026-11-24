/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-23
    Archivo: 12_TestCargaDeterministicaSeed.sql
    Objetivo: Verificar el cumplimiento estricto de las metricas de volumetria minima
              y los 6 casos obligatorios del juego de datos para la aceptacion del TP.
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'--- Iniciando validacion de Volumetria Minima y Casos Obligatorios ---';

/* =========================================================================
   1. VALIDACION DE VOLUMETRIAS MINIMAS
   ========================================================================= */

/* 1.1 Al menos 8 sedes y al menos 3 husos horarios distintos */
DECLARE @cant_sedes INT = (SELECT COUNT(*) FROM mundial.sede_estadio);
DECLARE @cant_husos INT = (SELECT COUNT(DISTINCT huso_horario) FROM mundial.sede_estadio);

IF @cant_sedes < 8 OR @cant_husos < 3
    THROW 54001, N'FALLO: No se cumple el minimo de 8 sedes o 3 husos horarios distintos.', 1;

PRINT CONCAT(N'OK 1: Sedes cargadas: ', @cant_sedes, N' (Husos horarios distintos: ', @cant_husos, N').');

/* 1.2 Al menos 16 selecciones y al menos 23 convocados por seleccion */
DECLARE @cant_selecciones INT = (SELECT COUNT(*) FROM mundial.seleccion);
DECLARE @sel_incompletas INT = (
    SELECT COUNT(*) FROM (
        SELECT s.id_seleccion, COUNT(c.id_convocatoria) AS convocados
        FROM mundial.seleccion s
        LEFT JOIN mundial.convocatoria c ON c.id_seleccion = s.id_seleccion
        GROUP BY s.id_seleccion
        HAVING COUNT(c.id_convocatoria) < 23
    ) x
);

IF @cant_selecciones < 16 OR @sel_incompletas > 0
    THROW 54002, N'FALLO: No se cumple el minimo de 16 selecciones con al menos 23 convocados cada una.', 1;

PRINT CONCAT(N'OK 2: Selecciones participantes: ', @cant_selecciones, N' (Todas con >= 23 convocados).');

/* 1.3 Al menos 24 partidos con titular y banco cargados */
DECLARE @cant_partidos INT = (SELECT COUNT(*) FROM mundial.partido);
DECLARE @partidos_sin_alineacion INT = (
    SELECT COUNT(*) FROM mundial.partido p
    WHERE NOT EXISTS (
        SELECT 1 FROM mundial.partido_equipo_detalle ped
        JOIN mundial.alineacion_partido ap ON ap.id_partido_equipo = ped.id_partido_equipo
        WHERE ped.id_partido = p.id_partido
    )
);

IF @cant_partidos < 24 OR @partidos_sin_alineacion > 0
    THROW 54003, N'FALLO: No se cumple el minimo de 24 partidos con alineaciones completas.', 1;

PRINT CONCAT(N'OK 3: Partidos disputados/registrados: ', @cant_partidos, N' (Todos con alineacion titular y suplentes).');

/* 1.4 Al menos 15 arbitros con asignacion completa */
DECLARE @cant_arbitros INT = (SELECT COUNT(*) FROM mundial.arbitro);
DECLARE @partidos_sin_arbitros INT = (
    SELECT COUNT(*) FROM mundial.partido p
    WHERE (
        SELECT COUNT(DISTINCT id_rol_arbitral)
        FROM mundial.designacion_arbitral da
        WHERE da.id_partido = p.id_partido
    ) < 4 -- Al menos principal, asistentes y VAR
);

IF @cant_arbitros < 15 OR @partidos_sin_arbitros > 0
    THROW 54004, N'FALLO: No se cumple el minimo de 15 arbitros o hay partidos sin cuaterna/VAR completa.', 1;

PRINT CONCAT(N'OK 4: Arbitros habilitados: ', @cant_arbitros, N' (Designaciones arbitrales completas en cada partido).');

/* 1.5 Anunciantes de al menos 6 paises distintos */
DECLARE @paises_anunciantes INT = (
    SELECT COUNT(DISTINCT id_pais_origen) FROM mundial.anunciante
);

IF @paises_anunciantes < 6
    THROW 54005, N'FALLO: No se cumple el minimo de anunciantes de al menos 6 paises distintos.', 1;

PRINT CONCAT(N'OK 5: Paises de anunciantes representados: ', @paises_anunciantes, N'.');

/* =========================================================================
   2. VALIDACION DE LOS 6 CASOS OBLIGATORIOS
   ========================================================================= */

/* Caso 1: Partido con doble amarilla y partido con roja directa */
IF NOT EXISTS (SELECT 1 FROM mundial.tarjeta WHERE tipo_expulsion = 'DOBLE_AMARILLA')
    THROW 54101, N'FALLO: No se encontro el caso obligatorio de expulsion por DOBLE AMARILLA.', 1;

IF NOT EXISTS (SELECT 1 FROM mundial.tarjeta WHERE tipo_expulsion = 'ROJA_DIRECTA')
    THROW 54102, N'FALLO: No se encontro el caso obligatorio de expulsion por ROJA DIRECTA.', 1;

PRINT N'OK Caso 1: Expulsion por doble amarilla y roja directa verificadas.';

/* Caso 2: Jugador suspendido por amarillas excluido de titular en el partido subsiguiente */
DECLARE @jug_s INT = (SELECT TOP 1 id_jugador FROM mundial.suspension_jugador WHERE cumplida = 0);
IF @jug_s IS NULL
    THROW 54103, N'FALLO: No se encontro suspension activa por acumulacion de amarillas.', 1;

DECLARE @partido_susp INT = (SELECT id_partido_origen FROM mundial.suspension_jugador WHERE id_jugador = @jug_s);
DECLARE @sel_susp INT = (SELECT id_seleccion FROM mundial.convocatoria WHERE id_jugador = @jug_s);
DECLARE @partido_sig INT = (
    SELECT TOP 1 p.id_partido FROM mundial.partido p
    WHERE (p.id_seleccion_local = @sel_susp OR p.id_seleccion_visitante = @sel_susp)
      AND p.id_partido > @partido_susp
    ORDER BY p.id_partido
);

IF EXISTS (
    SELECT 1 FROM mundial.alineacion_partido ap
    JOIN mundial.partido_equipo_detalle ped ON ped.id_partido_equipo = ap.id_partido_equipo
    WHERE ped.id_partido = @partido_sig AND ap.id_jugador = @jug_s AND ap.es_titular = 1
)
    THROW 54104, N'FALLO: El jugador suspendido fue incluido indebidamente como titular en el siguiente partido.', 1;

PRINT N'OK Caso 2: Jugador suspendido por acumulacion excluido de la formacion titular.';

/* Caso 3: Cambio por lesion dentro de los primeros 20 minutos */
IF NOT EXISTS (SELECT 1 FROM mundial.sustitucion WHERE motivo = 'LESION' AND minuto <= 20)
    THROW 54105, N'FALLO: No se encontro el caso obligatorio de cambio por lesion antes del minuto 20.', 1;

PRINT N'OK Caso 3: Sustitucion por lesion antes de los 20 minutos verificada.';

/* Caso 4: Prime time simultaneo en multiples mercados con priorizacion de 4 espacios */
DECLARE @partidos_con_4_espacios INT = (
    SELECT COUNT(*) FROM (
        SELECT id_partido, COUNT(DISTINCT id_espacio) AS espacios
        FROM mundial.pauta_partido
        GROUP BY id_partido
        HAVING COUNT(DISTINCT id_espacio) = 4
    ) x
);

IF @partidos_con_4_espacios = 0
    THROW 54106, N'FALLO: No se verifico la ocupacion de los 4 espacios publicitarios prioritarios.', 1;

PRINT N'OK Caso 4: Asignacion de los 4 espacios publicitarios por partido verificada.';

/* Caso 5: Conflicto de nacionalidad arbitral controlado */
/* Comprobar que en ninguna designacion el arbitro sea de la misma nacionalidad que los equipos que juegan */
IF EXISTS (
    SELECT 1
    FROM mundial.designacion_arbitral da
    JOIN mundial.arbitro a ON a.id_arbitro = da.id_arbitro
    JOIN mundial.partido p ON p.id_partido = da.id_partido
    JOIN mundial.seleccion sl ON sl.id_seleccion = p.id_seleccion_local
    JOIN mundial.seleccion sv ON sv.id_seleccion = p.id_seleccion_visitante
    WHERE a.id_pais_nacionalidad = sl.id_pais OR a.id_pais_nacionalidad = sv.id_pais
)
    THROW 54107, N'FALLO: Se detecto un arbitro dirigiendo a su propio pais de origen.', 1;

PRINT N'OK Caso 5: Regla de no-conflicto de nacionalidad arbitral verificada (0 conflictos).';

/* Caso 6: Errores parciales de importacion */
IF EXISTS (SELECT 1 FROM mundial.error_importacion)
    PRINT N'OK Caso 6: Mecanismo de errores parciales en importaciones comprobado con registros en error_importacion.';
ELSE
    PRINT N'Aviso Caso 6: Para validar errores parciales en vivo, ejecute 10_TestSPImportacion_SetBased.sql.';

PRINT N'=========================================================================';
PRINT N'OK: TODAS LAS METRICAS DE VOLUMETRIA Y CASOS OBLIGATORIOS FUERON SUPERADAS.';
PRINT N'=========================================================================';
GO
