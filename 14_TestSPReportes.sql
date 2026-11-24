/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-23
    Objetivo: Script de testing para los 7 procedimientos de reportes analiticos (Entrega 7).
              Incluye indicaciones y comentarios con los resultados esperados de cada ejecucion.
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'=========================================================================';
PRINT N'         TESTING INTEGRAL DE PROCEDIMIENTOS DE REPORTES (ENTREGA 7)      ';
PRINT N'=========================================================================';

/* =========================================================================
   TEST REPORTE 1: GOLEADORES
   Resultado esperado:
   - Lista ordenada descendentemente por cantidad de goles anotados.
   - Detalle de goles por jugada, penal, tiro libre y en contra.
   - Posibilidad de filtrar por fase o seleccion especifica.
   ========================================================================= */
PRINT N'--- TEST 1: Reporte de Goleadores del Torneo ---';
EXEC mundial.sp_reporte_Goleadores;

PRINT N'--- TEST 1.1: Reporte de Goleadores (Filtro por Seleccion Argentina) ---';
DECLARE @sel_arg INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'ARG');
EXEC mundial.sp_reporte_Goleadores @id_seleccion = @sel_arg;

/* =========================================================================
   TEST REPORTE 2: TARJETAS Y SUSPENSIONES ACTIVAS (XML)
   Resultado esperado:
   - Documento XML bien formado bajo el nodo raiz <ReporteDisciplinarioTorneo>.
   - Cada nodo <Seleccion> contiene sub-nodos <Jugador> con atributos de amarillas/rojas.
   - Si el jugador posee suspension activa, se anida el nodo <SuspensionActiva>.
   ========================================================================= */
PRINT N'--- TEST 2: Reporte Disciplinario de Tarjetas y Suspensiones (Salida XML) ---';
DECLARE @xml_disciplina XML;
EXEC mundial.sp_reporte_Tarjetas;

PRINT N'--- TEST 2.1: Reporte Disciplinario (Solo jugadores con suspension activa) ---';
EXEC mundial.sp_reporte_Tarjetas @solo_con_suspension = 1;

/* =========================================================================
   TEST REPORTE 3: DESIGNACIONES ARBITRALES
   Resultado esperado:
   - Nomina de arbitros con cantidad de partidos dirigidos discriminados por rol:
     Principal, Asistente, Cuarto Arbitro y VAR.
   - Conteo de tarjetas amarillas y rojas mostradas como arbitro principal.
   ========================================================================= */
PRINT N'--- TEST 3: Reporte de Designaciones Arbitrales y Tarjetas Mostradas ---';
EXEC mundial.sp_reporte_DesignacionesArbitrales;

/* =========================================================================
   TEST REPORTE 4: OCUPACION PUBLICITARIA POR SEDE Y PARTIDO
   Resultado esperado:
   - Detalle de los 4 espacios publicitarios por partido.
   - Razon social del anunciante y titulo de la pieza exhibida.
   - Montos de facturacion en USD y marcas de transmision en prime time.
   ========================================================================= */
PRINT N'--- TEST 4: Reporte de Ocupacion Publicitaria e Ingresos por Partido ---';
EXEC mundial.sp_reporte_OcupacionPublicitaria;

PRINT N'--- TEST 4.1: Reporte de Ocupacion Publicitaria (Filtro por Estadio Azteca) ---';
DECLARE @sede_azteca INT = (SELECT id_sede FROM mundial.sede_estadio WHERE nombre_estadio = 'Estadio Azteca');
EXEC mundial.sp_reporte_OcupacionPublicitaria @id_sede = @sede_azteca;

/* =========================================================================
   TEST REPORTE 5: MATRIZ DE PRIME TIME (PIVOT)
   Resultado esperado:
   - Tabla cruzada con partidos en filas y columnas por mercado:
     ARG (UTC-3), BRA (UTC-3), USA (UTC-5), MEX (UTC-6), FRA (UTC+2), GER (UTC+2), GBR (UTC+1), JPN (UTC+9).
   - Indicador SI/NO con hora local del mercado indicando si cae en horario prime time (19 a 23 hs).
   ========================================================================= */
PRINT N'--- TEST 5: Matriz Cruzada de Prime Time por Mercado Destino ---';
EXEC mundial.sp_reporte_MatrizPrimeTime;

/* =========================================================================
   TEST REPORTE 6: SELECCIONES Y PLANTILLAS (VECTOR ANIDADO EN XML)
   Resultado esperado:
   - Documento XML estructurado bajo el nodo raiz <TorneoMundialFIFA2026>.
   - Cada nodo <Seleccion> contiene el vector anidado <PlantillaConvocados> con los
     23 jugadores convocados, sus dorsales, linea de campo y club de origen.
   ========================================================================= */
PRINT N'--- TEST 6: Reporte de Selecciones y Plantillas (Salida XML Anidada) ---';
EXEC mundial.sp_reporte_SeleccionesPlantillas;

PRINT N'--- TEST 6.1: Reporte de Selecciones y Plantillas (Filtro por Seleccion Brasil) ---';
DECLARE @sel_bra INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'BRA');
EXEC mundial.sp_reporte_SeleccionesPlantillas @id_seleccion = @sel_bra;

/* =========================================================================
   TEST REPORTE 7: RESULTADOS DE LOS ENCUENTROS
   Resultado esperado:
   - Grilla clara e ilustrativa de todos los partidos del torneo.
   - Formato visual de marcador: "ARGENTINA [ 2 ] vs [ 1 ] BRASIL".
   - Identificacion de ganador, penales en caso de empate en fases eliminatorias,
     asistencia de publico y detalle condensado de goleadores del encuentro.
   ========================================================================= */
PRINT N'--- TEST 7: Reporte Ilustrativo de Resultados del Torneo ---';
EXEC mundial.sp_reporte_ResultadosEncuentros;

PRINT N'--- TEST 7.1: Reporte de Resultados (Filtro por Fase Final) ---';
DECLARE @fase_final INT = (SELECT id_fase FROM mundial.fase WHERE nombre_fase = 'Final');
EXEC mundial.sp_reporte_ResultadosEncuentros @id_fase = @fase_final;

PRINT N'=========================================================================';
PRINT N'         TODOS LOS REPORTES DE LA ENTREGA 7 FUERON EJECUTADOS CON EXITO   ';
PRINT N'=========================================================================';
GO
