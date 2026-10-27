--CREACION SP ABM Catalogos
USE TP2026
GO

/*
Integrantes: Quispe Sergio, Lopez Santiago, Coria Lautaro y Santos Jonatan
Descripcion: Procedimientos almacenados ABM y consulta para las tablas catalogo
             de la base de datos del Sistema de Registro y Gestion del Mundial.

IMPORTANTE:
- Ejecutar luego de crear la base, el esquema mundial y todas las tablas.
- Los procedimientos validan datos basicos y agrupan los errores detectados.
- Las bajas fisicas se intentan solo si el registro no esta referenciado.
- Este archivo no incluye datos de prueba; crear los tests en scripts separados.
*/
SET NOCOUNT ON;
GO

-- =========================================================
-- ABM y consulta: mundial.confederacion
-- =========================================================

CREATE OR ALTER PROCEDURE mundial.sp_confederacion_Alta
    @id_confederacion INT,
    @nombre VARCHAR(20),
    @sigla VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = '' SET @Errores += 'El campo nombre es obligatorio. ';
    IF @sigla IS NULL OR LTRIM(RTRIM(@sigla)) = '' SET @Errores += 'El campo sigla es obligatorio. ';
    IF @sigla IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.confederacion WHERE sigla = @sigla)
        SET @Errores += 'El valor de sigla ya existe. ';
    IF EXISTS (SELECT 1 FROM mundial.confederacion WHERE id_confederacion = @id_confederacion)
        SET @Errores += 'El identificador id_confederacion ya existe. ';
    IF LEN(@Errores) > 0 THROW 50001, @Errores, 1;
    INSERT INTO mundial.confederacion (id_confederacion, nombre, sigla)
    VALUES (@id_confederacion, @nombre, @sigla);
    SELECT @id_confederacion AS id_confederacion_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_confederacion_Modificar
    @id_confederacion INT,
    @nombre VARCHAR(20),
    @sigla VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF NOT EXISTS (SELECT 1 FROM mundial.confederacion WHERE id_confederacion = @id_confederacion)
        SET @Errores += 'No existe un registro con id_confederacion indicado. ';
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = '' SET @Errores += 'El campo nombre es obligatorio. ';
    IF @sigla IS NULL OR LTRIM(RTRIM(@sigla)) = '' SET @Errores += 'El campo sigla es obligatorio. ';
    IF @sigla IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.confederacion WHERE sigla = @sigla AND id_confederacion <> @id_confederacion)
        SET @Errores += 'El valor de sigla ya esta registrado en otro registro. ';
    IF LEN(@Errores) > 0 THROW 50002, @Errores, 1;
    UPDATE mundial.confederacion
    SET nombre = @nombre,
        sigla = @sigla
    WHERE id_confederacion = @id_confederacion;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_confederacion_Baja
    @id_confederacion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.confederacion WHERE id_confederacion = @id_confederacion)
        THROW 50003, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.confederacion WHERE id_confederacion = @id_confederacion;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (547)
            THROW 50004, 'No se puede eliminar el registro porque esta relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_confederacion_Consultar
    @id_confederacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.confederacion
    WHERE @id_confederacion IS NULL OR id_confederacion = @id_confederacion
    ORDER BY id_confederacion;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.grupo
-- =========================================================

CREATE OR ALTER PROCEDURE mundial.sp_grupo_Alta
    @nombre_grupo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF @nombre_grupo IS NULL OR LTRIM(RTRIM(@nombre_grupo)) = '' SET @Errores += 'El campo nombre_grupo es obligatorio. ';
    IF @nombre_grupo IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.grupo WHERE nombre_grupo = @nombre_grupo)
        SET @Errores += 'El valor de nombre_grupo ya existe. ';
    IF LEN(@Errores) > 0 THROW 50001, @Errores, 1;
    INSERT INTO mundial.grupo (nombre_grupo)
    VALUES (@nombre_grupo);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_grupo_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_grupo_Modificar
    @id_grupo INT,
    @nombre_grupo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF NOT EXISTS (SELECT 1 FROM mundial.grupo WHERE id_grupo = @id_grupo)
        SET @Errores += 'No existe un registro con id_grupo indicado. ';
    IF @nombre_grupo IS NULL OR LTRIM(RTRIM(@nombre_grupo)) = '' SET @Errores += 'El campo nombre_grupo es obligatorio. ';
    IF @nombre_grupo IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.grupo WHERE nombre_grupo = @nombre_grupo AND id_grupo <> @id_grupo)
        SET @Errores += 'El valor de nombre_grupo ya esta registrado en otro registro. ';
    IF LEN(@Errores) > 0 THROW 50002, @Errores, 1;
    UPDATE mundial.grupo
    SET nombre_grupo = @nombre_grupo
    WHERE id_grupo = @id_grupo;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_grupo_Baja
    @id_grupo INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.grupo WHERE id_grupo = @id_grupo)
        THROW 50003, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.grupo WHERE id_grupo = @id_grupo;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (547)
            THROW 50004, 'No se puede eliminar el registro porque esta relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_grupo_Consultar
    @id_grupo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.grupo
    WHERE @id_grupo IS NULL OR id_grupo = @id_grupo
    ORDER BY id_grupo;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.fase
-- =========================================================

CREATE OR ALTER PROCEDURE mundial.sp_fase_Alta
    @nombre_fase VARCHAR(20),
    @orden INT,
    @permite_alargue BIT,
    @permite_penales BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF @nombre_fase IS NULL OR LTRIM(RTRIM(@nombre_fase)) = '' SET @Errores += 'El campo nombre_fase es obligatorio. ';
    IF @orden IS NULL SET @Errores += 'El campo orden es obligatorio. ';
    IF @permite_alargue IS NULL SET @Errores += 'El campo permite_alargue es obligatorio. ';
    IF @permite_penales IS NULL SET @Errores += 'El campo permite_penales es obligatorio. ';
    IF @orden <= 0 SET @Errores += 'El orden debe ser mayor que cero. ';
    IF @nombre_fase IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.fase WHERE nombre_fase = @nombre_fase)
        SET @Errores += 'El valor de nombre_fase ya existe. ';
    IF @orden IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.fase WHERE orden = @orden)
        SET @Errores += 'El valor de orden ya existe. ';
    IF LEN(@Errores) > 0 THROW 50001, @Errores, 1;
    INSERT INTO mundial.fase (nombre_fase, orden, permite_alargue, permite_penales)
    VALUES (@nombre_fase, @orden, @permite_alargue, @permite_penales);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_fase_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_fase_Modificar
    @id_fase INT,
    @nombre_fase VARCHAR(20),
    @orden INT,
    @permite_alargue BIT,
    @permite_penales BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF NOT EXISTS (SELECT 1 FROM mundial.fase WHERE id_fase = @id_fase)
        SET @Errores += 'No existe un registro con id_fase indicado. ';
    IF @nombre_fase IS NULL OR LTRIM(RTRIM(@nombre_fase)) = '' SET @Errores += 'El campo nombre_fase es obligatorio. ';
    IF @orden IS NULL SET @Errores += 'El campo orden es obligatorio. ';
    IF @permite_alargue IS NULL SET @Errores += 'El campo permite_alargue es obligatorio. ';
    IF @permite_penales IS NULL SET @Errores += 'El campo permite_penales es obligatorio. ';
    IF @orden <= 0 SET @Errores += 'El orden debe ser mayor que cero. ';
    IF @nombre_fase IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.fase WHERE nombre_fase = @nombre_fase AND id_fase <> @id_fase)
        SET @Errores += 'El valor de nombre_fase ya esta registrado en otro registro. ';
    IF @orden IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.fase WHERE orden = @orden AND id_fase <> @id_fase)
        SET @Errores += 'El valor de orden ya esta registrado en otro registro. ';
    IF LEN(@Errores) > 0 THROW 50002, @Errores, 1;
    UPDATE mundial.fase
    SET nombre_fase = @nombre_fase,
        orden = @orden,
        permite_alargue = @permite_alargue,
        permite_penales = @permite_penales
    WHERE id_fase = @id_fase;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_fase_Baja
    @id_fase INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.fase WHERE id_fase = @id_fase)
        THROW 50003, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.fase WHERE id_fase = @id_fase;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (547)
            THROW 50004, 'No se puede eliminar el registro porque esta relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_fase_Consultar
    @id_fase INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.fase
    WHERE @id_fase IS NULL OR id_fase = @id_fase
    ORDER BY id_fase;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.idioma
-- =========================================================

CREATE OR ALTER PROCEDURE mundial.sp_idioma_Alta
    @nombre_idioma VARCHAR(20),
    @codigo_iso VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF @nombre_idioma IS NULL OR LTRIM(RTRIM(@nombre_idioma)) = '' SET @Errores += 'El campo nombre_idioma es obligatorio. ';
    IF @codigo_iso IS NULL OR LTRIM(RTRIM(@codigo_iso)) = '' SET @Errores += 'El campo codigo_iso es obligatorio. ';
    IF @codigo_iso IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.idioma WHERE codigo_iso = @codigo_iso)
        SET @Errores += 'El valor de codigo_iso ya existe. ';
    IF LEN(@Errores) > 0 THROW 50001, @Errores, 1;
    INSERT INTO mundial.idioma (nombre_idioma, codigo_iso)
    VALUES (@nombre_idioma, @codigo_iso);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_idioma_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_idioma_Modificar
    @id_idioma INT,
    @nombre_idioma VARCHAR(20),
    @codigo_iso VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF NOT EXISTS (SELECT 1 FROM mundial.idioma WHERE id_idioma = @id_idioma)
        SET @Errores += 'No existe un registro con id_idioma indicado. ';
    IF @nombre_idioma IS NULL OR LTRIM(RTRIM(@nombre_idioma)) = '' SET @Errores += 'El campo nombre_idioma es obligatorio. ';
    IF @codigo_iso IS NULL OR LTRIM(RTRIM(@codigo_iso)) = '' SET @Errores += 'El campo codigo_iso es obligatorio. ';
    IF @codigo_iso IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.idioma WHERE codigo_iso = @codigo_iso AND id_idioma <> @id_idioma)
        SET @Errores += 'El valor de codigo_iso ya esta registrado en otro registro. ';
    IF LEN(@Errores) > 0 THROW 50002, @Errores, 1;
    UPDATE mundial.idioma
    SET nombre_idioma = @nombre_idioma,
        codigo_iso = @codigo_iso
    WHERE id_idioma = @id_idioma;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_idioma_Baja
    @id_idioma INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.idioma WHERE id_idioma = @id_idioma)
        THROW 50003, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.idioma WHERE id_idioma = @id_idioma;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (547)
            THROW 50004, 'No se puede eliminar el registro porque esta relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_idioma_Consultar
    @id_idioma INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.idioma
    WHERE @id_idioma IS NULL OR id_idioma = @id_idioma
    ORDER BY id_idioma;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.moneda
-- =========================================================

CREATE OR ALTER PROCEDURE mundial.sp_moneda_Alta
    @codigo_iso VARCHAR(50),
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF @codigo_iso IS NULL OR LTRIM(RTRIM(@codigo_iso)) = '' SET @Errores += 'El campo codigo_iso es obligatorio. ';
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = '' SET @Errores += 'El campo descripcion es obligatorio. ';
    IF @codigo_iso IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.moneda WHERE codigo_iso = @codigo_iso)
        SET @Errores += 'El valor de codigo_iso ya existe. ';
    IF LEN(@Errores) > 0 THROW 50001, @Errores, 1;
    INSERT INTO mundial.moneda (codigo_iso, descripcion)
    VALUES (@codigo_iso, @descripcion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_moneda_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_moneda_Modificar
    @id_moneda INT,
    @codigo_iso VARCHAR(50),
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF NOT EXISTS (SELECT 1 FROM mundial.moneda WHERE id_moneda = @id_moneda)
        SET @Errores += 'No existe un registro con id_moneda indicado. ';
    IF @codigo_iso IS NULL OR LTRIM(RTRIM(@codigo_iso)) = '' SET @Errores += 'El campo codigo_iso es obligatorio. ';
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = '' SET @Errores += 'El campo descripcion es obligatorio. ';
    IF @codigo_iso IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.moneda WHERE codigo_iso = @codigo_iso AND id_moneda <> @id_moneda)
        SET @Errores += 'El valor de codigo_iso ya esta registrado en otro registro. ';
    IF LEN(@Errores) > 0 THROW 50002, @Errores, 1;
    UPDATE mundial.moneda
    SET codigo_iso = @codigo_iso,
        descripcion = @descripcion
    WHERE id_moneda = @id_moneda;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_moneda_Baja
    @id_moneda INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.moneda WHERE id_moneda = @id_moneda)
        THROW 50003, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.moneda WHERE id_moneda = @id_moneda;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (547)
            THROW 50004, 'No se puede eliminar el registro porque esta relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_moneda_Consultar
    @id_moneda INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.moneda
    WHERE @id_moneda IS NULL OR id_moneda = @id_moneda
    ORDER BY id_moneda;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.posicion
-- =========================================================

CREATE OR ALTER PROCEDURE mundial.sp_posicion_Alta
    @codigo VARCHAR(20),
    @descripcion VARCHAR(20),
    @linea_campo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF @codigo IS NULL OR LTRIM(RTRIM(@codigo)) = '' SET @Errores += 'El campo codigo es obligatorio. ';
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = '' SET @Errores += 'El campo descripcion es obligatorio. ';
    IF @linea_campo IS NULL OR LTRIM(RTRIM(@linea_campo)) = '' SET @Errores += 'El campo linea_campo es obligatorio. ';
    IF @codigo IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.posicion WHERE codigo = @codigo)
        SET @Errores += 'El valor de codigo ya existe. ';
    IF LEN(@Errores) > 0 THROW 50001, @Errores, 1;
    INSERT INTO mundial.posicion (codigo, descripcion, linea_campo)
    VALUES (@codigo, @descripcion, @linea_campo);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_posicion_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_posicion_Modificar
    @id_posicion INT,
    @codigo VARCHAR(20),
    @descripcion VARCHAR(20),
    @linea_campo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF NOT EXISTS (SELECT 1 FROM mundial.posicion WHERE id_posicion = @id_posicion)
        SET @Errores += 'No existe un registro con id_posicion indicado. ';
    IF @codigo IS NULL OR LTRIM(RTRIM(@codigo)) = '' SET @Errores += 'El campo codigo es obligatorio. ';
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = '' SET @Errores += 'El campo descripcion es obligatorio. ';
    IF @linea_campo IS NULL OR LTRIM(RTRIM(@linea_campo)) = '' SET @Errores += 'El campo linea_campo es obligatorio. ';
    IF @codigo IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.posicion WHERE codigo = @codigo AND id_posicion <> @id_posicion)
        SET @Errores += 'El valor de codigo ya esta registrado en otro registro. ';
    IF LEN(@Errores) > 0 THROW 50002, @Errores, 1;
    UPDATE mundial.posicion
    SET codigo = @codigo,
        descripcion = @descripcion,
        linea_campo = @linea_campo
    WHERE id_posicion = @id_posicion;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_posicion_Baja
    @id_posicion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.posicion WHERE id_posicion = @id_posicion)
        THROW 50003, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.posicion WHERE id_posicion = @id_posicion;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (547)
            THROW 50004, 'No se puede eliminar el registro porque esta relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_posicion_Consultar
    @id_posicion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.posicion
    WHERE @id_posicion IS NULL OR id_posicion = @id_posicion
    ORDER BY id_posicion;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.rol_cuerpo_tecnico
-- =========================================================

CREATE OR ALTER PROCEDURE mundial.sp_rol_cuerpo_tecnico_Alta
    @descripcion VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = '' SET @Errores += 'El campo descripcion es obligatorio. ';
    IF @descripcion IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.rol_cuerpo_tecnico WHERE descripcion = @descripcion)
        SET @Errores += 'El valor de descripcion ya existe. ';
    IF LEN(@Errores) > 0 THROW 50001, @Errores, 1;
    INSERT INTO mundial.rol_cuerpo_tecnico (descripcion)
    VALUES (@descripcion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_rol_ct_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_rol_cuerpo_tecnico_Modificar
    @id_rol_ct INT,
    @descripcion VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF NOT EXISTS (SELECT 1 FROM mundial.rol_cuerpo_tecnico WHERE id_rol_ct = @id_rol_ct)
        SET @Errores += 'No existe un registro con id_rol_ct indicado. ';
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = '' SET @Errores += 'El campo descripcion es obligatorio. ';
    IF @descripcion IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.rol_cuerpo_tecnico WHERE descripcion = @descripcion AND id_rol_ct <> @id_rol_ct)
        SET @Errores += 'El valor de descripcion ya esta registrado en otro registro. ';
    IF LEN(@Errores) > 0 THROW 50002, @Errores, 1;
    UPDATE mundial.rol_cuerpo_tecnico
    SET descripcion = @descripcion
    WHERE id_rol_ct = @id_rol_ct;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_rol_cuerpo_tecnico_Baja
    @id_rol_ct INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.rol_cuerpo_tecnico WHERE id_rol_ct = @id_rol_ct)
        THROW 50003, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.rol_cuerpo_tecnico WHERE id_rol_ct = @id_rol_ct;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (547)
            THROW 50004, 'No se puede eliminar el registro porque esta relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_rol_cuerpo_tecnico_Consultar
    @id_rol_ct INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.rol_cuerpo_tecnico
    WHERE @id_rol_ct IS NULL OR id_rol_ct = @id_rol_ct
    ORDER BY id_rol_ct;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.rol_arbitral
-- =========================================================

CREATE OR ALTER PROCEDURE mundial.sp_rol_arbitral_Alta
    @descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = '' SET @Errores += 'El campo descripcion es obligatorio. ';
    IF @descripcion IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.rol_arbitral WHERE descripcion = @descripcion)
        SET @Errores += 'El valor de descripcion ya existe. ';
    IF LEN(@Errores) > 0 THROW 50001, @Errores, 1;
    INSERT INTO mundial.rol_arbitral (descripcion)
    VALUES (@descripcion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_rol_arbitral_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_rol_arbitral_Modificar
    @id_rol_arbitral INT,
    @descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF NOT EXISTS (SELECT 1 FROM mundial.rol_arbitral WHERE id_rol_arbitral = @id_rol_arbitral)
        SET @Errores += 'No existe un registro con id_rol_arbitral indicado. ';
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = '' SET @Errores += 'El campo descripcion es obligatorio. ';
    IF @descripcion IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.rol_arbitral WHERE descripcion = @descripcion AND id_rol_arbitral <> @id_rol_arbitral)
        SET @Errores += 'El valor de descripcion ya esta registrado en otro registro. ';
    IF LEN(@Errores) > 0 THROW 50002, @Errores, 1;
    UPDATE mundial.rol_arbitral
    SET descripcion = @descripcion
    WHERE id_rol_arbitral = @id_rol_arbitral;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_rol_arbitral_Baja
    @id_rol_arbitral INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.rol_arbitral WHERE id_rol_arbitral = @id_rol_arbitral)
        THROW 50003, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.rol_arbitral WHERE id_rol_arbitral = @id_rol_arbitral;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (547)
            THROW 50004, 'No se puede eliminar el registro porque esta relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_rol_arbitral_Consultar
    @id_rol_arbitral INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.rol_arbitral
    WHERE @id_rol_arbitral IS NULL OR id_rol_arbitral = @id_rol_arbitral
    ORDER BY id_rol_arbitral;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.tipo_gol
-- =========================================================

CREATE OR ALTER PROCEDURE mundial.sp_tipo_gol_Alta
    @descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = '' SET @Errores += 'El campo descripcion es obligatorio. ';
    IF @descripcion IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.tipo_gol WHERE descripcion = @descripcion)
        SET @Errores += 'El valor de descripcion ya existe. ';
    IF LEN(@Errores) > 0 THROW 50001, @Errores, 1;
    INSERT INTO mundial.tipo_gol (descripcion)
    VALUES (@descripcion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_tipo_gol_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_tipo_gol_Modificar
    @id_tipo_gol INT,
    @descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF NOT EXISTS (SELECT 1 FROM mundial.tipo_gol WHERE id_tipo_gol = @id_tipo_gol)
        SET @Errores += 'No existe un registro con id_tipo_gol indicado. ';
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = '' SET @Errores += 'El campo descripcion es obligatorio. ';
    IF @descripcion IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.tipo_gol WHERE descripcion = @descripcion AND id_tipo_gol <> @id_tipo_gol)
        SET @Errores += 'El valor de descripcion ya esta registrado en otro registro. ';
    IF LEN(@Errores) > 0 THROW 50002, @Errores, 1;
    UPDATE mundial.tipo_gol
    SET descripcion = @descripcion
    WHERE id_tipo_gol = @id_tipo_gol;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_tipo_gol_Baja
    @id_tipo_gol INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.tipo_gol WHERE id_tipo_gol = @id_tipo_gol)
        THROW 50003, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.tipo_gol WHERE id_tipo_gol = @id_tipo_gol;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (547)
            THROW 50004, 'No se puede eliminar el registro porque esta relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_tipo_gol_Consultar
    @id_tipo_gol INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.tipo_gol
    WHERE @id_tipo_gol IS NULL OR id_tipo_gol = @id_tipo_gol
    ORDER BY id_tipo_gol;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.tipo_tarjeta
-- =========================================================

CREATE OR ALTER PROCEDURE mundial.sp_tipo_tarjeta_Alta
    @descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = '' SET @Errores += 'El campo descripcion es obligatorio. ';
    IF @descripcion IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.tipo_tarjeta WHERE descripcion = @descripcion)
        SET @Errores += 'El valor de descripcion ya existe. ';
    IF LEN(@Errores) > 0 THROW 50001, @Errores, 1;
    INSERT INTO mundial.tipo_tarjeta (descripcion)
    VALUES (@descripcion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_tipo_tarjeta_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_tipo_tarjeta_Modificar
    @id_tipo_tarjeta INT,
    @descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF NOT EXISTS (SELECT 1 FROM mundial.tipo_tarjeta WHERE id_tipo_tarjeta = @id_tipo_tarjeta)
        SET @Errores += 'No existe un registro con id_tipo_tarjeta indicado. ';
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = '' SET @Errores += 'El campo descripcion es obligatorio. ';
    IF @descripcion IS NOT NULL AND EXISTS (SELECT 1 FROM mundial.tipo_tarjeta WHERE descripcion = @descripcion AND id_tipo_tarjeta <> @id_tipo_tarjeta)
        SET @Errores += 'El valor de descripcion ya esta registrado en otro registro. ';
    IF LEN(@Errores) > 0 THROW 50002, @Errores, 1;
    UPDATE mundial.tipo_tarjeta
    SET descripcion = @descripcion
    WHERE id_tipo_tarjeta = @id_tipo_tarjeta;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_tipo_tarjeta_Baja
    @id_tipo_tarjeta INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.tipo_tarjeta WHERE id_tipo_tarjeta = @id_tipo_tarjeta)
        THROW 50003, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.tipo_tarjeta WHERE id_tipo_tarjeta = @id_tipo_tarjeta;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (547)
            THROW 50004, 'No se puede eliminar el registro porque esta relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_tipo_tarjeta_Consultar
    @id_tipo_tarjeta INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.tipo_tarjeta
    WHERE @id_tipo_tarjeta IS NULL OR id_tipo_tarjeta = @id_tipo_tarjeta
    ORDER BY id_tipo_tarjeta;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.criterio_suspension
-- =========================================================

CREATE OR ALTER PROCEDURE mundial.sp_criterio_suspension_Alta
    @cantidad_amarillas INT,
    @fase_aplicable VARCHAR(20),
    @partidos_suspension INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF @cantidad_amarillas IS NULL SET @Errores += 'El campo cantidad_amarillas es obligatorio. ';
    IF @fase_aplicable IS NULL OR LTRIM(RTRIM(@fase_aplicable)) = '' SET @Errores += 'El campo fase_aplicable es obligatorio. ';
    IF @partidos_suspension IS NULL SET @Errores += 'El campo partidos_suspension es obligatorio. ';
    IF @cantidad_amarillas <= 0 SET @Errores += 'La cantidad de amarillas debe ser mayor que cero. ';
    IF @partidos_suspension <= 0 SET @Errores += 'Los partidos de suspension deben ser mayores que cero. ';
    IF LEN(@Errores) > 0 THROW 50001, @Errores, 1;
    INSERT INTO mundial.criterio_suspension (cantidad_amarillas, fase_aplicable, partidos_suspension)
    VALUES (@cantidad_amarillas, @fase_aplicable, @partidos_suspension);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_criterio_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_criterio_suspension_Modificar
    @id_criterio INT,
    @cantidad_amarillas INT,
    @fase_aplicable VARCHAR(20),
    @partidos_suspension INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores VARCHAR(2048) = '';
    IF NOT EXISTS (SELECT 1 FROM mundial.criterio_suspension WHERE id_criterio = @id_criterio)
        SET @Errores += 'No existe un registro con id_criterio indicado. ';
    IF @cantidad_amarillas IS NULL SET @Errores += 'El campo cantidad_amarillas es obligatorio. ';
    IF @fase_aplicable IS NULL OR LTRIM(RTRIM(@fase_aplicable)) = '' SET @Errores += 'El campo fase_aplicable es obligatorio. ';
    IF @partidos_suspension IS NULL SET @Errores += 'El campo partidos_suspension es obligatorio. ';
    IF @cantidad_amarillas <= 0 SET @Errores += 'La cantidad de amarillas debe ser mayor que cero. ';
    IF @partidos_suspension <= 0 SET @Errores += 'Los partidos de suspension deben ser mayores que cero. ';
    IF LEN(@Errores) > 0 THROW 50002, @Errores, 1;
    UPDATE mundial.criterio_suspension
    SET cantidad_amarillas = @cantidad_amarillas,
        fase_aplicable = @fase_aplicable,
        partidos_suspension = @partidos_suspension
    WHERE id_criterio = @id_criterio;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_criterio_suspension_Baja
    @id_criterio INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.criterio_suspension WHERE id_criterio = @id_criterio)
        THROW 50003, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.criterio_suspension WHERE id_criterio = @id_criterio;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (547)
            THROW 50004, 'No se puede eliminar el registro porque esta relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_criterio_suspension_Consultar
    @id_criterio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.criterio_suspension
    WHERE @id_criterio IS NULL OR id_criterio = @id_criterio
    ORDER BY id_criterio;
END;
GO


-- =========================================================
-- ABM y consulta: mundial.pais
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_pais_Alta
    @id_confederacion INT,
    @nombre VARCHAR(20),
    @codigo_iso VARCHAR(20),
    @huso_horario_estandar VARCHAR(10),
    @huso_horario_minutos_utc SMALLINT,
    @pbi_per_capita DECIMAL(10,2),
    @codigo_moneda VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = '' SET @Errores += N'El campo nombre es obligatorio. ';
    IF @codigo_iso IS NULL OR LTRIM(RTRIM(@codigo_iso)) = '' SET @Errores += N'El campo codigo_iso es obligatorio. ';
    IF @pbi_per_capita < 0 SET @Errores += N'El PBI per cápita no puede ser negativo. ';
    IF EXISTS (SELECT 1 FROM mundial.pais t WHERE t.codigo_iso = @codigo_iso) SET @Errores += N'Ya existe un registro con la combinación codigo_iso. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.pais (id_confederacion, nombre, codigo_iso, huso_horario_estandar, huso_horario_minutos_utc, pbi_per_capita, codigo_moneda)
    VALUES (@id_confederacion, @nombre, @codigo_iso, @huso_horario_estandar, @huso_horario_minutos_utc, @pbi_per_capita, @codigo_moneda);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_pais_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_pais_Modificar
    @id_pais INT,
    @id_confederacion INT,
    @nombre VARCHAR(20),
    @codigo_iso VARCHAR(20),
    @huso_horario_estandar VARCHAR(10),
    @huso_horario_minutos_utc SMALLINT,
    @pbi_per_capita DECIMAL(10,2),
    @codigo_moneda VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais = @id_pais) SET @Errores += N'No existe el registro indicado. ';
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = '' SET @Errores += N'El campo nombre es obligatorio. ';
    IF @codigo_iso IS NULL OR LTRIM(RTRIM(@codigo_iso)) = '' SET @Errores += N'El campo codigo_iso es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.pais t WHERE t.codigo_iso = @codigo_iso AND t.id_pais <> @id_pais) SET @Errores += N'Ya existe otro registro con la combinación codigo_iso. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.pais
    SET id_confederacion = @id_confederacion,
        nombre = @nombre,
        codigo_iso = @codigo_iso,
        huso_horario_estandar = @huso_horario_estandar,
        huso_horario_minutos_utc = @huso_horario_minutos_utc,
        pbi_per_capita = @pbi_per_capita,
        codigo_moneda = @codigo_moneda
    WHERE id_pais = @id_pais;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_pais_Baja
    @id_pais INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.pais WHERE id_pais = @id_pais) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.pais WHERE id_pais = @id_pais;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_pais_Consultar
    @id_pais INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.pais
    WHERE (@id_pais IS NULL OR id_pais = @id_pais)
    ORDER BY id_pais;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.seleccion
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_seleccion_Alta
    @id_pais INT,
    @id_grupo INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_pais IS NULL SET @Errores += N'El campo id_pais es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.seleccion t WHERE t.id_pais = @id_pais) SET @Errores += N'Ya existe un registro con la combinación id_pais. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.seleccion (id_pais, id_grupo)
    VALUES (@id_pais, @id_grupo);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_seleccion_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_seleccion_Modificar
    @id_seleccion INT,
    @id_pais INT,
    @id_grupo INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion = @id_seleccion) SET @Errores += N'No existe el registro indicado. ';
    IF @id_pais IS NULL SET @Errores += N'El campo id_pais es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.seleccion t WHERE t.id_pais = @id_pais AND t.id_seleccion <> @id_seleccion) SET @Errores += N'Ya existe otro registro con la combinación id_pais. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.seleccion
    SET id_pais = @id_pais,
        id_grupo = @id_grupo
    WHERE id_seleccion = @id_seleccion;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_seleccion_Baja
    @id_seleccion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.seleccion WHERE id_seleccion = @id_seleccion) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.seleccion WHERE id_seleccion = @id_seleccion;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_seleccion_Consultar
    @id_seleccion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.seleccion
    WHERE (@id_seleccion IS NULL OR id_seleccion = @id_seleccion)
    ORDER BY id_seleccion;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.club
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_club_Alta
    @id_pais INT,
    @nombre_club VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @nombre_club IS NULL OR LTRIM(RTRIM(@nombre_club)) = '' SET @Errores += N'El campo nombre_club es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.club t WHERE t.id_pais = @id_pais AND t.nombre_club = @nombre_club) SET @Errores += N'Ya existe un registro con la combinación id_pais, nombre_club. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.club (id_pais, nombre_club)
    VALUES (@id_pais, @nombre_club);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_club_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_club_Modificar
    @id_club INT,
    @id_pais INT,
    @nombre_club VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.club WHERE id_club = @id_club) SET @Errores += N'No existe el registro indicado. ';
    IF @nombre_club IS NULL OR LTRIM(RTRIM(@nombre_club)) = '' SET @Errores += N'El campo nombre_club es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.club t WHERE t.id_pais = @id_pais AND t.nombre_club = @nombre_club AND t.id_club <> @id_club) SET @Errores += N'Ya existe otro registro con la combinación id_pais, nombre_club. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.club
    SET id_pais = @id_pais,
        nombre_club = @nombre_club
    WHERE id_club = @id_club;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_club_Baja
    @id_club INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.club WHERE id_club = @id_club) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.club WHERE id_club = @id_club;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_club_Consultar
    @id_club INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.club
    WHERE (@id_club IS NULL OR id_club = @id_club)
    ORDER BY id_club;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.cuerpo_tecnico
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_cuerpo_tecnico_Alta
    @id_seleccion INT,
    @id_pais_nacionalidad INT,
    @id_rol_ct INT,
    @nombres VARCHAR(20),
    @apellidos VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @nombres IS NULL OR LTRIM(RTRIM(@nombres)) = '' SET @Errores += N'El campo nombres es obligatorio. ';
    IF @apellidos IS NULL OR LTRIM(RTRIM(@apellidos)) = '' SET @Errores += N'El campo apellidos es obligatorio. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.cuerpo_tecnico (id_seleccion, id_pais_nacionalidad, id_rol_ct, nombres, apellidos)
    VALUES (@id_seleccion, @id_pais_nacionalidad, @id_rol_ct, @nombres, @apellidos);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_cuerpo_tecnico_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_cuerpo_tecnico_Modificar
    @id_miembro_ct INT,
    @id_seleccion INT,
    @id_pais_nacionalidad INT,
    @id_rol_ct INT,
    @nombres VARCHAR(20),
    @apellidos VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.cuerpo_tecnico WHERE id_miembro_ct = @id_miembro_ct) SET @Errores += N'No existe el registro indicado. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @nombres IS NULL OR LTRIM(RTRIM(@nombres)) = '' SET @Errores += N'El campo nombres es obligatorio. ';
    IF @apellidos IS NULL OR LTRIM(RTRIM(@apellidos)) = '' SET @Errores += N'El campo apellidos es obligatorio. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.cuerpo_tecnico
    SET id_seleccion = @id_seleccion,
        id_pais_nacionalidad = @id_pais_nacionalidad,
        id_rol_ct = @id_rol_ct,
        nombres = @nombres,
        apellidos = @apellidos
    WHERE id_miembro_ct = @id_miembro_ct;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_cuerpo_tecnico_Baja
    @id_miembro_ct INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.cuerpo_tecnico WHERE id_miembro_ct = @id_miembro_ct) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.cuerpo_tecnico WHERE id_miembro_ct = @id_miembro_ct;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_cuerpo_tecnico_Consultar
    @id_miembro_ct INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.cuerpo_tecnico
    WHERE (@id_miembro_ct IS NULL OR id_miembro_ct = @id_miembro_ct)
    ORDER BY id_miembro_ct;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.ciudad
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_ciudad_Alta
    @id_pais INT,
    @nombre VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_pais IS NULL SET @Errores += N'El campo id_pais es obligatorio. ';
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = '' SET @Errores += N'El campo nombre es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.ciudad t WHERE t.id_pais = @id_pais AND t.nombre = @nombre) SET @Errores += N'Ya existe un registro con la combinación id_pais, nombre. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.ciudad (id_pais, nombre)
    VALUES (@id_pais, @nombre);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_ciudad_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_ciudad_Modificar
    @id_ciudad INT,
    @id_pais INT,
    @nombre VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.ciudad WHERE id_ciudad = @id_ciudad) SET @Errores += N'No existe el registro indicado. ';
    IF @id_pais IS NULL SET @Errores += N'El campo id_pais es obligatorio. ';
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = '' SET @Errores += N'El campo nombre es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.ciudad t WHERE t.id_pais = @id_pais AND t.nombre = @nombre AND t.id_ciudad <> @id_ciudad) SET @Errores += N'Ya existe otro registro con la combinación id_pais, nombre. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.ciudad
    SET id_pais = @id_pais,
        nombre = @nombre
    WHERE id_ciudad = @id_ciudad;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_ciudad_Baja
    @id_ciudad INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.ciudad WHERE id_ciudad = @id_ciudad) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.ciudad WHERE id_ciudad = @id_ciudad;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_ciudad_Consultar
    @id_ciudad INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.ciudad
    WHERE (@id_ciudad IS NULL OR id_ciudad = @id_ciudad)
    ORDER BY id_ciudad;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.anunciante
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_anunciante_Alta
    @id_pais_origen INT,
    @razon_social VARCHAR(20),
    @identificador_fiscal VARCHAR(20),
    @email_contacto VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @razon_social IS NULL OR LTRIM(RTRIM(@razon_social)) = '' SET @Errores += N'El campo razon_social es obligatorio. ';
    IF @identificador_fiscal IS NULL OR LTRIM(RTRIM(@identificador_fiscal)) = '' SET @Errores += N'El campo identificador_fiscal es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.anunciante t WHERE t.identificador_fiscal = @identificador_fiscal) SET @Errores += N'Ya existe un registro con la combinación identificador_fiscal. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.anunciante (id_pais_origen, razon_social, identificador_fiscal, email_contacto)
    VALUES (@id_pais_origen, @razon_social, @identificador_fiscal, @email_contacto);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_anunciante_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_anunciante_Modificar
    @id_anunciante INT,
    @id_pais_origen INT,
    @razon_social VARCHAR(20),
    @identificador_fiscal VARCHAR(20),
    @email_contacto VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.anunciante WHERE id_anunciante = @id_anunciante) SET @Errores += N'No existe el registro indicado. ';
    IF @razon_social IS NULL OR LTRIM(RTRIM(@razon_social)) = '' SET @Errores += N'El campo razon_social es obligatorio. ';
    IF @identificador_fiscal IS NULL OR LTRIM(RTRIM(@identificador_fiscal)) = '' SET @Errores += N'El campo identificador_fiscal es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.anunciante t WHERE t.identificador_fiscal = @identificador_fiscal AND t.id_anunciante <> @id_anunciante) SET @Errores += N'Ya existe otro registro con la combinación identificador_fiscal. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.anunciante
    SET id_pais_origen = @id_pais_origen,
        razon_social = @razon_social,
        identificador_fiscal = @identificador_fiscal,
        email_contacto = @email_contacto
    WHERE id_anunciante = @id_anunciante;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_anunciante_Baja
    @id_anunciante INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.anunciante WHERE id_anunciante = @id_anunciante) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.anunciante WHERE id_anunciante = @id_anunciante;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_anunciante_Consultar
    @id_anunciante INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.anunciante
    WHERE (@id_anunciante IS NULL OR id_anunciante = @id_anunciante)
    ORDER BY id_anunciante;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.arbitro
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_Alta
    @id_pais_nacionalidad INT,
    @id_confederacion INT,
    @nombres VARCHAR(20),
    @apellidos VARCHAR(20),
    @fecha_nacimiento DATE,
    @categoria VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_pais_nacionalidad IS NULL SET @Errores += N'El campo id_pais_nacionalidad es obligatorio. ';
    IF @nombres IS NULL OR LTRIM(RTRIM(@nombres)) = '' SET @Errores += N'El campo nombres es obligatorio. ';
    IF @apellidos IS NULL OR LTRIM(RTRIM(@apellidos)) = '' SET @Errores += N'El campo apellidos es obligatorio. ';
    IF @fecha_nacimiento IS NULL SET @Errores += N'El campo fecha_nacimiento es obligatorio. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.arbitro (id_pais_nacionalidad, id_confederacion, nombres, apellidos, fecha_nacimiento, categoria)
    VALUES (@id_pais_nacionalidad, @id_confederacion, @nombres, @apellidos, @fecha_nacimiento, @categoria);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_arbitro_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_arbitro_Modificar
    @id_arbitro INT,
    @id_pais_nacionalidad INT,
    @id_confederacion INT,
    @nombres VARCHAR(20),
    @apellidos VARCHAR(20),
    @fecha_nacimiento DATE,
    @categoria VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.arbitro WHERE id_arbitro = @id_arbitro) SET @Errores += N'No existe el registro indicado. ';
    IF @id_pais_nacionalidad IS NULL SET @Errores += N'El campo id_pais_nacionalidad es obligatorio. ';
    IF @nombres IS NULL OR LTRIM(RTRIM(@nombres)) = '' SET @Errores += N'El campo nombres es obligatorio. ';
    IF @apellidos IS NULL OR LTRIM(RTRIM(@apellidos)) = '' SET @Errores += N'El campo apellidos es obligatorio. ';
    IF @fecha_nacimiento IS NULL SET @Errores += N'El campo fecha_nacimiento es obligatorio. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.arbitro
    SET id_pais_nacionalidad = @id_pais_nacionalidad,
        id_confederacion = @id_confederacion,
        nombres = @nombres,
        apellidos = @apellidos,
        fecha_nacimiento = @fecha_nacimiento,
        categoria = @categoria
    WHERE id_arbitro = @id_arbitro;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_arbitro_Baja
    @id_arbitro INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.arbitro WHERE id_arbitro = @id_arbitro) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.arbitro WHERE id_arbitro = @id_arbitro;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_arbitro_Consultar
    @id_arbitro INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.arbitro
    WHERE (@id_arbitro IS NULL OR id_arbitro = @id_arbitro)
    ORDER BY id_arbitro;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.arbitro_idioma
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_idioma_Alta
    @id_arbitro INT,
    @id_idioma INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_arbitro IS NULL SET @Errores += N'El campo id_arbitro es obligatorio. ';
    IF @id_idioma IS NULL SET @Errores += N'El campo id_idioma es obligatorio. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.arbitro_idioma (id_arbitro, id_idioma)
    VALUES (@id_arbitro, @id_idioma);
    SELECT 'Registro creado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_arbitro_idioma_Modificar
    @id_arbitro_original INT,
    @id_idioma_original INT,
    @id_arbitro_nuevo INT,
    @id_idioma_nuevo INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.arbitro_idioma WHERE id_arbitro = @id_arbitro_original AND id_idioma = @id_idioma_original)
        SET @Errores += N'No existe la relación original indicada. ';
    IF @id_arbitro_nuevo IS NULL SET @Errores += N'El campo id_arbitro_nuevo es obligatorio. ';
    IF @id_idioma_nuevo IS NULL SET @Errores += N'El campo id_idioma_nuevo es obligatorio. ';
    IF EXISTS (
        SELECT 1 FROM mundial.arbitro_idioma
        WHERE id_arbitro = @id_arbitro_nuevo AND id_idioma = @id_idioma_nuevo
    ) AND NOT (@id_arbitro_original = @id_arbitro_nuevo AND @id_idioma_original = @id_idioma_nuevo)
        SET @Errores += N'La relación nueva ya existe. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM mundial.arbitro_idioma WHERE id_arbitro = @id_arbitro_original AND id_idioma = @id_idioma_original;
        INSERT INTO mundial.arbitro_idioma (id_arbitro, id_idioma)
        VALUES (@id_arbitro_nuevo, @id_idioma_nuevo);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    SELECT 'Relación modificada correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_arbitro_idioma_Baja
    @id_arbitro INT,
    @id_idioma INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.arbitro_idioma WHERE id_arbitro = @id_arbitro AND id_idioma = @id_idioma) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.arbitro_idioma WHERE id_arbitro = @id_arbitro AND id_idioma = @id_idioma;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_arbitro_idioma_Consultar
    @id_arbitro INT = NULL,
    @id_idioma INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.arbitro_idioma
    WHERE (@id_arbitro IS NULL OR id_arbitro = @id_arbitro) AND (@id_idioma IS NULL OR id_idioma = @id_idioma)
    ORDER BY id_arbitro, id_idioma;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.jugador
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_jugador_Alta
    @id_pais_nacionalidad INT,
    @id_club INT,
    @id_posicion_habitual INT,
    @nombres VARCHAR(20),
    @apellidos VARCHAR(20),
    @fecha_nacimiento DATE,
    @doc_identidad VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @nombres IS NULL OR LTRIM(RTRIM(@nombres)) = '' SET @Errores += N'El campo nombres es obligatorio. ';
    IF @apellidos IS NULL OR LTRIM(RTRIM(@apellidos)) = '' SET @Errores += N'El campo apellidos es obligatorio. ';
    IF @fecha_nacimiento IS NULL SET @Errores += N'El campo fecha_nacimiento es obligatorio. ';
    IF @doc_identidad IS NULL OR LTRIM(RTRIM(@doc_identidad)) = '' SET @Errores += N'El campo doc_identidad es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.jugador t WHERE t.doc_identidad = @doc_identidad) SET @Errores += N'Ya existe un registro con la combinación doc_identidad. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.jugador (id_pais_nacionalidad, id_club, id_posicion_habitual, nombres, apellidos, fecha_nacimiento, doc_identidad)
    VALUES (@id_pais_nacionalidad, @id_club, @id_posicion_habitual, @nombres, @apellidos, @fecha_nacimiento, @doc_identidad);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_jugador_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_jugador_Modificar
    @id_jugador INT,
    @id_pais_nacionalidad INT,
    @id_club INT,
    @id_posicion_habitual INT,
    @nombres VARCHAR(20),
    @apellidos VARCHAR(20),
    @fecha_nacimiento DATE,
    @doc_identidad VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador = @id_jugador) SET @Errores += N'No existe el registro indicado. ';
    IF @nombres IS NULL OR LTRIM(RTRIM(@nombres)) = '' SET @Errores += N'El campo nombres es obligatorio. ';
    IF @apellidos IS NULL OR LTRIM(RTRIM(@apellidos)) = '' SET @Errores += N'El campo apellidos es obligatorio. ';
    IF @fecha_nacimiento IS NULL SET @Errores += N'El campo fecha_nacimiento es obligatorio. ';
    IF @doc_identidad IS NULL OR LTRIM(RTRIM(@doc_identidad)) = '' SET @Errores += N'El campo doc_identidad es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.jugador t WHERE t.doc_identidad = @doc_identidad AND t.id_jugador <> @id_jugador) SET @Errores += N'Ya existe otro registro con la combinación doc_identidad. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.jugador
    SET id_pais_nacionalidad = @id_pais_nacionalidad,
        id_club = @id_club,
        id_posicion_habitual = @id_posicion_habitual,
        nombres = @nombres,
        apellidos = @apellidos,
        fecha_nacimiento = @fecha_nacimiento,
        doc_identidad = @doc_identidad
    WHERE id_jugador = @id_jugador;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_jugador_Baja
    @id_jugador INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.jugador WHERE id_jugador = @id_jugador) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.jugador WHERE id_jugador = @id_jugador;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_jugador_Consultar
    @id_jugador INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.jugador
    WHERE (@id_jugador IS NULL OR id_jugador = @id_jugador)
    ORDER BY id_jugador;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.sede_estadio
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_sede_estadio_Alta
    @id_ciudad INT,
    @nombre_estadio VARCHAR(20),
    @capacidad INT,
    @huso_horario VARCHAR(10),
    @latitud DECIMAL(10,2),
    @longitud DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_ciudad IS NULL SET @Errores += N'El campo id_ciudad es obligatorio. ';
    IF @nombre_estadio IS NULL OR LTRIM(RTRIM(@nombre_estadio)) = '' SET @Errores += N'El campo nombre_estadio es obligatorio. ';
    IF @capacidad IS NOT NULL AND @capacidad <= 0 SET @Errores += N'La capacidad debe ser mayor que cero. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.sede_estadio (id_ciudad, nombre_estadio, capacidad, huso_horario, latitud, longitud)
    VALUES (@id_ciudad, @nombre_estadio, @capacidad, @huso_horario, @latitud, @longitud);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_sede_estadio_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_sede_estadio_Modificar
    @id_sede INT,
    @id_ciudad INT,
    @nombre_estadio VARCHAR(20),
    @capacidad INT,
    @huso_horario VARCHAR(10),
    @latitud DECIMAL(10,2),
    @longitud DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.sede_estadio WHERE id_sede = @id_sede) SET @Errores += N'No existe el registro indicado. ';
    IF @id_ciudad IS NULL SET @Errores += N'El campo id_ciudad es obligatorio. ';
    IF @nombre_estadio IS NULL OR LTRIM(RTRIM(@nombre_estadio)) = '' SET @Errores += N'El campo nombre_estadio es obligatorio. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.sede_estadio
    SET id_ciudad = @id_ciudad,
        nombre_estadio = @nombre_estadio,
        capacidad = @capacidad,
        huso_horario = @huso_horario,
        latitud = @latitud,
        longitud = @longitud
    WHERE id_sede = @id_sede;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_sede_estadio_Baja
    @id_sede INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.sede_estadio WHERE id_sede = @id_sede) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.sede_estadio WHERE id_sede = @id_sede;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_sede_estadio_Consultar
    @id_sede INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.sede_estadio
    WHERE (@id_sede IS NULL OR id_sede = @id_sede)
    ORDER BY id_sede;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.campania
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_campania_Alta
    @id_anunciante INT,
    @nombre_campania VARCHAR(20),
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @presupuesto_total DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_anunciante IS NULL SET @Errores += N'El campo id_anunciante es obligatorio. ';
    IF @nombre_campania IS NULL OR LTRIM(RTRIM(@nombre_campania)) = '' SET @Errores += N'El campo nombre_campania es obligatorio. ';
    IF @fecha_inicio IS NULL SET @Errores += N'El campo fecha_inicio es obligatorio. ';
    IF @fecha_fin IS NULL SET @Errores += N'El campo fecha_fin es obligatorio. ';
    IF @presupuesto_total IS NULL SET @Errores += N'El campo presupuesto_total es obligatorio. ';
    IF @fecha_inicio IS NOT NULL AND @fecha_fin IS NOT NULL AND @fecha_fin < @fecha_inicio SET @Errores += N'La fecha_fin no puede ser anterior a fecha_inicio. ';
    IF @presupuesto_total < 0 SET @Errores += N'El presupuesto no puede ser negativo. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.campania (id_anunciante, nombre_campania, fecha_inicio, fecha_fin, presupuesto_total)
    VALUES (@id_anunciante, @nombre_campania, @fecha_inicio, @fecha_fin, @presupuesto_total);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_campania_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_campania_Modificar
    @id_campania INT,
    @id_anunciante INT,
    @nombre_campania VARCHAR(20),
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @presupuesto_total DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.campania WHERE id_campania = @id_campania) SET @Errores += N'No existe el registro indicado. ';
    IF @id_anunciante IS NULL SET @Errores += N'El campo id_anunciante es obligatorio. ';
    IF @nombre_campania IS NULL OR LTRIM(RTRIM(@nombre_campania)) = '' SET @Errores += N'El campo nombre_campania es obligatorio. ';
    IF @fecha_inicio IS NULL SET @Errores += N'El campo fecha_inicio es obligatorio. ';
    IF @fecha_fin IS NULL SET @Errores += N'El campo fecha_fin es obligatorio. ';
    IF @presupuesto_total IS NULL SET @Errores += N'El campo presupuesto_total es obligatorio. ';
    IF @fecha_inicio IS NOT NULL AND @fecha_fin IS NOT NULL AND @fecha_fin < @fecha_inicio SET @Errores += N'La fecha_fin no puede ser anterior a fecha_inicio. ';
    IF @presupuesto_total < 0 SET @Errores += N'El presupuesto no puede ser negativo. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.campania
    SET id_anunciante = @id_anunciante,
        nombre_campania = @nombre_campania,
        fecha_inicio = @fecha_inicio,
        fecha_fin = @fecha_fin,
        presupuesto_total = @presupuesto_total
    WHERE id_campania = @id_campania;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_campania_Baja
    @id_campania INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.campania WHERE id_campania = @id_campania) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.campania WHERE id_campania = @id_campania;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_campania_Consultar
    @id_campania INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.campania
    WHERE (@id_campania IS NULL OR id_campania = @id_campania)
    ORDER BY id_campania;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.partido
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_partido_Alta
    @id_fase INT,
    @id_sede INT,
    @id_seleccion_local INT,
    @id_seleccion_visitante INT,
    @fecha_hora_utc DATETIME,
    @fecha_hora_local DATETIME,
    @goles_local INT,
    @goles_visitante INT,
    @penales_local INT,
    @penales_visitante INT,
    @asistencia_publico INT,
    @estado_partido VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_fase IS NULL SET @Errores += N'El campo id_fase es obligatorio. ';
    IF @id_sede IS NULL SET @Errores += N'El campo id_sede es obligatorio. ';
    IF @id_seleccion_local IS NULL SET @Errores += N'El campo id_seleccion_local es obligatorio. ';
    IF @id_seleccion_visitante IS NULL SET @Errores += N'El campo id_seleccion_visitante es obligatorio. ';
    IF @fecha_hora_utc IS NULL SET @Errores += N'El campo fecha_hora_utc es obligatorio. ';
    IF @estado_partido IS NULL OR LTRIM(RTRIM(@estado_partido)) = '' SET @Errores += N'El campo estado_partido es obligatorio. ';
    IF @id_seleccion_local IS NOT NULL AND @id_seleccion_visitante IS NOT NULL AND @id_seleccion_local = @id_seleccion_visitante SET @Errores += N'Las selecciones local y visitante deben ser distintas. ';
    IF @goles_local < 0 OR @goles_visitante < 0 OR @penales_local < 0 OR @penales_visitante < 0 OR @asistencia_publico < 0 SET @Errores += N'Los goles, penales y asistencia no pueden ser negativos. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.partido (id_fase, id_sede, id_seleccion_local, id_seleccion_visitante, fecha_hora_utc, fecha_hora_local, goles_local, goles_visitante, penales_local, penales_visitante, asistencia_publico, estado_partido)
    VALUES (@id_fase, @id_sede, @id_seleccion_local, @id_seleccion_visitante, @fecha_hora_utc, @fecha_hora_local, @goles_local, @goles_visitante, @penales_local, @penales_visitante, @asistencia_publico, @estado_partido);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_partido_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_partido_Modificar
    @id_partido INT,
    @id_fase INT,
    @id_sede INT,
    @id_seleccion_local INT,
    @id_seleccion_visitante INT,
    @fecha_hora_utc DATETIME,
    @fecha_hora_local DATETIME,
    @goles_local INT,
    @goles_visitante INT,
    @penales_local INT,
    @penales_visitante INT,
    @asistencia_publico INT,
    @estado_partido VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido = @id_partido) SET @Errores += N'No existe el registro indicado. ';
    IF @id_fase IS NULL SET @Errores += N'El campo id_fase es obligatorio. ';
    IF @id_sede IS NULL SET @Errores += N'El campo id_sede es obligatorio. ';
    IF @id_seleccion_local IS NULL SET @Errores += N'El campo id_seleccion_local es obligatorio. ';
    IF @id_seleccion_visitante IS NULL SET @Errores += N'El campo id_seleccion_visitante es obligatorio. ';
    IF @fecha_hora_utc IS NULL SET @Errores += N'El campo fecha_hora_utc es obligatorio. ';
    IF @estado_partido IS NULL OR LTRIM(RTRIM(@estado_partido)) = '' SET @Errores += N'El campo estado_partido es obligatorio. ';
    IF @id_seleccion_local IS NOT NULL AND @id_seleccion_visitante IS NOT NULL AND @id_seleccion_local = @id_seleccion_visitante SET @Errores += N'Las selecciones local y visitante deben ser distintas. ';
    IF @goles_local < 0 OR @goles_visitante < 0 OR @penales_local < 0 OR @penales_visitante < 0 OR @asistencia_publico < 0 SET @Errores += N'Los goles, penales y asistencia no pueden ser negativos. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.partido
    SET id_fase = @id_fase,
        id_sede = @id_sede,
        id_seleccion_local = @id_seleccion_local,
        id_seleccion_visitante = @id_seleccion_visitante,
        fecha_hora_utc = @fecha_hora_utc,
        fecha_hora_local = @fecha_hora_local,
        goles_local = @goles_local,
        goles_visitante = @goles_visitante,
        penales_local = @penales_local,
        penales_visitante = @penales_visitante,
        asistencia_publico = @asistencia_publico,
        estado_partido = @estado_partido
    WHERE id_partido = @id_partido;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_partido_Baja
    @id_partido INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.partido WHERE id_partido = @id_partido) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.partido WHERE id_partido = @id_partido;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_partido_Consultar
    @id_partido INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.partido
    WHERE (@id_partido IS NULL OR id_partido = @id_partido)
    ORDER BY id_partido;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.pieza_publicitaria
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_pieza_publicitaria_Alta
    @id_campania INT,
    @titulo VARCHAR(20),
    @idioma VARCHAR(20),
    @formato VARCHAR(20),
    @duracion_segundos INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_campania IS NULL SET @Errores += N'El campo id_campania es obligatorio. ';
    IF @titulo IS NULL OR LTRIM(RTRIM(@titulo)) = '' SET @Errores += N'El campo titulo es obligatorio. ';
    IF @idioma IS NULL OR LTRIM(RTRIM(@idioma)) = '' SET @Errores += N'El campo idioma es obligatorio. ';
    IF @formato IS NULL OR LTRIM(RTRIM(@formato)) = '' SET @Errores += N'El campo formato es obligatorio. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.pieza_publicitaria (id_campania, titulo, idioma, formato, duracion_segundos)
    VALUES (@id_campania, @titulo, @idioma, @formato, @duracion_segundos);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_pieza_publicitaria_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_pieza_publicitaria_Modificar
    @id_pieza INT,
    @id_campania INT,
    @titulo VARCHAR(20),
    @idioma VARCHAR(20),
    @formato VARCHAR(20),
    @duracion_segundos INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.pieza_publicitaria WHERE id_pieza = @id_pieza) SET @Errores += N'No existe el registro indicado. ';
    IF @id_campania IS NULL SET @Errores += N'El campo id_campania es obligatorio. ';
    IF @titulo IS NULL OR LTRIM(RTRIM(@titulo)) = '' SET @Errores += N'El campo titulo es obligatorio. ';
    IF @idioma IS NULL OR LTRIM(RTRIM(@idioma)) = '' SET @Errores += N'El campo idioma es obligatorio. ';
    IF @formato IS NULL OR LTRIM(RTRIM(@formato)) = '' SET @Errores += N'El campo formato es obligatorio. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.pieza_publicitaria
    SET id_campania = @id_campania,
        titulo = @titulo,
        idioma = @idioma,
        formato = @formato,
        duracion_segundos = @duracion_segundos
    WHERE id_pieza = @id_pieza;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_pieza_publicitaria_Baja
    @id_pieza INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.pieza_publicitaria WHERE id_pieza = @id_pieza) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.pieza_publicitaria WHERE id_pieza = @id_pieza;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_pieza_publicitaria_Consultar
    @id_pieza INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.pieza_publicitaria
    WHERE (@id_pieza IS NULL OR id_pieza = @id_pieza)
    ORDER BY id_pieza;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.pieza_pais_objetivo
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_pieza_pais_objetivo_Alta
    @id_pieza INT,
    @id_pais INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_pieza IS NULL SET @Errores += N'El campo id_pieza es obligatorio. ';
    IF @id_pais IS NULL SET @Errores += N'El campo id_pais es obligatorio. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.pieza_pais_objetivo (id_pieza, id_pais)
    VALUES (@id_pieza, @id_pais);
    SELECT 'Registro creado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_pieza_pais_objetivo_Modificar
    @id_pieza_original INT,
    @id_pais_original INT,
    @id_pieza_nuevo INT,
    @id_pais_nuevo INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.pieza_pais_objetivo WHERE id_pieza = @id_pieza_original AND id_pais = @id_pais_original)
        SET @Errores += N'No existe la relación original indicada. ';
    IF @id_pieza_nuevo IS NULL SET @Errores += N'El campo id_pieza_nuevo es obligatorio. ';
    IF @id_pais_nuevo IS NULL SET @Errores += N'El campo id_pais_nuevo es obligatorio. ';
    IF EXISTS (
        SELECT 1 FROM mundial.pieza_pais_objetivo
        WHERE id_pieza = @id_pieza_nuevo AND id_pais = @id_pais_nuevo
    ) AND NOT (@id_pieza_original = @id_pieza_nuevo AND @id_pais_original = @id_pais_nuevo)
        SET @Errores += N'La relación nueva ya existe. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM mundial.pieza_pais_objetivo WHERE id_pieza = @id_pieza_original AND id_pais = @id_pais_original;
        INSERT INTO mundial.pieza_pais_objetivo (id_pieza, id_pais)
        VALUES (@id_pieza_nuevo, @id_pais_nuevo);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    SELECT 'Relación modificada correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_pieza_pais_objetivo_Baja
    @id_pieza INT,
    @id_pais INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.pieza_pais_objetivo WHERE id_pieza = @id_pieza AND id_pais = @id_pais) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.pieza_pais_objetivo WHERE id_pieza = @id_pieza AND id_pais = @id_pais;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_pieza_pais_objetivo_Consultar
    @id_pieza INT = NULL,
    @id_pais INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.pieza_pais_objetivo
    WHERE (@id_pieza IS NULL OR id_pieza = @id_pieza) AND (@id_pais IS NULL OR id_pais = @id_pais)
    ORDER BY id_pieza, id_pais;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.espacio_publicitario
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_espacio_publicitario_Alta
    @id_sede INT,
    @numero_espacio INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_sede IS NULL SET @Errores += N'El campo id_sede es obligatorio. ';
    IF @numero_espacio IS NULL SET @Errores += N'El campo numero_espacio es obligatorio. ';
    IF @numero_espacio <= 0 SET @Errores += N'El número de espacio debe ser mayor que cero. ';
    IF EXISTS (SELECT 1 FROM mundial.espacio_publicitario t WHERE t.id_sede = @id_sede AND t.numero_espacio = @numero_espacio) SET @Errores += N'Ya existe un registro con la combinación id_sede, numero_espacio. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.espacio_publicitario (id_sede, numero_espacio)
    VALUES (@id_sede, @numero_espacio);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_espacio_publicitario_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_espacio_publicitario_Modificar
    @id_espacio INT,
    @id_sede INT,
    @numero_espacio INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.espacio_publicitario WHERE id_espacio = @id_espacio) SET @Errores += N'No existe el registro indicado. ';
    IF @id_sede IS NULL SET @Errores += N'El campo id_sede es obligatorio. ';
    IF @numero_espacio IS NULL SET @Errores += N'El campo numero_espacio es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.espacio_publicitario t WHERE t.id_sede = @id_sede AND t.numero_espacio = @numero_espacio AND t.id_espacio <> @id_espacio) SET @Errores += N'Ya existe otro registro con la combinación id_sede, numero_espacio. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.espacio_publicitario
    SET id_sede = @id_sede,
        numero_espacio = @numero_espacio
    WHERE id_espacio = @id_espacio;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_espacio_publicitario_Baja
    @id_espacio INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.espacio_publicitario WHERE id_espacio = @id_espacio) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.espacio_publicitario WHERE id_espacio = @id_espacio;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_espacio_publicitario_Consultar
    @id_espacio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.espacio_publicitario
    WHERE (@id_espacio IS NULL OR id_espacio = @id_espacio)
    ORDER BY id_espacio;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.convocatoria
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_convocatoria_Alta
    @id_seleccion INT,
    @id_jugador INT,
    @dorsal INT,
    @fecha_convocatoria DATE,
    @estado_convocatoria VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @dorsal IS NULL SET @Errores += N'El campo dorsal es obligatorio. ';
    IF @fecha_convocatoria IS NULL SET @Errores += N'El campo fecha_convocatoria es obligatorio. ';
    IF @estado_convocatoria IS NULL OR LTRIM(RTRIM(@estado_convocatoria)) = '' SET @Errores += N'El campo estado_convocatoria es obligatorio. ';
    IF @dorsal IS NOT NULL AND (@dorsal < 1 OR @dorsal > 99) SET @Errores += N'El dorsal debe estar entre 1 y 99. ';
    IF EXISTS (SELECT 1 FROM mundial.convocatoria t WHERE t.id_seleccion = @id_seleccion AND t.id_jugador = @id_jugador) SET @Errores += N'Ya existe un registro con la combinación id_seleccion, id_jugador. ';
    IF EXISTS (SELECT 1 FROM mundial.convocatoria t WHERE t.id_seleccion = @id_seleccion AND t.dorsal = @dorsal) SET @Errores += N'Ya existe un registro con la combinación id_seleccion, dorsal. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.convocatoria (id_seleccion, id_jugador, dorsal, fecha_convocatoria, estado_convocatoria)
    VALUES (@id_seleccion, @id_jugador, @dorsal, @fecha_convocatoria, @estado_convocatoria);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_convocatoria_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_convocatoria_Modificar
    @id_convocatoria INT,
    @id_seleccion INT,
    @id_jugador INT,
    @dorsal INT,
    @fecha_convocatoria DATE,
    @estado_convocatoria VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.convocatoria WHERE id_convocatoria = @id_convocatoria) SET @Errores += N'No existe el registro indicado. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @dorsal IS NULL SET @Errores += N'El campo dorsal es obligatorio. ';
    IF @fecha_convocatoria IS NULL SET @Errores += N'El campo fecha_convocatoria es obligatorio. ';
    IF @estado_convocatoria IS NULL OR LTRIM(RTRIM(@estado_convocatoria)) = '' SET @Errores += N'El campo estado_convocatoria es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.convocatoria t WHERE t.id_seleccion = @id_seleccion AND t.id_jugador = @id_jugador AND t.id_convocatoria <> @id_convocatoria) SET @Errores += N'Ya existe otro registro con la combinación id_seleccion, id_jugador. ';
    IF EXISTS (SELECT 1 FROM mundial.convocatoria t WHERE t.id_seleccion = @id_seleccion AND t.dorsal = @dorsal AND t.id_convocatoria <> @id_convocatoria) SET @Errores += N'Ya existe otro registro con la combinación id_seleccion, dorsal. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.convocatoria
    SET id_seleccion = @id_seleccion,
        id_jugador = @id_jugador,
        dorsal = @dorsal,
        fecha_convocatoria = @fecha_convocatoria,
        estado_convocatoria = @estado_convocatoria
    WHERE id_convocatoria = @id_convocatoria;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_convocatoria_Baja
    @id_convocatoria INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.convocatoria WHERE id_convocatoria = @id_convocatoria) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.convocatoria WHERE id_convocatoria = @id_convocatoria;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_convocatoria_Consultar
    @id_convocatoria INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.convocatoria
    WHERE (@id_convocatoria IS NULL OR id_convocatoria = @id_convocatoria)
    ORDER BY id_convocatoria;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.novedad_convocatoria
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_novedad_convocatoria_Alta
    @id_convocatoria_baja INT,
    @id_convocatoria_alta INT,
    @motivo VARCHAR(50),
    @fecha_cambio DATETIME,
    @dictamen_medico VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_convocatoria_baja IS NULL SET @Errores += N'El campo id_convocatoria_baja es obligatorio. ';
    IF @id_convocatoria_alta IS NULL SET @Errores += N'El campo id_convocatoria_alta es obligatorio. ';
    IF @motivo IS NULL OR LTRIM(RTRIM(@motivo)) = '' SET @Errores += N'El campo motivo es obligatorio. ';
    IF @fecha_cambio IS NULL SET @Errores += N'El campo fecha_cambio es obligatorio. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.novedad_convocatoria (id_convocatoria_baja, id_convocatoria_alta, motivo, fecha_cambio, dictamen_medico)
    VALUES (@id_convocatoria_baja, @id_convocatoria_alta, @motivo, @fecha_cambio, @dictamen_medico);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_novedad_convocatoria_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_novedad_convocatoria_Modificar
    @id_novedad INT,
    @id_convocatoria_baja INT,
    @id_convocatoria_alta INT,
    @motivo VARCHAR(50),
    @fecha_cambio DATETIME,
    @dictamen_medico VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.novedad_convocatoria WHERE id_novedad = @id_novedad) SET @Errores += N'No existe el registro indicado. ';
    IF @id_convocatoria_baja IS NULL SET @Errores += N'El campo id_convocatoria_baja es obligatorio. ';
    IF @id_convocatoria_alta IS NULL SET @Errores += N'El campo id_convocatoria_alta es obligatorio. ';
    IF @motivo IS NULL OR LTRIM(RTRIM(@motivo)) = '' SET @Errores += N'El campo motivo es obligatorio. ';
    IF @fecha_cambio IS NULL SET @Errores += N'El campo fecha_cambio es obligatorio. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.novedad_convocatoria
    SET id_convocatoria_baja = @id_convocatoria_baja,
        id_convocatoria_alta = @id_convocatoria_alta,
        motivo = @motivo,
        fecha_cambio = @fecha_cambio,
        dictamen_medico = @dictamen_medico
    WHERE id_novedad = @id_novedad;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_novedad_convocatoria_Baja
    @id_novedad INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.novedad_convocatoria WHERE id_novedad = @id_novedad) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.novedad_convocatoria WHERE id_novedad = @id_novedad;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_novedad_convocatoria_Consultar
    @id_novedad INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.novedad_convocatoria
    WHERE (@id_novedad IS NULL OR id_novedad = @id_novedad)
    ORDER BY id_novedad;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.sustitucion
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_sustitucion_Alta
    @id_partido INT,
    @id_seleccion INT,
    @id_jugador_sale INT,
    @id_jugador_entra INT,
    @minuto INT,
    @minuto_adicional INT,
    @periodo VARCHAR(20),
    @numero_ventana INT,
    @motivo VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_jugador_sale IS NULL SET @Errores += N'El campo id_jugador_sale es obligatorio. ';
    IF @id_jugador_entra IS NULL SET @Errores += N'El campo id_jugador_entra es obligatorio. ';
    IF @minuto IS NULL SET @Errores += N'El campo minuto es obligatorio. ';
    IF @periodo IS NULL OR LTRIM(RTRIM(@periodo)) = '' SET @Errores += N'El campo periodo es obligatorio. ';
    IF @minuto IS NOT NULL AND @minuto < 0 SET @Errores += N'El minuto no puede ser negativo. ';
    IF @minuto_adicional IS NOT NULL AND @minuto_adicional < 0 SET @Errores += N'El minuto adicional no puede ser negativo. ';
    IF @id_jugador_sale = @id_jugador_entra SET @Errores += N'El jugador que sale debe ser distinto del que entra. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.sustitucion (id_partido, id_seleccion, id_jugador_sale, id_jugador_entra, minuto, minuto_adicional, periodo, numero_ventana, motivo)
    VALUES (@id_partido, @id_seleccion, @id_jugador_sale, @id_jugador_entra, @minuto, @minuto_adicional, @periodo, @numero_ventana, @motivo);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_sustitucion_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_sustitucion_Modificar
    @id_sustitucion INT,
    @id_partido INT,
    @id_seleccion INT,
    @id_jugador_sale INT,
    @id_jugador_entra INT,
    @minuto INT,
    @minuto_adicional INT,
    @periodo VARCHAR(20),
    @numero_ventana INT,
    @motivo VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.sustitucion WHERE id_sustitucion = @id_sustitucion) SET @Errores += N'No existe el registro indicado. ';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_jugador_sale IS NULL SET @Errores += N'El campo id_jugador_sale es obligatorio. ';
    IF @id_jugador_entra IS NULL SET @Errores += N'El campo id_jugador_entra es obligatorio. ';
    IF @minuto IS NULL SET @Errores += N'El campo minuto es obligatorio. ';
    IF @periodo IS NULL OR LTRIM(RTRIM(@periodo)) = '' SET @Errores += N'El campo periodo es obligatorio. ';
    IF @minuto IS NOT NULL AND @minuto < 0 SET @Errores += N'El minuto no puede ser negativo. ';
    IF @minuto_adicional IS NOT NULL AND @minuto_adicional < 0 SET @Errores += N'El minuto adicional no puede ser negativo. ';
    IF @id_jugador_sale = @id_jugador_entra SET @Errores += N'El jugador que sale debe ser distinto del que entra. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.sustitucion
    SET id_partido = @id_partido,
        id_seleccion = @id_seleccion,
        id_jugador_sale = @id_jugador_sale,
        id_jugador_entra = @id_jugador_entra,
        minuto = @minuto,
        minuto_adicional = @minuto_adicional,
        periodo = @periodo,
        numero_ventana = @numero_ventana,
        motivo = @motivo
    WHERE id_sustitucion = @id_sustitucion;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_sustitucion_Baja
    @id_sustitucion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.sustitucion WHERE id_sustitucion = @id_sustitucion) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.sustitucion WHERE id_sustitucion = @id_sustitucion;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_sustitucion_Consultar
    @id_sustitucion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.sustitucion
    WHERE (@id_sustitucion IS NULL OR id_sustitucion = @id_sustitucion)
    ORDER BY id_sustitucion;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.gol
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_gol_Alta
    @id_partido INT,
    @id_seleccion INT,
    @id_jugador_autor INT,
    @id_jugador_asistente INT,
    @id_tipo_gol INT,
    @minuto INT,
    @minuto_adicional INT,
    @periodo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_jugador_autor IS NULL SET @Errores += N'El campo id_jugador_autor es obligatorio. ';
    IF @id_tipo_gol IS NULL SET @Errores += N'El campo id_tipo_gol es obligatorio. ';
    IF @minuto IS NULL SET @Errores += N'El campo minuto es obligatorio. ';
    IF @periodo IS NULL OR LTRIM(RTRIM(@periodo)) = '' SET @Errores += N'El campo periodo es obligatorio. ';
    IF @minuto IS NOT NULL AND @minuto < 0 SET @Errores += N'El minuto no puede ser negativo. ';
    IF @minuto_adicional IS NOT NULL AND @minuto_adicional < 0 SET @Errores += N'El minuto adicional no puede ser negativo. ';
    IF @id_jugador_autor IS NOT NULL AND @id_jugador_autor = @id_jugador_asistente SET @Errores += N'El autor del gol no puede ser su propio asistente. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.gol (id_partido, id_seleccion, id_jugador_autor, id_jugador_asistente, id_tipo_gol, minuto, minuto_adicional, periodo)
    VALUES (@id_partido, @id_seleccion, @id_jugador_autor, @id_jugador_asistente, @id_tipo_gol, @minuto, @minuto_adicional, @periodo);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_gol_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_gol_Modificar
    @id_gol INT,
    @id_partido INT,
    @id_seleccion INT,
    @id_jugador_autor INT,
    @id_jugador_asistente INT,
    @id_tipo_gol INT,
    @minuto INT,
    @minuto_adicional INT,
    @periodo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.gol WHERE id_gol = @id_gol) SET @Errores += N'No existe el registro indicado. ';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_jugador_autor IS NULL SET @Errores += N'El campo id_jugador_autor es obligatorio. ';
    IF @id_tipo_gol IS NULL SET @Errores += N'El campo id_tipo_gol es obligatorio. ';
    IF @minuto IS NULL SET @Errores += N'El campo minuto es obligatorio. ';
    IF @periodo IS NULL OR LTRIM(RTRIM(@periodo)) = '' SET @Errores += N'El campo periodo es obligatorio. ';
    IF @minuto IS NOT NULL AND @minuto < 0 SET @Errores += N'El minuto no puede ser negativo. ';
    IF @minuto_adicional IS NOT NULL AND @minuto_adicional < 0 SET @Errores += N'El minuto adicional no puede ser negativo. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.gol
    SET id_partido = @id_partido,
        id_seleccion = @id_seleccion,
        id_jugador_autor = @id_jugador_autor,
        id_jugador_asistente = @id_jugador_asistente,
        id_tipo_gol = @id_tipo_gol,
        minuto = @minuto,
        minuto_adicional = @minuto_adicional,
        periodo = @periodo
    WHERE id_gol = @id_gol;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_gol_Baja
    @id_gol INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.gol WHERE id_gol = @id_gol) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.gol WHERE id_gol = @id_gol;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_gol_Consultar
    @id_gol INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.gol
    WHERE (@id_gol IS NULL OR id_gol = @id_gol)
    ORDER BY id_gol;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.tarjeta
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_tarjeta_Alta
    @id_partido INT,
    @id_seleccion INT,
    @id_jugador INT,
    @id_tipo_tarjeta INT,
    @minuto INT,
    @minuto_adicional INT,
    @periodo VARCHAR(20),
    @motivo VARCHAR(50),
    @tipo_expulsion VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_tipo_tarjeta IS NULL SET @Errores += N'El campo id_tipo_tarjeta es obligatorio. ';
    IF @minuto IS NULL SET @Errores += N'El campo minuto es obligatorio. ';
    IF @periodo IS NULL OR LTRIM(RTRIM(@periodo)) = '' SET @Errores += N'El campo periodo es obligatorio. ';
    IF @minuto IS NOT NULL AND @minuto < 0 SET @Errores += N'El minuto no puede ser negativo. ';
    IF @minuto_adicional IS NOT NULL AND @minuto_adicional < 0 SET @Errores += N'El minuto adicional no puede ser negativo. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.tarjeta (id_partido, id_seleccion, id_jugador, id_tipo_tarjeta, minuto, minuto_adicional, periodo, motivo, tipo_expulsion)
    VALUES (@id_partido, @id_seleccion, @id_jugador, @id_tipo_tarjeta, @minuto, @minuto_adicional, @periodo, @motivo, @tipo_expulsion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_tarjeta_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_tarjeta_Modificar
    @id_tarjeta INT,
    @id_partido INT,
    @id_seleccion INT,
    @id_jugador INT,
    @id_tipo_tarjeta INT,
    @minuto INT,
    @minuto_adicional INT,
    @periodo VARCHAR(20),
    @motivo VARCHAR(50),
    @tipo_expulsion VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.tarjeta WHERE id_tarjeta = @id_tarjeta) SET @Errores += N'No existe el registro indicado. ';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_tipo_tarjeta IS NULL SET @Errores += N'El campo id_tipo_tarjeta es obligatorio. ';
    IF @minuto IS NULL SET @Errores += N'El campo minuto es obligatorio. ';
    IF @periodo IS NULL OR LTRIM(RTRIM(@periodo)) = '' SET @Errores += N'El campo periodo es obligatorio. ';
    IF @minuto IS NOT NULL AND @minuto < 0 SET @Errores += N'El minuto no puede ser negativo. ';
    IF @minuto_adicional IS NOT NULL AND @minuto_adicional < 0 SET @Errores += N'El minuto adicional no puede ser negativo. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.tarjeta
    SET id_partido = @id_partido,
        id_seleccion = @id_seleccion,
        id_jugador = @id_jugador,
        id_tipo_tarjeta = @id_tipo_tarjeta,
        minuto = @minuto,
        minuto_adicional = @minuto_adicional,
        periodo = @periodo,
        motivo = @motivo,
        tipo_expulsion = @tipo_expulsion
    WHERE id_tarjeta = @id_tarjeta;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_tarjeta_Baja
    @id_tarjeta INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.tarjeta WHERE id_tarjeta = @id_tarjeta) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.tarjeta WHERE id_tarjeta = @id_tarjeta;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_tarjeta_Consultar
    @id_tarjeta INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.tarjeta
    WHERE (@id_tarjeta IS NULL OR id_tarjeta = @id_tarjeta)
    ORDER BY id_tarjeta;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.suspension_jugador
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_suspension_jugador_Alta
    @id_criterio INT,
    @id_jugador INT,
    @id_partido_origen INT,
    @id_partido_suspendido INT,
    @motivo VARCHAR(100),
    @partidos_sancion INT,
    @cumplida BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_partido_origen IS NULL SET @Errores += N'El campo id_partido_origen es obligatorio. ';
    IF @motivo IS NULL OR LTRIM(RTRIM(@motivo)) = '' SET @Errores += N'El campo motivo es obligatorio. ';
    IF @partidos_sancion IS NULL SET @Errores += N'El campo partidos_sancion es obligatorio. ';
    IF @cumplida IS NULL SET @Errores += N'El campo cumplida es obligatorio. ';
    IF @partidos_sancion IS NOT NULL AND @partidos_sancion <= 0 SET @Errores += N'Los partidos de sanción deben ser mayores que cero. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.suspension_jugador (id_criterio, id_jugador, id_partido_origen, id_partido_suspendido, motivo, partidos_sancion, cumplida)
    VALUES (@id_criterio, @id_jugador, @id_partido_origen, @id_partido_suspendido, @motivo, @partidos_sancion, @cumplida);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_suspension_jugador_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_suspension_jugador_Modificar
    @id_suspension INT,
    @id_criterio INT,
    @id_jugador INT,
    @id_partido_origen INT,
    @id_partido_suspendido INT,
    @motivo VARCHAR(100),
    @partidos_sancion INT,
    @cumplida BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.suspension_jugador WHERE id_suspension = @id_suspension) SET @Errores += N'No existe el registro indicado. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_partido_origen IS NULL SET @Errores += N'El campo id_partido_origen es obligatorio. ';
    IF @motivo IS NULL OR LTRIM(RTRIM(@motivo)) = '' SET @Errores += N'El campo motivo es obligatorio. ';
    IF @partidos_sancion IS NULL SET @Errores += N'El campo partidos_sancion es obligatorio. ';
    IF @cumplida IS NULL SET @Errores += N'El campo cumplida es obligatorio. ';
    IF @partidos_sancion IS NOT NULL AND @partidos_sancion <= 0 SET @Errores += N'Los partidos de sanción deben ser mayores que cero. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.suspension_jugador
    SET id_criterio = @id_criterio,
        id_jugador = @id_jugador,
        id_partido_origen = @id_partido_origen,
        id_partido_suspendido = @id_partido_suspendido,
        motivo = @motivo,
        partidos_sancion = @partidos_sancion,
        cumplida = @cumplida
    WHERE id_suspension = @id_suspension;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_suspension_jugador_Baja
    @id_suspension INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.suspension_jugador WHERE id_suspension = @id_suspension) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.suspension_jugador WHERE id_suspension = @id_suspension;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_suspension_jugador_Consultar
    @id_suspension INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.suspension_jugador
    WHERE (@id_suspension IS NULL OR id_suspension = @id_suspension)
    ORDER BY id_suspension;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.pauta_partido
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_pauta_partido_Alta
    @id_partido INT,
    @id_espacio INT,
    @id_pieza INT,
    @id_moneda INT,
    @tarifa_base_usd DECIMAL(12,2),
    @tipo_cambio_aplicado DECIMAL(12,6),
    @tarifa_final DECIMAL(12,2),
    @es_prime_time BIT,
    @estado_facturacion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_espacio IS NULL SET @Errores += N'El campo id_espacio es obligatorio. ';
    IF @id_pieza IS NULL SET @Errores += N'El campo id_pieza es obligatorio. ';
    IF @id_moneda IS NULL SET @Errores += N'El campo id_moneda es obligatorio. ';
    IF @tarifa_base_usd IS NULL SET @Errores += N'El campo tarifa_base_usd es obligatorio. ';
    IF @tipo_cambio_aplicado IS NULL SET @Errores += N'El campo tipo_cambio_aplicado es obligatorio. ';
    IF @tarifa_final IS NULL SET @Errores += N'El campo tarifa_final es obligatorio. ';
    IF @es_prime_time IS NULL SET @Errores += N'El campo es_prime_time es obligatorio. ';
    IF @estado_facturacion IS NULL OR LTRIM(RTRIM(@estado_facturacion)) = '' SET @Errores += N'El campo estado_facturacion es obligatorio. ';
    IF @tarifa_base_usd < 0 OR @tarifa_final < 0 SET @Errores += N'Las tarifas no pueden ser negativas. ';
    IF @tipo_cambio_aplicado <= 0 SET @Errores += N'El tipo de cambio debe ser mayor que cero. ';
    IF EXISTS (SELECT 1 FROM mundial.pauta_partido t WHERE t.id_partido = @id_partido AND t.id_espacio = @id_espacio) SET @Errores += N'Ya existe un registro con la combinación id_partido, id_espacio. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.pauta_partido (id_partido, id_espacio, id_pieza, id_moneda, tarifa_base_usd, tipo_cambio_aplicado, tarifa_final, es_prime_time, estado_facturacion)
    VALUES (@id_partido, @id_espacio, @id_pieza, @id_moneda, @tarifa_base_usd, @tipo_cambio_aplicado, @tarifa_final, @es_prime_time, @estado_facturacion);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_pauta_partido_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_pauta_partido_Modificar
    @id_pauta INT,
    @id_partido INT,
    @id_espacio INT,
    @id_pieza INT,
    @id_moneda INT,
    @tarifa_base_usd DECIMAL(12,2),
    @tipo_cambio_aplicado DECIMAL(12,6),
    @tarifa_final DECIMAL(12,2),
    @es_prime_time BIT,
    @estado_facturacion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.pauta_partido WHERE id_pauta = @id_pauta) SET @Errores += N'No existe el registro indicado. ';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_espacio IS NULL SET @Errores += N'El campo id_espacio es obligatorio. ';
    IF @id_pieza IS NULL SET @Errores += N'El campo id_pieza es obligatorio. ';
    IF @id_moneda IS NULL SET @Errores += N'El campo id_moneda es obligatorio. ';
    IF @tarifa_base_usd IS NULL SET @Errores += N'El campo tarifa_base_usd es obligatorio. ';
    IF @tipo_cambio_aplicado IS NULL SET @Errores += N'El campo tipo_cambio_aplicado es obligatorio. ';
    IF @tarifa_final IS NULL SET @Errores += N'El campo tarifa_final es obligatorio. ';
    IF @es_prime_time IS NULL SET @Errores += N'El campo es_prime_time es obligatorio. ';
    IF @estado_facturacion IS NULL OR LTRIM(RTRIM(@estado_facturacion)) = '' SET @Errores += N'El campo estado_facturacion es obligatorio. ';
    IF @tarifa_base_usd < 0 OR @tarifa_final < 0 SET @Errores += N'Las tarifas no pueden ser negativas. ';
    IF @tipo_cambio_aplicado <= 0 SET @Errores += N'El tipo de cambio debe ser mayor que cero. ';
    IF EXISTS (SELECT 1 FROM mundial.pauta_partido t WHERE t.id_partido = @id_partido AND t.id_espacio = @id_espacio AND t.id_pauta <> @id_pauta) SET @Errores += N'Ya existe otro registro con la combinación id_partido, id_espacio. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.pauta_partido
    SET id_partido = @id_partido,
        id_espacio = @id_espacio,
        id_pieza = @id_pieza,
        id_moneda = @id_moneda,
        tarifa_base_usd = @tarifa_base_usd,
        tipo_cambio_aplicado = @tipo_cambio_aplicado,
        tarifa_final = @tarifa_final,
        es_prime_time = @es_prime_time,
        estado_facturacion = @estado_facturacion
    WHERE id_pauta = @id_pauta;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_pauta_partido_Baja
    @id_pauta INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.pauta_partido WHERE id_pauta = @id_pauta) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.pauta_partido WHERE id_pauta = @id_pauta;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_pauta_partido_Consultar
    @id_pauta INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.pauta_partido
    WHERE (@id_pauta IS NULL OR id_pauta = @id_pauta)
    ORDER BY id_pauta;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.partido_equipo_detalle
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_partido_equipo_detalle_Alta
    @id_partido INT,
    @id_seleccion INT,
    @condicion VARCHAR(50),
    @esquema_tactico VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @condicion IS NULL OR LTRIM(RTRIM(@condicion)) = '' SET @Errores += N'El campo condicion es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.partido_equipo_detalle t WHERE t.id_partido = @id_partido AND t.id_seleccion = @id_seleccion) SET @Errores += N'Ya existe un registro con la combinación id_partido, id_seleccion. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.partido_equipo_detalle (id_partido, id_seleccion, condicion, esquema_tactico)
    VALUES (@id_partido, @id_seleccion, @condicion, @esquema_tactico);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_partido_equipo_detalle_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_partido_equipo_detalle_Modificar
    @id_partido_equipo INT,
    @id_partido INT,
    @id_seleccion INT,
    @condicion VARCHAR(50),
    @esquema_tactico VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.partido_equipo_detalle WHERE id_partido_equipo = @id_partido_equipo) SET @Errores += N'No existe el registro indicado. ';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_seleccion IS NULL SET @Errores += N'El campo id_seleccion es obligatorio. ';
    IF @condicion IS NULL OR LTRIM(RTRIM(@condicion)) = '' SET @Errores += N'El campo condicion es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.partido_equipo_detalle t WHERE t.id_partido = @id_partido AND t.id_seleccion = @id_seleccion AND t.id_partido_equipo <> @id_partido_equipo) SET @Errores += N'Ya existe otro registro con la combinación id_partido, id_seleccion. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.partido_equipo_detalle
    SET id_partido = @id_partido,
        id_seleccion = @id_seleccion,
        condicion = @condicion,
        esquema_tactico = @esquema_tactico
    WHERE id_partido_equipo = @id_partido_equipo;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_partido_equipo_detalle_Baja
    @id_partido_equipo INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.partido_equipo_detalle WHERE id_partido_equipo = @id_partido_equipo) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.partido_equipo_detalle WHERE id_partido_equipo = @id_partido_equipo;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_partido_equipo_detalle_Consultar
    @id_partido_equipo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.partido_equipo_detalle
    WHERE (@id_partido_equipo IS NULL OR id_partido_equipo = @id_partido_equipo)
    ORDER BY id_partido_equipo;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.designacion_arbitral
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_designacion_arbitral_Alta
    @id_partido INT,
    @id_arbitro INT,
    @id_rol_arbitral INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_arbitro IS NULL SET @Errores += N'El campo id_arbitro es obligatorio. ';
    IF @id_rol_arbitral IS NULL SET @Errores += N'El campo id_rol_arbitral es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.designacion_arbitral t WHERE t.id_partido = @id_partido AND t.id_arbitro = @id_arbitro) SET @Errores += N'Ya existe un registro con la combinación id_partido, id_arbitro. ';
    IF EXISTS (SELECT 1 FROM mundial.designacion_arbitral t WHERE t.id_partido = @id_partido AND t.id_rol_arbitral = @id_rol_arbitral) SET @Errores += N'Ya existe un registro con la combinación id_partido, id_rol_arbitral. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.designacion_arbitral (id_partido, id_arbitro, id_rol_arbitral)
    VALUES (@id_partido, @id_arbitro, @id_rol_arbitral);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_designacion_arbitral_creado;
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
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.designacion_arbitral WHERE id_designacion = @id_designacion) SET @Errores += N'No existe el registro indicado. ';
    IF @id_partido IS NULL SET @Errores += N'El campo id_partido es obligatorio. ';
    IF @id_arbitro IS NULL SET @Errores += N'El campo id_arbitro es obligatorio. ';
    IF @id_rol_arbitral IS NULL SET @Errores += N'El campo id_rol_arbitral es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.designacion_arbitral t WHERE t.id_partido = @id_partido AND t.id_arbitro = @id_arbitro AND t.id_designacion <> @id_designacion) SET @Errores += N'Ya existe otro registro con la combinación id_partido, id_arbitro. ';
    IF EXISTS (SELECT 1 FROM mundial.designacion_arbitral t WHERE t.id_partido = @id_partido AND t.id_rol_arbitral = @id_rol_arbitral AND t.id_designacion <> @id_designacion) SET @Errores += N'Ya existe otro registro con la combinación id_partido, id_rol_arbitral. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.designacion_arbitral
    SET id_partido = @id_partido,
        id_arbitro = @id_arbitro,
        id_rol_arbitral = @id_rol_arbitral
    WHERE id_designacion = @id_designacion;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_designacion_arbitral_Baja
    @id_designacion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.designacion_arbitral WHERE id_designacion = @id_designacion) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.designacion_arbitral WHERE id_designacion = @id_designacion;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_designacion_arbitral_Consultar
    @id_designacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.designacion_arbitral
    WHERE (@id_designacion IS NULL OR id_designacion = @id_designacion)
    ORDER BY id_designacion;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.informe_arbitral
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_informe_arbitral_Alta
    @id_designacion INT,
    @fecha_informe DATE,
    @observaciones VARCHAR(50),
    @calificacion DECIMAL(5,2),
    @sanciones_pos_partido VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_designacion IS NULL SET @Errores += N'El campo id_designacion es obligatorio. ';
    IF @fecha_informe IS NULL SET @Errores += N'El campo fecha_informe es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.informe_arbitral t WHERE t.id_designacion = @id_designacion) SET @Errores += N'Ya existe un registro con la combinación id_designacion. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.informe_arbitral (id_designacion, fecha_informe, observaciones, calificacion, sanciones_pos_partido)
    VALUES (@id_designacion, @fecha_informe, @observaciones, @calificacion, @sanciones_pos_partido);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_informe_arbitral_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_informe_arbitral_Modificar
    @id_informe INT,
    @id_designacion INT,
    @fecha_informe DATE,
    @observaciones VARCHAR(50),
    @calificacion DECIMAL(5,2),
    @sanciones_pos_partido VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.informe_arbitral WHERE id_informe = @id_informe) SET @Errores += N'No existe el registro indicado. ';
    IF @id_designacion IS NULL SET @Errores += N'El campo id_designacion es obligatorio. ';
    IF @fecha_informe IS NULL SET @Errores += N'El campo fecha_informe es obligatorio. ';
    IF EXISTS (SELECT 1 FROM mundial.informe_arbitral t WHERE t.id_designacion = @id_designacion AND t.id_informe <> @id_informe) SET @Errores += N'Ya existe otro registro con la combinación id_designacion. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.informe_arbitral
    SET id_designacion = @id_designacion,
        fecha_informe = @fecha_informe,
        observaciones = @observaciones,
        calificacion = @calificacion,
        sanciones_pos_partido = @sanciones_pos_partido
    WHERE id_informe = @id_informe;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_informe_arbitral_Baja
    @id_informe INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.informe_arbitral WHERE id_informe = @id_informe) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.informe_arbitral WHERE id_informe = @id_informe;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_informe_arbitral_Consultar
    @id_informe INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.informe_arbitral
    WHERE (@id_informe IS NULL OR id_informe = @id_informe)
    ORDER BY id_informe;
END;
GO

-- =========================================================
-- ABM y consulta: mundial.alineacion_partido
-- =========================================================
CREATE OR ALTER PROCEDURE mundial.sp_alineacion_partido_Alta
    @id_partido_equipo INT,
    @id_jugador INT,
    @id_posicion_campo INT,
    @dorsal INT,
    @es_titular BIT,
    @minuto_regreso INT,
    @minuto_salida INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF @id_partido_equipo IS NULL SET @Errores += N'El campo id_partido_equipo es obligatorio. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_posicion_campo IS NULL SET @Errores += N'El campo id_posicion_campo es obligatorio. ';
    IF @dorsal IS NULL SET @Errores += N'El campo dorsal es obligatorio. ';
    IF @es_titular IS NULL SET @Errores += N'El campo es_titular es obligatorio. ';
    IF @dorsal IS NOT NULL AND (@dorsal < 1 OR @dorsal > 99) SET @Errores += N'El dorsal debe estar entre 1 y 99. ';
    IF @minuto_regreso IS NOT NULL AND @minuto_salida IS NOT NULL AND @minuto_regreso < @minuto_salida SET @Errores += N'El minuto de regreso no puede ser anterior al de salida. ';
    IF EXISTS (SELECT 1 FROM mundial.alineacion_partido t WHERE t.id_partido_equipo = @id_partido_equipo AND t.id_jugador = @id_jugador) SET @Errores += N'Ya existe un registro con la combinación id_partido_equipo, id_jugador. ';
    IF EXISTS (SELECT 1 FROM mundial.alineacion_partido t WHERE t.id_partido_equipo = @id_partido_equipo AND t.dorsal = @dorsal) SET @Errores += N'Ya existe un registro con la combinación id_partido_equipo, dorsal. ';
    IF LEN(@Errores) > 0 THROW 50100, @Errores, 1;
    INSERT INTO mundial.alineacion_partido (id_partido_equipo, id_jugador, id_posicion_campo, dorsal, es_titular, minuto_regreso, minuto_salida)
    VALUES (@id_partido_equipo, @id_jugador, @id_posicion_campo, @dorsal, @es_titular, @minuto_regreso, @minuto_salida);
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS id_alineacion_partido_creado;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_alineacion_partido_Modificar
    @id_alineacion INT,
    @id_partido_equipo INT,
    @id_jugador INT,
    @id_posicion_campo INT,
    @dorsal INT,
    @es_titular BIT,
    @minuto_regreso INT,
    @minuto_salida INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2048) = N'';
    IF NOT EXISTS (SELECT 1 FROM mundial.alineacion_partido WHERE id_alineacion = @id_alineacion) SET @Errores += N'No existe el registro indicado. ';
    IF @id_partido_equipo IS NULL SET @Errores += N'El campo id_partido_equipo es obligatorio. ';
    IF @id_jugador IS NULL SET @Errores += N'El campo id_jugador es obligatorio. ';
    IF @id_posicion_campo IS NULL SET @Errores += N'El campo id_posicion_campo es obligatorio. ';
    IF @dorsal IS NULL SET @Errores += N'El campo dorsal es obligatorio. ';
    IF @es_titular IS NULL SET @Errores += N'El campo es_titular es obligatorio. ';
    IF @dorsal IS NOT NULL AND (@dorsal < 1 OR @dorsal > 99) SET @Errores += N'El dorsal debe estar entre 1 y 99. ';
    IF @minuto_regreso IS NOT NULL AND @minuto_salida IS NOT NULL AND @minuto_regreso < @minuto_salida SET @Errores += N'El minuto de regreso no puede ser anterior al de salida. ';
    IF EXISTS (SELECT 1 FROM mundial.alineacion_partido t WHERE t.id_partido_equipo = @id_partido_equipo AND t.id_jugador = @id_jugador AND t.id_alineacion <> @id_alineacion) SET @Errores += N'Ya existe otro registro con la combinación id_partido_equipo, id_jugador. ';
    IF EXISTS (SELECT 1 FROM mundial.alineacion_partido t WHERE t.id_partido_equipo = @id_partido_equipo AND t.dorsal = @dorsal AND t.id_alineacion <> @id_alineacion) SET @Errores += N'Ya existe otro registro con la combinación id_partido_equipo, dorsal. ';
    IF LEN(@Errores) > 0 THROW 50101, @Errores, 1;
    UPDATE mundial.alineacion_partido
    SET id_partido_equipo = @id_partido_equipo,
        id_jugador = @id_jugador,
        id_posicion_campo = @id_posicion_campo,
        dorsal = @dorsal,
        es_titular = @es_titular,
        minuto_regreso = @minuto_regreso,
        minuto_salida = @minuto_salida
    WHERE id_alineacion = @id_alineacion;
    SELECT 'Registro modificado correctamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_alineacion_partido_Baja
    @id_alineacion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM mundial.alineacion_partido WHERE id_alineacion = @id_alineacion) THROW 50102, 'No existe el registro indicado.', 1;
    BEGIN TRY
        DELETE FROM mundial.alineacion_partido WHERE id_alineacion = @id_alineacion;
        SELECT 'Registro eliminado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 THROW 50103, 'No se puede eliminar el registro porque está relacionado con otros datos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE mundial.sp_alineacion_partido_Consultar
    @id_alineacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM mundial.alineacion_partido
    WHERE (@id_alineacion IS NULL OR id_alineacion = @id_alineacion)
    ORDER BY id_alineacion;
END;
GO



