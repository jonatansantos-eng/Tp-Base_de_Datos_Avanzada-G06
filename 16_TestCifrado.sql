/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-23
    Objetivo: Realizar pruebas unitarias sobre el cifrado de datos sensibles en la base de datos.
*/
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* 1. Verificar jerarquia criptografica. */
IF NOT EXISTS
(
    SELECT 1
    FROM sys.symmetric_keys
    WHERE name = N'SK_DatosPersonales'
)
    THROW 55100, N'Falta la clave simetrica SK_DatosPersonales.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.certificates
    WHERE name = N'Cert_DatosPersonales'
)
    THROW 55101, N'Falta el certificado Cert_DatosPersonales.', 1;

PRINT N'OK 1: certificado y clave simetrica existentes.';
GO

/* 2. Verificar que las columnas planas fueron eliminadas. */
DECLARE @ColumnasPlanas TABLE
(
    tabla SYSNAME,
    columna SYSNAME
);

INSERT INTO @ColumnasPlanas(tabla, columna)
VALUES
    (N'jugador', N'nombres'),
    (N'jugador', N'apellidos'),
    (N'jugador', N'fecha_nacimiento'),
    (N'jugador', N'doc_identidad'),
    (N'arbitro', N'nombres'),
    (N'arbitro', N'apellidos'),
    (N'arbitro', N'fecha_nacimiento'),
    (N'cuerpo_tecnico', N'nombres'),
    (N'cuerpo_tecnico', N'apellidos'),
    (N'anunciante', N'identificador_fiscal'),
    (N'anunciante', N'email_contacto');

IF EXISTS
(
    SELECT 1
    FROM @ColumnasPlanas AS p
    INNER JOIN sys.tables AS tb
        ON tb.name = p.tabla
       AND tb.schema_id = SCHEMA_ID(N'mundial')
    INNER JOIN sys.columns AS c
        ON c.object_id = tb.object_id
       AND c.name = p.columna
)
BEGIN
    SELECT
        p.tabla,
        p.columna AS columna_plana_encontrada
    FROM @ColumnasPlanas AS p
    INNER JOIN sys.tables AS tb
        ON tb.name = p.tabla
       AND tb.schema_id = SCHEMA_ID(N'mundial')
    INNER JOIN sys.columns AS c
        ON c.object_id = tb.object_id
       AND c.name = p.columna;

    THROW 55102, N'Quedaron columnas sensibles en texto plano.', 1;
END;

PRINT N'OK 2: no existen columnas sensibles en texto plano.';
GO

/* 3. Verificar columnas cifradas, tipos y obligatoriedad. */
DECLARE @Esperadas TABLE
(
    tabla SYSNAME,
    columna SYSNAME,
    tipo SYSNAME,
    longitud SMALLINT,
    permite_null BIT
);

INSERT INTO @Esperadas(tabla, columna, tipo, longitud, permite_null)
VALUES
    (N'jugador', N'nombres_cifrado', N'varbinary', 256, 0),
    (N'jugador', N'apellidos_cifrado', N'varbinary', 256, 0),
    (N'jugador', N'fecha_nacimiento_cifrado', N'varbinary', 128, 0),
    (N'jugador', N'doc_identidad_cifrado', N'varbinary', 256, 0),
    (N'jugador', N'doc_identidad_hash', N'binary', 32, 0),
    (N'arbitro', N'nombres_cifrado', N'varbinary', 256, 0),
    (N'arbitro', N'apellidos_cifrado', N'varbinary', 256, 0),
    (N'arbitro', N'fecha_nacimiento_cifrado', N'varbinary', 128, 0),
    (N'cuerpo_tecnico', N'nombres_cifrado', N'varbinary', 256, 0),
    (N'cuerpo_tecnico', N'apellidos_cifrado', N'varbinary', 256, 0),
    (N'anunciante', N'identificador_fiscal_cifrado', N'varbinary', 256, 0),
    (N'anunciante', N'email_contacto_cifrado', N'varbinary', 512, 0),
    (N'anunciante', N'identificador_fiscal_hash', N'binary', 32, 0),
    (N'anunciante', N'email_contacto_hash', N'binary', 32, 0);

IF EXISTS
(
    SELECT 1
    FROM @Esperadas AS e
    LEFT JOIN sys.tables AS tb
        ON tb.name = e.tabla
       AND tb.schema_id = SCHEMA_ID(N'mundial')
    LEFT JOIN sys.columns AS c
        ON c.object_id = tb.object_id
       AND c.name = e.columna
    LEFT JOIN sys.types AS ty
        ON ty.user_type_id = c.user_type_id
    WHERE c.column_id IS NULL
       OR ty.name <> e.tipo
       OR c.max_length <> e.longitud
       OR c.is_nullable <> e.permite_null
)
BEGIN
    SELECT
        e.tabla,
        e.columna,
        e.tipo AS tipo_esperado,
        ty.name AS tipo_actual,
        e.longitud AS longitud_esperada,
        c.max_length AS longitud_actual,
        e.permite_null AS null_esperado,
        c.is_nullable AS null_actual
    FROM @Esperadas AS e
    LEFT JOIN sys.tables AS tb
        ON tb.name = e.tabla
       AND tb.schema_id = SCHEMA_ID(N'mundial')
    LEFT JOIN sys.columns AS c
        ON c.object_id = tb.object_id
       AND c.name = e.columna
    LEFT JOIN sys.types AS ty
        ON ty.user_type_id = c.user_type_id
    WHERE c.column_id IS NULL
       OR ty.name <> e.tipo
       OR c.max_length <> e.longitud
       OR c.is_nullable <> e.permite_null;

    THROW 55103, N'La estructura de las columnas cifradas no coincide con la esperada.', 1;
END;

PRINT N'OK 3: columnas cifradas con tipo, longitud y nulabilidad correctos.';
GO

/* 4. Verificar que no haya valores cifrados o hashes nulos. */
IF EXISTS
(
    SELECT 1
    FROM mundial.jugador
    WHERE nombres_cifrado IS NULL
       OR apellidos_cifrado IS NULL
       OR fecha_nacimiento_cifrado IS NULL
       OR doc_identidad_cifrado IS NULL
       OR doc_identidad_hash IS NULL
)
    THROW 55104, N'Hay jugadores con datos cifrados incompletos.', 1;

IF EXISTS
(
    SELECT 1
    FROM mundial.arbitro
    WHERE nombres_cifrado IS NULL
       OR apellidos_cifrado IS NULL
       OR fecha_nacimiento_cifrado IS NULL
)
    THROW 55105, N'Hay arbitros con datos cifrados incompletos.', 1;

IF EXISTS
(
    SELECT 1
    FROM mundial.cuerpo_tecnico
    WHERE nombres_cifrado IS NULL
       OR apellidos_cifrado IS NULL
)
    THROW 55106, N'Hay miembros del cuerpo tecnico con datos cifrados incompletos.', 1;

IF EXISTS
(
    SELECT 1
    FROM mundial.anunciante
    WHERE identificador_fiscal_cifrado IS NULL
       OR email_contacto_cifrado IS NULL
       OR identificador_fiscal_hash IS NULL
       OR email_contacto_hash IS NULL
)
    THROW 55107, N'Hay anunciantes con datos cifrados incompletos.', 1;

PRINT N'OK 4: todos los registros tienen datos cifrados e indices hash.';
GO

/* 5. Demostrar que los valores persistidos son binarios y descifrables. */
DECLARE
    @id_jugador INT,
    @nombre_jugador VARCHAR(100),
    @apellido_jugador VARCHAR(100),
    @fecha_jugador DATE,
    @documento_jugador VARCHAR(50),
    @id_arbitro INT,
    @nombre_arbitro VARCHAR(100),
    @id_miembro_ct INT,
    @nombre_ct VARCHAR(100),
    @id_anunciante INT,
    @identificador_fiscal VARCHAR(50),
    @email VARCHAR(254);

SELECT TOP (1) @id_jugador = id_jugador
FROM mundial.jugador
ORDER BY id_jugador;

SELECT TOP (1) @id_arbitro = id_arbitro
FROM mundial.arbitro
ORDER BY id_arbitro;

SELECT TOP (1) @id_miembro_ct = id_miembro_ct
FROM mundial.cuerpo_tecnico
ORDER BY id_miembro_ct;

SELECT TOP (1) @id_anunciante = id_anunciante
FROM mundial.anunciante
ORDER BY id_anunciante;

OPEN SYMMETRIC KEY SK_DatosPersonales
DECRYPTION BY CERTIFICATE Cert_DatosPersonales;

SELECT
    @nombre_jugador = CONVERT(VARCHAR(100), DecryptByKey(nombres_cifrado)),
    @apellido_jugador = CONVERT(VARCHAR(100), DecryptByKey(apellidos_cifrado)),
    @fecha_jugador = TRY_CONVERT
    (
        DATE,
        CONVERT(VARCHAR(10), DecryptByKey(fecha_nacimiento_cifrado)),
        23
    ),
    @documento_jugador = CONVERT(VARCHAR(50), DecryptByKey(doc_identidad_cifrado))
FROM mundial.jugador
WHERE id_jugador = @id_jugador;

SELECT
    @nombre_arbitro = CONVERT(VARCHAR(100), DecryptByKey(nombres_cifrado))
FROM mundial.arbitro
WHERE id_arbitro = @id_arbitro;

SELECT
    @nombre_ct = CONVERT(VARCHAR(100), DecryptByKey(nombres_cifrado))
FROM mundial.cuerpo_tecnico
WHERE id_miembro_ct = @id_miembro_ct;

SELECT
    @identificador_fiscal = CONVERT
    (
        VARCHAR(50),
        DecryptByKey(identificador_fiscal_cifrado)
    ),
    @email = CONVERT
    (
        VARCHAR(254),
        DecryptByKey(email_contacto_cifrado)
    )
FROM mundial.anunciante
WHERE id_anunciante = @id_anunciante;

CLOSE SYMMETRIC KEY SK_DatosPersonales;

IF @id_jugador IS NOT NULL
   AND
   (
       NULLIF(@nombre_jugador, '') IS NULL
       OR NULLIF(@apellido_jugador, '') IS NULL
       OR @fecha_jugador IS NULL
       OR NULLIF(@documento_jugador, '') IS NULL
   )
    THROW 55108, N'No se pudo descifrar correctamente un jugador.', 1;

IF @id_arbitro IS NOT NULL AND NULLIF(@nombre_arbitro, '') IS NULL
    THROW 55109, N'No se pudo descifrar correctamente un arbitro.', 1;

IF @id_miembro_ct IS NOT NULL AND NULLIF(@nombre_ct, '') IS NULL
    THROW 55110, N'No se pudo descifrar correctamente un miembro del cuerpo tecnico.', 1;

IF @id_anunciante IS NOT NULL
   AND
   (
       NULLIF(@identificador_fiscal, '') IS NULL
       OR NULLIF(@email, '') IS NULL
   )
    THROW 55111, N'No se pudo descifrar correctamente un anunciante.', 1;

SELECT
    @id_jugador AS id_jugador_prueba,
    @nombre_jugador AS nombre_descifrado,
    @apellido_jugador AS apellido_descifrado,
    @fecha_jugador AS fecha_nacimiento_descifrada,
    @documento_jugador AS documento_descifrado;

PRINT N'OK 5: los datos cifrados se descifran correctamente con la clave autorizada.';
GO

/* 6. Verificar indices unicos de hashes. */
IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'mundial.jugador')
      AND name = N'UX_jugador_documento_hash'
      AND is_unique = 1
)
    THROW 55112, N'Falta el indice unico de documento del jugador.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'mundial.anunciante')
      AND name = N'UX_anunciante_identificador_hash'
      AND is_unique = 1
)
    THROW 55113, N'Falta el indice unico del identificador fiscal.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'mundial.anunciante')
      AND name = N'UX_anunciante_email_hash'
      AND is_unique = 1
)
    THROW 55114, N'Falta el indice unico del email.', 1;

PRINT N'OK 6: indices unicos sobre hashes existentes.';
GO

/* 7. Verificar SP públicos, sensibles y reportes afectados. */
DECLARE @Procedimientos TABLE(nombre SYSNAME PRIMARY KEY);
INSERT INTO @Procedimientos(nombre)
VALUES
    (N'mundial.sp_jugador_Alta'),
    (N'mundial.sp_jugador_Modificar'),
    (N'mundial.sp_jugador_Consultar'),
    (N'mundial.sp_jugador_ConsultarSensible'),
    (N'mundial.sp_arbitro_Consultar'),
    (N'mundial.sp_cuerpo_tecnico_Consultar'),
    (N'mundial.sp_anunciante_Consultar'),
    (N'mundial.sp_anunciante_ConsultarSensible'),
    (N'mundial.sp_reporte_Goleadores'),
    (N'mundial.sp_reporte_Tarjetas'),
    (N'mundial.sp_reporte_DesignacionesArbitrales'),
    (N'mundial.sp_reporte_SeleccionesPlantillas'),
    (N'mundial.sp_reporte_ResultadosEncuentros');

IF EXISTS
(
    SELECT 1
    FROM @Procedimientos
    WHERE OBJECT_ID(nombre, N'P') IS NULL
)
BEGIN
    SELECT nombre AS procedimiento_faltante
    FROM @Procedimientos
    WHERE OBJECT_ID(nombre, N'P') IS NULL;

    THROW 55115, N'Faltan procedimientos compatibles con el cifrado.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM sys.sql_modules AS m
    INNER JOIN sys.objects AS o
        ON o.object_id = m.object_id
    WHERE o.schema_id = SCHEMA_ID(N'mundial')
      AND o.name IN
      (
          N'sp_jugador_Alta',
          N'sp_jugador_Modificar',
          N'sp_jugador_Consultar',
          N'sp_jugador_ConsultarSensible',
          N'sp_reporte_Goleadores',
          N'sp_reporte_Tarjetas',
          N'sp_reporte_DesignacionesArbitrales',
          N'sp_reporte_SeleccionesPlantillas',
          N'sp_reporte_ResultadosEncuentros'
      )
      AND
      (
          m.definition LIKE N'%j.nombres)%'
          OR m.definition LIKE N'%j.apellidos)%'
          OR m.definition LIKE N'%j.fecha_nacimiento)%'
          OR m.definition LIKE N'%j.doc_identidad)%'
      )
)
    THROW 55116, N'Hay procedimientos que todavia referencian columnas planas.', 1;

PRINT N'OK 7: procedimientos y reportes adaptados al cifrado.';
GO

/* 8. Ejecutar consultas de demostracion. */
DECLARE @JugadorPrueba INT =
(
    SELECT TOP (1) id_jugador
    FROM mundial.jugador
    ORDER BY id_jugador
);

IF @JugadorPrueba IS NOT NULL
BEGIN
    EXEC mundial.sp_jugador_Consultar
        @id_jugador = @JugadorPrueba;

    EXEC mundial.sp_jugador_ConsultarSensible
        @id_jugador = @JugadorPrueba;
END;

PRINT N'FIN: testing de cifrado completado correctamente.';
GO
