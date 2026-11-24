/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-23
    Archivo: 05_CreacionObjetosImportacion.sql
    Objetivo: Crear objetos auxiliares, tablas de staging y estructuras para importaciones masivas (CSV, XML, JSON, Scraping).
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* 1. Trazabilidad de registros externos */
IF OBJECT_ID(N'mundial.registro_externo', N'U') IS NULL
BEGIN
    CREATE TABLE mundial.registro_externo
    (
        id_registro_externo BIGINT IDENTITY PRIMARY KEY,
        id_fuente INT NOT NULL,
        entidad_destino VARCHAR(128) NOT NULL,
        clave_externa VARCHAR(200) NOT NULL,
        id_registro_destino BIGINT NOT NULL,
        fecha_primera_importacion DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        fecha_ultima_importacion DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_regext_fuente FOREIGN KEY(id_fuente) REFERENCES mundial.fuente_importacion(id_fuente),
        CONSTRAINT UQ_regext UNIQUE(id_fuente, entidad_destino, clave_externa)
    );
END;
GO

/* 2. Staging de Partidos (CSV) */
IF OBJECT_ID(N'mundial.stg_partido', N'U') IS NULL
BEGIN
    CREATE TABLE mundial.stg_partido
    (
        id_stg_partido BIGINT IDENTITY PRIMARY KEY,
        id_lote INT NOT NULL,
        numero_fila INT NOT NULL,
        clave_externa NVARCHAR(200),
        fase NVARCHAR(100),
        estadio NVARCHAR(200),
        pais_local_iso NVARCHAR(20),
        pais_visitante_iso NVARCHAR(20),
        fecha_hora_utc NVARCHAR(100),
        fecha_hora_local NVARCHAR(100),
        goles_local NVARCHAR(30),
        goles_visitante NVARCHAR(30),
        asistencia_publico NVARCHAR(30),
        estado_partido NVARCHAR(50),
        CONSTRAINT FK_stgp_lote FOREIGN KEY(id_lote) REFERENCES mundial.lote_importacion(id_lote),
        CONSTRAINT UQ_stgp_lote_fila UNIQUE(id_lote, numero_fila)
    );
END;
GO

/* 3. Staging y almacenamiento de Indicadores Economicos (XML Banco Mundial) */
IF OBJECT_ID(N'mundial.stg_indicador_economico', N'U') IS NULL
BEGIN
    CREATE TABLE mundial.stg_indicador_economico
    (
        id_stg_indicador BIGINT IDENTITY PRIMARY KEY,
        id_lote INT NOT NULL,
        numero_fila INT NOT NULL,
        clave_externa NVARCHAR(200),
        codigo_pais NVARCHAR(20),
        codigo_indicador NVARCHAR(50),
        anio NVARCHAR(20),
        valor NVARCHAR(100),
        unidad NVARCHAR(50),
        fuente NVARCHAR(150),
        CONSTRAINT FK_stgi_lote FOREIGN KEY(id_lote) REFERENCES mundial.lote_importacion(id_lote),
        CONSTRAINT UQ_stgi_lote_fila UNIQUE(id_lote, numero_fila)
    );
END;
GO

IF OBJECT_ID(N'mundial.indicador_economico_pais', N'U') IS NULL
BEGIN
    CREATE TABLE mundial.indicador_economico_pais
    (
        id_indicador BIGINT IDENTITY PRIMARY KEY,
        id_pais INT NOT NULL,
        id_lote INT NOT NULL,
        codigo_indicador VARCHAR(50) NOT NULL,
        anio SMALLINT NOT NULL,
        valor DECIMAL(20,4) NOT NULL,
        unidad VARCHAR(50) NOT NULL,
        fuente VARCHAR(150) NOT NULL,
        fecha_importacion DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_indeco_pais FOREIGN KEY(id_pais) REFERENCES mundial.pais(id_pais),
        CONSTRAINT FK_indeco_lote FOREIGN KEY(id_lote) REFERENCES mundial.lote_importacion(id_lote),
        CONSTRAINT UQ_indeco UNIQUE(id_pais, codigo_indicador, anio, fuente),
        CONSTRAINT CK_indeco_anio CHECK(anio BETWEEN 1900 AND 2100),
        CONSTRAINT CK_indeco_valor CHECK(valor >= 0)
    );
END;
GO

/* 4. Staging de Arbitros (Scraping Wikipedia) */
IF OBJECT_ID(N'mundial.stg_arbitro', N'U') IS NULL
BEGIN
    CREATE TABLE mundial.stg_arbitro
    (
        id_stg_arbitro BIGINT IDENTITY PRIMARY KEY,
        id_lote INT NOT NULL,
        numero_fila INT NOT NULL,
        clave_externa NVARCHAR(200) NULL,
        nombres NVARCHAR(200) NULL,
        apellidos NVARCHAR(200) NULL,
        codigo_pais NVARCHAR(20) NULL,
        confederacion NVARCHAR(100) NULL,
        categoria NVARCHAR(100) NULL,
        fecha_nacimiento NVARCHAR(100) NULL,
        ediciones_mundial NVARCHAR(500) NULL,
        CONSTRAINT FK_stgarb_lote FOREIGN KEY(id_lote) REFERENCES mundial.lote_importacion(id_lote),
        CONSTRAINT UQ_stgarb_lote_fila UNIQUE(id_lote, numero_fila)
    );
END;
GO

/* 5. Tabla operativa y staging de Tipos de Cambio (API Frankfurter) */
IF OBJECT_ID(N'mundial.tipo_cambio', N'U') IS NULL
BEGIN
    CREATE TABLE mundial.tipo_cambio
    (
        id_tipo_cambio BIGINT IDENTITY(1,1) NOT NULL,
        id_moneda_origen INT NOT NULL,
        id_moneda_destino INT NOT NULL,
        id_lote INT NOT NULL,
        fecha_cotizacion DATE NOT NULL,
        cotizacion DECIMAL(18,8) NOT NULL,
        fuente VARCHAR(100) NOT NULL,
        CONSTRAINT PK_tipo_cambio PRIMARY KEY(id_tipo_cambio),
        CONSTRAINT FK_tipocambio_origen FOREIGN KEY(id_moneda_origen) REFERENCES mundial.moneda(id_moneda),
        CONSTRAINT FK_tipocambio_destino FOREIGN KEY(id_moneda_destino) REFERENCES mundial.moneda(id_moneda),
        CONSTRAINT FK_tipocambio_lote FOREIGN KEY(id_lote) REFERENCES mundial.lote_importacion(id_lote),
        CONSTRAINT UQ_tipocambio UNIQUE(id_moneda_origen, id_moneda_destino, fecha_cotizacion, fuente),
        CONSTRAINT CK_tipocambio_valor CHECK(cotizacion > 0),
        CONSTRAINT CK_tipocambio_monedas CHECK(id_moneda_origen <> id_moneda_destino)
    );
END;
GO

IF OBJECT_ID(N'mundial.stg_tipo_cambio', N'U') IS NULL
BEGIN
    CREATE TABLE mundial.stg_tipo_cambio
    (
        id_stg_tipo_cambio BIGINT IDENTITY PRIMARY KEY,
        id_lote INT NOT NULL,
        numero_fila INT NOT NULL,
        moneda_origen NVARCHAR(20) NULL,
        moneda_destino NVARCHAR(20) NULL,
        fecha_cotizacion NVARCHAR(30) NULL,
        cotizacion NVARCHAR(100) NULL,
        fuente NVARCHAR(100) NULL,
        CONSTRAINT FK_stgtc_lote FOREIGN KEY(id_lote) REFERENCES mundial.lote_importacion(id_lote),
        CONSTRAINT UQ_stgtc_lote_fila UNIQUE(id_lote, numero_fila)
    );
END;
GO

/* 6. Indices de rendimiento */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_stgp_lote' AND object_id = OBJECT_ID('mundial.stg_partido'))
    CREATE INDEX IX_stgp_lote ON mundial.stg_partido(id_lote);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_stgi_lote' AND object_id = OBJECT_ID('mundial.stg_indicador_economico'))
    CREATE INDEX IX_stgi_lote ON mundial.stg_indicador_economico(id_lote);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_stgarb_lote' AND object_id = OBJECT_ID('mundial.stg_arbitro'))
    CREATE INDEX IX_stgarb_lote ON mundial.stg_arbitro(id_lote);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_stgtc_lote' AND object_id = OBJECT_ID('mundial.stg_tipo_cambio'))
    CREATE INDEX IX_stgtc_lote ON mundial.stg_tipo_cambio(id_lote);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tipocambio_lote' AND object_id = OBJECT_ID('mundial.tipo_cambio'))
    CREATE INDEX IX_tipocambio_lote ON mundial.tipo_cambio(id_lote);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_detalle_lote_estado' AND object_id = OBJECT_ID('mundial.detalle_importacion'))
    CREATE INDEX IX_detalle_lote_estado ON mundial.detalle_importacion(id_lote, estado_registro);
GO
