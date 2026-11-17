 /*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-16
    Objetos auxiliares set-based.
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
CREATE TABLE mundial.registro_externo(
 id_registro_externo BIGINT IDENTITY PRIMARY KEY,id_fuente INT NOT NULL,
 entidad_destino VARCHAR(128) NOT NULL,clave_externa VARCHAR(200) NOT NULL,
 id_registro_destino BIGINT NOT NULL,fecha_primera_importacion DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
 fecha_ultima_importacion DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
 CONSTRAINT FK_regext_fuente FOREIGN KEY(id_fuente) REFERENCES mundial.fuente_importacion(id_fuente),
 CONSTRAINT UQ_regext UNIQUE(id_fuente,entidad_destino,clave_externa));
GO
CREATE TABLE mundial.stg_partido(
 id_stg_partido BIGINT IDENTITY PRIMARY KEY,id_lote INT NOT NULL,numero_fila INT NOT NULL,
 clave_externa NVARCHAR(200),fase NVARCHAR(100),estadio NVARCHAR(200),pais_local_iso NVARCHAR(20),
 pais_visitante_iso NVARCHAR(20),fecha_hora_utc NVARCHAR(100),fecha_hora_local NVARCHAR(100),
 goles_local NVARCHAR(30),goles_visitante NVARCHAR(30),asistencia_publico NVARCHAR(30),estado_partido NVARCHAR(50),
 CONSTRAINT FK_stgp_lote FOREIGN KEY(id_lote) REFERENCES mundial.lote_importacion(id_lote),
 CONSTRAINT UQ_stgp_lote_fila UNIQUE(id_lote,numero_fila));
GO
CREATE TABLE mundial.stg_indicador_economico(
 id_stg_indicador BIGINT IDENTITY PRIMARY KEY,id_lote INT NOT NULL,numero_fila INT NOT NULL,
 clave_externa NVARCHAR(200),codigo_pais NVARCHAR(20),codigo_indicador NVARCHAR(50),anio NVARCHAR(20),
 valor NVARCHAR(100),unidad NVARCHAR(50),fuente NVARCHAR(150),
 CONSTRAINT FK_stgi_lote FOREIGN KEY(id_lote) REFERENCES mundial.lote_importacion(id_lote),
 CONSTRAINT UQ_stgi_lote_fila UNIQUE(id_lote,numero_fila));
GO
CREATE TABLE mundial.indicador_economico_pais(
 id_indicador BIGINT IDENTITY PRIMARY KEY,id_pais INT NOT NULL,id_lote INT NOT NULL,
 codigo_indicador VARCHAR(50) NOT NULL,anio SMALLINT NOT NULL,valor DECIMAL(20,4) NOT NULL,
 unidad VARCHAR(50) NOT NULL,fuente VARCHAR(150) NOT NULL,fecha_importacion DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
 CONSTRAINT FK_indeco_pais FOREIGN KEY(id_pais) REFERENCES mundial.pais(id_pais),
 CONSTRAINT FK_indeco_lote FOREIGN KEY(id_lote) REFERENCES mundial.lote_importacion(id_lote),
 CONSTRAINT UQ_indeco UNIQUE(id_pais,codigo_indicador,anio,fuente),
 CONSTRAINT CK_indeco_anio CHECK(anio BETWEEN 1900 AND 2100),CONSTRAINT CK_indeco_valor CHECK(valor>=0));
GO
CREATE INDEX IX_stgp_lote ON mundial.stg_partido(id_lote);
CREATE INDEX IX_stgi_lote ON mundial.stg_indicador_economico(id_lote);
CREATE INDEX IX_detalle_lote_estado ON mundial.detalle_importacion(id_lote,estado_registro);
GO
