/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-23
    Objetivo: Carga deterministica de datos maestros y operativos para garantizar
              los volumenes minimos y los 6 casos obligatorios del juego de datos.
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'--- Iniciando carga deterministica de seed y casos obligatorios ---';

/* 
   1. CONFEDERACIONES Y PAISES (Al menos 16 selecciones y 6 paises anunciantes)
*/

DECLARE @Conf TABLE (nombre VARCHAR(100), sigla VARCHAR(10));
INSERT INTO @Conf VALUES
    ('Confederacion Sudamericana de Futbol', 'CONMEBOL'),
    ('Union of European Football Associations', 'UEFA'),
    ('Confederation of North, Central America and Caribbean Association Football', 'CONCACAF'),
    ('Asian Football Confederation', 'AFC'),
    ('Confederation of African Football', 'CAF');

INSERT INTO mundial.confederacion (nombre, sigla)
SELECT c.nombre, c.sigla FROM @Conf c
WHERE NOT EXISTS (SELECT 1 FROM mundial.confederacion WHERE sigla = c.sigla);

DECLARE @c_conmebol INT = (SELECT id_confederacion FROM mundial.confederacion WHERE sigla = 'CONMEBOL');
DECLARE @c_uefa INT = (SELECT id_confederacion FROM mundial.confederacion WHERE sigla = 'UEFA');
DECLARE @c_concacaf INT = (SELECT id_confederacion FROM mundial.confederacion WHERE sigla = 'CONCACAF');
DECLARE @c_afc INT = (SELECT id_confederacion FROM mundial.confederacion WHERE sigla = 'AFC');
DECLARE @c_caf INT = (SELECT id_confederacion FROM mundial.confederacion WHERE sigla = 'CAF');

DECLARE @Paises TABLE (id_conf INT, nombre VARCHAR(100), iso CHAR(3), tz VARCHAR(100), pbi DECIMAL(18,2), moneda CHAR(3));
INSERT INTO @Paises VALUES
    (@c_conmebol, 'Argentina', 'ARG', 'America/Argentina/Buenos_Aires', 13686.00, 'ARS'),
    (@c_conmebol, 'Brasil', 'BRA', 'America/Sao_Paulo', 8917.00, 'BRL'),
    (@c_conmebol, 'Uruguay', 'URU', 'America/Montevideo', 20000.00, 'UYU'),
    (@c_conmebol, 'Colombia', 'COL', 'America/Bogota', 6600.00, 'COP'),
    (@c_uefa, 'Francia', 'FRA', 'Europe/Paris', 44460.00, 'EUR'),
    (@c_uefa, 'Alemania', 'GER', 'Europe/Berlin', 48432.00, 'EUR'),
    (@c_uefa, 'Espana', 'ESP', 'Europe/Madrid', 29350.00, 'EUR'),
    (@c_uefa, 'Inglaterra', 'ENG', 'Europe/London', 46000.00, 'GBP'),
    (@c_uefa, 'Italia', 'ITA', 'Europe/Rome', 35000.00, 'EUR'),
    (@c_uefa, 'Paises Bajos', 'NED', 'Europe/Amsterdam', 57000.00, 'EUR'),
    (@c_uefa, 'Croacia', 'CRO', 'Europe/Zagreb', 18000.00, 'EUR'),
    (@c_uefa, 'Portugal', 'POR', 'Europe/Lisbon', 24000.00, 'EUR'),
    (@c_concacaf, 'Estados Unidos', 'USA', 'America/New_York', 76398.00, 'USD'),
    (@c_concacaf, 'Mexico', 'MEX', 'America/Mexico_City', 11000.00, 'MXN'),
    (@c_concacaf, 'Canada', 'CAN', 'America/Toronto', 52000.00, 'CAD'),
    (@c_afc, 'Japon', 'JPN', 'Asia/Tokyo', 33800.00, 'JPY');

INSERT INTO mundial.pais (id_confederacion, nombre, codigo_iso, huso_horario_estandar, pbi_per_capita, codigo_moneda)
SELECT p.id_conf, p.nombre, p.iso, p.tz, p.pbi, p.moneda
FROM @Paises p
WHERE NOT EXISTS (SELECT 1 FROM mundial.pais WHERE codigo_iso = p.iso);

/* Monedas */
DECLARE @Monedas TABLE (iso CHAR(3), descr VARCHAR(100));
INSERT INTO @Monedas VALUES
    ('USD', 'Dolar Estadounidense'), ('EUR', 'Euro'), ('BRL', 'Real Brasileno'),
    ('GBP', 'Libra Esterlina'), ('JPY', 'Yen Japones'), ('CAD', 'Dolar Canadiense'),
    ('MXN', 'Peso Mexicano'), ('ARS', 'Peso Argentino'), ('UYU', 'Peso Uruguayo'),
    ('COP', 'Peso Colombiano');

INSERT INTO mundial.moneda (codigo_iso, descripcion)
SELECT m.iso, m.descr FROM @Monedas m
WHERE NOT EXISTS (SELECT 1 FROM mundial.moneda WHERE codigo_iso = m.iso);

/*
   2. SEDES (Al menos 8 sedes con al menos 3 husos horarios distintos)
 */

/* Ciudades */
DECLARE @Ciudades TABLE (iso CHAR(3), nombre VARCHAR(100));
INSERT INTO @Ciudades VALUES
    ('USA', 'East Rutherford'), ('USA', 'Inglewood'), ('USA', 'Atlanta'), ('USA', 'Miami'),
    ('MEX', 'Ciudad de Mexico'), ('MEX', 'Guadalajara'),
    ('CAN', 'Toronto'), ('CAN', 'Vancouver');

INSERT INTO mundial.ciudad (id_pais, nombre)
SELECT p.id_pais, c.nombre
FROM @Ciudades c
JOIN mundial.pais p ON p.codigo_iso = c.iso
WHERE NOT EXISTS (SELECT 1 FROM mundial.ciudad cd WHERE cd.id_pais = p.id_pais AND cd.nombre = c.nombre);

/* 8 Estadios con diferentes husos horarios: America/New_York (UTC-5), America/Los_Angeles (UTC-8), America/Mexico_City (UTC-6) */
DECLARE @Estadios TABLE (ciudad VARCHAR(100), estadio VARCHAR(150), cap INT, tz VARCHAR(100), lat DECIMAL(9,6), lon DECIMAL(9,6));
INSERT INTO @Estadios VALUES
    ('East Rutherford', 'MetLife Stadium', 82500, 'America/New_York', 40.812800, -74.074200),
    ('Inglewood', 'SoFi Stadium', 70240, 'America/Los_Angeles', 33.953500, -118.339000),
    ('Atlanta', 'Mercedes-Benz Stadium', 71000, 'America/New_York', 33.755300, -84.400600),
    ('Miami', 'Hard Rock Stadium', 64767, 'America/New_York', 25.958000, -80.238900),
    ('Ciudad de Mexico', 'Estadio Azteca', 87523, 'America/Mexico_City', 19.302900, -99.150500),
    ('Guadalajara', 'Estadio Akron', 46355, 'America/Mexico_City', 20.681700, -103.462800),
    ('Toronto', 'BMO Field', 45000, 'America/Toronto', 43.633200, -79.418600),
    ('Vancouver', 'BC Place', 54500, 'America/Vancouver', 49.276800, -123.112000);

INSERT INTO mundial.sede_estadio (id_ciudad, nombre_estadio, capacidad, huso_horario, latitud, longitud)
SELECT c.id_ciudad, e.estadio, e.cap, e.tz, e.lat, e.lon
FROM @Estadios e
JOIN mundial.ciudad c ON c.nombre = e.ciudad
WHERE NOT EXISTS (SELECT 1 FROM mundial.sede_estadio se WHERE se.nombre_estadio = e.estadio);

/* 
   3. GRUPOS, FASES Y REGLAMENTO
*/

DECLARE @Grupos TABLE (nombre VARCHAR(50));
INSERT INTO @Grupos VALUES ('Grupo A'), ('Grupo B'), ('Grupo C'), ('Grupo D');

INSERT INTO mundial.grupo (nombre_grupo)
SELECT g.nombre FROM @Grupos g
WHERE NOT EXISTS (SELECT 1 FROM mundial.grupo WHERE nombre_grupo = g.nombre);

IF NOT EXISTS (SELECT 1 FROM mundial.reglamento_sustitucion WHERE nombre = 'Reglamento FIFA 2026')
    INSERT INTO mundial.reglamento_sustitucion (nombre, maximo_cambios, maximo_ventanas, cambios_adicionales_suplementario, ventanas_adicionales_suplementario, entretiempo_computa_ventana, intervalo_suplementario_computa_ventana, fecha_vigencia_desde, activo)
    VALUES ('Reglamento FIFA 2026', 5, 3, 1, 1, 0, 0, '2026-01-01', 1);

DECLARE @id_reg INT = (SELECT id_reglamento_sustitucion FROM mundial.reglamento_sustitucion WHERE nombre = 'Reglamento FIFA 2026');

DECLARE @Fases TABLE (nombre VARCHAR(50), orden TINYINT, alargue BIT, penales BIT);
INSERT INTO @Fases VALUES
    ('Fase de Grupos', 1, 0, 0),
    ('Octavos de Final', 2, 1, 1),
    ('Cuartos de Final', 3, 1, 1),
    ('Semifinal', 4, 1, 1),
    ('Tercer Puesto', 5, 1, 1),
    ('Final', 6, 1, 1);

INSERT INTO mundial.fase (id_reglamento_sustitucion, nombre_fase, orden, permite_alargue, permite_penales)
SELECT @id_reg, f.nombre, f.orden, f.alargue, f.penales
FROM @Fases f
WHERE NOT EXISTS (SELECT 1 FROM mundial.fase WHERE nombre_fase = f.nombre);

/* Asignar las 16 selecciones a sus grupos */
DECLARE @SelAsig TABLE (iso CHAR(3), grupo VARCHAR(50));
INSERT INTO @SelAsig VALUES
    ('ARG', 'Grupo A'), ('BRA', 'Grupo A'), ('URU', 'Grupo A'), ('COL', 'Grupo A'),
    ('FRA', 'Grupo B'), ('GER', 'Grupo B'), ('ESP', 'Grupo B'), ('ENG', 'Grupo B'),
    ('USA', 'Grupo C'), ('MEX', 'Grupo C'), ('CAN', 'Grupo C'), ('NED', 'Grupo C'),
    ('ITA', 'Grupo D'), ('POR', 'Grupo D'), ('CRO', 'Grupo D'), ('JPN', 'Grupo D');

INSERT INTO mundial.seleccion (id_pais, id_grupo)
SELECT p.id_pais, g.id_grupo
FROM @SelAsig sa
JOIN mundial.pais p ON p.codigo_iso = sa.iso
JOIN mundial.grupo g ON g.nombre_grupo = sa.grupo
WHERE NOT EXISTS (SELECT 1 FROM mundial.seleccion s WHERE s.id_pais = p.id_pais);

/* 
   4. POSICIONES Y CLUBES
*/

DECLARE @Pos TABLE (cod VARCHAR(10), descr VARCHAR(100), linea VARCHAR(30));
INSERT INTO @Pos VALUES
    ('POR', 'Portero', 'ARQUERO'),
    ('DEF', 'Defensor Central', 'DEFENSA'),
    ('LAT', 'Lateral', 'DEFENSA'),
    ('MED', 'Mediocampista', 'MEDIOCAMPO'),
    ('DEL', 'Delantero', 'DELANTERA');

INSERT INTO mundial.posicion (codigo, descripcion, linea_campo)
SELECT p.cod, p.descr, p.linea FROM @Pos p
WHERE NOT EXISTS (SELECT 1 FROM mundial.posicion WHERE codigo = p.cod);

/* Clubes */
DECLARE @Clubes TABLE (iso CHAR(3), nombre VARCHAR(150));
INSERT INTO @Clubes VALUES
    ('ARG', 'River Plate'), ('ARG', 'Boca Juniors'),
    ('BRA', 'Flamengo'), ('BRA', 'Palmeiras'),
    ('FRA', 'Paris Saint-Germain'),
    ('ESP', 'Real Madrid'), ('ESP', 'FC Barcelona'),
    ('ENG', 'Manchester City'), ('ENG', 'Liverpool FC'),
    ('GER', 'Bayern Munich'),
    ('USA', 'Inter Miami CF');

INSERT INTO mundial.club (id_pais, nombre_club)
SELECT p.id_pais, cl.nombre
FROM @Clubes cl
JOIN mundial.pais p ON p.codigo_iso = cl.iso
WHERE NOT EXISTS (SELECT 1 FROM mundial.club WHERE nombre_club = cl.nombre AND id_pais = p.id_pais);

/*
   5. PLANTILLAS Y JUGADORES (Al menos 23 convocados por cada una de las 16 selecciones = 368 jugadores)
*/

DECLARE @id_pos_por INT = (SELECT id_posicion FROM mundial.posicion WHERE codigo = 'POR');
DECLARE @id_pos_def INT = (SELECT id_posicion FROM mundial.posicion WHERE codigo = 'DEF');
DECLARE @id_pos_med INT = (SELECT id_posicion FROM mundial.posicion WHERE codigo = 'MED');
DECLARE @id_pos_del INT = (SELECT id_posicion FROM mundial.posicion WHERE codigo = 'DEL');
DECLARE @id_club_gen INT = (SELECT TOP 1 id_club FROM mundial.club);

;WITH CTE_Nums AS
(
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM CTE_Nums WHERE n < 23
),
CTE_PaisesSel AS
(
    SELECT s.id_seleccion, p.id_pais, p.codigo_iso, p.nombre AS pais_nombre
    FROM mundial.seleccion s
    JOIN mundial.pais p ON p.id_pais = s.id_pais
)
INSERT INTO mundial.jugador (id_pais_nacionalidad, id_club, id_posicion_habitual, nombres, apellidos, fecha_nacimiento, doc_identidad)
SELECT
    ps.id_pais,
    @id_club_gen,
    CASE
        WHEN n.n IN (1, 12, 23) THEN @id_pos_por
        WHEN n.n BETWEEN 2 AND 6 THEN @id_pos_def
        WHEN n.n BETWEEN 7 AND 14 THEN @id_pos_med
        ELSE @id_pos_del
    END,
    CONCAT(ps.codigo_iso, ' Nombre ', n.n),
    CONCAT(ps.codigo_iso, ' Apellido ', n.n),
    DATEADD(YEAR, -24 - (n.n % 10), '2026-01-01'),
    CONCAT('DOC_', ps.codigo_iso, '_', n.n)
FROM CTE_PaisesSel ps
CROSS JOIN CTE_Nums n
WHERE NOT EXISTS (SELECT 1 FROM mundial.jugador j WHERE j.doc_identidad = CONCAT('DOC_', ps.codigo_iso, '_', n.n))
OPTION (MAXRECURSION 100);

/* Convocatorias correspondientes */
INSERT INTO mundial.convocatoria (id_seleccion, id_jugador, dorsal, fecha_convocatoria, estado_convocatoria)
SELECT
    s.id_seleccion,
    j.id_jugador,
    CAST(SUBSTRING(j.doc_identidad, CHARINDEX('_', j.doc_identidad, 5) + 1, 2) AS TINYINT),
    '2026-05-15',
    'ACTIVA'
FROM mundial.jugador j
JOIN mundial.seleccion s ON s.id_pais = j.id_pais_nacionalidad
WHERE NOT EXISTS (
    SELECT 1 FROM mundial.convocatoria c
    WHERE c.id_seleccion = s.id_seleccion AND c.id_jugador = j.id_jugador
);

/* 
   6. ARBITROS (Al menos 15 arbitros con federaciones y nacionalidades)
*/

DECLARE @Arbs TABLE (iso CHAR(3), sigla_conf VARCHAR(10), nom VARCHAR(100), ape VARCHAR(100), nac DATE, cat VARCHAR(50));
INSERT INTO @Arbs VALUES
    ('ARG', 'CONMEBOL', 'Nestor', 'Pitana', '1975-06-17', 'FIFA Elite'),
    ('ARG', 'CONMEBOL', 'Facundo', 'Tello', '1982-05-04', 'FIFA Elite'),
    ('BRA', 'CONMEBOL', 'Wilton', 'Sampaio', '1981-12-28', 'FIFA Elite'),
    ('BRA', 'CONMEBOL', 'Raphael', 'Claus', '1979-09-06', 'FIFA Elite'),
    ('FRA', 'UEFA', 'Clement', 'Turpin', '1982-05-16', 'FIFA Elite'),
    ('FRA', 'UEFA', 'Stephanie', 'Frappart', '1983-12-14', 'FIFA Elite'),
    ('USA', 'CONCACAF', 'Ismail', 'Elfath', '1982-03-03', 'FIFA Elite'),
    ('USA', 'CONCACAF', 'Armando', 'Villarreal', '1986-05-31', 'FIFA Premier'),
    ('ENG', 'UEFA', 'Michael', 'Oliver', '1985-02-20', 'FIFA Elite'),
    ('ENG', 'UEFA', 'Anthony', 'Taylor', '1978-10-20', 'FIFA Elite'),
    ('GER', 'UEFA', 'Daniel', 'Siebert', '1984-05-04', 'FIFA Elite'),
    ('ESP', 'UEFA', 'Antonio', 'Mateu Lahoz', '1977-03-12', 'FIFA Elite'),
    ('ITA', 'UEFA', 'Daniele', 'Orsato', '1975-11-23', 'FIFA Elite'),
    ('MEX', 'CONCACAF', 'Cesar', 'Ramos', '1983-12-15', 'FIFA Elite'),
    ('JPN', 'AFC', 'Yoshimi', 'Yamashita', '1986-02-20', 'FIFA Elite'),
    ('CAN', 'CONCACAF', 'Drew', 'Fischer', '1980-07-10', 'FIFA Elite');

INSERT INTO mundial.arbitro (id_pais_nacionalidad, id_confederacion_afiliacion, nombres, apellidos, fecha_nacimiento, categoria)
SELECT p.id_pais, c.id_confederacion, a.nom, a.ape, a.nac, a.cat
FROM @Arbs a
JOIN mundial.pais p ON p.codigo_iso = a.iso
JOIN mundial.confederacion c ON c.sigla = a.sigla_conf
WHERE NOT EXISTS (
    SELECT 1 FROM mundial.arbitro ar
    WHERE ar.nombres = a.nom AND ar.apellidos = a.ape
);

/* Roles arbitrales */
DECLARE @RolesArb TABLE (descr VARCHAR(100));
INSERT INTO @RolesArb VALUES ('ARBITRO_PRINCIPAL'), ('ASISTENTE_1'), ('ASISTENTE_2'), ('CUARTO_ARBITRO'), ('VAR');

INSERT INTO mundial.rol_arbitral (descripcion)
SELECT r.descr FROM @RolesArb r
WHERE NOT EXISTS (SELECT 1 FROM mundial.rol_arbitral WHERE descripcion = r.descr);

/* 
   7. PARTIDOS (Al menos 24 partidos)
*/

DECLARE @id_fase_grupos INT = (SELECT id_fase FROM mundial.fase WHERE nombre_fase = 'Fase de Grupos');
DECLARE @id_fase_octavos INT = (SELECT id_fase FROM mundial.fase WHERE nombre_fase = 'Octavos de Final');
DECLARE @id_fase_cuartos INT = (SELECT id_fase FROM mundial.fase WHERE nombre_fase = 'Cuartos de Final');
DECLARE @id_fase_semi INT = (SELECT id_fase FROM mundial.fase WHERE nombre_fase = 'Semifinal');
DECLARE @id_fase_final INT = (SELECT id_fase FROM mundial.fase WHERE nombre_fase = 'Final');

DECLARE @id_s_metlife INT = (SELECT id_sede FROM mundial.sede_estadio WHERE nombre_estadio = 'MetLife Stadium');
DECLARE @id_s_sofi INT = (SELECT id_sede FROM mundial.sede_estadio WHERE nombre_estadio = 'SoFi Stadium');
DECLARE @id_s_azteca INT = (SELECT id_sede FROM mundial.sede_estadio WHERE nombre_estadio = 'Estadio Azteca');
DECLARE @id_s_akron INT = (SELECT id_sede FROM mundial.sede_estadio WHERE nombre_estadio = 'Estadio Akron');
DECLARE @id_s_atlanta INT = (SELECT id_sede FROM mundial.sede_estadio WHERE nombre_estadio = 'Mercedes-Benz Stadium');
DECLARE @id_s_miami INT = (SELECT id_sede FROM mundial.sede_estadio WHERE nombre_estadio = 'Hard Rock Stadium');
DECLARE @id_s_bmo INT = (SELECT id_sede FROM mundial.sede_estadio WHERE nombre_estadio = 'BMO Field');
DECLARE @id_s_bc INT = (SELECT id_sede FROM mundial.sede_estadio WHERE nombre_estadio = 'BC Place');

/* Funcion auxiliar de selecciones */
DECLARE @sel_ARG INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'ARG');
DECLARE @sel_BRA INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'BRA');
DECLARE @sel_URU INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'URU');
DECLARE @sel_COL INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'COL');
DECLARE @sel_FRA INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'FRA');
DECLARE @sel_GER INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'GER');
DECLARE @sel_ESP INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'ESP');
DECLARE @sel_ENG INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'ENG');
DECLARE @sel_USA INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'USA');
DECLARE @sel_MEX INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'MEX');
DECLARE @sel_CAN INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'CAN');
DECLARE @sel_NED INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'NED');
DECLARE @sel_ITA INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'ITA');
DECLARE @sel_POR INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'POR');
DECLARE @sel_CRO INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'CRO');
DECLARE @sel_JPN INT = (SELECT s.id_seleccion FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais = s.id_pais WHERE p.codigo_iso = 'JPN');

DECLARE @PartidosFixture TABLE
(
    num INT, id_fase INT, id_sede INT, loc INT, vis INT,
    utc DATETIME2(0), loc_dt DATETIME2(0),
    gl TINYINT, gv TINYINT, ast INT, est VARCHAR(20)
);

INSERT INTO @PartidosFixture VALUES
    /* 1 a 12: Grupos */
    (1,  @id_fase_grupos, @id_s_metlife, @sel_ARG, @sel_BRA, '2026-06-11T20:00:00', '2026-06-11T16:00:00', 2, 1, 82500, 'FINALIZADO'),
    (2,  @id_fase_grupos, @id_s_sofi,    @sel_URU, @sel_COL, '2026-06-11T23:00:00', '2026-06-11T16:00:00', 1, 1, 70000, 'FINALIZADO'),
    (3,  @id_fase_grupos, @id_s_azteca,  @sel_FRA, @sel_GER, '2026-06-12T19:00:00', '2026-06-12T13:00:00', 3, 2, 85000, 'FINALIZADO'),
    (4,  @id_fase_grupos, @id_s_akron,   @sel_ESP, @sel_ENG, '2026-06-12T22:00:00', '2026-06-12T16:00:00', 0, 1, 45000, 'FINALIZADO'),
    (5,  @id_fase_grupos, @id_s_atlanta, @sel_USA, @sel_MEX, '2026-06-13T18:00:00', '2026-06-13T14:00:00', 2, 2, 68000, 'FINALIZADO'),
    (6,  @id_fase_grupos, @id_s_miami,   @sel_CAN, @sel_NED, '2026-06-13T21:00:00', '2026-06-13T17:00:00', 0, 2, 62000, 'FINALIZADO'),
    (7,  @id_fase_grupos, @id_s_bmo,     @sel_ITA, @sel_POR, '2026-06-14T17:00:00', '2026-06-14T13:00:00', 1, 0, 44000, 'FINALIZADO'),
    (8,  @id_fase_grupos, @id_s_bc,      @sel_CRO, @sel_JPN, '2026-06-14T20:00:00', '2026-06-14T13:00:00', 2, 3, 52000, 'FINALIZADO'),
    (9,  @id_fase_grupos, @id_s_metlife, @sel_ARG, @sel_URU, '2026-06-17T20:00:00', '2026-06-17T16:00:00', 1, 0, 81000, 'FINALIZADO'),
    (10, @id_fase_grupos, @id_s_sofi,    @sel_BRA, @sel_COL, '2026-06-17T23:00:00', '2026-06-17T16:00:00', 2, 0, 69000, 'FINALIZADO'),
    (11, @id_fase_grupos, @id_s_azteca,  @sel_FRA, @sel_ESP, '2026-06-18T19:00:00', '2026-06-18T13:00:00', 1, 1, 84000, 'FINALIZADO'),
    (12, @id_fase_grupos, @id_s_akron,   @sel_GER, @sel_ENG, '2026-06-18T22:00:00', '2026-06-18T16:00:00', 0, 0, 46000, 'FINALIZADO'),
    /* 13 a 18: Octavos */
    (13, @id_fase_octavos, @id_s_atlanta, @sel_ARG, @sel_ENG, '2026-06-23T18:00:00', '2026-06-23T14:00:00', 2, 1, 70000, 'FINALIZADO'),
    (14, @id_fase_octavos, @id_s_miami,   @sel_BRA, @sel_FRA, '2026-06-23T21:00:00', '2026-06-23T17:00:00', 1, 2, 64000, 'FINALIZADO'),
    (15, @id_fase_octavos, @id_s_bmo,     @sel_USA, @sel_ITA, '2026-06-24T17:00:00', '2026-06-24T13:00:00', 1, 0, 45000, 'FINALIZADO'),
    (16, @id_fase_octavos, @id_s_bc,      @sel_NED, @sel_JPN, '2026-06-24T20:00:00', '2026-06-24T13:00:00', 3, 1, 53000, 'FINALIZADO'),
    (17, @id_fase_octavos, @id_s_metlife, @sel_GER, @sel_COL, '2026-06-25T18:00:00', '2026-06-25T14:00:00', 2, 0, 80000, 'FINALIZADO'),
    (18, @id_fase_octavos, @id_s_sofi,    @sel_ESP, @sel_POR, '2026-06-25T21:00:00', '2026-06-25T14:00:00', 1, 2, 70000, 'FINALIZADO'),
    /* 19 a 22: Cuartos */
    (19, @id_fase_cuartos, @id_s_azteca,  @sel_ARG, @sel_FRA, '2026-06-29T19:00:00', '2026-06-29T13:00:00', 3, 2, 86000, 'FINALIZADO'),
    (20, @id_fase_cuartos, @id_s_akron,   @sel_USA, @sel_NED, '2026-06-29T22:00:00', '2026-06-29T16:00:00', 0, 1, 46000, 'FINALIZADO'),
    (21, @id_fase_cuartos, @id_s_atlanta, @sel_GER, @sel_POR, '2026-06-30T18:00:00', '2026-06-30T14:00:00', 1, 2, 71000, 'FINALIZADO'),
    (22, @id_fase_cuartos, @id_s_miami,   @sel_BRA, @sel_ITA, '2026-06-30T21:00:00', '2026-06-30T17:00:00', 2, 1, 63000, 'FINALIZADO'),
    /* 23 y 24: Semifinal y Final */
    (23, @id_fase_semi,    @id_s_sofi,    @sel_ARG, @sel_NED, '2026-07-04T20:00:00', '2026-07-04T13:00:00', 2, 0, 70000, 'FINALIZADO'),
    (24, @id_fase_final,   @id_s_metlife, @sel_ARG, @sel_POR, '2026-07-11T20:00:00', '2026-07-11T16:00:00', 3, 1, 82500, 'FINALIZADO');

INSERT INTO mundial.partido
(
    id_fase, id_sede, id_seleccion_local, id_seleccion_visitante,
    fecha_hora_utc, fecha_hora_local, goles_local, goles_visitante, penales_local, penales_visitante, asistencia_publico, estado_partido
)
SELECT
    pf.id_fase, pf.id_sede, pf.loc, pf.vis, pf.utc, pf.loc_dt, pf.gl, pf.gv, NULL, NULL, pf.ast, pf.est
FROM @PartidosFixture pf
WHERE NOT EXISTS (
    SELECT 1 FROM mundial.partido p
    WHERE p.fecha_hora_utc = pf.utc AND p.id_seleccion_local = pf.loc AND p.id_seleccion_visitante = pf.vis
);

/* Detalle equipo para los 24 partidos */
INSERT INTO mundial.partido_equipo_detalle (id_partido, id_seleccion, condicion, esquema_tactico)
SELECT p.id_partido, p.id_seleccion_local, 'LOCAL', '4-3-3'
FROM mundial.partido p
WHERE NOT EXISTS (
    SELECT 1 FROM mundial.partido_equipo_detalle ped
    WHERE ped.id_partido = p.id_partido AND ped.condicion = 'LOCAL'
);

INSERT INTO mundial.partido_equipo_detalle (id_partido, id_seleccion, condicion, esquema_tactico)
SELECT p.id_partido, p.id_seleccion_visitante, 'VISITANTE', '4-4-2'
FROM mundial.partido p
WHERE NOT EXISTS (
    SELECT 1 FROM mundial.partido_equipo_detalle ped
    WHERE ped.id_partido = p.id_partido AND ped.condicion = 'VISITANTE'
);

/* Alineaciones para los 24 partidos (11 titulares y 12 suplentes por equipo) */
INSERT INTO mundial.alineacion_partido (id_partido_equipo, id_jugador, id_posicion_campo, dorsal, es_titular, minuto_ingreso, minuto_salida)
SELECT
    ped.id_partido_equipo,
    c.id_jugador,
    j.id_posicion_habitual,
    c.dorsal,
    CASE WHEN c.dorsal <= 11 THEN 1 ELSE 0 END,
    CASE WHEN c.dorsal <= 11 THEN 0 ELSE NULL END,
    NULL
FROM mundial.partido_equipo_detalle ped
JOIN mundial.convocatoria c ON c.id_seleccion = ped.id_seleccion
JOIN mundial.jugador j ON j.id_jugador = c.id_jugador
WHERE NOT EXISTS (
    SELECT 1 FROM mundial.alineacion_partido ap
    WHERE ap.id_partido_equipo = ped.id_partido_equipo AND ap.id_jugador = c.id_jugador
);

/* 
   8. DESIGNACIONES ARBITRALES COMPLETAS (Para los 24 partidos)
   Garantiza no-conflicto de nacionalidad y 5 arbitros distintos por partido
*/

DECLARE @rol_prin INT = (SELECT id_rol_arbitral FROM mundial.rol_arbitral WHERE descripcion = 'ARBITRO_PRINCIPAL');
DECLARE @rol_as1 INT = (SELECT id_rol_arbitral FROM mundial.rol_arbitral WHERE descripcion = 'ASISTENTE_1');
DECLARE @rol_as2 INT = (SELECT id_rol_arbitral FROM mundial.rol_arbitral WHERE descripcion = 'ASISTENTE_2');
DECLARE @rol_4to INT = (SELECT id_rol_arbitral FROM mundial.rol_arbitral WHERE descripcion = 'CUARTO_ARBITRO');
DECLARE @rol_var INT = (SELECT id_rol_arbitral FROM mundial.rol_arbitral WHERE descripcion = 'VAR');

;WITH ArbitrosValidosPorPartido AS
(
    SELECT
        p.id_partido,
        a.id_arbitro,
        ROW_NUMBER() OVER (
            PARTITION BY p.id_partido
            ORDER BY ((p.id_partido * 13 + a.id_arbitro * 7) % 101)
        ) AS rn_arb
    FROM mundial.partido p
    JOIN mundial.seleccion sl ON sl.id_seleccion = p.id_seleccion_local
    JOIN mundial.seleccion sv ON sv.id_seleccion = p.id_seleccion_visitante
    JOIN mundial.arbitro a
        ON a.id_pais_nacionalidad <> sl.id_pais
       AND a.id_pais_nacionalidad <> sv.id_pais
),
RolesPorOffset AS
(
    SELECT offset_rol, id_rol
    FROM (
        VALUES
        (1, @rol_prin),
        (2, @rol_as1),
        (3, @rol_as2),
        (4, @rol_4to),
        (5, @rol_var)
    ) r(offset_rol, id_rol)
)
INSERT INTO mundial.designacion_arbitral (id_partido, id_arbitro, id_rol_arbitral)
SELECT av.id_partido, av.id_arbitro, ro.id_rol
FROM ArbitrosValidosPorPartido av
JOIN RolesPorOffset ro ON ro.offset_rol = av.rn_arb
WHERE av.rn_arb <= 5
  AND NOT EXISTS (
      SELECT 1 FROM mundial.designacion_arbitral da
      WHERE da.id_partido = av.id_partido AND da.id_rol_arbitral = ro.id_rol
  );

/* 
   9. ANUNCIANTES, ESPACIOS Y PAUTAS PUBLICITARIAS (6 paises, 4 espacios)
*/

/* Espacios publicitarios (4 por sede) */
INSERT INTO mundial.espacio_publicitario (id_sede, numero_espacio)
SELECT s.id_sede, n.num
FROM mundial.sede_estadio s
CROSS JOIN (VALUES (1), (2), (3), (4)) n(num)
WHERE NOT EXISTS (
    SELECT 1 FROM mundial.espacio_publicitario ep
    WHERE ep.id_sede = s.id_sede AND ep.numero_espacio = n.num
);

/* Anunciantes de al menos 6 paises distintos */
DECLARE @Anunciantes TABLE (iso CHAR(3), razon VARCHAR(200), tax VARCHAR(50), email VARCHAR(254));
INSERT INTO @Anunciantes VALUES
    ('USA', 'Global Tech Corp', 'TAX_USA_001', 'ads@globaltech.com'),
    ('GER', 'Automobile Deutchland AG', 'TAX_GER_001', 'marketing@autode.de'),
    ('JPN', 'Nippon Electronics Ltd', 'TAX_JPN_001', 'sponsor@nipponel.jp'),
    ('ARG', 'Mercado Pampeano SA', 'TAX_ARG_001', 'comercial@mercadopampeano.com.ar'),
    ('BRA', 'Banco Central de Negocios SA', 'TAX_BRA_001', 'pauta@bancobrasilneg.br'),
    ('FRA', 'Mode et Luxe Paris', 'TAX_FRA_001', 'contact@modeluxe.fr');

INSERT INTO mundial.anunciante (id_pais_origen, razon_social, identificador_fiscal, email_contacto)
SELECT p.id_pais, a.razon, a.tax, a.email
FROM @Anunciantes a
JOIN mundial.pais p ON p.codigo_iso = a.iso
WHERE NOT EXISTS (SELECT 1 FROM mundial.anunciante WHERE identificador_fiscal = a.tax);

/* Campanias y piezas */
INSERT INTO mundial.campania (id_anunciante, nombre_campania, fecha_inicio, fecha_fin, presupuesto_total)
SELECT a.id_anunciante, CONCAT('Campania Mundial 2026 - ', a.razon_social), '2026-06-01', '2026-07-31', 5000000.00
FROM mundial.anunciante a
WHERE NOT EXISTS (
    SELECT 1 FROM mundial.campania c WHERE c.id_anunciante = a.id_anunciante
);

/* Idioma espanol e ingles por defecto para piezas */
IF NOT EXISTS (SELECT 1 FROM mundial.idioma WHERE codigo_iso = 'es-ES')
    INSERT INTO mundial.idioma (nombre_idioma, codigo_iso) VALUES ('Espanol', 'es-ES');
IF NOT EXISTS (SELECT 1 FROM mundial.idioma WHERE codigo_iso = 'en-US')
    INSERT INTO mundial.idioma (nombre_idioma, codigo_iso) VALUES ('Ingles', 'en-US');

DECLARE @id_idioma_es INT = (SELECT id_idioma FROM mundial.idioma WHERE codigo_iso = 'es-ES');

INSERT INTO mundial.pieza_publicitaria (id_campania, id_idioma, titulo, formato, duracion_segundos)
SELECT c.id_campania, @id_idioma_es, CONCAT('Spot LED ', c.id_campania), 'PANEL_ROTATIVO', 30
FROM mundial.campania c
WHERE NOT EXISTS (
    SELECT 1 FROM mundial.pieza_publicitaria p WHERE p.id_campania = c.id_campania
);

/* Asignar pauta en los 4 espacios para cada partido */
DECLARE @id_moneda_usd INT = (SELECT id_moneda FROM mundial.moneda WHERE codigo_iso = 'USD');

;WITH PartidosConSede AS
(
    SELECT p.id_partido, p.id_sede
    FROM mundial.partido p
),
PiezasDisponibles AS
(
    SELECT id_pieza, ROW_NUMBER() OVER(ORDER BY id_pieza) AS rn_pz
    FROM mundial.pieza_publicitaria
)
INSERT INTO mundial.pauta_partido
(
    id_partido, id_espacio, id_pieza, id_moneda, tarifa_base_usd, tipo_cambio_aplicado, tarifa_final, es_prime_time, estado_pauta, estado_facturacion
)
SELECT
    ps.id_partido,
    ep.id_espacio,
    pz.id_pieza,
    @id_moneda_usd,
    75000.00,
    1.000000,
    75000.00,
    CASE WHEN ep.numero_espacio = 1 THEN 1 ELSE 0 END,
    'EXHIBIDA',
    'FACTURADA'
FROM PartidosConSede ps
JOIN mundial.espacio_publicitario ep ON ep.id_sede = ps.id_sede
JOIN PiezasDisponibles pz ON pz.rn_pz = ((ps.id_partido + ep.numero_espacio) % (SELECT COUNT(*) FROM PiezasDisponibles)) + 1
WHERE NOT EXISTS (
    SELECT 1 FROM mundial.pauta_partido pp
    WHERE pp.id_partido = ps.id_partido AND pp.id_espacio = ep.id_espacio
);

/* 
   10. CASOS OBLIGATORIOS
*/

/* Tipos de gol y tipos de tarjeta */
IF NOT EXISTS (SELECT 1 FROM mundial.tipo_gol WHERE descripcion = 'JUGADA')
    INSERT INTO mundial.tipo_gol (descripcion) VALUES ('JUGADA');
IF NOT EXISTS (SELECT 1 FROM mundial.tipo_gol WHERE descripcion = 'PENAL')
    INSERT INTO mundial.tipo_gol (descripcion) VALUES ('PENAL');
IF NOT EXISTS (SELECT 1 FROM mundial.tipo_gol WHERE descripcion = 'TIRO_LIBRE')
    INSERT INTO mundial.tipo_gol (descripcion) VALUES ('TIRO_LIBRE');

DECLARE @id_tg_jugada INT = (SELECT id_tipo_gol FROM mundial.tipo_gol WHERE descripcion = 'JUGADA');

IF NOT EXISTS (SELECT 1 FROM mundial.tipo_tarjeta WHERE descripcion = 'AMARILLA')
    INSERT INTO mundial.tipo_tarjeta (descripcion) VALUES ('AMARILLA');
IF NOT EXISTS (SELECT 1 FROM mundial.tipo_tarjeta WHERE descripcion = 'ROJA')
    INSERT INTO mundial.tipo_tarjeta (descripcion) VALUES ('ROJA');

DECLARE @id_tt_amarilla INT = (SELECT id_tipo_tarjeta FROM mundial.tipo_tarjeta WHERE descripcion = 'AMARILLA');
DECLARE @id_tt_roja INT = (SELECT id_tipo_tarjeta FROM mundial.tipo_tarjeta WHERE descripcion = 'ROJA');

/* --- CASO 1: Un partido con doble amarilla y otro con roja directa --- */
DECLARE @p1 INT = (SELECT TOP 1 id_partido FROM mundial.partido ORDER BY id_partido);
DECLARE @p2 INT = (SELECT TOP 1 id_partido FROM mundial.partido WHERE id_partido > @p1 ORDER BY id_partido);

DECLARE @ped1_loc INT = (SELECT id_partido_equipo FROM mundial.partido_equipo_detalle WHERE id_partido = @p1 AND condicion = 'LOCAL');
DECLARE @jug_exp1 INT = (SELECT TOP 1 id_jugador FROM mundial.alineacion_partido WHERE id_partido_equipo = @ped1_loc AND dorsal = 4);
DECLARE @sel1_loc INT = (SELECT id_seleccion FROM mundial.partido_equipo_detalle WHERE id_partido_equipo = @ped1_loc);

/* Doble amarilla en partido 1 */
IF NOT EXISTS (SELECT 1 FROM mundial.tarjeta WHERE id_partido = @p1 AND id_jugador = @jug_exp1)
BEGIN
    INSERT INTO mundial.tarjeta (id_partido, id_seleccion, id_jugador, id_tipo_tarjeta, minuto, minuto_adicional, periodo, motivo, tipo_expulsion)
    VALUES (@p1, @sel1_loc, @jug_exp1, @id_tt_amarilla, 35, 0, 'PRIMER_TIEMPO', 'Falta reiterada', NULL);

    INSERT INTO mundial.tarjeta (id_partido, id_seleccion, id_jugador, id_tipo_tarjeta, minuto, minuto_adicional, periodo, motivo, tipo_expulsion)
    VALUES (@p1, @sel1_loc, @jug_exp1, @id_tt_roja, 72, 0, 'SEGUNDO_TIEMPO', 'Segunda amonestacion por juego brusco', 'DOBLE_AMARILLA');
END;

/* Roja directa en partido 2 */
DECLARE @ped2_vis INT = (SELECT id_partido_equipo FROM mundial.partido_equipo_detalle WHERE id_partido = @p2 AND condicion = 'VISITANTE');
DECLARE @jug_exp2 INT = (SELECT TOP 1 id_jugador FROM mundial.alineacion_partido WHERE id_partido_equipo = @ped2_vis AND dorsal = 2);
DECLARE @sel2_vis INT = (SELECT id_seleccion FROM mundial.partido_equipo_detalle WHERE id_partido_equipo = @ped2_vis);

IF NOT EXISTS (SELECT 1 FROM mundial.tarjeta WHERE id_partido = @p2 AND id_jugador = @jug_exp2)
BEGIN
    INSERT INTO mundial.tarjeta (id_partido, id_seleccion, id_jugador, id_tipo_tarjeta, minuto, minuto_adicional, periodo, motivo, tipo_expulsion)
    VALUES (@p2, @sel2_vis, @jug_exp2, @id_tt_roja, 55, 0, 'SEGUNDO_TIEMPO', 'Conducta violenta con balon detenido', 'ROJA_DIRECTA');
END;

/* --- CASO 2: Jugador suspendido por acumulacion de amarillas, excluido de titular en el siguiente partido --- */
/* Tomamos al jugador con dorsal 5 de Argentina en Partido 1 y Partido 9 */
DECLARE @p_arg1 INT = (SELECT TOP 1 id_partido FROM mundial.partido WHERE id_seleccion_local = @sel_ARG OR id_seleccion_visitante = @sel_ARG ORDER BY id_partido);
DECLARE @p_arg2 INT = (SELECT TOP 1 id_partido FROM mundial.partido WHERE (id_seleccion_local = @sel_ARG OR id_seleccion_visitante = @sel_ARG) AND id_partido > @p_arg1 ORDER BY id_partido);
DECLARE @p_arg3 INT = (SELECT TOP 1 id_partido FROM mundial.partido WHERE (id_seleccion_local = @sel_ARG OR id_seleccion_visitante = @sel_ARG) AND id_partido > @p_arg2 ORDER BY id_partido);

DECLARE @jug_susp INT = (SELECT c.id_jugador FROM mundial.convocatoria c WHERE c.id_seleccion = @sel_ARG AND c.dorsal = 5);

IF NOT EXISTS (SELECT 1 FROM mundial.criterio_suspension WHERE tipo_infraccion = 'ACUMULACION_AMARILLAS')
    INSERT INTO mundial.criterio_suspension (id_fase, cantidad_amarillas, tipo_infraccion, partidos_suspension, vigencia_desde)
    VALUES (@id_fase_grupos, 2, 'ACUMULACION_AMARILLAS', 1, '2026-01-01');

DECLARE @id_criterio_susp INT = (SELECT id_criterio FROM mundial.criterio_suspension WHERE tipo_infraccion = 'ACUMULACION_AMARILLAS');

/* Tarjeta en Partido 1 */
IF NOT EXISTS (SELECT 1 FROM mundial.tarjeta WHERE id_partido = @p_arg1 AND id_jugador = @jug_susp)
    INSERT INTO mundial.tarjeta (id_partido, id_seleccion, id_jugador, id_tipo_tarjeta, minuto, minuto_adicional, periodo, motivo, tipo_expulsion)
    VALUES (@p_arg1, @sel_ARG, @jug_susp, @id_tt_amarilla, 28, 0, 'PRIMER_TIEMPO', 'Falta tactica', NULL);

/* Tarjeta en Partido 2 (acumula 2) */
IF NOT EXISTS (SELECT 1 FROM mundial.tarjeta WHERE id_partido = @p_arg2 AND id_jugador = @jug_susp)
    INSERT INTO mundial.tarjeta (id_partido, id_seleccion, id_jugador, id_tipo_tarjeta, minuto, minuto_adicional, periodo, motivo, tipo_expulsion)
    VALUES (@p_arg2, @sel_ARG, @jug_susp, @id_tt_amarilla, 80, 0, 'SEGUNDO_TIEMPO', 'Mano deliberada', NULL);

/* Registro formal de la suspension */
IF NOT EXISTS (SELECT 1 FROM mundial.suspension_jugador WHERE id_jugador = @jug_susp AND id_partido_origen = @p_arg2)
BEGIN
    INSERT INTO mundial.suspension_jugador (id_criterio, id_jugador, id_partido_origen, motivo, partidos_sancion, partidos_cumplidos, cumplida)
    VALUES (@id_criterio_susp, @jug_susp, @p_arg2, 'Suspension por acumulacion de 2 tarjetas amarillas', 1, 0, 0);
END;

/* En el siguiente partido (@p_arg3), el jugador suspendido NO es titular */
DECLARE @ped_arg3 INT = (SELECT id_partido_equipo FROM mundial.partido_equipo_detalle WHERE id_partido = @p_arg3 AND id_seleccion = @sel_ARG);
UPDATE mundial.alineacion_partido
SET es_titular = 0, minuto_ingreso = NULL
WHERE id_partido_equipo = @ped_arg3 AND id_jugador = @jug_susp;

/* --- CASO 3: Un cambio por lesion antes del minuto 20 --- */
DECLARE @ped_lesion INT = (SELECT id_partido_equipo FROM mundial.partido_equipo_detalle WHERE id_partido = @p1 AND condicion = 'LOCAL');
DECLARE @jug_sale INT = (SELECT TOP 1 id_jugador FROM mundial.alineacion_partido WHERE id_partido_equipo = @ped_lesion AND es_titular = 1 AND dorsal = 9);
DECLARE @jug_entra INT = (SELECT TOP 1 id_jugador FROM mundial.alineacion_partido WHERE id_partido_equipo = @ped_lesion AND es_titular = 0 AND dorsal = 18);

IF NOT EXISTS (SELECT 1 FROM mundial.sustitucion WHERE id_partido_equipo = @ped_lesion AND id_jugador_sale = @jug_sale)
BEGIN
    INSERT INTO mundial.sustitucion
    (
        id_partido_equipo, id_jugador_sale, id_jugador_entra, minuto, minuto_adicional,
        periodo, numero_ventana, motivo
    )
    VALUES
    (
        @ped_lesion, @jug_sale, @jug_entra, 14, 0, 'PRIMER_TIEMPO', 1, 'LESION'
    );

    UPDATE mundial.alineacion_partido SET minuto_salida = 14 WHERE id_partido_equipo = @ped_lesion AND id_jugador = @jug_sale;
    UPDATE mundial.alineacion_partido SET minuto_ingreso = 14 WHERE id_partido_equipo = @ped_lesion AND id_jugador = @jug_entra;
END;

/* Goles representativos para que la tabla de goleadores tenga datos ricos */
DECLARE @jug_gol1 INT = (SELECT c.id_jugador FROM mundial.convocatoria c WHERE c.id_seleccion = @sel_ARG AND c.dorsal = 10);
DECLARE @jug_gol2 INT = (SELECT c.id_jugador FROM mundial.convocatoria c WHERE c.id_seleccion = @sel_FRA AND c.dorsal = 10);
DECLARE @jug_gol3 INT = (SELECT c.id_jugador FROM mundial.convocatoria c WHERE c.id_seleccion = @sel_POR AND c.dorsal = 7);

IF NOT EXISTS (SELECT 1 FROM mundial.gol WHERE id_jugador_autor = @jug_gol1)
BEGIN
    INSERT INTO mundial.gol (id_partido, id_seleccion_beneficiada, id_jugador_autor, id_jugador_asistente, id_tipo_gol, minuto, periodo)
    VALUES
        (@p1, @sel_ARG, @jug_gol1, NULL, @id_tg_jugada, 25, 'PRIMER_TIEMPO'),
        (@p1, @sel_ARG, @jug_gol1, NULL, @id_tg_jugada, 88, 'SEGUNDO_TIEMPO'),
        (13, @sel_ARG, @jug_gol1, NULL, @id_tg_jugada, 60, 'SEGUNDO_TIEMPO'),
        (24, @sel_ARG, @jug_gol1, NULL, @id_tg_jugada, 30, 'PRIMER_TIEMPO'),
        (24, @sel_ARG, @jug_gol1, NULL, @id_tg_jugada, 75, 'SEGUNDO_TIEMPO');
END;

IF NOT EXISTS (SELECT 1 FROM mundial.gol WHERE id_jugador_autor = @jug_gol2)
BEGIN
    INSERT INTO mundial.gol (id_partido, id_seleccion_beneficiada, id_jugador_autor, id_jugador_asistente, id_tipo_gol, minuto, periodo)
    VALUES
        (3, @sel_FRA, @jug_gol2, NULL, @id_tg_jugada, 12, 'PRIMER_TIEMPO'),
        (3, @sel_FRA, @jug_gol2, NULL, @id_tg_jugada, 45, 'PRIMER_TIEMPO'),
        (14, @sel_FRA, @jug_gol2, NULL, @id_tg_jugada, 70, 'SEGUNDO_TIEMPO'),
        (19, @sel_FRA, @jug_gol2, NULL, @id_tg_jugada, 81, 'SEGUNDO_TIEMPO');
END;

PRINT N'OK: Carga deterministica de seed y 6 casos obligatorios completada con exito.';
GO
