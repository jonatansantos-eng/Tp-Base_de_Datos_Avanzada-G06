/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-16
    Archivo: 02_CreacionTablas.sql
    Objetivo: crear las 37 tablas, claves y restricciones del modelo.
*/

USE TP2026;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO



CREATE TABLE mundial.confederacion
(
    id_confederacion INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    sigla VARCHAR(10) NOT NULL,
    CONSTRAINT PK_confederacion PRIMARY KEY (id_confederacion),
    CONSTRAINT UQ_confederacion_nombre UNIQUE (nombre),
    CONSTRAINT UQ_confederacion_sigla UNIQUE (sigla)
);
GO

CREATE TABLE mundial.pais
(
    id_pais INT IDENTITY(1,1) NOT NULL,
    id_confederacion INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    codigo_iso CHAR(3) NOT NULL,
    huso_horario_estandar VARCHAR(100) NOT NULL,
    pbi_per_capita DECIMAL(18,2) NULL,
    codigo_moneda CHAR(3) NOT NULL,
    CONSTRAINT PK_pais PRIMARY KEY (id_pais),
    CONSTRAINT FK_pais_confederacion FOREIGN KEY (id_confederacion)
        REFERENCES mundial.confederacion(id_confederacion),
    CONSTRAINT UQ_pais_nombre UNIQUE (nombre),
    CONSTRAINT UQ_pais_codigo_iso UNIQUE (codigo_iso),
    CONSTRAINT CK_pais_pbi CHECK (pbi_per_capita IS NULL OR pbi_per_capita >= 0)
);
GO

CREATE TABLE mundial.ciudad
(
    id_ciudad INT IDENTITY(1,1) NOT NULL,
    id_pais INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    CONSTRAINT PK_ciudad PRIMARY KEY (id_ciudad),
    CONSTRAINT FK_ciudad_pais FOREIGN KEY (id_pais)
        REFERENCES mundial.pais(id_pais),
    CONSTRAINT UQ_ciudad_pais_nombre UNIQUE (id_pais, nombre)
);
GO

CREATE TABLE mundial.sede_estadio
(
    id_sede INT IDENTITY(1,1) NOT NULL,
    id_ciudad INT NOT NULL,
    nombre_estadio VARCHAR(150) NOT NULL,
    capacidad INT NOT NULL,
    huso_horario VARCHAR(100) NOT NULL,
    latitud DECIMAL(9,6) NOT NULL,
    longitud DECIMAL(9,6) NOT NULL,
    CONSTRAINT PK_sede_estadio PRIMARY KEY (id_sede),
    CONSTRAINT FK_sede_ciudad FOREIGN KEY (id_ciudad)
        REFERENCES mundial.ciudad(id_ciudad),
    CONSTRAINT UQ_sede_ciudad_nombre UNIQUE (id_ciudad, nombre_estadio),
    CONSTRAINT CK_sede_capacidad CHECK (capacidad > 0),
    CONSTRAINT CK_sede_latitud CHECK (latitud BETWEEN -90 AND 90),
    CONSTRAINT CK_sede_longitud CHECK (longitud BETWEEN -180 AND 180)
);
GO

CREATE TABLE mundial.grupo
(
    id_grupo INT IDENTITY(1,1) NOT NULL,
    nombre_grupo VARCHAR(50) NOT NULL,
    CONSTRAINT PK_grupo PRIMARY KEY (id_grupo),
    CONSTRAINT UQ_grupo_nombre UNIQUE (nombre_grupo)
);
GO

CREATE TABLE mundial.reglamento_sustitucion
(
    id_reglamento_sustitucion INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    maximo_cambios TINYINT NOT NULL,
    maximo_ventanas TINYINT NOT NULL,
    cambios_adicionales_suplementario TINYINT NOT NULL,
    ventanas_adicionales_suplementario TINYINT NOT NULL,
    entretiempo_computa_ventana BIT NOT NULL,
    intervalo_suplementario_computa_ventana BIT NOT NULL,
    fecha_vigencia_desde DATE NOT NULL,
    fecha_vigencia_hasta DATE NULL,
    activo BIT NOT NULL CONSTRAINT DF_reglamento_activo DEFAULT (1),
    CONSTRAINT PK_reglamento_sustitucion PRIMARY KEY (id_reglamento_sustitucion),
    CONSTRAINT UQ_reglamento_nombre UNIQUE (nombre),
    CONSTRAINT CK_reglamento_vigencia CHECK
        (fecha_vigencia_hasta IS NULL OR fecha_vigencia_hasta >= fecha_vigencia_desde),
    CONSTRAINT CK_reglamento_maximos CHECK
        (maximo_cambios > 0 AND maximo_ventanas > 0),
    CONSTRAINT CK_reglamento_adicionales CHECK
        (cambios_adicionales_suplementario >= 0 AND ventanas_adicionales_suplementario >= 0)
);
GO

CREATE TABLE mundial.fase
(
    id_fase INT IDENTITY(1,1) NOT NULL,
    id_reglamento_sustitucion INT NOT NULL,
    nombre_fase VARCHAR(50) NOT NULL,
    orden TINYINT NOT NULL,
    permite_alargue BIT NOT NULL,
    permite_penales BIT NOT NULL,
    CONSTRAINT PK_fase PRIMARY KEY (id_fase),
    CONSTRAINT FK_fase_reglamento FOREIGN KEY (id_reglamento_sustitucion)
        REFERENCES mundial.reglamento_sustitucion(id_reglamento_sustitucion),
    CONSTRAINT UQ_fase_nombre UNIQUE (nombre_fase),
    CONSTRAINT UQ_fase_orden UNIQUE (orden),
    CONSTRAINT CK_fase_orden CHECK (orden > 0)
);
GO

CREATE TABLE mundial.seleccion
(
    id_seleccion INT IDENTITY(1,1) NOT NULL,
    id_pais INT NOT NULL,
    id_grupo INT NULL,
    CONSTRAINT PK_seleccion PRIMARY KEY (id_seleccion),
    CONSTRAINT FK_seleccion_pais FOREIGN KEY (id_pais)
        REFERENCES mundial.pais(id_pais),
    CONSTRAINT FK_seleccion_grupo FOREIGN KEY (id_grupo)
        REFERENCES mundial.grupo(id_grupo),
    CONSTRAINT UQ_seleccion_pais UNIQUE (id_pais)
);
GO



CREATE TABLE mundial.club
(
    id_club INT IDENTITY(1,1) NOT NULL,
    id_pais INT NOT NULL,
    nombre_club VARCHAR(150) NOT NULL,
    CONSTRAINT PK_club PRIMARY KEY (id_club),
    CONSTRAINT FK_club_pais FOREIGN KEY (id_pais)
        REFERENCES mundial.pais(id_pais),
    CONSTRAINT UQ_club_pais_nombre UNIQUE (id_pais, nombre_club)
);
GO

CREATE TABLE mundial.posicion
(
    id_posicion INT IDENTITY(1,1) NOT NULL,
    codigo VARCHAR(10) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    linea_campo VARCHAR(30) NOT NULL,
    CONSTRAINT PK_posicion PRIMARY KEY (id_posicion),
    CONSTRAINT UQ_posicion_codigo UNIQUE (codigo)
);
GO

CREATE TABLE mundial.jugador
(
    id_jugador INT IDENTITY(1,1) NOT NULL,
    id_pais_nacionalidad INT NOT NULL,
    id_club INT NOT NULL,
    id_posicion_habitual INT NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    doc_identidad VARCHAR(50) NOT NULL,
    CONSTRAINT PK_jugador PRIMARY KEY (id_jugador),
    CONSTRAINT FK_jugador_pais FOREIGN KEY (id_pais_nacionalidad)
        REFERENCES mundial.pais(id_pais),
    CONSTRAINT FK_jugador_club FOREIGN KEY (id_club)
        REFERENCES mundial.club(id_club),
    CONSTRAINT FK_jugador_posicion FOREIGN KEY (id_posicion_habitual)
        REFERENCES mundial.posicion(id_posicion),
    CONSTRAINT UQ_jugador_documento UNIQUE (doc_identidad)
);
GO

CREATE TABLE mundial.rol_cuerpo_tecnico
(
    id_rol_ct INT IDENTITY(1,1) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    CONSTRAINT PK_rol_cuerpo_tecnico PRIMARY KEY (id_rol_ct),
    CONSTRAINT UQ_rol_cuerpo_tecnico UNIQUE (descripcion)
);
GO

CREATE TABLE mundial.cuerpo_tecnico
(
    id_miembro_ct INT IDENTITY(1,1) NOT NULL,
    id_seleccion INT NOT NULL,
    id_pais_nacionalidad INT NOT NULL,
    id_rol_ct INT NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    CONSTRAINT PK_cuerpo_tecnico PRIMARY KEY (id_miembro_ct),
    CONSTRAINT FK_ct_seleccion FOREIGN KEY (id_seleccion)
        REFERENCES mundial.seleccion(id_seleccion),
    CONSTRAINT FK_ct_pais FOREIGN KEY (id_pais_nacionalidad)
        REFERENCES mundial.pais(id_pais),
    CONSTRAINT FK_ct_rol FOREIGN KEY (id_rol_ct)
        REFERENCES mundial.rol_cuerpo_tecnico(id_rol_ct)
);
GO

CREATE TABLE mundial.convocatoria
(
    id_convocatoria INT IDENTITY(1,1) NOT NULL,
    id_seleccion INT NOT NULL,
    id_jugador INT NOT NULL,
    dorsal TINYINT NOT NULL,
    fecha_convocatoria DATE NOT NULL,
    estado_convocatoria VARCHAR(20) NOT NULL,
    CONSTRAINT PK_convocatoria PRIMARY KEY (id_convocatoria),
    CONSTRAINT FK_convocatoria_seleccion FOREIGN KEY (id_seleccion)
        REFERENCES mundial.seleccion(id_seleccion),
    CONSTRAINT FK_convocatoria_jugador FOREIGN KEY (id_jugador)
        REFERENCES mundial.jugador(id_jugador),
    CONSTRAINT UQ_convocatoria_seleccion_jugador UNIQUE (id_seleccion, id_jugador),
    CONSTRAINT UQ_convocatoria_seleccion_dorsal UNIQUE (id_seleccion, dorsal),
    CONSTRAINT CK_convocatoria_dorsal CHECK (dorsal BETWEEN 1 AND 99),
    CONSTRAINT CK_convocatoria_estado CHECK
        (estado_convocatoria IN ('ACTIVA','BAJA','REEMPLAZADA'))
);
GO

CREATE TABLE mundial.novedad_convocatoria
(
    id_novedad INT IDENTITY(1,1) NOT NULL,
    id_convocatoria_baja INT NOT NULL,
    id_convocatoria_alta INT NOT NULL,
    motivo VARCHAR(200) NOT NULL,
    fecha_cambio DATETIME2(0) NOT NULL,
    dictamen_medico VARCHAR(500) NULL,
    CONSTRAINT PK_novedad_convocatoria PRIMARY KEY (id_novedad),
    CONSTRAINT FK_novedad_baja FOREIGN KEY (id_convocatoria_baja)
        REFERENCES mundial.convocatoria(id_convocatoria),
    CONSTRAINT FK_novedad_alta FOREIGN KEY (id_convocatoria_alta)
        REFERENCES mundial.convocatoria(id_convocatoria),
    CONSTRAINT CK_novedad_convocatorias_distintas CHECK
        (id_convocatoria_baja <> id_convocatoria_alta),
    CONSTRAINT UQ_novedad_baja UNIQUE (id_convocatoria_baja),
    CONSTRAINT UQ_novedad_alta UNIQUE (id_convocatoria_alta)
);
GO



CREATE TABLE mundial.partido
(
    id_partido INT IDENTITY(1,1) NOT NULL,
    id_fase INT NOT NULL,
    id_sede INT NOT NULL,
    id_seleccion_local INT NOT NULL,
    id_seleccion_visitante INT NOT NULL,
    fecha_hora_utc DATETIME2(0) NOT NULL,
    fecha_hora_local DATETIME2(0) NOT NULL,
    goles_local TINYINT NULL,
    goles_visitante TINYINT NULL,
    penales_local TINYINT NULL,
    penales_visitante TINYINT NULL,
    asistencia_publico INT NULL,
    estado_partido VARCHAR(20) NOT NULL,
    CONSTRAINT PK_partido PRIMARY KEY (id_partido),
    CONSTRAINT FK_partido_fase FOREIGN KEY (id_fase)
        REFERENCES mundial.fase(id_fase),
    CONSTRAINT FK_partido_sede FOREIGN KEY (id_sede)
        REFERENCES mundial.sede_estadio(id_sede),
    CONSTRAINT FK_partido_local FOREIGN KEY (id_seleccion_local)
        REFERENCES mundial.seleccion(id_seleccion),
    CONSTRAINT FK_partido_visitante FOREIGN KEY (id_seleccion_visitante)
        REFERENCES mundial.seleccion(id_seleccion),
    CONSTRAINT CK_partido_selecciones_distintas CHECK
        (id_seleccion_local <> id_seleccion_visitante),
    CONSTRAINT CK_partido_goles CHECK
        ((goles_local IS NULL OR goles_local >= 0) AND
         (goles_visitante IS NULL OR goles_visitante >= 0)),
    CONSTRAINT CK_partido_penales CHECK
        ((penales_local IS NULL OR penales_local >= 0) AND
         (penales_visitante IS NULL OR penales_visitante >= 0)),
    CONSTRAINT CK_partido_asistencia CHECK
        (asistencia_publico IS NULL OR asistencia_publico >= 0),
    CONSTRAINT CK_partido_estado CHECK
        (estado_partido IN ('PROGRAMADO','EN_CURSO','FINALIZADO','SUSPENDIDO','CANCELADO'))
);
GO

CREATE TABLE mundial.partido_equipo_detalle
(
    id_partido_equipo INT IDENTITY(1,1) NOT NULL,
    id_partido INT NOT NULL,
    id_seleccion INT NOT NULL,
    condicion VARCHAR(10) NOT NULL,
    esquema_tactico VARCHAR(30) NULL,
    CONSTRAINT PK_partido_equipo_detalle PRIMARY KEY (id_partido_equipo),
    CONSTRAINT FK_ped_partido FOREIGN KEY (id_partido)
        REFERENCES mundial.partido(id_partido),
    CONSTRAINT FK_ped_seleccion FOREIGN KEY (id_seleccion)
        REFERENCES mundial.seleccion(id_seleccion),
    CONSTRAINT UQ_ped_partido_seleccion UNIQUE (id_partido, id_seleccion),
    CONSTRAINT UQ_ped_partido_condicion UNIQUE (id_partido, condicion),
    CONSTRAINT CK_ped_condicion CHECK (condicion IN ('LOCAL','VISITANTE'))
);
GO

CREATE TABLE mundial.alineacion_partido
(
    id_alineacion INT IDENTITY(1,1) NOT NULL,
    id_partido_equipo INT NOT NULL,
    id_jugador INT NOT NULL,
    id_posicion_campo INT NOT NULL,
    dorsal TINYINT NOT NULL,
    es_titular BIT NOT NULL,
    minuto_ingreso TINYINT NULL,
    minuto_salida TINYINT NULL,
    CONSTRAINT PK_alineacion_partido PRIMARY KEY (id_alineacion),
    CONSTRAINT FK_alineacion_partido_equipo FOREIGN KEY (id_partido_equipo)
        REFERENCES mundial.partido_equipo_detalle(id_partido_equipo),
    CONSTRAINT FK_alineacion_jugador FOREIGN KEY (id_jugador)
        REFERENCES mundial.jugador(id_jugador),
    CONSTRAINT FK_alineacion_posicion FOREIGN KEY (id_posicion_campo)
        REFERENCES mundial.posicion(id_posicion),
    CONSTRAINT UQ_alineacion_equipo_jugador UNIQUE (id_partido_equipo, id_jugador),
    CONSTRAINT UQ_alineacion_equipo_dorsal UNIQUE (id_partido_equipo, dorsal),
    CONSTRAINT CK_alineacion_dorsal CHECK (dorsal BETWEEN 1 AND 99),
    CONSTRAINT CK_alineacion_minutos CHECK
        ((minuto_ingreso IS NULL OR minuto_ingreso BETWEEN 0 AND 120) AND
         (minuto_salida IS NULL OR minuto_salida BETWEEN 0 AND 120) AND
         (minuto_ingreso IS NULL OR minuto_salida IS NULL OR minuto_salida >= minuto_ingreso))
);
GO

CREATE TABLE mundial.sustitucion
(
    id_sustitucion INT IDENTITY(1,1) NOT NULL,
    id_partido_equipo INT NOT NULL,
    id_jugador_sale INT NOT NULL,
    id_jugador_entra INT NOT NULL,
    minuto TINYINT NOT NULL,
    minuto_adicional TINYINT NOT NULL CONSTRAINT DF_sustitucion_adicional DEFAULT (0),
    periodo VARCHAR(30) NOT NULL,
    numero_ventana TINYINT NOT NULL,
    motivo VARCHAR(30) NOT NULL,
    CONSTRAINT PK_sustitucion PRIMARY KEY (id_sustitucion),
    CONSTRAINT FK_sustitucion_partido_equipo FOREIGN KEY (id_partido_equipo)
        REFERENCES mundial.partido_equipo_detalle(id_partido_equipo),
    CONSTRAINT FK_sustitucion_sale FOREIGN KEY (id_jugador_sale)
        REFERENCES mundial.jugador(id_jugador),
    CONSTRAINT FK_sustitucion_entra FOREIGN KEY (id_jugador_entra)
        REFERENCES mundial.jugador(id_jugador),
    CONSTRAINT CK_sustitucion_jugadores_distintos CHECK
        (id_jugador_sale <> id_jugador_entra),
    CONSTRAINT CK_sustitucion_minuto CHECK (minuto BETWEEN 0 AND 120),
    CONSTRAINT CK_sustitucion_adicional CHECK (minuto_adicional BETWEEN 0 AND 30),
    CONSTRAINT CK_sustitucion_ventana CHECK (numero_ventana > 0),
    CONSTRAINT CK_sustitucion_motivo CHECK
        (motivo IN ('TACTICO','LESION','PRECAUCION'))
);
GO

CREATE TABLE mundial.tipo_gol
(
    id_tipo_gol INT IDENTITY(1,1) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    CONSTRAINT PK_tipo_gol PRIMARY KEY (id_tipo_gol),
    CONSTRAINT UQ_tipo_gol UNIQUE (descripcion)
);
GO

CREATE TABLE mundial.gol
(
    id_gol INT IDENTITY(1,1) NOT NULL,
    id_partido INT NOT NULL,
    id_seleccion_beneficiada INT NOT NULL,
    id_jugador_autor INT NOT NULL,
    id_jugador_asistente INT NULL,
    id_tipo_gol INT NOT NULL,
    minuto TINYINT NOT NULL,
    minuto_adicional TINYINT NOT NULL CONSTRAINT DF_gol_adicional DEFAULT (0),
    periodo VARCHAR(30) NOT NULL,
    es_gol_en_contra BIT NOT NULL CONSTRAINT DF_gol_en_contra DEFAULT (0),
    CONSTRAINT PK_gol PRIMARY KEY (id_gol),
    CONSTRAINT FK_gol_partido FOREIGN KEY (id_partido)
        REFERENCES mundial.partido(id_partido),
    CONSTRAINT FK_gol_seleccion FOREIGN KEY (id_seleccion_beneficiada)
        REFERENCES mundial.seleccion(id_seleccion),
    CONSTRAINT FK_gol_autor FOREIGN KEY (id_jugador_autor)
        REFERENCES mundial.jugador(id_jugador),
    CONSTRAINT FK_gol_asistente FOREIGN KEY (id_jugador_asistente)
        REFERENCES mundial.jugador(id_jugador),
    CONSTRAINT FK_gol_tipo FOREIGN KEY (id_tipo_gol)
        REFERENCES mundial.tipo_gol(id_tipo_gol),
    CONSTRAINT CK_gol_autor_asistente CHECK
        (id_jugador_asistente IS NULL OR id_jugador_asistente <> id_jugador_autor),
    CONSTRAINT CK_gol_minuto CHECK (minuto BETWEEN 0 AND 120),
    CONSTRAINT CK_gol_adicional CHECK (minuto_adicional BETWEEN 0 AND 30)
);
GO

CREATE TABLE mundial.tipo_tarjeta
(
    id_tipo_tarjeta INT IDENTITY(1,1) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    CONSTRAINT PK_tipo_tarjeta PRIMARY KEY (id_tipo_tarjeta),
    CONSTRAINT UQ_tipo_tarjeta UNIQUE (descripcion)
);
GO

CREATE TABLE mundial.tarjeta
(
    id_tarjeta INT IDENTITY(1,1) NOT NULL,
    id_partido INT NOT NULL,
    id_seleccion INT NOT NULL,
    id_jugador INT NOT NULL,
    id_tipo_tarjeta INT NOT NULL,
    minuto TINYINT NOT NULL,
    minuto_adicional TINYINT NOT NULL CONSTRAINT DF_tarjeta_adicional DEFAULT (0),
    periodo VARCHAR(30) NOT NULL,
    motivo VARCHAR(200) NOT NULL,
    tipo_expulsion VARCHAR(30) NULL,
    CONSTRAINT PK_tarjeta PRIMARY KEY (id_tarjeta),
    CONSTRAINT FK_tarjeta_partido FOREIGN KEY (id_partido)
        REFERENCES mundial.partido(id_partido),
    CONSTRAINT FK_tarjeta_seleccion FOREIGN KEY (id_seleccion)
        REFERENCES mundial.seleccion(id_seleccion),
    CONSTRAINT FK_tarjeta_jugador FOREIGN KEY (id_jugador)
        REFERENCES mundial.jugador(id_jugador),
    CONSTRAINT FK_tarjeta_tipo FOREIGN KEY (id_tipo_tarjeta)
        REFERENCES mundial.tipo_tarjeta(id_tipo_tarjeta),
    CONSTRAINT CK_tarjeta_minuto CHECK (minuto BETWEEN 0 AND 120),
    CONSTRAINT CK_tarjeta_adicional CHECK (minuto_adicional BETWEEN 0 AND 30),
    CONSTRAINT CK_tarjeta_expulsion CHECK
        (tipo_expulsion IS NULL OR tipo_expulsion IN ('DOBLE_AMARILLA','ROJA_DIRECTA'))
);
GO

CREATE TABLE mundial.criterio_suspension
(
    id_criterio INT IDENTITY(1,1) NOT NULL,
    id_fase INT NULL,
    cantidad_amarillas TINYINT NULL,
    tipo_infraccion VARCHAR(50) NOT NULL,
    partidos_suspension TINYINT NOT NULL,
    vigencia_desde DATE NOT NULL,
    vigencia_hasta DATE NULL,
    CONSTRAINT PK_criterio_suspension PRIMARY KEY (id_criterio),
    CONSTRAINT FK_criterio_fase FOREIGN KEY (id_fase)
        REFERENCES mundial.fase(id_fase),
    CONSTRAINT CK_criterio_amarillas CHECK
        (cantidad_amarillas IS NULL OR cantidad_amarillas > 0),
    CONSTRAINT CK_criterio_partidos CHECK (partidos_suspension > 0),
    CONSTRAINT CK_criterio_vigencia CHECK
        (vigencia_hasta IS NULL OR vigencia_hasta >= vigencia_desde)
);
GO

CREATE TABLE mundial.suspension_jugador
(
    id_suspension INT IDENTITY(1,1) NOT NULL,
    id_criterio INT NULL,
    id_jugador INT NOT NULL,
    id_partido_origen INT NOT NULL,
    motivo VARCHAR(200) NOT NULL,
    partidos_sancion TINYINT NOT NULL,
    partidos_cumplidos TINYINT NOT NULL CONSTRAINT DF_suspension_cumplidos DEFAULT (0),
    cumplida BIT NOT NULL CONSTRAINT DF_suspension_cumplida DEFAULT (0),
    CONSTRAINT PK_suspension_jugador PRIMARY KEY (id_suspension),
    CONSTRAINT FK_suspension_criterio FOREIGN KEY (id_criterio)
        REFERENCES mundial.criterio_suspension(id_criterio),
    CONSTRAINT FK_suspension_jugador FOREIGN KEY (id_jugador)
        REFERENCES mundial.jugador(id_jugador),
    CONSTRAINT FK_suspension_partido FOREIGN KEY (id_partido_origen)
        REFERENCES mundial.partido(id_partido),
    CONSTRAINT CK_suspension_sancion CHECK (partidos_sancion > 0),
    CONSTRAINT CK_suspension_cumplidos CHECK
        (partidos_cumplidos BETWEEN 0 AND partidos_sancion)
);
GO

CREATE TABLE mundial.cumplimiento_suspension
(
    id_cumplimiento INT IDENTITY(1,1) NOT NULL,
    id_suspension INT NOT NULL,
    id_partido INT NOT NULL,
    fecha_registro DATETIME2(0) NOT NULL
        CONSTRAINT DF_cumplimiento_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_cumplimiento_suspension PRIMARY KEY (id_cumplimiento),
    CONSTRAINT FK_cumplimiento_suspension FOREIGN KEY (id_suspension)
        REFERENCES mundial.suspension_jugador(id_suspension),
    CONSTRAINT FK_cumplimiento_partido FOREIGN KEY (id_partido)
        REFERENCES mundial.partido(id_partido),
    CONSTRAINT UQ_cumplimiento_suspension_partido UNIQUE (id_suspension, id_partido)
);
GO


CREATE TABLE mundial.arbitro
(
    id_arbitro INT IDENTITY(1,1) NOT NULL,
    id_pais_nacionalidad INT NOT NULL,
    id_confederacion_afiliacion INT NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    CONSTRAINT PK_arbitro PRIMARY KEY (id_arbitro),
    CONSTRAINT FK_arbitro_pais FOREIGN KEY (id_pais_nacionalidad)
        REFERENCES mundial.pais(id_pais),
    CONSTRAINT FK_arbitro_confederacion FOREIGN KEY (id_confederacion_afiliacion)
        REFERENCES mundial.confederacion(id_confederacion)
);
GO

CREATE TABLE mundial.idioma
(
    id_idioma INT IDENTITY(1,1) NOT NULL,
    nombre_idioma VARCHAR(100) NOT NULL,
    codigo_iso VARCHAR(10) NOT NULL,
    CONSTRAINT PK_idioma PRIMARY KEY (id_idioma),
    CONSTRAINT UQ_idioma_nombre UNIQUE (nombre_idioma),
    CONSTRAINT UQ_idioma_codigo UNIQUE (codigo_iso)
);
GO

CREATE TABLE mundial.arbitro_idioma
(
    id_arbitro INT NOT NULL,
    id_idioma INT NOT NULL,
    CONSTRAINT PK_arbitro_idioma PRIMARY KEY (id_arbitro, id_idioma),
    CONSTRAINT FK_arbitro_idioma_arbitro FOREIGN KEY (id_arbitro)
        REFERENCES mundial.arbitro(id_arbitro),
    CONSTRAINT FK_arbitro_idioma_idioma FOREIGN KEY (id_idioma)
        REFERENCES mundial.idioma(id_idioma)
);
GO

CREATE TABLE mundial.rol_arbitral
(
    id_rol_arbitral INT IDENTITY(1,1) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    CONSTRAINT PK_rol_arbitral PRIMARY KEY (id_rol_arbitral),
    CONSTRAINT UQ_rol_arbitral UNIQUE (descripcion)
);
GO

CREATE TABLE mundial.designacion_arbitral
(
    id_designacion INT IDENTITY(1,1) NOT NULL,
    id_partido INT NOT NULL,
    id_arbitro INT NOT NULL,
    id_rol_arbitral INT NOT NULL,
    CONSTRAINT PK_designacion_arbitral PRIMARY KEY (id_designacion),
    CONSTRAINT FK_designacion_partido FOREIGN KEY (id_partido)
        REFERENCES mundial.partido(id_partido),
    CONSTRAINT FK_designacion_arbitro FOREIGN KEY (id_arbitro)
        REFERENCES mundial.arbitro(id_arbitro),
    CONSTRAINT FK_designacion_rol FOREIGN KEY (id_rol_arbitral)
        REFERENCES mundial.rol_arbitral(id_rol_arbitral),
    CONSTRAINT UQ_designacion_partido_arbitro UNIQUE (id_partido, id_arbitro),
    CONSTRAINT UQ_designacion_partido_rol UNIQUE (id_partido, id_rol_arbitral)
);
GO

CREATE TABLE mundial.informe_arbitral
(
    id_informe INT IDENTITY(1,1) NOT NULL,
    id_designacion INT NOT NULL,
    fecha_informe DATE NOT NULL,
    observaciones VARCHAR(1000) NULL,
    calificacion DECIMAL(5,2) NULL,
    sanciones_post_partido VARCHAR(1000) NULL,
    CONSTRAINT PK_informe_arbitral PRIMARY KEY (id_informe),
    CONSTRAINT FK_informe_designacion FOREIGN KEY (id_designacion)
        REFERENCES mundial.designacion_arbitral(id_designacion),
    CONSTRAINT UQ_informe_designacion UNIQUE (id_designacion),
    CONSTRAINT CK_informe_calificacion CHECK
        (calificacion IS NULL OR calificacion BETWEEN 0 AND 10)
);
GO



CREATE TABLE mundial.anunciante
(
    id_anunciante INT IDENTITY(1,1) NOT NULL,
    id_pais_origen INT NOT NULL,
    razon_social VARCHAR(200) NOT NULL,
    identificador_fiscal VARCHAR(50) NOT NULL,
    email_contacto VARCHAR(254) NOT NULL,
    CONSTRAINT PK_anunciante PRIMARY KEY (id_anunciante),
    CONSTRAINT FK_anunciante_pais FOREIGN KEY (id_pais_origen)
        REFERENCES mundial.pais(id_pais),
    CONSTRAINT UQ_anunciante_identificador UNIQUE (identificador_fiscal),
    CONSTRAINT UQ_anunciante_email UNIQUE (email_contacto)
);
GO

CREATE TABLE mundial.campania
(
    id_campania INT IDENTITY(1,1) NOT NULL,
    id_anunciante INT NOT NULL,
    nombre_campania VARCHAR(150) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    presupuesto_total DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_campania PRIMARY KEY (id_campania),
    CONSTRAINT FK_campania_anunciante FOREIGN KEY (id_anunciante)
        REFERENCES mundial.anunciante(id_anunciante),
    CONSTRAINT UQ_campania_anunciante_nombre UNIQUE (id_anunciante, nombre_campania),
    CONSTRAINT CK_campania_fechas CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT CK_campania_presupuesto CHECK (presupuesto_total >= 0)
);
GO

CREATE TABLE mundial.pieza_publicitaria
(
    id_pieza INT IDENTITY(1,1) NOT NULL,
    id_campania INT NOT NULL,
    id_idioma INT NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    formato VARCHAR(50) NOT NULL,
    duracion_segundos SMALLINT NOT NULL,
    CONSTRAINT PK_pieza_publicitaria PRIMARY KEY (id_pieza),
    CONSTRAINT FK_pieza_campania FOREIGN KEY (id_campania)
        REFERENCES mundial.campania(id_campania),
    CONSTRAINT FK_pieza_idioma FOREIGN KEY (id_idioma)
        REFERENCES mundial.idioma(id_idioma),
    CONSTRAINT CK_pieza_duracion CHECK (duracion_segundos > 0)
);
GO

CREATE TABLE mundial.pieza_pais_objetivo
(
    id_pieza INT NOT NULL,
    id_pais INT NOT NULL,
    prioridad TINYINT NOT NULL,
    CONSTRAINT PK_pieza_pais_objetivo PRIMARY KEY (id_pieza, id_pais),
    CONSTRAINT FK_ppo_pieza FOREIGN KEY (id_pieza)
        REFERENCES mundial.pieza_publicitaria(id_pieza),
    CONSTRAINT FK_ppo_pais FOREIGN KEY (id_pais)
        REFERENCES mundial.pais(id_pais),
    CONSTRAINT UQ_ppo_pieza_prioridad UNIQUE (id_pieza, prioridad),
    CONSTRAINT CK_ppo_prioridad CHECK (prioridad > 0)
);
GO

CREATE TABLE mundial.espacio_publicitario
(
    id_espacio INT IDENTITY(1,1) NOT NULL,
    id_sede INT NOT NULL,
    numero_espacio TINYINT NOT NULL,
    CONSTRAINT PK_espacio_publicitario PRIMARY KEY (id_espacio),
    CONSTRAINT FK_espacio_sede FOREIGN KEY (id_sede)
        REFERENCES mundial.sede_estadio(id_sede),
    CONSTRAINT UQ_espacio_sede_numero UNIQUE (id_sede, numero_espacio),
    CONSTRAINT CK_espacio_numero CHECK (numero_espacio BETWEEN 1 AND 4)
);
GO

CREATE TABLE mundial.moneda
(
    id_moneda INT IDENTITY(1,1) NOT NULL,
    codigo_iso CHAR(3) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    CONSTRAINT PK_moneda PRIMARY KEY (id_moneda),
    CONSTRAINT UQ_moneda_codigo UNIQUE (codigo_iso)
);
GO

CREATE TABLE mundial.pauta_partido
(
    id_pauta INT IDENTITY(1,1) NOT NULL,
    id_partido INT NOT NULL,
    id_espacio INT NOT NULL,
    id_pieza INT NOT NULL,
    id_moneda INT NOT NULL,
    tarifa_base_usd DECIMAL(18,2) NOT NULL,
    tipo_cambio_aplicado DECIMAL(18,6) NOT NULL,
    tarifa_final DECIMAL(18,2) NOT NULL,
    es_prime_time BIT NOT NULL,
    estado_pauta VARCHAR(20) NOT NULL,
    estado_facturacion VARCHAR(20) NOT NULL,
    CONSTRAINT PK_pauta_partido PRIMARY KEY (id_pauta),
    CONSTRAINT FK_pauta_partido FOREIGN KEY (id_partido)
        REFERENCES mundial.partido(id_partido),
    CONSTRAINT FK_pauta_espacio FOREIGN KEY (id_espacio)
        REFERENCES mundial.espacio_publicitario(id_espacio),
    CONSTRAINT FK_pauta_pieza FOREIGN KEY (id_pieza)
        REFERENCES mundial.pieza_publicitaria(id_pieza),
    CONSTRAINT FK_pauta_moneda FOREIGN KEY (id_moneda)
        REFERENCES mundial.moneda(id_moneda),
    CONSTRAINT UQ_pauta_partido_espacio UNIQUE (id_partido, id_espacio),
    CONSTRAINT CK_pauta_importes CHECK
        (tarifa_base_usd >= 0 AND tipo_cambio_aplicado > 0 AND tarifa_final >= 0),
    CONSTRAINT CK_pauta_estado CHECK
        (estado_pauta IN ('PROPUESTA','CONFIRMADA','EXHIBIDA','CANCELADA')),
    CONSTRAINT CK_pauta_facturacion CHECK
        (estado_facturacion IN ('PENDIENTE','FACTURADA','COBRADA','ANULADA'))
);
GO



CREATE TABLE mundial.fuente_importacion
(
    id_fuente INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    tipo_fuente VARCHAR(20) NOT NULL,
    formato VARCHAR(20) NULL,
    url_origen VARCHAR(1000) NULL,
    descripcion VARCHAR(500) NULL,
    condiciones_uso VARCHAR(1000) NULL,
    activa BIT NOT NULL CONSTRAINT DF_fuente_activa DEFAULT (1),
    CONSTRAINT PK_fuente_importacion PRIMARY KEY (id_fuente),
    CONSTRAINT UQ_fuente_nombre UNIQUE (nombre),
    CONSTRAINT CK_fuente_tipo CHECK
        (tipo_fuente IN ('ARCHIVO','API','SCRAPING','MANUAL'))
);
GO

CREATE TABLE mundial.lote_importacion
(
    id_lote INT IDENTITY(1,1) NOT NULL,
    id_fuente INT NOT NULL,
    nombre_archivo VARCHAR(260) NULL,
    entidad_destino VARCHAR(128) NOT NULL,
    fecha_inicio DATETIME2(0) NOT NULL CONSTRAINT DF_lote_inicio DEFAULT (SYSDATETIME()),
    fecha_fin DATETIME2(0) NULL,
    estado_lote VARCHAR(20) NOT NULL,
    cantidad_leidos INT NOT NULL CONSTRAINT DF_lote_leidos DEFAULT (0),
    cantidad_insertados INT NOT NULL CONSTRAINT DF_lote_insertados DEFAULT (0),
    cantidad_actualizados INT NOT NULL CONSTRAINT DF_lote_actualizados DEFAULT (0),
    cantidad_rechazados INT NOT NULL CONSTRAINT DF_lote_rechazados DEFAULT (0),
    hash_archivo VARCHAR(128) NULL,
    CONSTRAINT PK_lote_importacion PRIMARY KEY (id_lote),
    CONSTRAINT FK_lote_fuente FOREIGN KEY (id_fuente)
        REFERENCES mundial.fuente_importacion(id_fuente),
    CONSTRAINT CK_lote_fechas CHECK
        (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT CK_lote_cantidades CHECK
        (cantidad_leidos >= 0 AND cantidad_insertados >= 0 AND
         cantidad_actualizados >= 0 AND cantidad_rechazados >= 0),
    CONSTRAINT CK_lote_estado CHECK
        (estado_lote IN ('PENDIENTE','EN_PROCESO','COMPLETADO','PARCIAL','FALLIDO'))
);
GO

CREATE UNIQUE INDEX UX_lote_hash_archivo
ON mundial.lote_importacion(hash_archivo)
WHERE hash_archivo IS NOT NULL;
GO

CREATE TABLE mundial.detalle_importacion
(
    id_detalle_importacion BIGINT IDENTITY(1,1) NOT NULL,
    id_lote INT NOT NULL,
    numero_fila INT NOT NULL,
    clave_externa VARCHAR(200) NULL,
    tipo_operacion VARCHAR(20) NULL,
    estado_registro VARCHAR(20) NOT NULL,
    datos_originales NVARCHAR(MAX) NULL,
    fecha_procesamiento DATETIME2(0) NULL,
    CONSTRAINT PK_detalle_importacion PRIMARY KEY (id_detalle_importacion),
    CONSTRAINT FK_detalle_lote FOREIGN KEY (id_lote)
        REFERENCES mundial.lote_importacion(id_lote),
    CONSTRAINT UQ_detalle_lote_fila UNIQUE (id_lote, numero_fila),
    CONSTRAINT CK_detalle_fila CHECK (numero_fila > 0),
    CONSTRAINT CK_detalle_operacion CHECK
        (tipo_operacion IS NULL OR tipo_operacion IN ('INSERT','UPDATE','SIN_CAMBIOS','RECHAZADO')),
    CONSTRAINT CK_detalle_estado CHECK
        (estado_registro IN ('PENDIENTE','VALIDO','PROCESADO','RECHAZADO'))
);
GO

CREATE TABLE mundial.error_importacion
(
    id_error BIGINT IDENTITY(1,1) NOT NULL,
    id_detalle_importacion BIGINT NOT NULL,
    codigo_error VARCHAR(50) NOT NULL,
    campo_error VARCHAR(128) NULL,
    descripcion_error VARCHAR(1000) NOT NULL,
    valor_recibido NVARCHAR(MAX) NULL,
    fecha_error DATETIME2(0) NOT NULL CONSTRAINT DF_error_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_error_importacion PRIMARY KEY (id_error),
    CONSTRAINT FK_error_detalle FOREIGN KEY (id_detalle_importacion)
        REFERENCES mundial.detalle_importacion(id_detalle_importacion)
);
GO
