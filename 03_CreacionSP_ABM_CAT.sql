/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-16
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ===== CONFEDERACION ===== */
CREATE OR ALTER PROCEDURE mundial.sp_confederacion_Alta
    @nombre VARCHAR(100),
    @sigla VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @nombre IS NULL SET @Errores += N'El campo nombre es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL SET @Errores += N'El campo nombre no puede estar vacío. ';
    IF @sigla IS NULL SET @Errores += N'El campo sigla es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@sigla)), '') IS NULL SET @Errores += N'El campo sigla no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.confederacion (nombre, sigla) VALUES (@nombre, @sigla);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_confederacion_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_confederacion_Modificar
    @id_confederacion INT,
    @nombre VARCHAR(100),
    @sigla VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.confederacion WHERE id_confederacion=@id_confederacion) SET @Errores += N'El registro no existe. ';
    IF @nombre IS NULL SET @Errores += N'El campo nombre es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL SET @Errores += N'El campo nombre no puede estar vacío. ';
    IF @sigla IS NULL SET @Errores += N'El campo sigla es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@sigla)), '') IS NULL SET @Errores += N'El campo sigla no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.confederacion SET nombre=@nombre,
            sigla=@sigla WHERE id_confederacion=@id_confederacion;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_confederacion_Baja
    @id_confederacion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.confederacion WHERE id_confederacion=@id_confederacion) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.confederacion WHERE id_confederacion=@id_confederacion;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_confederacion_Consultar
    @id_confederacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.confederacion WHERE (@id_confederacion IS NULL OR id_confederacion=@id_confederacion) ORDER BY id_confederacion;
END;
GO

/* ===== PAIS ===== */
CREATE OR ALTER PROCEDURE mundial.sp_pais_Alta
    @id_confederacion INT,
    @nombre VARCHAR(100),
    @codigo_iso CHAR(3),
    @huso_horario_estandar VARCHAR(100),
    @pbi_per_capita DECIMAL(18,2) = NULL,
    @codigo_moneda CHAR(3)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_confederacion IS NULL SET @Errores += N'El campo id_confederacion es obligatorio. ';
    IF @id_confederacion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.confederacion WHERE id_confederacion=@id_confederacion) SET @Errores += N'La referencia id_confederacion no existe. ';
    IF @nombre IS NULL SET @Errores += N'El campo nombre es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL SET @Errores += N'El campo nombre no puede estar vacío. ';
    IF @codigo_iso IS NULL SET @Errores += N'El campo codigo_iso es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@codigo_iso)), '') IS NULL SET @Errores += N'El campo codigo_iso no puede estar vacío. ';
    IF @huso_horario_estandar IS NULL SET @Errores += N'El campo huso_horario_estandar es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@huso_horario_estandar)), '') IS NULL SET @Errores += N'El campo huso_horario_estandar no puede estar vacío. ';
    IF @codigo_moneda IS NULL SET @Errores += N'El campo codigo_moneda es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@codigo_moneda)), '') IS NULL SET @Errores += N'El campo codigo_moneda no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.pais (id_confederacion, nombre, codigo_iso, huso_horario_estandar, pbi_per_capita, codigo_moneda) VALUES (@id_confederacion, @nombre, @codigo_iso, @huso_horario_estandar, @pbi_per_capita, @codigo_moneda);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_pais_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_pais_Modificar
    @id_pais INT,
    @id_confederacion INT,
    @nombre VARCHAR(100),
    @codigo_iso CHAR(3),
    @huso_horario_estandar VARCHAR(100),
    @pbi_per_capita DECIMAL(18,2) = NULL,
    @codigo_moneda CHAR(3)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais) SET @Errores += N'El registro no existe. ';
    IF @id_confederacion IS NULL SET @Errores += N'El campo id_confederacion es obligatorio. ';
    IF @id_confederacion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.confederacion WHERE id_confederacion=@id_confederacion) SET @Errores += N'La referencia id_confederacion no existe. ';
    IF @nombre IS NULL SET @Errores += N'El campo nombre es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL SET @Errores += N'El campo nombre no puede estar vacío. ';
    IF @codigo_iso IS NULL SET @Errores += N'El campo codigo_iso es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@codigo_iso)), '') IS NULL SET @Errores += N'El campo codigo_iso no puede estar vacío. ';
    IF @huso_horario_estandar IS NULL SET @Errores += N'El campo huso_horario_estandar es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@huso_horario_estandar)), '') IS NULL SET @Errores += N'El campo huso_horario_estandar no puede estar vacío. ';
    IF @codigo_moneda IS NULL SET @Errores += N'El campo codigo_moneda es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@codigo_moneda)), '') IS NULL SET @Errores += N'El campo codigo_moneda no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.pais SET id_confederacion=@id_confederacion,
            nombre=@nombre,
            codigo_iso=@codigo_iso,
            huso_horario_estandar=@huso_horario_estandar,
            pbi_per_capita=@pbi_per_capita,
            codigo_moneda=@codigo_moneda WHERE id_pais=@id_pais;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_pais_Baja
    @id_pais INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.pais WHERE id_pais=@id_pais;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_pais_Consultar
    @id_pais INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.pais WHERE (@id_pais IS NULL OR id_pais=@id_pais) ORDER BY id_pais;
END;
GO

/* ===== CIUDAD ===== */
CREATE OR ALTER PROCEDURE mundial.sp_ciudad_Alta
    @id_pais INT,
    @nombre VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_pais IS NULL SET @Errores += N'El campo id_pais es obligatorio. ';
    IF @id_pais IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais) SET @Errores += N'La referencia id_pais no existe. ';
    IF @nombre IS NULL SET @Errores += N'El campo nombre es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL SET @Errores += N'El campo nombre no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.ciudad (id_pais, nombre) VALUES (@id_pais, @nombre);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_ciudad_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_ciudad_Modificar
    @id_ciudad INT,
    @id_pais INT,
    @nombre VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.ciudad WHERE id_ciudad=@id_ciudad) SET @Errores += N'El registro no existe. ';
    IF @id_pais IS NULL SET @Errores += N'El campo id_pais es obligatorio. ';
    IF @id_pais IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais) SET @Errores += N'La referencia id_pais no existe. ';
    IF @nombre IS NULL SET @Errores += N'El campo nombre es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL SET @Errores += N'El campo nombre no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.ciudad SET id_pais=@id_pais,
            nombre=@nombre WHERE id_ciudad=@id_ciudad;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_ciudad_Baja
    @id_ciudad INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.ciudad WHERE id_ciudad=@id_ciudad) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.ciudad WHERE id_ciudad=@id_ciudad;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_ciudad_Consultar
    @id_ciudad INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.ciudad WHERE (@id_ciudad IS NULL OR id_ciudad=@id_ciudad) ORDER BY id_ciudad;
END;
GO

/* ===== SEDE_ESTADIO ===== */
CREATE OR ALTER PROCEDURE mundial.sp_sede_estadio_Alta
    @id_ciudad INT,
    @nombre_estadio VARCHAR(150),
    @capacidad INT,
    @huso_horario VARCHAR(100),
    @latitud DECIMAL(9,6),
    @longitud DECIMAL(9,6)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_ciudad IS NULL SET @Errores += N'El campo id_ciudad es obligatorio. ';
    IF @id_ciudad IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.ciudad WHERE id_ciudad=@id_ciudad) SET @Errores += N'La referencia id_ciudad no existe. ';
    IF @nombre_estadio IS NULL SET @Errores += N'El campo nombre_estadio es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre_estadio)), '') IS NULL SET @Errores += N'El campo nombre_estadio no puede estar vacío. ';
    IF @capacidad IS NULL SET @Errores += N'El campo capacidad es obligatorio. ';
    IF @huso_horario IS NULL SET @Errores += N'El campo huso_horario es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@huso_horario)), '') IS NULL SET @Errores += N'El campo huso_horario no puede estar vacío. ';
    IF @latitud IS NULL SET @Errores += N'El campo latitud es obligatorio. ';
    IF @longitud IS NULL SET @Errores += N'El campo longitud es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.sede_estadio (id_ciudad, nombre_estadio, capacidad, huso_horario, latitud, longitud) VALUES (@id_ciudad, @nombre_estadio, @capacidad, @huso_horario, @latitud, @longitud);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_sede_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_sede_estadio_Modificar
    @id_sede INT,
    @id_ciudad INT,
    @nombre_estadio VARCHAR(150),
    @capacidad INT,
    @huso_horario VARCHAR(100),
    @latitud DECIMAL(9,6),
    @longitud DECIMAL(9,6)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.sede_estadio WHERE id_sede=@id_sede) SET @Errores += N'El registro no existe. ';
    IF @id_ciudad IS NULL SET @Errores += N'El campo id_ciudad es obligatorio. ';
    IF @id_ciudad IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.ciudad WHERE id_ciudad=@id_ciudad) SET @Errores += N'La referencia id_ciudad no existe. ';
    IF @nombre_estadio IS NULL SET @Errores += N'El campo nombre_estadio es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre_estadio)), '') IS NULL SET @Errores += N'El campo nombre_estadio no puede estar vacío. ';
    IF @capacidad IS NULL SET @Errores += N'El campo capacidad es obligatorio. ';
    IF @huso_horario IS NULL SET @Errores += N'El campo huso_horario es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@huso_horario)), '') IS NULL SET @Errores += N'El campo huso_horario no puede estar vacío. ';
    IF @latitud IS NULL SET @Errores += N'El campo latitud es obligatorio. ';
    IF @longitud IS NULL SET @Errores += N'El campo longitud es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.sede_estadio SET id_ciudad=@id_ciudad,
            nombre_estadio=@nombre_estadio,
            capacidad=@capacidad,
            huso_horario=@huso_horario,
            latitud=@latitud,
            longitud=@longitud WHERE id_sede=@id_sede;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_sede_estadio_Baja
    @id_sede INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.sede_estadio WHERE id_sede=@id_sede) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.sede_estadio WHERE id_sede=@id_sede;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_sede_estadio_Consultar
    @id_sede INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.sede_estadio WHERE (@id_sede IS NULL OR id_sede=@id_sede) ORDER BY id_sede;
END;
GO

/* ===== GRUPO ===== */
CREATE OR ALTER PROCEDURE mundial.sp_grupo_Alta
    @nombre_grupo VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @nombre_grupo IS NULL SET @Errores += N'El campo nombre_grupo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre_grupo)), '') IS NULL SET @Errores += N'El campo nombre_grupo no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.grupo (nombre_grupo) VALUES (@nombre_grupo);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_grupo_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_grupo_Modificar
    @id_grupo INT,
    @nombre_grupo VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.grupo WHERE id_grupo=@id_grupo) SET @Errores += N'El registro no existe. ';
    IF @nombre_grupo IS NULL SET @Errores += N'El campo nombre_grupo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre_grupo)), '') IS NULL SET @Errores += N'El campo nombre_grupo no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.grupo SET nombre_grupo=@nombre_grupo WHERE id_grupo=@id_grupo;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_grupo_Baja
    @id_grupo INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.grupo WHERE id_grupo=@id_grupo) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.grupo WHERE id_grupo=@id_grupo;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_grupo_Consultar
    @id_grupo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.grupo WHERE (@id_grupo IS NULL OR id_grupo=@id_grupo) ORDER BY id_grupo;
END;
GO

/* ===== REGLAMENTO_SUSTITUCION ===== */
CREATE OR ALTER PROCEDURE mundial.sp_reglamento_sustitucion_Alta
    @nombre VARCHAR(100),
    @maximo_cambios TINYINT,
    @maximo_ventanas TINYINT,
    @cambios_adicionales_suplementario TINYINT,
    @ventanas_adicionales_suplementario TINYINT,
    @entretiempo_computa_ventana BIT,
    @intervalo_suplementario_computa_ventana BIT,
    @fecha_vigencia_desde DATE,
    @fecha_vigencia_hasta DATE = NULL,
    @activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @nombre IS NULL SET @Errores += N'El campo nombre es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL SET @Errores += N'El campo nombre no puede estar vacío. ';
    IF @maximo_cambios IS NULL SET @Errores += N'El campo maximo_cambios es obligatorio. ';
    IF @maximo_ventanas IS NULL SET @Errores += N'El campo maximo_ventanas es obligatorio. ';
    IF @cambios_adicionales_suplementario IS NULL SET @Errores += N'El campo cambios_adicionales_suplementario es obligatorio. ';
    IF @ventanas_adicionales_suplementario IS NULL SET @Errores += N'El campo ventanas_adicionales_suplementario es obligatorio. ';
    IF @entretiempo_computa_ventana IS NULL SET @Errores += N'El campo entretiempo_computa_ventana es obligatorio. ';
    IF @intervalo_suplementario_computa_ventana IS NULL SET @Errores += N'El campo intervalo_suplementario_computa_ventana es obligatorio. ';
    IF @fecha_vigencia_desde IS NULL SET @Errores += N'El campo fecha_vigencia_desde es obligatorio. ';
    IF @activo IS NULL SET @Errores += N'El campo activo es obligatorio. ';
    IF @fecha_vigencia_hasta IS NOT NULL AND @fecha_vigencia_hasta<@fecha_vigencia_desde SET @Errores += N'Vigencia inválida. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.reglamento_sustitucion (nombre, maximo_cambios, maximo_ventanas, cambios_adicionales_suplementario, ventanas_adicionales_suplementario, entretiempo_computa_ventana, intervalo_suplementario_computa_ventana, fecha_vigencia_desde, fecha_vigencia_hasta, activo) VALUES (@nombre, @maximo_cambios, @maximo_ventanas, @cambios_adicionales_suplementario, @ventanas_adicionales_suplementario, @entretiempo_computa_ventana, @intervalo_suplementario_computa_ventana, @fecha_vigencia_desde, @fecha_vigencia_hasta, @activo);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_reglamento_sustitucion_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_reglamento_sustitucion_Modificar
    @id_reglamento_sustitucion INT,
    @nombre VARCHAR(100),
    @maximo_cambios TINYINT,
    @maximo_ventanas TINYINT,
    @cambios_adicionales_suplementario TINYINT,
    @ventanas_adicionales_suplementario TINYINT,
    @entretiempo_computa_ventana BIT,
    @intervalo_suplementario_computa_ventana BIT,
    @fecha_vigencia_desde DATE,
    @fecha_vigencia_hasta DATE = NULL,
    @activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.reglamento_sustitucion WHERE id_reglamento_sustitucion=@id_reglamento_sustitucion) SET @Errores += N'El registro no existe. ';
    IF @nombre IS NULL SET @Errores += N'El campo nombre es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL SET @Errores += N'El campo nombre no puede estar vacío. ';
    IF @maximo_cambios IS NULL SET @Errores += N'El campo maximo_cambios es obligatorio. ';
    IF @maximo_ventanas IS NULL SET @Errores += N'El campo maximo_ventanas es obligatorio. ';
    IF @cambios_adicionales_suplementario IS NULL SET @Errores += N'El campo cambios_adicionales_suplementario es obligatorio. ';
    IF @ventanas_adicionales_suplementario IS NULL SET @Errores += N'El campo ventanas_adicionales_suplementario es obligatorio. ';
    IF @entretiempo_computa_ventana IS NULL SET @Errores += N'El campo entretiempo_computa_ventana es obligatorio. ';
    IF @intervalo_suplementario_computa_ventana IS NULL SET @Errores += N'El campo intervalo_suplementario_computa_ventana es obligatorio. ';
    IF @fecha_vigencia_desde IS NULL SET @Errores += N'El campo fecha_vigencia_desde es obligatorio. ';
    IF @activo IS NULL SET @Errores += N'El campo activo es obligatorio. ';
    IF @fecha_vigencia_hasta IS NOT NULL AND @fecha_vigencia_hasta<@fecha_vigencia_desde SET @Errores += N'Vigencia inválida. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.reglamento_sustitucion SET nombre=@nombre,
            maximo_cambios=@maximo_cambios,
            maximo_ventanas=@maximo_ventanas,
            cambios_adicionales_suplementario=@cambios_adicionales_suplementario,
            ventanas_adicionales_suplementario=@ventanas_adicionales_suplementario,
            entretiempo_computa_ventana=@entretiempo_computa_ventana,
            intervalo_suplementario_computa_ventana=@intervalo_suplementario_computa_ventana,
            fecha_vigencia_desde=@fecha_vigencia_desde,
            fecha_vigencia_hasta=@fecha_vigencia_hasta,
            activo=@activo WHERE id_reglamento_sustitucion=@id_reglamento_sustitucion;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_reglamento_sustitucion_Baja
    @id_reglamento_sustitucion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.reglamento_sustitucion WHERE id_reglamento_sustitucion=@id_reglamento_sustitucion) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.reglamento_sustitucion WHERE id_reglamento_sustitucion=@id_reglamento_sustitucion;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_reglamento_sustitucion_Consultar
    @id_reglamento_sustitucion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.reglamento_sustitucion WHERE (@id_reglamento_sustitucion IS NULL OR id_reglamento_sustitucion=@id_reglamento_sustitucion) ORDER BY id_reglamento_sustitucion;
END;
GO

/* ===== FASE ===== */
CREATE OR ALTER PROCEDURE mundial.sp_fase_Alta
    @id_reglamento_sustitucion INT,
    @nombre_fase VARCHAR(50),
    @orden TINYINT,
    @permite_alargue BIT,
    @permite_penales BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_reglamento_sustitucion IS NULL SET @Errores += N'El campo id_reglamento_sustitucion es obligatorio. ';
    IF @id_reglamento_sustitucion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.reglamento_sustitucion WHERE id_reglamento_sustitucion=@id_reglamento_sustitucion) SET @Errores += N'La referencia id_reglamento_sustitucion no existe. ';
    IF @nombre_fase IS NULL SET @Errores += N'El campo nombre_fase es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre_fase)), '') IS NULL SET @Errores += N'El campo nombre_fase no puede estar vacío. ';
    IF @orden IS NULL SET @Errores += N'El campo orden es obligatorio. ';
    IF @permite_alargue IS NULL SET @Errores += N'El campo permite_alargue es obligatorio. ';
    IF @permite_penales IS NULL SET @Errores += N'El campo permite_penales es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.fase (id_reglamento_sustitucion, nombre_fase, orden, permite_alargue, permite_penales) VALUES (@id_reglamento_sustitucion, @nombre_fase, @orden, @permite_alargue, @permite_penales);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_fase_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_fase_Modificar
    @id_fase INT,
    @id_reglamento_sustitucion INT,
    @nombre_fase VARCHAR(50),
    @orden TINYINT,
    @permite_alargue BIT,
    @permite_penales BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.fase WHERE id_fase=@id_fase) SET @Errores += N'El registro no existe. ';
    IF @id_reglamento_sustitucion IS NULL SET @Errores += N'El campo id_reglamento_sustitucion es obligatorio. ';
    IF @id_reglamento_sustitucion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.reglamento_sustitucion WHERE id_reglamento_sustitucion=@id_reglamento_sustitucion) SET @Errores += N'La referencia id_reglamento_sustitucion no existe. ';
    IF @nombre_fase IS NULL SET @Errores += N'El campo nombre_fase es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre_fase)), '') IS NULL SET @Errores += N'El campo nombre_fase no puede estar vacío. ';
    IF @orden IS NULL SET @Errores += N'El campo orden es obligatorio. ';
    IF @permite_alargue IS NULL SET @Errores += N'El campo permite_alargue es obligatorio. ';
    IF @permite_penales IS NULL SET @Errores += N'El campo permite_penales es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.fase SET id_reglamento_sustitucion=@id_reglamento_sustitucion,
            nombre_fase=@nombre_fase,
            orden=@orden,
            permite_alargue=@permite_alargue,
            permite_penales=@permite_penales WHERE id_fase=@id_fase;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_fase_Baja
    @id_fase INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.fase WHERE id_fase=@id_fase) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.fase WHERE id_fase=@id_fase;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_fase_Consultar
    @id_fase INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.fase WHERE (@id_fase IS NULL OR id_fase=@id_fase) ORDER BY id_fase;
END;
GO

/* ===== SELECCION ===== */
CREATE OR ALTER PROCEDURE mundial.sp_seleccion_Alta
    @id_pais INT,
    @id_grupo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_pais IS NULL SET @Errores += N'El campo id_pais es obligatorio. ';
    IF @id_pais IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais) SET @Errores += N'La referencia id_pais no existe. ';
    IF @id_grupo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.grupo WHERE id_grupo=@id_grupo) SET @Errores += N'La referencia id_grupo no existe. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.seleccion (id_pais, id_grupo) VALUES (@id_pais, @id_grupo);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_seleccion_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_seleccion_Modificar
    @id_seleccion INT,
    @id_pais INT,
    @id_grupo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion) SET @Errores += N'El registro no existe. ';
    IF @id_pais IS NULL SET @Errores += N'El campo id_pais es obligatorio. ';
    IF @id_pais IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais) SET @Errores += N'La referencia id_pais no existe. ';
    IF @id_grupo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.grupo WHERE id_grupo=@id_grupo) SET @Errores += N'La referencia id_grupo no existe. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.seleccion SET id_pais=@id_pais,
            id_grupo=@id_grupo WHERE id_seleccion=@id_seleccion;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_seleccion_Baja
    @id_seleccion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.seleccion WHERE id_seleccion=@id_seleccion;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_seleccion_Consultar
    @id_seleccion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.seleccion WHERE (@id_seleccion IS NULL OR id_seleccion=@id_seleccion) ORDER BY id_seleccion;
END;
GO

/* ===== CLUB ===== */
CREATE OR ALTER PROCEDURE mundial.sp_club_Alta
    @id_pais INT,
    @nombre_club VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_pais IS NULL SET @Errores += N'El campo id_pais es obligatorio. ';
    IF @id_pais IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais) SET @Errores += N'La referencia id_pais no existe. ';
    IF @nombre_club IS NULL SET @Errores += N'El campo nombre_club es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre_club)), '') IS NULL SET @Errores += N'El campo nombre_club no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.club (id_pais, nombre_club) VALUES (@id_pais, @nombre_club);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_club_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_club_Modificar
    @id_club INT,
    @id_pais INT,
    @nombre_club VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.club WHERE id_club=@id_club) SET @Errores += N'El registro no existe. ';
    IF @id_pais IS NULL SET @Errores += N'El campo id_pais es obligatorio. ';
    IF @id_pais IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais) SET @Errores += N'La referencia id_pais no existe. ';
    IF @nombre_club IS NULL SET @Errores += N'El campo nombre_club es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre_club)), '') IS NULL SET @Errores += N'El campo nombre_club no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.club SET id_pais=@id_pais,
            nombre_club=@nombre_club WHERE id_club=@id_club;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_club_Baja
    @id_club INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.club WHERE id_club=@id_club) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.club WHERE id_club=@id_club;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_club_Consultar
    @id_club INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.club WHERE (@id_club IS NULL OR id_club=@id_club) ORDER BY id_club;
END;
GO

/* ===== POSICION ===== */
CREATE OR ALTER PROCEDURE mundial.sp_posicion_Alta
    @codigo VARCHAR(10),
    @descripcion VARCHAR(100),
    @linea_campo VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @codigo IS NULL SET @Errores += N'El campo codigo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@codigo)), '') IS NULL SET @Errores += N'El campo codigo no puede estar vacío. ';
    IF @descripcion IS NULL SET @Errores += N'El campo descripcion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL SET @Errores += N'El campo descripcion no puede estar vacío. ';
    IF @linea_campo IS NULL SET @Errores += N'El campo linea_campo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@linea_campo)), '') IS NULL SET @Errores += N'El campo linea_campo no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.posicion (codigo, descripcion, linea_campo) VALUES (@codigo, @descripcion, @linea_campo);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_posicion_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_posicion_Modificar
    @id_posicion INT,
    @codigo VARCHAR(10),
    @descripcion VARCHAR(100),
    @linea_campo VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.posicion WHERE id_posicion=@id_posicion) SET @Errores += N'El registro no existe. ';
    IF @codigo IS NULL SET @Errores += N'El campo codigo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@codigo)), '') IS NULL SET @Errores += N'El campo codigo no puede estar vacío. ';
    IF @descripcion IS NULL SET @Errores += N'El campo descripcion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL SET @Errores += N'El campo descripcion no puede estar vacío. ';
    IF @linea_campo IS NULL SET @Errores += N'El campo linea_campo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@linea_campo)), '') IS NULL SET @Errores += N'El campo linea_campo no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.posicion SET codigo=@codigo,
            descripcion=@descripcion,
            linea_campo=@linea_campo WHERE id_posicion=@id_posicion;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_posicion_Baja
    @id_posicion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.posicion WHERE id_posicion=@id_posicion) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.posicion WHERE id_posicion=@id_posicion;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_posicion_Consultar
    @id_posicion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.posicion WHERE (@id_posicion IS NULL OR id_posicion=@id_posicion) ORDER BY id_posicion;
END;
GO

/* ===== JUGADOR ===== */
CREATE OR ALTER PROCEDURE mundial.sp_jugador_Alta
    @id_pais_nacionalidad INT,
    @id_club INT,
    @id_posicion_habitual INT,
    @nombres VARCHAR(100),
    @apellidos VARCHAR(100),
    @fecha_nacimiento DATE,
    @doc_identidad VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_pais_nacionalidad IS NULL SET @Errores += N'El campo id_pais_nacionalidad es obligatorio. ';
    IF @id_pais_nacionalidad IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais_nacionalidad) SET @Errores += N'La referencia id_pais_nacionalidad no existe. ';
    IF @id_club IS NULL SET @Errores += N'El campo id_club es obligatorio. ';
    IF @id_club IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.club WHERE id_club=@id_club) SET @Errores += N'La referencia id_club no existe. ';
    IF @id_posicion_habitual IS NULL SET @Errores += N'El campo id_posicion_habitual es obligatorio. ';
    IF @id_posicion_habitual IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.posicion WHERE id_posicion=@id_posicion_habitual) SET @Errores += N'La referencia id_posicion_habitual no existe. ';
    IF @nombres IS NULL SET @Errores += N'El campo nombres es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombres)), '') IS NULL SET @Errores += N'El campo nombres no puede estar vacío. ';
    IF @apellidos IS NULL SET @Errores += N'El campo apellidos es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@apellidos)), '') IS NULL SET @Errores += N'El campo apellidos no puede estar vacío. ';
    IF @fecha_nacimiento IS NULL SET @Errores += N'El campo fecha_nacimiento es obligatorio. ';
    IF @doc_identidad IS NULL SET @Errores += N'El campo doc_identidad es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@doc_identidad)), '') IS NULL SET @Errores += N'El campo doc_identidad no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.jugador (id_pais_nacionalidad, id_club, id_posicion_habitual, nombres, apellidos, fecha_nacimiento, doc_identidad) VALUES (@id_pais_nacionalidad, @id_club, @id_posicion_habitual, @nombres, @apellidos, @fecha_nacimiento, @doc_identidad);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_jugador_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_jugador_Modificar
    @id_jugador INT,
    @id_pais_nacionalidad INT,
    @id_club INT,
    @id_posicion_habitual INT,
    @nombres VARCHAR(100),
    @apellidos VARCHAR(100),
    @fecha_nacimiento DATE,
    @doc_identidad VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador) SET @Errores += N'El registro no existe. ';
    IF @id_pais_nacionalidad IS NULL SET @Errores += N'El campo id_pais_nacionalidad es obligatorio. ';
    IF @id_pais_nacionalidad IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais_nacionalidad) SET @Errores += N'La referencia id_pais_nacionalidad no existe. ';
    IF @id_club IS NULL SET @Errores += N'El campo id_club es obligatorio. ';
    IF @id_club IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.club WHERE id_club=@id_club) SET @Errores += N'La referencia id_club no existe. ';
    IF @id_posicion_habitual IS NULL SET @Errores += N'El campo id_posicion_habitual es obligatorio. ';
    IF @id_posicion_habitual IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.posicion WHERE id_posicion=@id_posicion_habitual) SET @Errores += N'La referencia id_posicion_habitual no existe. ';
    IF @nombres IS NULL SET @Errores += N'El campo nombres es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombres)), '') IS NULL SET @Errores += N'El campo nombres no puede estar vacío. ';
    IF @apellidos IS NULL SET @Errores += N'El campo apellidos es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@apellidos)), '') IS NULL SET @Errores += N'El campo apellidos no puede estar vacío. ';
    IF @fecha_nacimiento IS NULL SET @Errores += N'El campo fecha_nacimiento es obligatorio. ';
    IF @doc_identidad IS NULL SET @Errores += N'El campo doc_identidad es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@doc_identidad)), '') IS NULL SET @Errores += N'El campo doc_identidad no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.jugador SET id_pais_nacionalidad=@id_pais_nacionalidad,
            id_club=@id_club,
            id_posicion_habitual=@id_posicion_habitual,
            nombres=@nombres,
            apellidos=@apellidos,
            fecha_nacimiento=@fecha_nacimiento,
            doc_identidad=@doc_identidad WHERE id_jugador=@id_jugador;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_jugador_Baja
    @id_jugador INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.jugador WHERE id_jugador=@id_jugador;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_jugador_Consultar
    @id_jugador INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.jugador WHERE (@id_jugador IS NULL OR id_jugador=@id_jugador) ORDER BY id_jugador;
END;
GO

/* ===== ROL_CUERPO_TECNICO ===== */
CREATE OR ALTER PROCEDURE mundial.sp_rol_cuerpo_tecnico_Alta
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @descripcion IS NULL SET @Errores += N'El campo descripcion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL SET @Errores += N'El campo descripcion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.rol_cuerpo_tecnico (descripcion) VALUES (@descripcion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_rol_ct_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_rol_cuerpo_tecnico_Modificar
    @id_rol_ct INT,
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.rol_cuerpo_tecnico WHERE id_rol_ct=@id_rol_ct) SET @Errores += N'El registro no existe. ';
    IF @descripcion IS NULL SET @Errores += N'El campo descripcion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL SET @Errores += N'El campo descripcion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.rol_cuerpo_tecnico SET descripcion=@descripcion WHERE id_rol_ct=@id_rol_ct;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_rol_cuerpo_tecnico_Baja
    @id_rol_ct INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.rol_cuerpo_tecnico WHERE id_rol_ct=@id_rol_ct) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.rol_cuerpo_tecnico WHERE id_rol_ct=@id_rol_ct;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_rol_cuerpo_tecnico_Consultar
    @id_rol_ct INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.rol_cuerpo_tecnico WHERE (@id_rol_ct IS NULL OR id_rol_ct=@id_rol_ct) ORDER BY id_rol_ct;
END;
GO

/* ===== CUERPO_TECNICO ===== */
CREATE OR ALTER PROCEDURE mundial.sp_cuerpo_tecnico_Alta
    @id_seleccion INT,
    @id_pais_nacionalidad INT,
    @id_rol_ct INT,
    @nombres VARCHAR(100),
    @apellidos VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_seleccion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion) SET @Errores += N'La referencia id_seleccion no existe. ';
    IF @id_pais_nacionalidad IS NULL SET @Errores += N'El campo id_pais_nacionalidad es obligatorio. ';
    IF @id_pais_nacionalidad IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais_nacionalidad) SET @Errores += N'La referencia id_pais_nacionalidad no existe. ';
    IF @id_rol_ct IS NULL SET @Errores += N'El campo id_rol_ct es obligatorio. ';
    IF @id_rol_ct IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.rol_cuerpo_tecnico WHERE id_rol_ct=@id_rol_ct) SET @Errores += N'La referencia id_rol_ct no existe. ';
    IF @nombres IS NULL SET @Errores += N'El campo nombres es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombres)), '') IS NULL SET @Errores += N'El campo nombres no puede estar vacío. ';
    IF @apellidos IS NULL SET @Errores += N'El campo apellidos es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@apellidos)), '') IS NULL SET @Errores += N'El campo apellidos no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.cuerpo_tecnico (id_seleccion, id_pais_nacionalidad, id_rol_ct, nombres, apellidos) VALUES (@id_seleccion, @id_pais_nacionalidad, @id_rol_ct, @nombres, @apellidos);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_miembro_ct_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_cuerpo_tecnico_Modificar
    @id_miembro_ct INT,
    @id_seleccion INT,
    @id_pais_nacionalidad INT,
    @id_rol_ct INT,
    @nombres VARCHAR(100),
    @apellidos VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.cuerpo_tecnico WHERE id_miembro_ct=@id_miembro_ct) SET @Errores += N'El registro no existe. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_seleccion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion) SET @Errores += N'La referencia id_seleccion no existe. ';
    IF @id_pais_nacionalidad IS NULL SET @Errores += N'El campo id_pais_nacionalidad es obligatorio. ';
    IF @id_pais_nacionalidad IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais_nacionalidad) SET @Errores += N'La referencia id_pais_nacionalidad no existe. ';
    IF @id_rol_ct IS NULL SET @Errores += N'El campo id_rol_ct es obligatorio. ';
    IF @id_rol_ct IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.rol_cuerpo_tecnico WHERE id_rol_ct=@id_rol_ct) SET @Errores += N'La referencia id_rol_ct no existe. ';
    IF @nombres IS NULL SET @Errores += N'El campo nombres es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombres)), '') IS NULL SET @Errores += N'El campo nombres no puede estar vacío. ';
    IF @apellidos IS NULL SET @Errores += N'El campo apellidos es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@apellidos)), '') IS NULL SET @Errores += N'El campo apellidos no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.cuerpo_tecnico SET id_seleccion=@id_seleccion,
            id_pais_nacionalidad=@id_pais_nacionalidad,
            id_rol_ct=@id_rol_ct,
            nombres=@nombres,
            apellidos=@apellidos WHERE id_miembro_ct=@id_miembro_ct;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_cuerpo_tecnico_Baja
    @id_miembro_ct INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.cuerpo_tecnico WHERE id_miembro_ct=@id_miembro_ct) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.cuerpo_tecnico WHERE id_miembro_ct=@id_miembro_ct;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_cuerpo_tecnico_Consultar
    @id_miembro_ct INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.cuerpo_tecnico WHERE (@id_miembro_ct IS NULL OR id_miembro_ct=@id_miembro_ct) ORDER BY id_miembro_ct;
END;
GO

/* ===== CONVOCATORIA ===== */
CREATE OR ALTER PROCEDURE mundial.sp_convocatoria_Alta
    @id_seleccion INT,
    @id_jugador INT,
    @dorsal TINYINT,
    @fecha_convocatoria DATE,
    @estado_convocatoria VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_seleccion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion) SET @Errores += N'La referencia id_seleccion no existe. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_jugador IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador) SET @Errores += N'La referencia id_jugador no existe. ';
    IF @dorsal IS NULL SET @Errores += N'El campo dorsal es obligatorio. ';
    IF @fecha_convocatoria IS NULL SET @Errores += N'El campo fecha_convocatoria es obligatorio. ';
    IF @estado_convocatoria IS NULL SET @Errores += N'El campo estado_convocatoria es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@estado_convocatoria)), '') IS NULL SET @Errores += N'El campo estado_convocatoria no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.convocatoria (id_seleccion, id_jugador, dorsal, fecha_convocatoria, estado_convocatoria) VALUES (@id_seleccion, @id_jugador, @dorsal, @fecha_convocatoria, @estado_convocatoria);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_convocatoria_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_convocatoria_Modificar
    @id_convocatoria INT,
    @id_seleccion INT,
    @id_jugador INT,
    @dorsal TINYINT,
    @fecha_convocatoria DATE,
    @estado_convocatoria VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.convocatoria WHERE id_convocatoria=@id_convocatoria) SET @Errores += N'El registro no existe. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_seleccion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion) SET @Errores += N'La referencia id_seleccion no existe. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_jugador IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador) SET @Errores += N'La referencia id_jugador no existe. ';
    IF @dorsal IS NULL SET @Errores += N'El campo dorsal es obligatorio. ';
    IF @fecha_convocatoria IS NULL SET @Errores += N'El campo fecha_convocatoria es obligatorio. ';
    IF @estado_convocatoria IS NULL SET @Errores += N'El campo estado_convocatoria es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@estado_convocatoria)), '') IS NULL SET @Errores += N'El campo estado_convocatoria no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.convocatoria SET id_seleccion=@id_seleccion,
            id_jugador=@id_jugador,
            dorsal=@dorsal,
            fecha_convocatoria=@fecha_convocatoria,
            estado_convocatoria=@estado_convocatoria WHERE id_convocatoria=@id_convocatoria;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_convocatoria_Baja
    @id_convocatoria INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.convocatoria WHERE id_convocatoria=@id_convocatoria) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.convocatoria WHERE id_convocatoria=@id_convocatoria;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_convocatoria_Consultar
    @id_convocatoria INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.convocatoria WHERE (@id_convocatoria IS NULL OR id_convocatoria=@id_convocatoria) ORDER BY id_convocatoria;
END;
GO

/* ===== NOVEDAD_CONVOCATORIA ===== */
CREATE OR ALTER PROCEDURE mundial.sp_novedad_convocatoria_Alta
    @id_convocatoria_baja INT,
    @id_convocatoria_alta INT,
    @motivo VARCHAR(200),
    @fecha_cambio DATETIME2(0),
    @dictamen_medico VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_convocatoria_baja IS NULL SET @Errores += N'El campo id_convocatoria_baja es obligatorio. ';
    IF @id_convocatoria_baja IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.convocatoria WHERE id_convocatoria=@id_convocatoria_baja) SET @Errores += N'La referencia id_convocatoria_baja no existe. ';
    IF @id_convocatoria_alta IS NULL SET @Errores += N'El campo id_convocatoria_alta es obligatorio. ';
    IF @id_convocatoria_alta IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.convocatoria WHERE id_convocatoria=@id_convocatoria_alta) SET @Errores += N'La referencia id_convocatoria_alta no existe. ';
    IF @motivo IS NULL SET @Errores += N'El campo motivo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@motivo)), '') IS NULL SET @Errores += N'El campo motivo no puede estar vacío. ';
    IF @fecha_cambio IS NULL SET @Errores += N'El campo fecha_cambio es obligatorio. ';
    IF @id_convocatoria_baja=@id_convocatoria_alta SET @Errores += N'Las convocatorias de baja y alta deben ser distintas. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.novedad_convocatoria (id_convocatoria_baja, id_convocatoria_alta, motivo, fecha_cambio, dictamen_medico) VALUES (@id_convocatoria_baja, @id_convocatoria_alta, @motivo, @fecha_cambio, @dictamen_medico);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_novedad_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_novedad_convocatoria_Modificar
    @id_novedad INT,
    @id_convocatoria_baja INT,
    @id_convocatoria_alta INT,
    @motivo VARCHAR(200),
    @fecha_cambio DATETIME2(0),
    @dictamen_medico VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.novedad_convocatoria WHERE id_novedad=@id_novedad) SET @Errores += N'El registro no existe. ';
    IF @id_convocatoria_baja IS NULL SET @Errores += N'El campo id_convocatoria_baja es obligatorio. ';
    IF @id_convocatoria_baja IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.convocatoria WHERE id_convocatoria=@id_convocatoria_baja) SET @Errores += N'La referencia id_convocatoria_baja no existe. ';
    IF @id_convocatoria_alta IS NULL SET @Errores += N'El campo id_convocatoria_alta es obligatorio. ';
    IF @id_convocatoria_alta IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.convocatoria WHERE id_convocatoria=@id_convocatoria_alta) SET @Errores += N'La referencia id_convocatoria_alta no existe. ';
    IF @motivo IS NULL SET @Errores += N'El campo motivo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@motivo)), '') IS NULL SET @Errores += N'El campo motivo no puede estar vacío. ';
    IF @fecha_cambio IS NULL SET @Errores += N'El campo fecha_cambio es obligatorio. ';
    IF @id_convocatoria_baja=@id_convocatoria_alta SET @Errores += N'Las convocatorias de baja y alta deben ser distintas. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.novedad_convocatoria SET id_convocatoria_baja=@id_convocatoria_baja,
            id_convocatoria_alta=@id_convocatoria_alta,
            motivo=@motivo,
            fecha_cambio=@fecha_cambio,
            dictamen_medico=@dictamen_medico WHERE id_novedad=@id_novedad;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_novedad_convocatoria_Baja
    @id_novedad INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.novedad_convocatoria WHERE id_novedad=@id_novedad) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.novedad_convocatoria WHERE id_novedad=@id_novedad;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_novedad_convocatoria_Consultar
    @id_novedad INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.novedad_convocatoria WHERE (@id_novedad IS NULL OR id_novedad=@id_novedad) ORDER BY id_novedad;
END;
GO

/* ===== PARTIDO ===== */
CREATE OR ALTER PROCEDURE mundial.sp_partido_Alta
    @id_fase INT,
    @id_sede INT,
    @id_seleccion_local INT,
    @id_seleccion_visitante INT,
    @fecha_hora_utc DATETIME2(0),
    @fecha_hora_local DATETIME2(0),
    @goles_local TINYINT = NULL,
    @goles_visitante TINYINT = NULL,
    @penales_local TINYINT = NULL,
    @penales_visitante TINYINT = NULL,
    @asistencia_publico INT = NULL,
    @estado_partido VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_fase IS NULL SET @Errores += N'El campo id_fase es obligatorio. ';
    IF @id_fase IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.fase WHERE id_fase=@id_fase) SET @Errores += N'La referencia id_fase no existe. ';
    IF @id_sede IS NULL SET @Errores += N'El campo id_sede es obligatorio. ';
    IF @id_sede IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.sede_estadio WHERE id_sede=@id_sede) SET @Errores += N'La referencia id_sede no existe. ';
    IF @id_seleccion_local IS NULL SET @Errores += N'El campo id_seleccion_local es obligatorio. ';
    IF @id_seleccion_local IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion_local) SET @Errores += N'La referencia id_seleccion_local no existe. ';
    IF @id_seleccion_visitante IS NULL SET @Errores += N'El campo id_seleccion_visitante es obligatorio. ';
    IF @id_seleccion_visitante IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion_visitante) SET @Errores += N'La referencia id_seleccion_visitante no existe. ';
    IF @fecha_hora_utc IS NULL SET @Errores += N'El campo fecha_hora_utc es obligatorio. ';
    IF @fecha_hora_local IS NULL SET @Errores += N'El campo fecha_hora_local es obligatorio. ';
    IF @estado_partido IS NULL SET @Errores += N'El campo estado_partido es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@estado_partido)), '') IS NULL SET @Errores += N'El campo estado_partido no puede estar vacío. ';
    IF @id_seleccion_local=@id_seleccion_visitante SET @Errores += N'Las selecciones deben ser distintas. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.partido (id_fase, id_sede, id_seleccion_local, id_seleccion_visitante, fecha_hora_utc, fecha_hora_local, goles_local, goles_visitante, penales_local, penales_visitante, asistencia_publico, estado_partido) VALUES (@id_fase, @id_sede, @id_seleccion_local, @id_seleccion_visitante, @fecha_hora_utc, @fecha_hora_local, @goles_local, @goles_visitante, @penales_local, @penales_visitante, @asistencia_publico, @estado_partido);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_partido_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_partido_Modificar
    @id_partido INT,
    @id_fase INT,
    @id_sede INT,
    @id_seleccion_local INT,
    @id_seleccion_visitante INT,
    @fecha_hora_utc DATETIME2(0),
    @fecha_hora_local DATETIME2(0),
    @goles_local TINYINT = NULL,
    @goles_visitante TINYINT = NULL,
    @penales_local TINYINT = NULL,
    @penales_visitante TINYINT = NULL,
    @asistencia_publico INT = NULL,
    @estado_partido VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) SET @Errores += N'El registro no existe. ';
    IF @id_fase IS NULL SET @Errores += N'El campo id_fase es obligatorio. ';
    IF @id_fase IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.fase WHERE id_fase=@id_fase) SET @Errores += N'La referencia id_fase no existe. ';
    IF @id_sede IS NULL SET @Errores += N'El campo id_sede es obligatorio. ';
    IF @id_sede IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.sede_estadio WHERE id_sede=@id_sede) SET @Errores += N'La referencia id_sede no existe. ';
    IF @id_seleccion_local IS NULL SET @Errores += N'El campo id_seleccion_local es obligatorio. ';
    IF @id_seleccion_local IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion_local) SET @Errores += N'La referencia id_seleccion_local no existe. ';
    IF @id_seleccion_visitante IS NULL SET @Errores += N'El campo id_seleccion_visitante es obligatorio. ';
    IF @id_seleccion_visitante IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion_visitante) SET @Errores += N'La referencia id_seleccion_visitante no existe. ';
    IF @fecha_hora_utc IS NULL SET @Errores += N'El campo fecha_hora_utc es obligatorio. ';
    IF @fecha_hora_local IS NULL SET @Errores += N'El campo fecha_hora_local es obligatorio. ';
    IF @estado_partido IS NULL SET @Errores += N'El campo estado_partido es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@estado_partido)), '') IS NULL SET @Errores += N'El campo estado_partido no puede estar vacío. ';
    IF @id_seleccion_local=@id_seleccion_visitante SET @Errores += N'Las selecciones deben ser distintas. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.partido SET id_fase=@id_fase,
            id_sede=@id_sede,
            id_seleccion_local=@id_seleccion_local,
            id_seleccion_visitante=@id_seleccion_visitante,
            fecha_hora_utc=@fecha_hora_utc,
            fecha_hora_local=@fecha_hora_local,
            goles_local=@goles_local,
            goles_visitante=@goles_visitante,
            penales_local=@penales_local,
            penales_visitante=@penales_visitante,
            asistencia_publico=@asistencia_publico,
            estado_partido=@estado_partido WHERE id_partido=@id_partido;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_partido_Baja
    @id_partido INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.partido WHERE id_partido=@id_partido;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_partido_Consultar
    @id_partido INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.partido WHERE (@id_partido IS NULL OR id_partido=@id_partido) ORDER BY id_partido;
END;
GO

/* ===== PARTIDO_EQUIPO_DETALLE ===== */
CREATE OR ALTER PROCEDURE mundial.sp_partido_equipo_detalle_Alta
    @id_partido INT,
    @id_seleccion INT,
    @condicion VARCHAR(10),
    @esquema_tactico VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) SET @Errores += N'La referencia id_partido no existe. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_seleccion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion) SET @Errores += N'La referencia id_seleccion no existe. ';
    IF @condicion IS NULL SET @Errores += N'El campo condicion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@condicion)), '') IS NULL SET @Errores += N'El campo condicion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.partido_equipo_detalle (id_partido, id_seleccion, condicion, esquema_tactico) VALUES (@id_partido, @id_seleccion, @condicion, @esquema_tactico);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_partido_equipo_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_partido_equipo_detalle_Modificar
    @id_partido_equipo INT,
    @id_partido INT,
    @id_seleccion INT,
    @condicion VARCHAR(10),
    @esquema_tactico VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.partido_equipo_detalle WHERE id_partido_equipo=@id_partido_equipo) SET @Errores += N'El registro no existe. ';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) SET @Errores += N'La referencia id_partido no existe. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_seleccion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion) SET @Errores += N'La referencia id_seleccion no existe. ';
    IF @condicion IS NULL SET @Errores += N'El campo condicion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@condicion)), '') IS NULL SET @Errores += N'El campo condicion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.partido_equipo_detalle SET id_partido=@id_partido,
            id_seleccion=@id_seleccion,
            condicion=@condicion,
            esquema_tactico=@esquema_tactico WHERE id_partido_equipo=@id_partido_equipo;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_partido_equipo_detalle_Baja
    @id_partido_equipo INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.partido_equipo_detalle WHERE id_partido_equipo=@id_partido_equipo) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.partido_equipo_detalle WHERE id_partido_equipo=@id_partido_equipo;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_partido_equipo_detalle_Consultar
    @id_partido_equipo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.partido_equipo_detalle WHERE (@id_partido_equipo IS NULL OR id_partido_equipo=@id_partido_equipo) ORDER BY id_partido_equipo;
END;
GO

/* ===== ALINEACION_PARTIDO ===== */
CREATE OR ALTER PROCEDURE mundial.sp_alineacion_partido_Alta
    @id_partido_equipo INT,
    @id_jugador INT,
    @id_posicion_campo INT,
    @dorsal TINYINT,
    @es_titular BIT,
    @minuto_ingreso TINYINT = NULL,
    @minuto_salida TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_partido_equipo IS NULL SET @Errores += N'El campo id_partido_equipo es obligatorio. ';
    IF @id_partido_equipo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido_equipo_detalle WHERE id_partido_equipo=@id_partido_equipo) SET @Errores += N'La referencia id_partido_equipo no existe. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_jugador IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador) SET @Errores += N'La referencia id_jugador no existe. ';
    IF @id_posicion_campo IS NULL SET @Errores += N'El campo id_posicion_campo es obligatorio. ';
    IF @id_posicion_campo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.posicion WHERE id_posicion=@id_posicion_campo) SET @Errores += N'La referencia id_posicion_campo no existe. ';
    IF @dorsal IS NULL SET @Errores += N'El campo dorsal es obligatorio. ';
    IF @es_titular IS NULL SET @Errores += N'El campo es_titular es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.alineacion_partido (id_partido_equipo, id_jugador, id_posicion_campo, dorsal, es_titular, minuto_ingreso, minuto_salida) VALUES (@id_partido_equipo, @id_jugador, @id_posicion_campo, @dorsal, @es_titular, @minuto_ingreso, @minuto_salida);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_alineacion_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_alineacion_partido_Modificar
    @id_alineacion INT,
    @id_partido_equipo INT,
    @id_jugador INT,
    @id_posicion_campo INT,
    @dorsal TINYINT,
    @es_titular BIT,
    @minuto_ingreso TINYINT = NULL,
    @minuto_salida TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.alineacion_partido WHERE id_alineacion=@id_alineacion) SET @Errores += N'El registro no existe. ';
    IF @id_partido_equipo IS NULL SET @Errores += N'El campo id_partido_equipo es obligatorio. ';
    IF @id_partido_equipo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido_equipo_detalle WHERE id_partido_equipo=@id_partido_equipo) SET @Errores += N'La referencia id_partido_equipo no existe. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_jugador IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador) SET @Errores += N'La referencia id_jugador no existe. ';
    IF @id_posicion_campo IS NULL SET @Errores += N'El campo id_posicion_campo es obligatorio. ';
    IF @id_posicion_campo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.posicion WHERE id_posicion=@id_posicion_campo) SET @Errores += N'La referencia id_posicion_campo no existe. ';
    IF @dorsal IS NULL SET @Errores += N'El campo dorsal es obligatorio. ';
    IF @es_titular IS NULL SET @Errores += N'El campo es_titular es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.alineacion_partido SET id_partido_equipo=@id_partido_equipo,
            id_jugador=@id_jugador,
            id_posicion_campo=@id_posicion_campo,
            dorsal=@dorsal,
            es_titular=@es_titular,
            minuto_ingreso=@minuto_ingreso,
            minuto_salida=@minuto_salida WHERE id_alineacion=@id_alineacion;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_alineacion_partido_Baja
    @id_alineacion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.alineacion_partido WHERE id_alineacion=@id_alineacion) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.alineacion_partido WHERE id_alineacion=@id_alineacion;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_alineacion_partido_Consultar
    @id_alineacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.alineacion_partido WHERE (@id_alineacion IS NULL OR id_alineacion=@id_alineacion) ORDER BY id_alineacion;
END;
GO

/* ===== SUSTITUCION ===== */
CREATE OR ALTER PROCEDURE mundial.sp_sustitucion_Alta
    @id_partido_equipo INT,
    @id_jugador_sale INT,
    @id_jugador_entra INT,
    @minuto TINYINT,
    @minuto_adicional TINYINT,
    @periodo VARCHAR(30),
    @numero_ventana TINYINT,
    @motivo VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_partido_equipo IS NULL SET @Errores += N'El campo id_partido_equipo es obligatorio. ';
    IF @id_partido_equipo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido_equipo_detalle WHERE id_partido_equipo=@id_partido_equipo) SET @Errores += N'La referencia id_partido_equipo no existe. ';
    IF @id_jugador_sale IS NULL SET @Errores += N'El campo id_jugador_sale es obligatorio. ';
    IF @id_jugador_sale IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador_sale) SET @Errores += N'La referencia id_jugador_sale no existe. ';
    IF @id_jugador_entra IS NULL SET @Errores += N'El campo id_jugador_entra es obligatorio. ';
    IF @id_jugador_entra IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador_entra) SET @Errores += N'La referencia id_jugador_entra no existe. ';
    IF @minuto IS NULL SET @Errores += N'El campo minuto es obligatorio. ';
    IF @minuto_adicional IS NULL SET @Errores += N'El campo minuto_adicional es obligatorio. ';
    IF @periodo IS NULL SET @Errores += N'El campo periodo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@periodo)), '') IS NULL SET @Errores += N'El campo periodo no puede estar vacío. ';
    IF @numero_ventana IS NULL SET @Errores += N'El campo numero_ventana es obligatorio. ';
    IF @motivo IS NULL SET @Errores += N'El campo motivo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@motivo)), '') IS NULL SET @Errores += N'El campo motivo no puede estar vacío. ';
    IF @id_jugador_sale=@id_jugador_entra SET @Errores += N'Los jugadores de la sustitución deben ser distintos. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.sustitucion (id_partido_equipo, id_jugador_sale, id_jugador_entra, minuto, minuto_adicional, periodo, numero_ventana, motivo) VALUES (@id_partido_equipo, @id_jugador_sale, @id_jugador_entra, @minuto, @minuto_adicional, @periodo, @numero_ventana, @motivo);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_sustitucion_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_sustitucion_Modificar
    @id_sustitucion INT,
    @id_partido_equipo INT,
    @id_jugador_sale INT,
    @id_jugador_entra INT,
    @minuto TINYINT,
    @minuto_adicional TINYINT,
    @periodo VARCHAR(30),
    @numero_ventana TINYINT,
    @motivo VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.sustitucion WHERE id_sustitucion=@id_sustitucion) SET @Errores += N'El registro no existe. ';
    IF @id_partido_equipo IS NULL SET @Errores += N'El campo id_partido_equipo es obligatorio. ';
    IF @id_partido_equipo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido_equipo_detalle WHERE id_partido_equipo=@id_partido_equipo) SET @Errores += N'La referencia id_partido_equipo no existe. ';
    IF @id_jugador_sale IS NULL SET @Errores += N'El campo id_jugador_sale es obligatorio. ';
    IF @id_jugador_sale IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador_sale) SET @Errores += N'La referencia id_jugador_sale no existe. ';
    IF @id_jugador_entra IS NULL SET @Errores += N'El campo id_jugador_entra es obligatorio. ';
    IF @id_jugador_entra IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador_entra) SET @Errores += N'La referencia id_jugador_entra no existe. ';
    IF @minuto IS NULL SET @Errores += N'El campo minuto es obligatorio. ';
    IF @minuto_adicional IS NULL SET @Errores += N'El campo minuto_adicional es obligatorio. ';
    IF @periodo IS NULL SET @Errores += N'El campo periodo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@periodo)), '') IS NULL SET @Errores += N'El campo periodo no puede estar vacío. ';
    IF @numero_ventana IS NULL SET @Errores += N'El campo numero_ventana es obligatorio. ';
    IF @motivo IS NULL SET @Errores += N'El campo motivo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@motivo)), '') IS NULL SET @Errores += N'El campo motivo no puede estar vacío. ';
    IF @id_jugador_sale=@id_jugador_entra SET @Errores += N'Los jugadores de la sustitución deben ser distintos. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.sustitucion SET id_partido_equipo=@id_partido_equipo,
            id_jugador_sale=@id_jugador_sale,
            id_jugador_entra=@id_jugador_entra,
            minuto=@minuto,
            minuto_adicional=@minuto_adicional,
            periodo=@periodo,
            numero_ventana=@numero_ventana,
            motivo=@motivo WHERE id_sustitucion=@id_sustitucion;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_sustitucion_Baja
    @id_sustitucion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.sustitucion WHERE id_sustitucion=@id_sustitucion) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.sustitucion WHERE id_sustitucion=@id_sustitucion;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_sustitucion_Consultar
    @id_sustitucion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.sustitucion WHERE (@id_sustitucion IS NULL OR id_sustitucion=@id_sustitucion) ORDER BY id_sustitucion;
END;
GO

/* ===== TIPO_GOL ===== */
CREATE OR ALTER PROCEDURE mundial.sp_tipo_gol_Alta
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @descripcion IS NULL SET @Errores += N'El campo descripcion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL SET @Errores += N'El campo descripcion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.tipo_gol (descripcion) VALUES (@descripcion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_tipo_gol_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_tipo_gol_Modificar
    @id_tipo_gol INT,
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.tipo_gol WHERE id_tipo_gol=@id_tipo_gol) SET @Errores += N'El registro no existe. ';
    IF @descripcion IS NULL SET @Errores += N'El campo descripcion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL SET @Errores += N'El campo descripcion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.tipo_gol SET descripcion=@descripcion WHERE id_tipo_gol=@id_tipo_gol;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_tipo_gol_Baja
    @id_tipo_gol INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.tipo_gol WHERE id_tipo_gol=@id_tipo_gol) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.tipo_gol WHERE id_tipo_gol=@id_tipo_gol;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_tipo_gol_Consultar
    @id_tipo_gol INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.tipo_gol WHERE (@id_tipo_gol IS NULL OR id_tipo_gol=@id_tipo_gol) ORDER BY id_tipo_gol;
END;
GO

/* ===== GOL ===== */
CREATE OR ALTER PROCEDURE mundial.sp_gol_Alta
    @id_partido INT,
    @id_seleccion_beneficiada INT,
    @id_jugador_autor INT,
    @id_jugador_asistente INT = NULL,
    @id_tipo_gol INT,
    @minuto TINYINT,
    @minuto_adicional TINYINT,
    @periodo VARCHAR(30),
    @es_gol_en_contra BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) SET @Errores += N'La referencia id_partido no existe. ';
    IF @id_seleccion_beneficiada IS NULL SET @Errores += N'El campo id_seleccion_beneficiada es obligatorio. ';
    IF @id_seleccion_beneficiada IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion_beneficiada) SET @Errores += N'La referencia id_seleccion_beneficiada no existe. ';
    IF @id_jugador_autor IS NULL SET @Errores += N'El campo id_jugador_autor es obligatorio. ';
    IF @id_jugador_autor IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador_autor) SET @Errores += N'La referencia id_jugador_autor no existe. ';
    IF @id_jugador_asistente IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador_asistente) SET @Errores += N'La referencia id_jugador_asistente no existe. ';
    IF @id_tipo_gol IS NULL SET @Errores += N'El campo id_tipo_gol es obligatorio. ';
    IF @id_tipo_gol IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.tipo_gol WHERE id_tipo_gol=@id_tipo_gol) SET @Errores += N'La referencia id_tipo_gol no existe. ';
    IF @minuto IS NULL SET @Errores += N'El campo minuto es obligatorio. ';
    IF @minuto_adicional IS NULL SET @Errores += N'El campo minuto_adicional es obligatorio. ';
    IF @periodo IS NULL SET @Errores += N'El campo periodo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@periodo)), '') IS NULL SET @Errores += N'El campo periodo no puede estar vacío. ';
    IF @es_gol_en_contra IS NULL SET @Errores += N'El campo es_gol_en_contra es obligatorio. ';
    IF @id_jugador_asistente=@id_jugador_autor SET @Errores += N'El autor no puede asistirse a sí mismo. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.gol (id_partido, id_seleccion_beneficiada, id_jugador_autor, id_jugador_asistente, id_tipo_gol, minuto, minuto_adicional, periodo, es_gol_en_contra) VALUES (@id_partido, @id_seleccion_beneficiada, @id_jugador_autor, @id_jugador_asistente, @id_tipo_gol, @minuto, @minuto_adicional, @periodo, @es_gol_en_contra);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_gol_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_gol_Modificar
    @id_gol INT,
    @id_partido INT,
    @id_seleccion_beneficiada INT,
    @id_jugador_autor INT,
    @id_jugador_asistente INT = NULL,
    @id_tipo_gol INT,
    @minuto TINYINT,
    @minuto_adicional TINYINT,
    @periodo VARCHAR(30),
    @es_gol_en_contra BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.gol WHERE id_gol=@id_gol) SET @Errores += N'El registro no existe. ';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) SET @Errores += N'La referencia id_partido no existe. ';
    IF @id_seleccion_beneficiada IS NULL SET @Errores += N'El campo id_seleccion_beneficiada es obligatorio. ';
    IF @id_seleccion_beneficiada IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion_beneficiada) SET @Errores += N'La referencia id_seleccion_beneficiada no existe. ';
    IF @id_jugador_autor IS NULL SET @Errores += N'El campo id_jugador_autor es obligatorio. ';
    IF @id_jugador_autor IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador_autor) SET @Errores += N'La referencia id_jugador_autor no existe. ';
    IF @id_jugador_asistente IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador_asistente) SET @Errores += N'La referencia id_jugador_asistente no existe. ';
    IF @id_tipo_gol IS NULL SET @Errores += N'El campo id_tipo_gol es obligatorio. ';
    IF @id_tipo_gol IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.tipo_gol WHERE id_tipo_gol=@id_tipo_gol) SET @Errores += N'La referencia id_tipo_gol no existe. ';
    IF @minuto IS NULL SET @Errores += N'El campo minuto es obligatorio. ';
    IF @minuto_adicional IS NULL SET @Errores += N'El campo minuto_adicional es obligatorio. ';
    IF @periodo IS NULL SET @Errores += N'El campo periodo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@periodo)), '') IS NULL SET @Errores += N'El campo periodo no puede estar vacío. ';
    IF @es_gol_en_contra IS NULL SET @Errores += N'El campo es_gol_en_contra es obligatorio. ';
    IF @id_jugador_asistente=@id_jugador_autor SET @Errores += N'El autor no puede asistirse a sí mismo. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.gol SET id_partido=@id_partido,
            id_seleccion_beneficiada=@id_seleccion_beneficiada,
            id_jugador_autor=@id_jugador_autor,
            id_jugador_asistente=@id_jugador_asistente,
            id_tipo_gol=@id_tipo_gol,
            minuto=@minuto,
            minuto_adicional=@minuto_adicional,
            periodo=@periodo,
            es_gol_en_contra=@es_gol_en_contra WHERE id_gol=@id_gol;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_gol_Baja
    @id_gol INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.gol WHERE id_gol=@id_gol) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.gol WHERE id_gol=@id_gol;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_gol_Consultar
    @id_gol INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.gol WHERE (@id_gol IS NULL OR id_gol=@id_gol) ORDER BY id_gol;
END;
GO

/* ===== TIPO_TARJETA ===== */
CREATE OR ALTER PROCEDURE mundial.sp_tipo_tarjeta_Alta
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @descripcion IS NULL SET @Errores += N'El campo descripcion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL SET @Errores += N'El campo descripcion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.tipo_tarjeta (descripcion) VALUES (@descripcion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_tipo_tarjeta_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_tipo_tarjeta_Modificar
    @id_tipo_tarjeta INT,
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.tipo_tarjeta WHERE id_tipo_tarjeta=@id_tipo_tarjeta) SET @Errores += N'El registro no existe. ';
    IF @descripcion IS NULL SET @Errores += N'El campo descripcion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL SET @Errores += N'El campo descripcion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.tipo_tarjeta SET descripcion=@descripcion WHERE id_tipo_tarjeta=@id_tipo_tarjeta;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_tipo_tarjeta_Baja
    @id_tipo_tarjeta INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.tipo_tarjeta WHERE id_tipo_tarjeta=@id_tipo_tarjeta) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.tipo_tarjeta WHERE id_tipo_tarjeta=@id_tipo_tarjeta;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_tipo_tarjeta_Consultar
    @id_tipo_tarjeta INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.tipo_tarjeta WHERE (@id_tipo_tarjeta IS NULL OR id_tipo_tarjeta=@id_tipo_tarjeta) ORDER BY id_tipo_tarjeta;
END;
GO

/* ===== TARJETA ===== */
CREATE OR ALTER PROCEDURE mundial.sp_tarjeta_Alta
    @id_partido INT,
    @id_seleccion INT,
    @id_jugador INT,
    @id_tipo_tarjeta INT,
    @minuto TINYINT,
    @minuto_adicional TINYINT,
    @periodo VARCHAR(30),
    @motivo VARCHAR(200),
    @tipo_expulsion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) SET @Errores += N'La referencia id_partido no existe. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_seleccion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion) SET @Errores += N'La referencia id_seleccion no existe. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_jugador IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador) SET @Errores += N'La referencia id_jugador no existe. ';
    IF @id_tipo_tarjeta IS NULL SET @Errores += N'El campo id_tipo_tarjeta es obligatorio. ';
    IF @id_tipo_tarjeta IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.tipo_tarjeta WHERE id_tipo_tarjeta=@id_tipo_tarjeta) SET @Errores += N'La referencia id_tipo_tarjeta no existe. ';
    IF @minuto IS NULL SET @Errores += N'El campo minuto es obligatorio. ';
    IF @minuto_adicional IS NULL SET @Errores += N'El campo minuto_adicional es obligatorio. ';
    IF @periodo IS NULL SET @Errores += N'El campo periodo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@periodo)), '') IS NULL SET @Errores += N'El campo periodo no puede estar vacío. ';
    IF @motivo IS NULL SET @Errores += N'El campo motivo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@motivo)), '') IS NULL SET @Errores += N'El campo motivo no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.tarjeta (id_partido, id_seleccion, id_jugador, id_tipo_tarjeta, minuto, minuto_adicional, periodo, motivo, tipo_expulsion) VALUES (@id_partido, @id_seleccion, @id_jugador, @id_tipo_tarjeta, @minuto, @minuto_adicional, @periodo, @motivo, @tipo_expulsion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_tarjeta_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_tarjeta_Modificar
    @id_tarjeta INT,
    @id_partido INT,
    @id_seleccion INT,
    @id_jugador INT,
    @id_tipo_tarjeta INT,
    @minuto TINYINT,
    @minuto_adicional TINYINT,
    @periodo VARCHAR(30),
    @motivo VARCHAR(200),
    @tipo_expulsion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.tarjeta WHERE id_tarjeta=@id_tarjeta) SET @Errores += N'El registro no existe. ';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) SET @Errores += N'La referencia id_partido no existe. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_seleccion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion=@id_seleccion) SET @Errores += N'La referencia id_seleccion no existe. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_jugador IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador) SET @Errores += N'La referencia id_jugador no existe. ';
    IF @id_tipo_tarjeta IS NULL SET @Errores += N'El campo id_tipo_tarjeta es obligatorio. ';
    IF @id_tipo_tarjeta IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.tipo_tarjeta WHERE id_tipo_tarjeta=@id_tipo_tarjeta) SET @Errores += N'La referencia id_tipo_tarjeta no existe. ';
    IF @minuto IS NULL SET @Errores += N'El campo minuto es obligatorio. ';
    IF @minuto_adicional IS NULL SET @Errores += N'El campo minuto_adicional es obligatorio. ';
    IF @periodo IS NULL SET @Errores += N'El campo periodo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@periodo)), '') IS NULL SET @Errores += N'El campo periodo no puede estar vacío. ';
    IF @motivo IS NULL SET @Errores += N'El campo motivo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@motivo)), '') IS NULL SET @Errores += N'El campo motivo no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.tarjeta SET id_partido=@id_partido,
            id_seleccion=@id_seleccion,
            id_jugador=@id_jugador,
            id_tipo_tarjeta=@id_tipo_tarjeta,
            minuto=@minuto,
            minuto_adicional=@minuto_adicional,
            periodo=@periodo,
            motivo=@motivo,
            tipo_expulsion=@tipo_expulsion WHERE id_tarjeta=@id_tarjeta;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_tarjeta_Baja
    @id_tarjeta INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.tarjeta WHERE id_tarjeta=@id_tarjeta) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.tarjeta WHERE id_tarjeta=@id_tarjeta;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_tarjeta_Consultar
    @id_tarjeta INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.tarjeta WHERE (@id_tarjeta IS NULL OR id_tarjeta=@id_tarjeta) ORDER BY id_tarjeta;
END;
GO

/* ===== CRITERIO_SUSPENSION ===== */
CREATE OR ALTER PROCEDURE mundial.sp_criterio_suspension_Alta
    @id_fase INT = NULL,
    @cantidad_amarillas TINYINT = NULL,
    @tipo_infraccion VARCHAR(50),
    @partidos_suspension TINYINT,
    @vigencia_desde DATE,
    @vigencia_hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_fase IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.fase WHERE id_fase=@id_fase) SET @Errores += N'La referencia id_fase no existe. ';
    IF @tipo_infraccion IS NULL SET @Errores += N'El campo tipo_infraccion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@tipo_infraccion)), '') IS NULL SET @Errores += N'El campo tipo_infraccion no puede estar vacío. ';
    IF @partidos_suspension IS NULL SET @Errores += N'El campo partidos_suspension es obligatorio. ';
    IF @vigencia_desde IS NULL SET @Errores += N'El campo vigencia_desde es obligatorio. ';
    IF @vigencia_hasta IS NOT NULL AND @vigencia_hasta<@vigencia_desde SET @Errores += N'Vigencia inválida. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.criterio_suspension (id_fase, cantidad_amarillas, tipo_infraccion, partidos_suspension, vigencia_desde, vigencia_hasta) VALUES (@id_fase, @cantidad_amarillas, @tipo_infraccion, @partidos_suspension, @vigencia_desde, @vigencia_hasta);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_criterio_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_criterio_suspension_Modificar
    @id_criterio INT,
    @id_fase INT = NULL,
    @cantidad_amarillas TINYINT = NULL,
    @tipo_infraccion VARCHAR(50),
    @partidos_suspension TINYINT,
    @vigencia_desde DATE,
    @vigencia_hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.criterio_suspension WHERE id_criterio=@id_criterio) SET @Errores += N'El registro no existe. ';
    IF @id_fase IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.fase WHERE id_fase=@id_fase) SET @Errores += N'La referencia id_fase no existe. ';
    IF @tipo_infraccion IS NULL SET @Errores += N'El campo tipo_infraccion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@tipo_infraccion)), '') IS NULL SET @Errores += N'El campo tipo_infraccion no puede estar vacío. ';
    IF @partidos_suspension IS NULL SET @Errores += N'El campo partidos_suspension es obligatorio. ';
    IF @vigencia_desde IS NULL SET @Errores += N'El campo vigencia_desde es obligatorio. ';
    IF @vigencia_hasta IS NOT NULL AND @vigencia_hasta<@vigencia_desde SET @Errores += N'Vigencia inválida. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.criterio_suspension SET id_fase=@id_fase,
            cantidad_amarillas=@cantidad_amarillas,
            tipo_infraccion=@tipo_infraccion,
            partidos_suspension=@partidos_suspension,
            vigencia_desde=@vigencia_desde,
            vigencia_hasta=@vigencia_hasta WHERE id_criterio=@id_criterio;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_criterio_suspension_Baja
    @id_criterio INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.criterio_suspension WHERE id_criterio=@id_criterio) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.criterio_suspension WHERE id_criterio=@id_criterio;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_criterio_suspension_Consultar
    @id_criterio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.criterio_suspension WHERE (@id_criterio IS NULL OR id_criterio=@id_criterio) ORDER BY id_criterio;
END;
GO

/* ===== SUSPENSION_JUGADOR ===== */
CREATE OR ALTER PROCEDURE mundial.sp_suspension_jugador_Alta
    @id_criterio INT = NULL,
    @id_jugador INT,
    @id_partido_origen INT,
    @motivo VARCHAR(200),
    @partidos_sancion TINYINT,
    @partidos_cumplidos TINYINT,
    @cumplida BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_criterio IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.criterio_suspension WHERE id_criterio=@id_criterio) SET @Errores += N'La referencia id_criterio no existe. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_jugador IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador) SET @Errores += N'La referencia id_jugador no existe. ';
    IF @id_partido_origen IS NULL SET @Errores += N'El campo id_partido_origen es obligatorio. ';
    IF @id_partido_origen IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido_origen) SET @Errores += N'La referencia id_partido_origen no existe. ';
    IF @motivo IS NULL SET @Errores += N'El campo motivo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@motivo)), '') IS NULL SET @Errores += N'El campo motivo no puede estar vacío. ';
    IF @partidos_sancion IS NULL SET @Errores += N'El campo partidos_sancion es obligatorio. ';
    IF @partidos_cumplidos IS NULL SET @Errores += N'El campo partidos_cumplidos es obligatorio. ';
    IF @cumplida IS NULL SET @Errores += N'El campo cumplida es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.suspension_jugador (id_criterio, id_jugador, id_partido_origen, motivo, partidos_sancion, partidos_cumplidos, cumplida) VALUES (@id_criterio, @id_jugador, @id_partido_origen, @motivo, @partidos_sancion, @partidos_cumplidos, @cumplida);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_suspension_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_suspension_jugador_Modificar
    @id_suspension INT,
    @id_criterio INT = NULL,
    @id_jugador INT,
    @id_partido_origen INT,
    @motivo VARCHAR(200),
    @partidos_sancion TINYINT,
    @partidos_cumplidos TINYINT,
    @cumplida BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.suspension_jugador WHERE id_suspension=@id_suspension) SET @Errores += N'El registro no existe. ';
    IF @id_criterio IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.criterio_suspension WHERE id_criterio=@id_criterio) SET @Errores += N'La referencia id_criterio no existe. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_jugador IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador) SET @Errores += N'La referencia id_jugador no existe. ';
    IF @id_partido_origen IS NULL SET @Errores += N'El campo id_partido_origen es obligatorio. ';
    IF @id_partido_origen IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido_origen) SET @Errores += N'La referencia id_partido_origen no existe. ';
    IF @motivo IS NULL SET @Errores += N'El campo motivo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@motivo)), '') IS NULL SET @Errores += N'El campo motivo no puede estar vacío. ';
    IF @partidos_sancion IS NULL SET @Errores += N'El campo partidos_sancion es obligatorio. ';
    IF @partidos_cumplidos IS NULL SET @Errores += N'El campo partidos_cumplidos es obligatorio. ';
    IF @cumplida IS NULL SET @Errores += N'El campo cumplida es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.suspension_jugador SET id_criterio=@id_criterio,
            id_jugador=@id_jugador,
            id_partido_origen=@id_partido_origen,
            motivo=@motivo,
            partidos_sancion=@partidos_sancion,
            partidos_cumplidos=@partidos_cumplidos,
            cumplida=@cumplida WHERE id_suspension=@id_suspension;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_suspension_jugador_Baja
    @id_suspension INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.suspension_jugador WHERE id_suspension=@id_suspension) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.suspension_jugador WHERE id_suspension=@id_suspension;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_suspension_jugador_Consultar
    @id_suspension INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.suspension_jugador WHERE (@id_suspension IS NULL OR id_suspension=@id_suspension) ORDER BY id_suspension;
END;
GO

/* ===== CUMPLIMIENTO_SUSPENSION ===== */
CREATE OR ALTER PROCEDURE mundial.sp_cumplimiento_suspension_Alta
    @id_suspension INT,
    @id_partido INT,
    @fecha_registro DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_suspension IS NULL SET @Errores += N'El campo id_suspension es obligatorio. ';
    IF @id_suspension IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.suspension_jugador WHERE id_suspension=@id_suspension) SET @Errores += N'La referencia id_suspension no existe. ';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) SET @Errores += N'La referencia id_partido no existe. ';
    IF @fecha_registro IS NULL SET @Errores += N'El campo fecha_registro es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.cumplimiento_suspension (id_suspension, id_partido, fecha_registro) VALUES (@id_suspension, @id_partido, @fecha_registro);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_cumplimiento_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_cumplimiento_suspension_Modificar
    @id_cumplimiento INT,
    @id_suspension INT,
    @id_partido INT,
    @fecha_registro DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.cumplimiento_suspension WHERE id_cumplimiento=@id_cumplimiento) SET @Errores += N'El registro no existe. ';
    IF @id_suspension IS NULL SET @Errores += N'El campo id_suspension es obligatorio. ';
    IF @id_suspension IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.suspension_jugador WHERE id_suspension=@id_suspension) SET @Errores += N'La referencia id_suspension no existe. ';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) SET @Errores += N'La referencia id_partido no existe. ';
    IF @fecha_registro IS NULL SET @Errores += N'El campo fecha_registro es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.cumplimiento_suspension SET id_suspension=@id_suspension,
            id_partido=@id_partido,
            fecha_registro=@fecha_registro WHERE id_cumplimiento=@id_cumplimiento;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_cumplimiento_suspension_Baja
    @id_cumplimiento INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.cumplimiento_suspension WHERE id_cumplimiento=@id_cumplimiento) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.cumplimiento_suspension WHERE id_cumplimiento=@id_cumplimiento;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_cumplimiento_suspension_Consultar
    @id_cumplimiento INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.cumplimiento_suspension WHERE (@id_cumplimiento IS NULL OR id_cumplimiento=@id_cumplimiento) ORDER BY id_cumplimiento;
END;
GO

/* ===== ARBITRO ===== */
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_Alta
    @id_pais_nacionalidad INT,
    @id_confederacion_afiliacion INT,
    @nombres VARCHAR(100),
    @apellidos VARCHAR(100),
    @fecha_nacimiento DATE,
    @categoria VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_pais_nacionalidad IS NULL SET @Errores += N'El campo id_pais_nacionalidad es obligatorio. ';
    IF @id_pais_nacionalidad IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais_nacionalidad) SET @Errores += N'La referencia id_pais_nacionalidad no existe. ';
    IF @id_confederacion_afiliacion IS NULL SET @Errores += N'El campo id_confederacion_afiliacion es obligatorio. ';
    IF @id_confederacion_afiliacion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.confederacion WHERE id_confederacion=@id_confederacion_afiliacion) SET @Errores += N'La referencia id_confederacion_afiliacion no existe. ';
    IF @nombres IS NULL SET @Errores += N'El campo nombres es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombres)), '') IS NULL SET @Errores += N'El campo nombres no puede estar vacío. ';
    IF @apellidos IS NULL SET @Errores += N'El campo apellidos es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@apellidos)), '') IS NULL SET @Errores += N'El campo apellidos no puede estar vacío. ';
    IF @fecha_nacimiento IS NULL SET @Errores += N'El campo fecha_nacimiento es obligatorio. ';
    IF @categoria IS NULL SET @Errores += N'El campo categoria es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@categoria)), '') IS NULL SET @Errores += N'El campo categoria no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.arbitro (id_pais_nacionalidad, id_confederacion_afiliacion, nombres, apellidos, fecha_nacimiento, categoria) VALUES (@id_pais_nacionalidad, @id_confederacion_afiliacion, @nombres, @apellidos, @fecha_nacimiento, @categoria);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_arbitro_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_Modificar
    @id_arbitro INT,
    @id_pais_nacionalidad INT,
    @id_confederacion_afiliacion INT,
    @nombres VARCHAR(100),
    @apellidos VARCHAR(100),
    @fecha_nacimiento DATE,
    @categoria VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.arbitro WHERE id_arbitro=@id_arbitro) SET @Errores += N'El registro no existe. ';
    IF @id_pais_nacionalidad IS NULL SET @Errores += N'El campo id_pais_nacionalidad es obligatorio. ';
    IF @id_pais_nacionalidad IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais_nacionalidad) SET @Errores += N'La referencia id_pais_nacionalidad no existe. ';
    IF @id_confederacion_afiliacion IS NULL SET @Errores += N'El campo id_confederacion_afiliacion es obligatorio. ';
    IF @id_confederacion_afiliacion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.confederacion WHERE id_confederacion=@id_confederacion_afiliacion) SET @Errores += N'La referencia id_confederacion_afiliacion no existe. ';
    IF @nombres IS NULL SET @Errores += N'El campo nombres es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombres)), '') IS NULL SET @Errores += N'El campo nombres no puede estar vacío. ';
    IF @apellidos IS NULL SET @Errores += N'El campo apellidos es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@apellidos)), '') IS NULL SET @Errores += N'El campo apellidos no puede estar vacío. ';
    IF @fecha_nacimiento IS NULL SET @Errores += N'El campo fecha_nacimiento es obligatorio. ';
    IF @categoria IS NULL SET @Errores += N'El campo categoria es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@categoria)), '') IS NULL SET @Errores += N'El campo categoria no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.arbitro SET id_pais_nacionalidad=@id_pais_nacionalidad,
            id_confederacion_afiliacion=@id_confederacion_afiliacion,
            nombres=@nombres,
            apellidos=@apellidos,
            fecha_nacimiento=@fecha_nacimiento,
            categoria=@categoria WHERE id_arbitro=@id_arbitro;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_Baja
    @id_arbitro INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.arbitro WHERE id_arbitro=@id_arbitro) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.arbitro WHERE id_arbitro=@id_arbitro;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_Consultar
    @id_arbitro INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.arbitro WHERE (@id_arbitro IS NULL OR id_arbitro=@id_arbitro) ORDER BY id_arbitro;
END;
GO

/* ===== IDIOMA ===== */
CREATE OR ALTER PROCEDURE mundial.sp_idioma_Alta
    @nombre_idioma VARCHAR(100),
    @codigo_iso VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @nombre_idioma IS NULL SET @Errores += N'El campo nombre_idioma es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre_idioma)), '') IS NULL SET @Errores += N'El campo nombre_idioma no puede estar vacío. ';
    IF @codigo_iso IS NULL SET @Errores += N'El campo codigo_iso es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@codigo_iso)), '') IS NULL SET @Errores += N'El campo codigo_iso no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.idioma (nombre_idioma, codigo_iso) VALUES (@nombre_idioma, @codigo_iso);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_idioma_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_idioma_Modificar
    @id_idioma INT,
    @nombre_idioma VARCHAR(100),
    @codigo_iso VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.idioma WHERE id_idioma=@id_idioma) SET @Errores += N'El registro no existe. ';
    IF @nombre_idioma IS NULL SET @Errores += N'El campo nombre_idioma es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre_idioma)), '') IS NULL SET @Errores += N'El campo nombre_idioma no puede estar vacío. ';
    IF @codigo_iso IS NULL SET @Errores += N'El campo codigo_iso es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@codigo_iso)), '') IS NULL SET @Errores += N'El campo codigo_iso no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.idioma SET nombre_idioma=@nombre_idioma,
            codigo_iso=@codigo_iso WHERE id_idioma=@id_idioma;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_idioma_Baja
    @id_idioma INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.idioma WHERE id_idioma=@id_idioma) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.idioma WHERE id_idioma=@id_idioma;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_idioma_Consultar
    @id_idioma INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.idioma WHERE (@id_idioma IS NULL OR id_idioma=@id_idioma) ORDER BY id_idioma;
END;
GO

/* ===== ARBITRO_IDIOMA ===== */
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_idioma_Alta
    @id_arbitro INT,
    @id_idioma INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS(SELECT 1 FROM mundial.arbitro WHERE id_arbitro=@id_arbitro) SET @Errores+=N'El árbitro no existe. ';
    IF NOT EXISTS(SELECT 1 FROM mundial.idioma WHERE id_idioma=@id_idioma) SET @Errores+=N'El idioma no existe. ';
    IF EXISTS(SELECT 1 FROM mundial.arbitro_idioma WHERE id_arbitro=@id_arbitro AND id_idioma=@id_idioma) SET @Errores+=N'La relación ya existe. ';
    IF LEN(@Errores)>0 THROW 51001,@Errores,1;
    INSERT INTO mundial.arbitro_idioma(id_arbitro,id_idioma) VALUES(@id_arbitro,@id_idioma);
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_idioma_Modificar
    @id_arbitro_original INT,
    @id_idioma_original INT,
    @id_arbitro_nuevo INT,
    @id_idioma_nuevo INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS(SELECT 1 FROM mundial.arbitro_idioma WHERE id_arbitro=@id_arbitro_original AND id_idioma=@id_idioma_original) SET @Errores+=N'La relación original no existe. ';
    IF NOT EXISTS(SELECT 1 FROM mundial.arbitro WHERE id_arbitro=@id_arbitro_nuevo) SET @Errores+=N'El árbitro nuevo no existe. ';
    IF NOT EXISTS(SELECT 1 FROM mundial.idioma WHERE id_idioma=@id_idioma_nuevo) SET @Errores+=N'El idioma nuevo no existe. ';
    IF EXISTS(SELECT 1 FROM mundial.arbitro_idioma WHERE id_arbitro=@id_arbitro_nuevo AND id_idioma=@id_idioma_nuevo AND NOT(id_arbitro=@id_arbitro_original AND id_idioma=@id_idioma_original)) SET @Errores+=N'La relación nueva ya existe. ';
    IF LEN(@Errores)>0 THROW 51002,@Errores,1;
    BEGIN TRANSACTION;
    DELETE mundial.arbitro_idioma WHERE id_arbitro=@id_arbitro_original AND id_idioma=@id_idioma_original;
    INSERT mundial.arbitro_idioma(id_arbitro,id_idioma) VALUES(@id_arbitro_nuevo,@id_idioma_nuevo);
    COMMIT;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_idioma_Baja @id_arbitro INT,@id_idioma INT AS
BEGIN SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM mundial.arbitro_idioma WHERE id_arbitro=@id_arbitro AND id_idioma=@id_idioma) THROW 51003,N'La relación no existe.',1;
 DELETE mundial.arbitro_idioma WHERE id_arbitro=@id_arbitro AND id_idioma=@id_idioma;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_idioma_Consultar @id_arbitro INT=NULL,@id_idioma INT=NULL AS
BEGIN SET NOCOUNT ON; SELECT * FROM mundial.arbitro_idioma WHERE (@id_arbitro IS NULL OR id_arbitro=@id_arbitro) AND (@id_idioma IS NULL OR id_idioma=@id_idioma) ORDER BY id_arbitro,id_idioma; END;
GO
/* ===== ROL_ARBITRAL ===== */
CREATE OR ALTER PROCEDURE mundial.sp_rol_arbitral_Alta
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @descripcion IS NULL SET @Errores += N'El campo descripcion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL SET @Errores += N'El campo descripcion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.rol_arbitral (descripcion) VALUES (@descripcion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_rol_arbitral_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_rol_arbitral_Modificar
    @id_rol_arbitral INT,
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.rol_arbitral WHERE id_rol_arbitral=@id_rol_arbitral) SET @Errores += N'El registro no existe. ';
    IF @descripcion IS NULL SET @Errores += N'El campo descripcion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL SET @Errores += N'El campo descripcion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.rol_arbitral SET descripcion=@descripcion WHERE id_rol_arbitral=@id_rol_arbitral;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_rol_arbitral_Baja
    @id_rol_arbitral INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.rol_arbitral WHERE id_rol_arbitral=@id_rol_arbitral) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.rol_arbitral WHERE id_rol_arbitral=@id_rol_arbitral;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_rol_arbitral_Consultar
    @id_rol_arbitral INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.rol_arbitral WHERE (@id_rol_arbitral IS NULL OR id_rol_arbitral=@id_rol_arbitral) ORDER BY id_rol_arbitral;
END;
GO

/* ===== DESIGNACION_ARBITRAL ===== */
CREATE OR ALTER PROCEDURE mundial.sp_designacion_arbitral_Alta
    @id_partido INT,
    @id_arbitro INT,
    @id_rol_arbitral INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) SET @Errores += N'La referencia id_partido no existe. ';
    IF @id_arbitro IS NULL SET @Errores += N'El campo id_arbitro es obligatorio. ';
    IF @id_arbitro IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.arbitro WHERE id_arbitro=@id_arbitro) SET @Errores += N'La referencia id_arbitro no existe. ';
    IF @id_rol_arbitral IS NULL SET @Errores += N'El campo id_rol_arbitral es obligatorio. ';
    IF @id_rol_arbitral IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.rol_arbitral WHERE id_rol_arbitral=@id_rol_arbitral) SET @Errores += N'La referencia id_rol_arbitral no existe. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.designacion_arbitral (id_partido, id_arbitro, id_rol_arbitral) VALUES (@id_partido, @id_arbitro, @id_rol_arbitral);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_designacion_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_designacion_arbitral_Modificar
    @id_designacion INT,
    @id_partido INT,
    @id_arbitro INT,
    @id_rol_arbitral INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.designacion_arbitral WHERE id_designacion=@id_designacion) SET @Errores += N'El registro no existe. ';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) SET @Errores += N'La referencia id_partido no existe. ';
    IF @id_arbitro IS NULL SET @Errores += N'El campo id_arbitro es obligatorio. ';
    IF @id_arbitro IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.arbitro WHERE id_arbitro=@id_arbitro) SET @Errores += N'La referencia id_arbitro no existe. ';
    IF @id_rol_arbitral IS NULL SET @Errores += N'El campo id_rol_arbitral es obligatorio. ';
    IF @id_rol_arbitral IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.rol_arbitral WHERE id_rol_arbitral=@id_rol_arbitral) SET @Errores += N'La referencia id_rol_arbitral no existe. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.designacion_arbitral SET id_partido=@id_partido,
            id_arbitro=@id_arbitro,
            id_rol_arbitral=@id_rol_arbitral WHERE id_designacion=@id_designacion;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_designacion_arbitral_Baja
    @id_designacion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.designacion_arbitral WHERE id_designacion=@id_designacion) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.designacion_arbitral WHERE id_designacion=@id_designacion;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_designacion_arbitral_Consultar
    @id_designacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.designacion_arbitral WHERE (@id_designacion IS NULL OR id_designacion=@id_designacion) ORDER BY id_designacion;
END;
GO

/* ===== INFORME_ARBITRAL ===== */
CREATE OR ALTER PROCEDURE mundial.sp_informe_arbitral_Alta
    @id_designacion INT,
    @fecha_informe DATE,
    @observaciones VARCHAR(1000) = NULL,
    @calificacion DECIMAL(5,2) = NULL,
    @sanciones_post_partido VARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_designacion IS NULL SET @Errores += N'El campo id_designacion es obligatorio. ';
    IF @id_designacion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.designacion_arbitral WHERE id_designacion=@id_designacion) SET @Errores += N'La referencia id_designacion no existe. ';
    IF @fecha_informe IS NULL SET @Errores += N'El campo fecha_informe es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.informe_arbitral (id_designacion, fecha_informe, observaciones, calificacion, sanciones_post_partido) VALUES (@id_designacion, @fecha_informe, @observaciones, @calificacion, @sanciones_post_partido);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_informe_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_informe_arbitral_Modificar
    @id_informe INT,
    @id_designacion INT,
    @fecha_informe DATE,
    @observaciones VARCHAR(1000) = NULL,
    @calificacion DECIMAL(5,2) = NULL,
    @sanciones_post_partido VARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.informe_arbitral WHERE id_informe=@id_informe) SET @Errores += N'El registro no existe. ';
    IF @id_designacion IS NULL SET @Errores += N'El campo id_designacion es obligatorio. ';
    IF @id_designacion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.designacion_arbitral WHERE id_designacion=@id_designacion) SET @Errores += N'La referencia id_designacion no existe. ';
    IF @fecha_informe IS NULL SET @Errores += N'El campo fecha_informe es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.informe_arbitral SET id_designacion=@id_designacion,
            fecha_informe=@fecha_informe,
            observaciones=@observaciones,
            calificacion=@calificacion,
            sanciones_post_partido=@sanciones_post_partido WHERE id_informe=@id_informe;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_informe_arbitral_Baja
    @id_informe INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.informe_arbitral WHERE id_informe=@id_informe) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.informe_arbitral WHERE id_informe=@id_informe;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_informe_arbitral_Consultar
    @id_informe INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.informe_arbitral WHERE (@id_informe IS NULL OR id_informe=@id_informe) ORDER BY id_informe;
END;
GO

/* ===== ANUNCIANTE ===== */
CREATE OR ALTER PROCEDURE mundial.sp_anunciante_Alta
    @id_pais_origen INT,
    @razon_social VARCHAR(200),
    @identificador_fiscal VARCHAR(50),
    @email_contacto VARCHAR(254)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_pais_origen IS NULL SET @Errores += N'El campo id_pais_origen es obligatorio. ';
    IF @id_pais_origen IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais_origen) SET @Errores += N'La referencia id_pais_origen no existe. ';
    IF @razon_social IS NULL SET @Errores += N'El campo razon_social es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@razon_social)), '') IS NULL SET @Errores += N'El campo razon_social no puede estar vacío. ';
    IF @identificador_fiscal IS NULL SET @Errores += N'El campo identificador_fiscal es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@identificador_fiscal)), '') IS NULL SET @Errores += N'El campo identificador_fiscal no puede estar vacío. ';
    IF @email_contacto IS NULL SET @Errores += N'El campo email_contacto es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@email_contacto)), '') IS NULL SET @Errores += N'El campo email_contacto no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.anunciante (id_pais_origen, razon_social, identificador_fiscal, email_contacto) VALUES (@id_pais_origen, @razon_social, @identificador_fiscal, @email_contacto);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_anunciante_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_anunciante_Modificar
    @id_anunciante INT,
    @id_pais_origen INT,
    @razon_social VARCHAR(200),
    @identificador_fiscal VARCHAR(50),
    @email_contacto VARCHAR(254)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.anunciante WHERE id_anunciante=@id_anunciante) SET @Errores += N'El registro no existe. ';
    IF @id_pais_origen IS NULL SET @Errores += N'El campo id_pais_origen es obligatorio. ';
    IF @id_pais_origen IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais_origen) SET @Errores += N'La referencia id_pais_origen no existe. ';
    IF @razon_social IS NULL SET @Errores += N'El campo razon_social es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@razon_social)), '') IS NULL SET @Errores += N'El campo razon_social no puede estar vacío. ';
    IF @identificador_fiscal IS NULL SET @Errores += N'El campo identificador_fiscal es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@identificador_fiscal)), '') IS NULL SET @Errores += N'El campo identificador_fiscal no puede estar vacío. ';
    IF @email_contacto IS NULL SET @Errores += N'El campo email_contacto es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@email_contacto)), '') IS NULL SET @Errores += N'El campo email_contacto no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.anunciante SET id_pais_origen=@id_pais_origen,
            razon_social=@razon_social,
            identificador_fiscal=@identificador_fiscal,
            email_contacto=@email_contacto WHERE id_anunciante=@id_anunciante;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_anunciante_Baja
    @id_anunciante INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.anunciante WHERE id_anunciante=@id_anunciante) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.anunciante WHERE id_anunciante=@id_anunciante;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_anunciante_Consultar
    @id_anunciante INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.anunciante WHERE (@id_anunciante IS NULL OR id_anunciante=@id_anunciante) ORDER BY id_anunciante;
END;
GO

/* ===== CAMPANIA ===== */
CREATE OR ALTER PROCEDURE mundial.sp_campania_Alta
    @id_anunciante INT,
    @nombre_campania VARCHAR(150),
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @presupuesto_total DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_anunciante IS NULL SET @Errores += N'El campo id_anunciante es obligatorio. ';
    IF @id_anunciante IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.anunciante WHERE id_anunciante=@id_anunciante) SET @Errores += N'La referencia id_anunciante no existe. ';
    IF @nombre_campania IS NULL SET @Errores += N'El campo nombre_campania es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre_campania)), '') IS NULL SET @Errores += N'El campo nombre_campania no puede estar vacío. ';
    IF @fecha_inicio IS NULL SET @Errores += N'El campo fecha_inicio es obligatorio. ';
    IF @fecha_fin IS NULL SET @Errores += N'El campo fecha_fin es obligatorio. ';
    IF @presupuesto_total IS NULL SET @Errores += N'El campo presupuesto_total es obligatorio. ';
    IF @fecha_fin<@fecha_inicio SET @Errores += N'La fecha final no puede ser anterior a la inicial. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.campania (id_anunciante, nombre_campania, fecha_inicio, fecha_fin, presupuesto_total) VALUES (@id_anunciante, @nombre_campania, @fecha_inicio, @fecha_fin, @presupuesto_total);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_campania_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_campania_Modificar
    @id_campania INT,
    @id_anunciante INT,
    @nombre_campania VARCHAR(150),
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @presupuesto_total DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.campania WHERE id_campania=@id_campania) SET @Errores += N'El registro no existe. ';
    IF @id_anunciante IS NULL SET @Errores += N'El campo id_anunciante es obligatorio. ';
    IF @id_anunciante IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.anunciante WHERE id_anunciante=@id_anunciante) SET @Errores += N'La referencia id_anunciante no existe. ';
    IF @nombre_campania IS NULL SET @Errores += N'El campo nombre_campania es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre_campania)), '') IS NULL SET @Errores += N'El campo nombre_campania no puede estar vacío. ';
    IF @fecha_inicio IS NULL SET @Errores += N'El campo fecha_inicio es obligatorio. ';
    IF @fecha_fin IS NULL SET @Errores += N'El campo fecha_fin es obligatorio. ';
    IF @presupuesto_total IS NULL SET @Errores += N'El campo presupuesto_total es obligatorio. ';
    IF @fecha_fin<@fecha_inicio SET @Errores += N'La fecha final no puede ser anterior a la inicial. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.campania SET id_anunciante=@id_anunciante,
            nombre_campania=@nombre_campania,
            fecha_inicio=@fecha_inicio,
            fecha_fin=@fecha_fin,
            presupuesto_total=@presupuesto_total WHERE id_campania=@id_campania;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_campania_Baja
    @id_campania INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.campania WHERE id_campania=@id_campania) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.campania WHERE id_campania=@id_campania;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_campania_Consultar
    @id_campania INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.campania WHERE (@id_campania IS NULL OR id_campania=@id_campania) ORDER BY id_campania;
END;
GO

/* ===== PIEZA_PUBLICITARIA ===== */
CREATE OR ALTER PROCEDURE mundial.sp_pieza_publicitaria_Alta
    @id_campania INT,
    @id_idioma INT,
    @titulo VARCHAR(150),
    @formato VARCHAR(50),
    @duracion_segundos SMALLINT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_campania IS NULL SET @Errores += N'El campo id_campania es obligatorio. ';
    IF @id_campania IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.campania WHERE id_campania=@id_campania) SET @Errores += N'La referencia id_campania no existe. ';
    IF @id_idioma IS NULL SET @Errores += N'El campo id_idioma es obligatorio. ';
    IF @id_idioma IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.idioma WHERE id_idioma=@id_idioma) SET @Errores += N'La referencia id_idioma no existe. ';
    IF @titulo IS NULL SET @Errores += N'El campo titulo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@titulo)), '') IS NULL SET @Errores += N'El campo titulo no puede estar vacío. ';
    IF @formato IS NULL SET @Errores += N'El campo formato es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@formato)), '') IS NULL SET @Errores += N'El campo formato no puede estar vacío. ';
    IF @duracion_segundos IS NULL SET @Errores += N'El campo duracion_segundos es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.pieza_publicitaria (id_campania, id_idioma, titulo, formato, duracion_segundos) VALUES (@id_campania, @id_idioma, @titulo, @formato, @duracion_segundos);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_pieza_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_pieza_publicitaria_Modificar
    @id_pieza INT,
    @id_campania INT,
    @id_idioma INT,
    @titulo VARCHAR(150),
    @formato VARCHAR(50),
    @duracion_segundos SMALLINT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.pieza_publicitaria WHERE id_pieza=@id_pieza) SET @Errores += N'El registro no existe. ';
    IF @id_campania IS NULL SET @Errores += N'El campo id_campania es obligatorio. ';
    IF @id_campania IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.campania WHERE id_campania=@id_campania) SET @Errores += N'La referencia id_campania no existe. ';
    IF @id_idioma IS NULL SET @Errores += N'El campo id_idioma es obligatorio. ';
    IF @id_idioma IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.idioma WHERE id_idioma=@id_idioma) SET @Errores += N'La referencia id_idioma no existe. ';
    IF @titulo IS NULL SET @Errores += N'El campo titulo es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@titulo)), '') IS NULL SET @Errores += N'El campo titulo no puede estar vacío. ';
    IF @formato IS NULL SET @Errores += N'El campo formato es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@formato)), '') IS NULL SET @Errores += N'El campo formato no puede estar vacío. ';
    IF @duracion_segundos IS NULL SET @Errores += N'El campo duracion_segundos es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.pieza_publicitaria SET id_campania=@id_campania,
            id_idioma=@id_idioma,
            titulo=@titulo,
            formato=@formato,
            duracion_segundos=@duracion_segundos WHERE id_pieza=@id_pieza;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_pieza_publicitaria_Baja
    @id_pieza INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.pieza_publicitaria WHERE id_pieza=@id_pieza) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.pieza_publicitaria WHERE id_pieza=@id_pieza;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_pieza_publicitaria_Consultar
    @id_pieza INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.pieza_publicitaria WHERE (@id_pieza IS NULL OR id_pieza=@id_pieza) ORDER BY id_pieza;
END;
GO

/* ===== PIEZA_PAIS_OBJETIVO ===== */
CREATE OR ALTER PROCEDURE mundial.sp_pieza_pais_objetivo_Alta
 @id_pieza INT,@id_pais INT,@prioridad TINYINT
AS
BEGIN SET NOCOUNT ON; DECLARE @Errores NVARCHAR(2048)=N'';
 IF NOT EXISTS(SELECT 1 FROM mundial.pieza_publicitaria WHERE id_pieza=@id_pieza) SET @Errores+=N'La pieza no existe. ';
 IF NOT EXISTS(SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais) SET @Errores+=N'El país no existe. ';
 IF @prioridad IS NULL OR @prioridad<=0 SET @Errores+=N'La prioridad debe ser mayor que cero. ';
 IF EXISTS(SELECT 1 FROM mundial.pieza_pais_objetivo WHERE id_pieza=@id_pieza AND (id_pais=@id_pais OR prioridad=@prioridad)) SET @Errores+=N'La relación o prioridad ya existe. ';
 IF LEN(@Errores)>0 THROW 51001,@Errores,1;
 INSERT mundial.pieza_pais_objetivo(id_pieza,id_pais,prioridad) VALUES(@id_pieza,@id_pais,@prioridad);
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_pieza_pais_objetivo_Modificar
 @id_pieza_original INT,@id_pais_original INT,@id_pieza_nuevo INT,@id_pais_nuevo INT,@prioridad TINYINT
AS
BEGIN SET NOCOUNT ON; SET XACT_ABORT ON; DECLARE @Errores NVARCHAR(2048)=N'';
 IF NOT EXISTS(SELECT 1 FROM mundial.pieza_pais_objetivo WHERE id_pieza=@id_pieza_original AND id_pais=@id_pais_original) SET @Errores+=N'La relación original no existe. ';
 IF NOT EXISTS(SELECT 1 FROM mundial.pieza_publicitaria WHERE id_pieza=@id_pieza_nuevo) SET @Errores+=N'La pieza nueva no existe. ';
 IF NOT EXISTS(SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais_nuevo) SET @Errores+=N'El país nuevo no existe. ';
 IF @prioridad IS NULL OR @prioridad<=0 SET @Errores+=N'La prioridad debe ser mayor que cero. ';
 IF EXISTS(SELECT 1 FROM mundial.pieza_pais_objetivo WHERE id_pieza=@id_pieza_nuevo AND (id_pais=@id_pais_nuevo OR prioridad=@prioridad) AND NOT(id_pieza=@id_pieza_original AND id_pais=@id_pais_original)) SET @Errores+=N'La relación o prioridad nueva ya existe. ';
 IF LEN(@Errores)>0 THROW 51002,@Errores,1;
 BEGIN TRANSACTION;
 DELETE mundial.pieza_pais_objetivo WHERE id_pieza=@id_pieza_original AND id_pais=@id_pais_original;
 INSERT mundial.pieza_pais_objetivo(id_pieza,id_pais,prioridad) VALUES(@id_pieza_nuevo,@id_pais_nuevo,@prioridad);
 COMMIT;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_pieza_pais_objetivo_Baja @id_pieza INT,@id_pais INT AS
BEGIN SET NOCOUNT ON; IF NOT EXISTS(SELECT 1 FROM mundial.pieza_pais_objetivo WHERE id_pieza=@id_pieza AND id_pais=@id_pais) THROW 51003,N'La relación no existe.',1; DELETE mundial.pieza_pais_objetivo WHERE id_pieza=@id_pieza AND id_pais=@id_pais; END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_pieza_pais_objetivo_Consultar @id_pieza INT=NULL,@id_pais INT=NULL AS
BEGIN SET NOCOUNT ON; SELECT * FROM mundial.pieza_pais_objetivo WHERE (@id_pieza IS NULL OR id_pieza=@id_pieza) AND (@id_pais IS NULL OR id_pais=@id_pais) ORDER BY id_pieza,id_pais; END;
GO
/* ===== ESPACIO_PUBLICITARIO ===== */
CREATE OR ALTER PROCEDURE mundial.sp_espacio_publicitario_Alta
    @id_sede INT,
    @numero_espacio TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_sede IS NULL SET @Errores += N'El campo id_sede es obligatorio. ';
    IF @id_sede IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.sede_estadio WHERE id_sede=@id_sede) SET @Errores += N'La referencia id_sede no existe. ';
    IF @numero_espacio IS NULL SET @Errores += N'El campo numero_espacio es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.espacio_publicitario (id_sede, numero_espacio) VALUES (@id_sede, @numero_espacio);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_espacio_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_espacio_publicitario_Modificar
    @id_espacio INT,
    @id_sede INT,
    @numero_espacio TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.espacio_publicitario WHERE id_espacio=@id_espacio) SET @Errores += N'El registro no existe. ';
    IF @id_sede IS NULL SET @Errores += N'El campo id_sede es obligatorio. ';
    IF @id_sede IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.sede_estadio WHERE id_sede=@id_sede) SET @Errores += N'La referencia id_sede no existe. ';
    IF @numero_espacio IS NULL SET @Errores += N'El campo numero_espacio es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.espacio_publicitario SET id_sede=@id_sede,
            numero_espacio=@numero_espacio WHERE id_espacio=@id_espacio;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_espacio_publicitario_Baja
    @id_espacio INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.espacio_publicitario WHERE id_espacio=@id_espacio) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.espacio_publicitario WHERE id_espacio=@id_espacio;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_espacio_publicitario_Consultar
    @id_espacio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.espacio_publicitario WHERE (@id_espacio IS NULL OR id_espacio=@id_espacio) ORDER BY id_espacio;
END;
GO

/* ===== MONEDA ===== */
CREATE OR ALTER PROCEDURE mundial.sp_moneda_Alta
    @codigo_iso CHAR(3),
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @codigo_iso IS NULL SET @Errores += N'El campo codigo_iso es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@codigo_iso)), '') IS NULL SET @Errores += N'El campo codigo_iso no puede estar vacío. ';
    IF @descripcion IS NULL SET @Errores += N'El campo descripcion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL SET @Errores += N'El campo descripcion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.moneda (codigo_iso, descripcion) VALUES (@codigo_iso, @descripcion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_moneda_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_moneda_Modificar
    @id_moneda INT,
    @codigo_iso CHAR(3),
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.moneda WHERE id_moneda=@id_moneda) SET @Errores += N'El registro no existe. ';
    IF @codigo_iso IS NULL SET @Errores += N'El campo codigo_iso es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@codigo_iso)), '') IS NULL SET @Errores += N'El campo codigo_iso no puede estar vacío. ';
    IF @descripcion IS NULL SET @Errores += N'El campo descripcion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL SET @Errores += N'El campo descripcion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.moneda SET codigo_iso=@codigo_iso,
            descripcion=@descripcion WHERE id_moneda=@id_moneda;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_moneda_Baja
    @id_moneda INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.moneda WHERE id_moneda=@id_moneda) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.moneda WHERE id_moneda=@id_moneda;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_moneda_Consultar
    @id_moneda INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.moneda WHERE (@id_moneda IS NULL OR id_moneda=@id_moneda) ORDER BY id_moneda;
END;
GO

/* ===== PAUTA_PARTIDO ===== */
CREATE OR ALTER PROCEDURE mundial.sp_pauta_partido_Alta
    @id_partido INT,
    @id_espacio INT,
    @id_pieza INT,
    @id_moneda INT,
    @tarifa_base_usd DECIMAL(18,2),
    @tipo_cambio_aplicado DECIMAL(18,6),
    @tarifa_final DECIMAL(18,2),
    @es_prime_time BIT,
    @estado_pauta VARCHAR(20),
    @estado_facturacion VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) SET @Errores += N'La referencia id_partido no existe. ';
    IF @id_espacio IS NULL SET @Errores += N'El campo id_espacio es obligatorio. ';
    IF @id_espacio IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.espacio_publicitario WHERE id_espacio=@id_espacio) SET @Errores += N'La referencia id_espacio no existe. ';
    IF @id_pieza IS NULL SET @Errores += N'El campo id_pieza es obligatorio. ';
    IF @id_pieza IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pieza_publicitaria WHERE id_pieza=@id_pieza) SET @Errores += N'La referencia id_pieza no existe. ';
    IF @id_moneda IS NULL SET @Errores += N'El campo id_moneda es obligatorio. ';
    IF @id_moneda IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.moneda WHERE id_moneda=@id_moneda) SET @Errores += N'La referencia id_moneda no existe. ';
    IF @tarifa_base_usd IS NULL SET @Errores += N'El campo tarifa_base_usd es obligatorio. ';
    IF @tipo_cambio_aplicado IS NULL SET @Errores += N'El campo tipo_cambio_aplicado es obligatorio. ';
    IF @tarifa_final IS NULL SET @Errores += N'El campo tarifa_final es obligatorio. ';
    IF @es_prime_time IS NULL SET @Errores += N'El campo es_prime_time es obligatorio. ';
    IF @estado_pauta IS NULL SET @Errores += N'El campo estado_pauta es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@estado_pauta)), '') IS NULL SET @Errores += N'El campo estado_pauta no puede estar vacío. ';
    IF @estado_facturacion IS NULL SET @Errores += N'El campo estado_facturacion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@estado_facturacion)), '') IS NULL SET @Errores += N'El campo estado_facturacion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.pauta_partido (id_partido, id_espacio, id_pieza, id_moneda, tarifa_base_usd, tipo_cambio_aplicado, tarifa_final, es_prime_time, estado_pauta, estado_facturacion) VALUES (@id_partido, @id_espacio, @id_pieza, @id_moneda, @tarifa_base_usd, @tipo_cambio_aplicado, @tarifa_final, @es_prime_time, @estado_pauta, @estado_facturacion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_pauta_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_pauta_partido_Modificar
    @id_pauta INT,
    @id_partido INT,
    @id_espacio INT,
    @id_pieza INT,
    @id_moneda INT,
    @tarifa_base_usd DECIMAL(18,2),
    @tipo_cambio_aplicado DECIMAL(18,6),
    @tarifa_final DECIMAL(18,2),
    @es_prime_time BIT,
    @estado_pauta VARCHAR(20),
    @estado_facturacion VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.pauta_partido WHERE id_pauta=@id_pauta) SET @Errores += N'El registro no existe. ';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido=@id_partido) SET @Errores += N'La referencia id_partido no existe. ';
    IF @id_espacio IS NULL SET @Errores += N'El campo id_espacio es obligatorio. ';
    IF @id_espacio IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.espacio_publicitario WHERE id_espacio=@id_espacio) SET @Errores += N'La referencia id_espacio no existe. ';
    IF @id_pieza IS NULL SET @Errores += N'El campo id_pieza es obligatorio. ';
    IF @id_pieza IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.pieza_publicitaria WHERE id_pieza=@id_pieza) SET @Errores += N'La referencia id_pieza no existe. ';
    IF @id_moneda IS NULL SET @Errores += N'El campo id_moneda es obligatorio. ';
    IF @id_moneda IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.moneda WHERE id_moneda=@id_moneda) SET @Errores += N'La referencia id_moneda no existe. ';
    IF @tarifa_base_usd IS NULL SET @Errores += N'El campo tarifa_base_usd es obligatorio. ';
    IF @tipo_cambio_aplicado IS NULL SET @Errores += N'El campo tipo_cambio_aplicado es obligatorio. ';
    IF @tarifa_final IS NULL SET @Errores += N'El campo tarifa_final es obligatorio. ';
    IF @es_prime_time IS NULL SET @Errores += N'El campo es_prime_time es obligatorio. ';
    IF @estado_pauta IS NULL SET @Errores += N'El campo estado_pauta es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@estado_pauta)), '') IS NULL SET @Errores += N'El campo estado_pauta no puede estar vacío. ';
    IF @estado_facturacion IS NULL SET @Errores += N'El campo estado_facturacion es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@estado_facturacion)), '') IS NULL SET @Errores += N'El campo estado_facturacion no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.pauta_partido SET id_partido=@id_partido,
            id_espacio=@id_espacio,
            id_pieza=@id_pieza,
            id_moneda=@id_moneda,
            tarifa_base_usd=@tarifa_base_usd,
            tipo_cambio_aplicado=@tipo_cambio_aplicado,
            tarifa_final=@tarifa_final,
            es_prime_time=@es_prime_time,
            estado_pauta=@estado_pauta,
            estado_facturacion=@estado_facturacion WHERE id_pauta=@id_pauta;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_pauta_partido_Baja
    @id_pauta INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.pauta_partido WHERE id_pauta=@id_pauta) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.pauta_partido WHERE id_pauta=@id_pauta;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_pauta_partido_Consultar
    @id_pauta INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.pauta_partido WHERE (@id_pauta IS NULL OR id_pauta=@id_pauta) ORDER BY id_pauta;
END;
GO

/* ===== FUENTE_IMPORTACION ===== */
CREATE OR ALTER PROCEDURE mundial.sp_fuente_importacion_Alta
    @nombre VARCHAR(150),
    @tipo_fuente VARCHAR(20),
    @formato VARCHAR(20) = NULL,
    @url_origen VARCHAR(1000) = NULL,
    @descripcion VARCHAR(500) = NULL,
    @condiciones_uso VARCHAR(1000) = NULL,
    @activa BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @nombre IS NULL SET @Errores += N'El campo nombre es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL SET @Errores += N'El campo nombre no puede estar vacío. ';
    IF @tipo_fuente IS NULL SET @Errores += N'El campo tipo_fuente es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@tipo_fuente)), '') IS NULL SET @Errores += N'El campo tipo_fuente no puede estar vacío. ';
    IF @activa IS NULL SET @Errores += N'El campo activa es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.fuente_importacion (nombre, tipo_fuente, formato, url_origen, descripcion, condiciones_uso, activa) VALUES (@nombre, @tipo_fuente, @formato, @url_origen, @descripcion, @condiciones_uso, @activa);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_fuente_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_fuente_importacion_Modificar
    @id_fuente INT,
    @nombre VARCHAR(150),
    @tipo_fuente VARCHAR(20),
    @formato VARCHAR(20) = NULL,
    @url_origen VARCHAR(1000) = NULL,
    @descripcion VARCHAR(500) = NULL,
    @condiciones_uso VARCHAR(1000) = NULL,
    @activa BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.fuente_importacion WHERE id_fuente=@id_fuente) SET @Errores += N'El registro no existe. ';
    IF @nombre IS NULL SET @Errores += N'El campo nombre es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL SET @Errores += N'El campo nombre no puede estar vacío. ';
    IF @tipo_fuente IS NULL SET @Errores += N'El campo tipo_fuente es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@tipo_fuente)), '') IS NULL SET @Errores += N'El campo tipo_fuente no puede estar vacío. ';
    IF @activa IS NULL SET @Errores += N'El campo activa es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.fuente_importacion SET nombre=@nombre,
            tipo_fuente=@tipo_fuente,
            formato=@formato,
            url_origen=@url_origen,
            descripcion=@descripcion,
            condiciones_uso=@condiciones_uso,
            activa=@activa WHERE id_fuente=@id_fuente;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_fuente_importacion_Baja
    @id_fuente INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.fuente_importacion WHERE id_fuente=@id_fuente) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.fuente_importacion WHERE id_fuente=@id_fuente;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_fuente_importacion_Consultar
    @id_fuente INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.fuente_importacion WHERE (@id_fuente IS NULL OR id_fuente=@id_fuente) ORDER BY id_fuente;
END;
GO

/* ===== LOTE_IMPORTACION ===== */
CREATE OR ALTER PROCEDURE mundial.sp_lote_importacion_Alta
    @id_fuente INT,
    @nombre_archivo VARCHAR(260) = NULL,
    @entidad_destino VARCHAR(128),
    @fecha_inicio DATETIME2(0),
    @fecha_fin DATETIME2(0) = NULL,
    @estado_lote VARCHAR(20),
    @cantidad_leidos INT,
    @cantidad_insertados INT,
    @cantidad_actualizados INT,
    @cantidad_rechazados INT,
    @hash_archivo VARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_fuente IS NULL SET @Errores += N'El campo id_fuente es obligatorio. ';
    IF @id_fuente IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.fuente_importacion WHERE id_fuente=@id_fuente) SET @Errores += N'La referencia id_fuente no existe. ';
    IF @entidad_destino IS NULL SET @Errores += N'El campo entidad_destino es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@entidad_destino)), '') IS NULL SET @Errores += N'El campo entidad_destino no puede estar vacío. ';
    IF @fecha_inicio IS NULL SET @Errores += N'El campo fecha_inicio es obligatorio. ';
    IF @estado_lote IS NULL SET @Errores += N'El campo estado_lote es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@estado_lote)), '') IS NULL SET @Errores += N'El campo estado_lote no puede estar vacío. ';
    IF @cantidad_leidos IS NULL SET @Errores += N'El campo cantidad_leidos es obligatorio. ';
    IF @cantidad_insertados IS NULL SET @Errores += N'El campo cantidad_insertados es obligatorio. ';
    IF @cantidad_actualizados IS NULL SET @Errores += N'El campo cantidad_actualizados es obligatorio. ';
    IF @cantidad_rechazados IS NULL SET @Errores += N'El campo cantidad_rechazados es obligatorio. ';
    IF @fecha_fin IS NOT NULL AND @fecha_fin<@fecha_inicio SET @Errores += N'Fechas del lote inválidas. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.lote_importacion (id_fuente, nombre_archivo, entidad_destino, fecha_inicio, fecha_fin, estado_lote, cantidad_leidos, cantidad_insertados, cantidad_actualizados, cantidad_rechazados, hash_archivo) VALUES (@id_fuente, @nombre_archivo, @entidad_destino, @fecha_inicio, @fecha_fin, @estado_lote, @cantidad_leidos, @cantidad_insertados, @cantidad_actualizados, @cantidad_rechazados, @hash_archivo);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_lote_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_lote_importacion_Modificar
    @id_lote INT,
    @id_fuente INT,
    @nombre_archivo VARCHAR(260) = NULL,
    @entidad_destino VARCHAR(128),
    @fecha_inicio DATETIME2(0),
    @fecha_fin DATETIME2(0) = NULL,
    @estado_lote VARCHAR(20),
    @cantidad_leidos INT,
    @cantidad_insertados INT,
    @cantidad_actualizados INT,
    @cantidad_rechazados INT,
    @hash_archivo VARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.lote_importacion WHERE id_lote=@id_lote) SET @Errores += N'El registro no existe. ';
    IF @id_fuente IS NULL SET @Errores += N'El campo id_fuente es obligatorio. ';
    IF @id_fuente IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.fuente_importacion WHERE id_fuente=@id_fuente) SET @Errores += N'La referencia id_fuente no existe. ';
    IF @entidad_destino IS NULL SET @Errores += N'El campo entidad_destino es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@entidad_destino)), '') IS NULL SET @Errores += N'El campo entidad_destino no puede estar vacío. ';
    IF @fecha_inicio IS NULL SET @Errores += N'El campo fecha_inicio es obligatorio. ';
    IF @estado_lote IS NULL SET @Errores += N'El campo estado_lote es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@estado_lote)), '') IS NULL SET @Errores += N'El campo estado_lote no puede estar vacío. ';
    IF @cantidad_leidos IS NULL SET @Errores += N'El campo cantidad_leidos es obligatorio. ';
    IF @cantidad_insertados IS NULL SET @Errores += N'El campo cantidad_insertados es obligatorio. ';
    IF @cantidad_actualizados IS NULL SET @Errores += N'El campo cantidad_actualizados es obligatorio. ';
    IF @cantidad_rechazados IS NULL SET @Errores += N'El campo cantidad_rechazados es obligatorio. ';
    IF @fecha_fin IS NOT NULL AND @fecha_fin<@fecha_inicio SET @Errores += N'Fechas del lote inválidas. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.lote_importacion SET id_fuente=@id_fuente,
            nombre_archivo=@nombre_archivo,
            entidad_destino=@entidad_destino,
            fecha_inicio=@fecha_inicio,
            fecha_fin=@fecha_fin,
            estado_lote=@estado_lote,
            cantidad_leidos=@cantidad_leidos,
            cantidad_insertados=@cantidad_insertados,
            cantidad_actualizados=@cantidad_actualizados,
            cantidad_rechazados=@cantidad_rechazados,
            hash_archivo=@hash_archivo WHERE id_lote=@id_lote;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_lote_importacion_Baja
    @id_lote INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.lote_importacion WHERE id_lote=@id_lote) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.lote_importacion WHERE id_lote=@id_lote;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_lote_importacion_Consultar
    @id_lote INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.lote_importacion WHERE (@id_lote IS NULL OR id_lote=@id_lote) ORDER BY id_lote;
END;
GO

/* ===== DETALLE_IMPORTACION ===== */
CREATE OR ALTER PROCEDURE mundial.sp_detalle_importacion_Alta
    @id_lote INT,
    @numero_fila INT,
    @clave_externa VARCHAR(200) = NULL,
    @tipo_operacion VARCHAR(20) = NULL,
    @estado_registro VARCHAR(20),
    @datos_originales NVARCHAR(MAX) = NULL,
    @fecha_procesamiento DATETIME2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_lote IS NULL SET @Errores += N'El campo id_lote es obligatorio. ';
    IF @id_lote IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.lote_importacion WHERE id_lote=@id_lote) SET @Errores += N'La referencia id_lote no existe. ';
    IF @numero_fila IS NULL SET @Errores += N'El campo numero_fila es obligatorio. ';
    IF @estado_registro IS NULL SET @Errores += N'El campo estado_registro es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@estado_registro)), '') IS NULL SET @Errores += N'El campo estado_registro no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.detalle_importacion (id_lote, numero_fila, clave_externa, tipo_operacion, estado_registro, datos_originales, fecha_procesamiento) VALUES (@id_lote, @numero_fila, @clave_externa, @tipo_operacion, @estado_registro, @datos_originales, @fecha_procesamiento);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS id_detalle_importacion_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_detalle_importacion_Modificar
    @id_detalle_importacion BIGINT,
    @id_lote INT,
    @numero_fila INT,
    @clave_externa VARCHAR(200) = NULL,
    @tipo_operacion VARCHAR(20) = NULL,
    @estado_registro VARCHAR(20),
    @datos_originales NVARCHAR(MAX) = NULL,
    @fecha_procesamiento DATETIME2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.detalle_importacion WHERE id_detalle_importacion=@id_detalle_importacion) SET @Errores += N'El registro no existe. ';
    IF @id_lote IS NULL SET @Errores += N'El campo id_lote es obligatorio. ';
    IF @id_lote IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.lote_importacion WHERE id_lote=@id_lote) SET @Errores += N'La referencia id_lote no existe. ';
    IF @numero_fila IS NULL SET @Errores += N'El campo numero_fila es obligatorio. ';
    IF @estado_registro IS NULL SET @Errores += N'El campo estado_registro es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@estado_registro)), '') IS NULL SET @Errores += N'El campo estado_registro no puede estar vacío. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.detalle_importacion SET id_lote=@id_lote,
            numero_fila=@numero_fila,
            clave_externa=@clave_externa,
            tipo_operacion=@tipo_operacion,
            estado_registro=@estado_registro,
            datos_originales=@datos_originales,
            fecha_procesamiento=@fecha_procesamiento WHERE id_detalle_importacion=@id_detalle_importacion;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_detalle_importacion_Baja
    @id_detalle_importacion BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.detalle_importacion WHERE id_detalle_importacion=@id_detalle_importacion) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.detalle_importacion WHERE id_detalle_importacion=@id_detalle_importacion;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_detalle_importacion_Consultar
    @id_detalle_importacion BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.detalle_importacion WHERE (@id_detalle_importacion IS NULL OR id_detalle_importacion=@id_detalle_importacion) ORDER BY id_detalle_importacion;
END;
GO

/* ===== ERROR_IMPORTACION ===== */
CREATE OR ALTER PROCEDURE mundial.sp_error_importacion_Alta
    @id_detalle_importacion BIGINT,
    @codigo_error VARCHAR(50),
    @campo_error VARCHAR(128) = NULL,
    @descripcion_error VARCHAR(1000),
    @valor_recibido NVARCHAR(MAX) = NULL,
    @fecha_error DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF @id_detalle_importacion IS NULL SET @Errores += N'El campo id_detalle_importacion es obligatorio. ';
    IF @id_detalle_importacion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.detalle_importacion WHERE id_detalle_importacion=@id_detalle_importacion) SET @Errores += N'La referencia id_detalle_importacion no existe. ';
    IF @codigo_error IS NULL SET @Errores += N'El campo codigo_error es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@codigo_error)), '') IS NULL SET @Errores += N'El campo codigo_error no puede estar vacío. ';
    IF @descripcion_error IS NULL SET @Errores += N'El campo descripcion_error es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion_error)), '') IS NULL SET @Errores += N'El campo descripcion_error no puede estar vacío. ';
    IF @fecha_error IS NULL SET @Errores += N'El campo fecha_error es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51001, @Errores, 1;
    BEGIN TRY
        INSERT INTO mundial.error_importacion (id_detalle_importacion, codigo_error, campo_error, descripcion_error, valor_recibido, fecha_error) VALUES (@id_detalle_importacion, @codigo_error, @campo_error, @descripcion_error, @valor_recibido, @fecha_error);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS id_error_creado;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'El registro duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'El registro incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_error_importacion_Modificar
    @id_error BIGINT,
    @id_detalle_importacion BIGINT,
    @codigo_error VARCHAR(50),
    @campo_error VARCHAR(128) = NULL,
    @descripcion_error VARCHAR(1000),
    @valor_recibido NVARCHAR(MAX) = NULL,
    @fecha_error DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048)=N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.error_importacion WHERE id_error=@id_error) SET @Errores += N'El registro no existe. ';
    IF @id_detalle_importacion IS NULL SET @Errores += N'El campo id_detalle_importacion es obligatorio. ';
    IF @id_detalle_importacion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mundial.detalle_importacion WHERE id_detalle_importacion=@id_detalle_importacion) SET @Errores += N'La referencia id_detalle_importacion no existe. ';
    IF @codigo_error IS NULL SET @Errores += N'El campo codigo_error es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@codigo_error)), '') IS NULL SET @Errores += N'El campo codigo_error no puede estar vacío. ';
    IF @descripcion_error IS NULL SET @Errores += N'El campo descripcion_error es obligatorio. ';
    IF NULLIF(LTRIM(RTRIM(@descripcion_error)), '') IS NULL SET @Errores += N'El campo descripcion_error no puede estar vacío. ';
    IF @fecha_error IS NULL SET @Errores += N'El campo fecha_error es obligatorio. ';
    IF LEN(@Errores)>0 THROW 51002, @Errores, 1;
    BEGIN TRY
        UPDATE mundial.error_importacion SET id_detalle_importacion=@id_detalle_importacion,
            codigo_error=@codigo_error,
            campo_error=@campo_error,
            descripcion_error=@descripcion_error,
            valor_recibido=@valor_recibido,
            fecha_error=@fecha_error WHERE id_error=@id_error;
        SELECT N'Registro modificado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (2601,2627) THROW 51005, N'La modificación duplica una clave única.', 1;
        IF ERROR_NUMBER()=547 THROW 51006, N'La modificación incumple una relación o restricción.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_error_importacion_Baja
    @id_error BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.error_importacion WHERE id_error=@id_error) THROW 51003, N'El registro no existe.', 1;
    BEGIN TRY
        DELETE FROM mundial.error_importacion WHERE id_error=@id_error;
        SELECT N'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()=547 THROW 51004, N'No puede eliminarse porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_error_importacion_Consultar
    @id_error BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.error_importacion WHERE (@id_error IS NULL OR id_error=@id_error) ORDER BY id_error;
END;
GO
