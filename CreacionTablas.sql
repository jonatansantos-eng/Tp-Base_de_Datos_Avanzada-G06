--TABLAS

CREATE TABLE mundial.confederacion(
	id_confederacion INT PRIMARY KEY,
	nombre VARCHAR(20),
	sigla VARCHAR(20)
)
GO

CREATE TABLE mundial.pais(
	id_pais INT IDENTITY(1,1) PRIMARY KEY,
	id_confederacion INT REFERENCES mundial.confederacion(id_confederacion),
	nombre VARCHAR(20),
	codigo_iso VARCHAR(20),
	huso_horario_estandar VARCHAR(10),
	huso_horario_minutos_utc SMALLINT NULL,
	pbi_per_capita DECIMAL(10,2),
	codigo_moneda VARCHAR (10)
)
GO
select * from mundial.pais

CREATE TABLE mundial.grupo(
	id_grupo INT IDENTITY(1,1) PRIMARY KEY,
	nombre_grupo VARCHAR(20)
)
GO

CREATE TABLE mundial.seleccion(
	id_seleccion INT IDENTITY(1,1) PRIMARY KEY,  --id_confederacion eliminado
	id_pais INT REFERENCES mundial.pais(id_pais),
	id_grupo INT REFERENCES mundial.grupo(id_grupo)
)
GO

CREATE TABLE mundial.club(
	id_club INT IDENTITY(1,1) PRIMARY KEY,
	id_pais INT REFERENCES mundial.pais(id_pais),
	nombre_club VARCHAR(20)
)
GO

CREATE TABLE mundial.rol_cuerpo_tecnico(
	id_rol_ct INT IDENTITY(1,1) PRIMARY KEY,
	descripcion VARCHAR(20)
)
GO

CREATE TABLE mundial.cuerpo_tecnico(
	id_miembro_ct INT IDENTITY(1,1) PRIMARY KEY,
	id_seleccion INT REFERENCES mundial.seleccion(id_seleccion),
	id_pais_nacionalidad INT REFERENCES mundial.pais(id_pais),
	id_rol_ct INT REFERENCES mundial.rol_cuerpo_tecnico(id_rol_ct),
	nombres VARCHAR(20),
	apellidos VARCHAR(20)
)
GO

CREATE TABLE mundial.ciudad(
	id_ciudad INT IDENTITY(1,1) PRIMARY KEY,
	id_pais INT REFERENCES mundial.pais(id_pais),
	nombre VARCHAR(20)
)
GO

CREATE TABLE mundial.anunciante(
	id_anunciante INT IDENTITY(1,1) PRIMARY KEY,
	id_pais_origen INT REFERENCES mundial.pais(id_pais),
	razon_social VARCHAR(20),
	identificador_fiscal VARCHAR(20),
	email_contacto VARCHAR(50)
)
GO

CREATE TABLE mundial.arbitro(
	id_arbitro INT IDENTITY(1,1) PRIMARY KEY,
	id_pais_nacionalidad INT REFERENCES mundial.pais(id_pais),
	id_confederacion INT REFERENCES mundial.confederacion(id_confederacion),
	nombres VARCHAR(20) NOT NULL,
	apellidos VARCHAR(20) NOT NULL,
	fecha_nacimiento DATE NOT NULL,
	categoria VARCHAR(20)
)
GO

CREATE TABLE mundial.idioma(
	id_idioma INT IDENTITY(1,1) PRIMARY KEY,
	nombre_idioma VARCHAR(20),
	codigo_iso VARCHAR(20)
)
GO

CREATE TABLE mundial.arbitro_idioma(
	id_arbitro INT NOT NULL REFERENCES mundial.arbitro(id_arbitro),
    id_idioma INT NOT NULL REFERENCES mundial.idioma(id_idioma),
	CONSTRAINT PK_arbitro_idioma PRIMARY KEY (id_arbitro,id_idioma)
)
GO

CREATE TABLE mundial.posicion(
	id_posicion INT IDENTITY(1,1) PRIMARY KEY,
	codigo VARCHAR(20),
	descripcion VARCHAR(20),
	linea_campo VARCHAR(20)
)
GO

CREATE TABLE mundial.jugador(
	id_jugador INT IDENTITY(1,1) PRIMARY KEY,
	id_pais_nacionalidad INT REFERENCES mundial.pais(id_pais),
	id_club INT REFERENCES mundial.club(id_club),
	id_posicion_habitual INT REFERENCES mundial.posicion(id_posicion),
	nombres VARCHAR(20) NOT NULL,
	apellidos VARCHAR(20) NOT NULL,
	fecha_nacimiento DATE NOT NULL,
	doc_identidad VARCHAR(20) NOT NULL
)
GO

CREATE TABLE mundial.fase(
	id_fase INT IDENTITY(1,1) PRIMARY KEY,
	nombre_fase VARCHAR(20),
	orden INT,
	permite_alargue BIT,
	permite_penales BIT
)
GO

CREATE TABLE mundial.sede_estadio(
	id_sede INT IDENTITY(1,1) PRIMARY KEY,
	id_ciudad INT REFERENCES mundial.ciudad(id_ciudad),
	nombre_estadio VARCHAR(20),
	capacidad INT,
	huso_horario VARCHAR(10),
	latitud DECIMAL(10,2),
	longitud DECIMAL(10,2)
)
GO

CREATE TABLE mundial.campania(
	id_campania INT IDENTITY(1,1) PRIMARY KEY,
	id_anunciante INT REFERENCES mundial.anunciante(id_anunciante),
	nombre_campania VARCHAR(20),
	fecha_inicio DATE,
	fecha_fin DATE CHECK(fecha_fin >= fecha_inicio),
	presupuesto_total DECIMAL(10,2) CHECK(presupuesto_total>=0)
)
GO

CREATE TABLE mundial.partido(
	id_partido INT IDENTITY(1,1) PRIMARY KEY,
	id_fase INT REFERENCES mundial.fase(id_fase),
	id_sede INT REFERENCES mundial.sede_estadio(id_sede),
	id_seleccion_local INT REFERENCES mundial.seleccion(id_seleccion),
	id_seleccion_visitante INT REFERENCES mundial.seleccion(id_seleccion),
	fecha_hora_utc DATETIME,
	fecha_hora_local DATETIME,
	goles_local INT,
	goles_visitante INT,
	penales_local INT,
	penales_visitante INT,
	asistencia_publico INT,
	estado_partido VARCHAR(20)
)
GO

CREATE TABLE mundial.pieza_publicitaria(
	id_pieza INT IDENTITY(1,1) PRIMARY KEY,
	id_campania INT REFERENCES mundial.campania(id_campania),
	titulo VARCHAR(20),
	idioma VARCHAR(20),
	formato VARCHAR(20),
	duracion_segundos INT
)
GO

CREATE TABLE mundial.pieza_pais_objetivo(
	id_pieza INT NOT NULL REFERENCES mundial.pieza_publicitaria(id_pieza),
    id_pais INT NOT NULL REFERENCES mundial.pais(id_pais),
	CONSTRAINT PK_pieza_pais_objetivo PRIMARY KEY (id_pieza,id_pais)
)
GO

CREATE TABLE mundial.espacio_publicitario(
	id_espacio INT IDENTITY(1,1) PRIMARY KEY,
	id_sede INT NOT NULL REFERENCES mundial.sede_estadio(id_sede),
	numero_espacio INT NOT NULL,
	CONSTRAINT UQ_espacio_sede_numero UNIQUE (id_sede, numero_espacio)
)
GO

CREATE TABLE mundial.convocatoria(
	id_convocatoria INT IDENTITY(1,1) PRIMARY KEY,
	id_seleccion INT REFERENCES mundial.seleccion(id_seleccion),
	id_jugador INT REFERENCES mundial.jugador(id_jugador),
	dorsal INT,
	fecha_convocatoria DATE,
	estado_convocatoria VARCHAR(20)
)
GO

CREATE TABLE mundial.novedad_convocatoria(
	id_novedad INT IDENTITY(1,1) PRIMARY KEY,
	id_convocatoria_baja INT REFERENCES mundial.convocatoria(id_convocatoria),
	id_convocatoria_alta INT REFERENCES mundial.convocatoria(id_convocatoria),
	motivo VARCHAR(50),
	fecha_cambio DATETIME,
	dictamen_medico VARCHAR(50)
)
GO

CREATE TABLE mundial.sustitucion(
	id_sustitucion INT IDENTITY(1,1) PRIMARY KEY,
	id_partido INT REFERENCES mundial.partido(id_partido),
	id_seleccion INT REFERENCES mundial.seleccion(id_seleccion),
	id_jugador_sale INT REFERENCES mundial.jugador(id_jugador),
	id_jugador_entra INT REFERENCES mundial.jugador(id_jugador),
	minuto INT,
	minuto_adicional INT,
	periodo VARCHAR(20),
	numero_ventana INT,
	motivo VARCHAR(50)
)
GO

CREATE TABLE mundial.tipo_gol(
	id_tipo_gol INT IDENTITY(1,1) PRIMARY KEY,
	descripcion VARCHAR(50)
)
GO

CREATE TABLE mundial.gol(
	id_gol INT IDENTITY(1,1) PRIMARY KEY,
	id_partido INT REFERENCES mundial.partido(id_partido),
	id_seleccion INT REFERENCES mundial.seleccion(id_seleccion),
	id_jugador_autor INT REFERENCES mundial.jugador(id_jugador),
	id_jugador_asistente INT REFERENCES mundial.jugador(id_jugador),
	id_tipo_gol INT REFERENCES mundial.tipo_gol(id_tipo_gol),
	minuto INT,
	minuto_adicional INT,
	periodo VARCHAR(20)
)
GO

CREATE TABLE mundial.tipo_tarjeta(
	id_tipo_tarjeta INT IDENTITY(1,1) PRIMARY KEY,
	descripcion VARCHAR(50)
)
GO

CREATE TABLE mundial.tarjeta(
	id_tarjeta INT IDENTITY(1,1) PRIMARY KEY,
	id_partido INT REFERENCES mundial.partido(id_partido),
	id_seleccion INT REFERENCES mundial.seleccion(id_seleccion),
	id_jugador INT REFERENCES mundial.jugador(id_jugador),
	id_tipo_tarjeta INT REFERENCES mundial.tipo_tarjeta(id_tipo_tarjeta),
	minuto INT,
	minuto_adicional INT,
	periodo VARCHAR(20),
	motivo VARCHAR(50),
	tipo_expulsion VARCHAR(20)
)
GO

CREATE TABLE mundial.criterio_suspension(
	id_criterio INT IDENTITY(1,1) PRIMARY KEY,
	cantidad_amarillas INT,
	fase_aplicable VARCHAR(20),
	partidos_suspension INT
)
GO

CREATE TABLE mundial.suspension_jugador(
	id_suspension INT IDENTITY(1,1) PRIMARY KEY,
	id_criterio INT REFERENCES mundial.criterio_suspension(id_criterio),
	id_jugador INT REFERENCES mundial.jugador(id_jugador),
	id_partido_origen INT REFERENCES mundial.partido(id_partido),
	id_partido_suspendido INT REFERENCES mundial.partido(id_partido),
	motivo VARCHAR(100),
	partidos_sancion INT,
	cumplida BIT
)
GO

CREATE TABLE mundial.moneda(
	id_moneda INT IDENTITY(1,1) PRIMARY KEY,
	codigo_iso VARCHAR(50),
	descripcion VARCHAR(100)
)
GO

CREATE TABLE mundial.pauta_partido(
	id_pauta INT IDENTITY(1,1) PRIMARY KEY,
	id_partido INT REFERENCES mundial.partido(id_partido),
	id_espacio INT REFERENCES mundial.espacio_publicitario(id_espacio),
	id_pieza INT REFERENCES mundial.pieza_publicitaria(id_pieza),
	id_moneda INT REFERENCES mundial.moneda(id_moneda),
	tarifa_base_usd DECIMAL(12,2) CHECK(tarifa_base_usd >= 0) NOT NULL,
	tipo_cambio_aplicado DECIMAL(12,6) CHECK(tipo_cambio_aplicado >= 0) NOT NULL,
	tarifa_final DECIMAL(12,2) CHECK(tarifa_final >= 0) NOT NULL,
	es_prime_time BIT NOT NULL,
	estado_facturacion VARCHAR(50) NOT NULL,
	CONSTRAINT UQ_pauta_partido_espacio UNIQUE (id_partido,id_espacio)
)
GO

CREATE TABLE mundial.partido_equipo_detalle(
	id_partido_equipo INT IDENTITY(1,1) PRIMARY KEY,
	id_partido INT REFERENCES mundial.partido(id_partido),
	id_seleccion INT REFERENCES mundial.seleccion(id_seleccion),
	condicion VARCHAR(50),
	esquema_tactico VARCHAR(50)
)	
GO

CREATE TABLE mundial.rol_arbitral(
	id_rol_arbitral INT IDENTITY(1,1) PRIMARY KEY,
	descripcion VARCHAR(50)
)
GO

CREATE TABLE mundial.designacion_arbitral(
	id_designacion INT IDENTITY(1,1) PRIMARY KEY,
	id_partido INT REFERENCES mundial.partido(id_partido),
	id_arbitro INT REFERENCES mundial.arbitro(id_arbitro),
	id_rol_arbitral INT REFERENCES mundial.rol_arbitral(id_rol_arbitral)
)
go

CREATE TABLE mundial.informe_arbitral(
	id_informe INT IDENTITY(1,1) PRIMARY KEY,
	id_designacion INT REFERENCES mundial.designacion_arbitral(id_designacion),
	fecha_informe DATE,
	observaciones VARCHAR(50),
	calificacion DECIMAL(5,2),
	sanciones_pos_partido VARCHAR(50)
)
GO

CREATE TABLE mundial.alineacion_partido(
	id_alineacion INT IDENTITY(1,1) PRIMARY KEY,
	id_partido_equipo INT REFERENCES mundial.partido_equipo_detalle(id_partido_equipo),
	id_jugador INT REFERENCES mundial.jugador(id_jugador),
	id_posicion_campo INT REFERENCES mundial.posicion(id_posicion),
	dorsal INT,
	es_titular BIT,
	minuto_regreso INT,
	minuto_salida INT
)
GO

--37 TABLAS


