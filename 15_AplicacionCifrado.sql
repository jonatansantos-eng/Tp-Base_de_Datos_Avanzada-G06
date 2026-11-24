/*
 Universidad Nacional de La Matanza
 Materia: 3641 - Bases de Datos Aplicada
 Entrega 8 - Aplicacion de cifrado de datos sensibles
 Integrantes: Coria Lautaro, Quispe Barja Sergio, Santos Jonatan
 Fecha: 2026-11-23

 IMPORTANTE:
 1. Ejecutar con SQLCMD Mode activado.
 2. Ejecutar sobre una TP2026 limpia, reconstruida con scripts 01 a 14.
 3. Realizar un backup completo previo.
*/
:r C:\TP2026\00_Secretos.local.sql

USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* Precondicion: impedir ejecutar sobre una migracion parcial. */
IF COL_LENGTH(N'mundial.jugador',N'nombres_cifrado') IS NOT NULL
   OR EXISTS
   (
       SELECT 1
       FROM sys.columns c
       JOIN sys.types t ON t.user_type_id=c.user_type_id
       WHERE c.object_id=OBJECT_ID(N'mundial.jugador')
         AND c.name=N'nombres'
         AND t.name=N'varbinary'
   )
BEGIN
    THROW 55000,N'La base ya tiene una migracion de cifrado total o parcial. Recree TP2026 con scripts 01 a 14 antes de ejecutar este archivo.',1;
END;
GO

/* 1. Jerarquia criptografica. */
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name=N'##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD='$(PasswordMasterKey)';
GO
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name=N'Cert_DatosPersonales')
    CREATE CERTIFICATE Cert_DatosPersonales
    WITH SUBJECT=N'Cifrado AES-256 de datos personales de TP2026',EXPIRY_DATE='2036-12-31';
GO
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name=N'SK_DatosPersonales')
    CREATE SYMMETRIC KEY SK_DatosPersonales WITH ALGORITHM=AES_256
    ENCRYPTION BY CERTIFICATE Cert_DatosPersonales;
GO

/* 2. Columnas de destino. No se renombran las columnas: se conservan sufijos _cifrado.
      Eso evita invalidacion de metadatos y conversiones implicitas. */
ALTER TABLE mundial.jugador ADD
 nombres_cifrado VARBINARY(256) NULL,apellidos_cifrado VARBINARY(256) NULL,
 fecha_nacimiento_cifrado VARBINARY(128) NULL,doc_identidad_cifrado VARBINARY(256) NULL,
 doc_identidad_hash BINARY(32) NULL;
ALTER TABLE mundial.arbitro ADD
 nombres_cifrado VARBINARY(256) NULL,apellidos_cifrado VARBINARY(256) NULL,
 fecha_nacimiento_cifrado VARBINARY(128) NULL;
ALTER TABLE mundial.cuerpo_tecnico ADD nombres_cifrado VARBINARY(256) NULL,apellidos_cifrado VARBINARY(256) NULL;
ALTER TABLE mundial.anunciante ADD
 identificador_fiscal_cifrado VARBINARY(256) NULL,email_contacto_cifrado VARBINARY(512) NULL,
 identificador_fiscal_hash BINARY(32) NULL,email_contacto_hash BINARY(32) NULL;
GO

/* 3. Copia cifrada. */
BEGIN TRY
 BEGIN TRANSACTION;
 OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 UPDATE mundial.jugador SET
  nombres_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),nombres)),
  apellidos_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),apellidos)),
  fecha_nacimiento_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),CONVERT(CHAR(10),fecha_nacimiento,23))),
  doc_identidad_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),doc_identidad)),
  doc_identidad_hash=HASHBYTES('SHA2_256',UPPER(LTRIM(RTRIM(doc_identidad))));
 UPDATE mundial.arbitro SET
  nombres_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),nombres)),
  apellidos_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),apellidos)),
  fecha_nacimiento_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),CONVERT(CHAR(10),fecha_nacimiento,23)));
 UPDATE mundial.cuerpo_tecnico SET
  nombres_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),nombres)),
  apellidos_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),apellidos));
 UPDATE mundial.anunciante SET
  identificador_fiscal_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),identificador_fiscal)),
  email_contacto_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),email_contacto)),
  identificador_fiscal_hash=HASHBYTES('SHA2_256',UPPER(LTRIM(RTRIM(identificador_fiscal)))),
  email_contacto_hash=HASHBYTES('SHA2_256',LOWER(LTRIM(RTRIM(email_contacto))));
 CLOSE SYMMETRIC KEY SK_DatosPersonales;
 IF EXISTS(SELECT 1 FROM mundial.jugador WHERE nombres_cifrado IS NULL OR apellidos_cifrado IS NULL OR fecha_nacimiento_cifrado IS NULL OR doc_identidad_cifrado IS NULL OR doc_identidad_hash IS NULL) THROW 55001,N'Migracion de jugadores incompleta.',1;
 IF EXISTS(SELECT 1 FROM mundial.arbitro WHERE nombres_cifrado IS NULL OR apellidos_cifrado IS NULL OR fecha_nacimiento_cifrado IS NULL) THROW 55002,N'Migracion de arbitros incompleta.',1;
 IF EXISTS(SELECT 1 FROM mundial.cuerpo_tecnico WHERE nombres_cifrado IS NULL OR apellidos_cifrado IS NULL) THROW 55003,N'Migracion de cuerpo tecnico incompleta.',1;
 IF EXISTS(SELECT 1 FROM mundial.anunciante WHERE identificador_fiscal_cifrado IS NULL OR email_contacto_cifrado IS NULL OR identificador_fiscal_hash IS NULL OR email_contacto_hash IS NULL) THROW 55004,N'Migracion de anunciantes incompleta.',1;
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 IF EXISTS(SELECT 1 FROM sys.openkeys WHERE key_name=N'SK_DatosPersonales') CLOSE SYMMETRIC KEY SK_DatosPersonales;
 THROW;
END CATCH;
GO

/* 4. Validar descifrado antes de eliminar texto plano. */
DECLARE @Fallos INT=0;
OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
SELECT @Fallos=@Fallos+COUNT(*) FROM mundial.jugador WHERE NULLIF(CONVERT(VARCHAR(100),DecryptByKey(nombres_cifrado)),'') IS NULL OR NULLIF(CONVERT(VARCHAR(50),DecryptByKey(doc_identidad_cifrado)),'') IS NULL;
SELECT @Fallos=@Fallos+COUNT(*) FROM mundial.arbitro WHERE NULLIF(CONVERT(VARCHAR(100),DecryptByKey(nombres_cifrado)),'') IS NULL;
SELECT @Fallos=@Fallos+COUNT(*) FROM mundial.cuerpo_tecnico WHERE NULLIF(CONVERT(VARCHAR(100),DecryptByKey(nombres_cifrado)),'') IS NULL;
SELECT @Fallos=@Fallos+COUNT(*) FROM mundial.anunciante WHERE NULLIF(CONVERT(VARCHAR(50),DecryptByKey(identificador_fiscal_cifrado)),'') IS NULL;
CLOSE SYMMETRIC KEY SK_DatosPersonales;
IF @Fallos>0 THROW 55005,N'La comprobacion de descifrado fallo. No se elimina texto plano.',1;
GO

/* 5. Primero modificar SP y reportes para que no dependan de columnas planas. */
CREATE OR ALTER PROCEDURE mundial.sp_jugador_Alta
 @id_pais_nacionalidad INT,@id_club INT,@id_posicion_habitual INT,@nombres VARCHAR(100),@apellidos VARCHAR(100),@fecha_nacimiento DATE,@doc_identidad VARCHAR(50)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @e NVARCHAR(2048)=N'',@h BINARY(32)=HASHBYTES('SHA2_256',UPPER(LTRIM(RTRIM(@doc_identidad))));
 IF NOT EXISTS(SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais_nacionalidad) SET @e+=N'El pais no existe. ';
 IF NOT EXISTS(SELECT 1 FROM mundial.club WHERE id_club=@id_club) SET @e+=N'El club no existe. ';
 IF NOT EXISTS(SELECT 1 FROM mundial.posicion WHERE id_posicion=@id_posicion_habitual) SET @e+=N'La posicion no existe. ';
 IF NULLIF(LTRIM(RTRIM(@nombres)),'') IS NULL SET @e+=N'Nombres obligatorios. ';
 IF NULLIF(LTRIM(RTRIM(@apellidos)),'') IS NULL SET @e+=N'Apellidos obligatorios. ';
 IF @fecha_nacimiento IS NULL SET @e+=N'Fecha obligatoria. ';
 IF NULLIF(LTRIM(RTRIM(@doc_identidad)),'') IS NULL SET @e+=N'Documento obligatorio. ';
 IF EXISTS(SELECT 1 FROM mundial.jugador WHERE doc_identidad_hash=@h) SET @e+=N'Documento duplicado. ';
 IF LEN(@e)>0 THROW 55010,@e,1;
 OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 INSERT mundial.jugador(id_pais_nacionalidad,id_club,id_posicion_habitual,nombres,apellidos,fecha_nacimiento,doc_identidad,nombres_cifrado,apellidos_cifrado,fecha_nacimiento_cifrado,doc_identidad_cifrado,doc_identidad_hash)
 VALUES(@id_pais_nacionalidad,@id_club,@id_posicion_habitual,'CIFRADO','CIFRADO','19000101','CIFRADO',
  EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@nombres)),EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@apellidos)),
  EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),CONVERT(CHAR(10),@fecha_nacimiento,23))),EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@doc_identidad)),@h);
 CLOSE SYMMETRIC KEY SK_DatosPersonales;
 SELECT CONVERT(INT,SCOPE_IDENTITY()) id_jugador_creado;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_jugador_Modificar
 @id_jugador INT,@id_pais_nacionalidad INT,@id_club INT,@id_posicion_habitual INT,@nombres VARCHAR(100),@apellidos VARCHAR(100),@fecha_nacimiento DATE,@doc_identidad VARCHAR(50)
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @h BINARY(32)=HASHBYTES('SHA2_256',UPPER(LTRIM(RTRIM(@doc_identidad))));
 IF NOT EXISTS(SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador) THROW 55011,N'Jugador inexistente.',1;
 IF EXISTS(SELECT 1 FROM mundial.jugador WHERE doc_identidad_hash=@h AND id_jugador<>@id_jugador) THROW 55012,N'Documento duplicado.',1;
 OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 UPDATE mundial.jugador SET id_pais_nacionalidad=@id_pais_nacionalidad,id_club=@id_club,id_posicion_habitual=@id_posicion_habitual,
  nombres_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@nombres)),apellidos_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@apellidos)),
  fecha_nacimiento_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),CONVERT(CHAR(10),@fecha_nacimiento,23))),doc_identidad_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@doc_identidad)),doc_identidad_hash=@h
 WHERE id_jugador=@id_jugador;
 CLOSE SYMMETRIC KEY SK_DatosPersonales;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_jugador_Consultar @id_jugador INT=NULL
AS BEGIN OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 SELECT id_jugador,id_pais_nacionalidad,id_club,id_posicion_habitual,CONVERT(VARCHAR(100),DecryptByKey(nombres_cifrado)) nombres,CONVERT(VARCHAR(100),DecryptByKey(apellidos_cifrado)) apellidos FROM mundial.jugador WHERE @id_jugador IS NULL OR id_jugador=@id_jugador;
 CLOSE SYMMETRIC KEY SK_DatosPersonales; END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_jugador_ConsultarSensible @id_jugador INT=NULL
AS BEGIN OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 SELECT id_jugador,id_pais_nacionalidad,id_club,id_posicion_habitual,CONVERT(VARCHAR(100),DecryptByKey(nombres_cifrado)) nombres,CONVERT(VARCHAR(100),DecryptByKey(apellidos_cifrado)) apellidos,
 TRY_CONVERT(DATE,CONVERT(VARCHAR(10),DecryptByKey(fecha_nacimiento_cifrado)),23) fecha_nacimiento,CONVERT(VARCHAR(50),DecryptByKey(doc_identidad_cifrado)) doc_identidad FROM mundial.jugador WHERE @id_jugador IS NULL OR id_jugador=@id_jugador;
 CLOSE SYMMETRIC KEY SK_DatosPersonales; END;
GO

/* Los ABM de arbitro, cuerpo tecnico y anunciante se recompilan contra columnas *_cifrado. */
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_Consultar @id_arbitro INT=NULL
AS BEGIN OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 SELECT id_arbitro,id_pais_nacionalidad,id_confederacion_afiliacion,CONVERT(VARCHAR(100),DecryptByKey(nombres_cifrado)) nombres,CONVERT(VARCHAR(100),DecryptByKey(apellidos_cifrado)) apellidos,categoria FROM mundial.arbitro WHERE @id_arbitro IS NULL OR id_arbitro=@id_arbitro;
 CLOSE SYMMETRIC KEY SK_DatosPersonales; END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_cuerpo_tecnico_Consultar @id_miembro_ct INT=NULL
AS BEGIN OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 SELECT id_miembro_ct,id_seleccion,id_pais_nacionalidad,id_rol_ct,CONVERT(VARCHAR(100),DecryptByKey(nombres_cifrado)) nombres,CONVERT(VARCHAR(100),DecryptByKey(apellidos_cifrado)) apellidos FROM mundial.cuerpo_tecnico WHERE @id_miembro_ct IS NULL OR id_miembro_ct=@id_miembro_ct;
 CLOSE SYMMETRIC KEY SK_DatosPersonales; END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_anunciante_Consultar @id_anunciante INT=NULL
AS SELECT id_anunciante,id_pais_origen,razon_social FROM mundial.anunciante WHERE @id_anunciante IS NULL OR id_anunciante=@id_anunciante;
GO
CREATE OR ALTER PROCEDURE mundial.sp_anunciante_ConsultarSensible @id_anunciante INT=NULL
AS BEGIN OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 SELECT id_anunciante,id_pais_origen,razon_social,CONVERT(VARCHAR(50),DecryptByKey(identificador_fiscal_cifrado)) identificador_fiscal,CONVERT(VARCHAR(254),DecryptByKey(email_contacto_cifrado)) email_contacto FROM mundial.anunciante WHERE @id_anunciante IS NULL OR id_anunciante=@id_anunciante;
 CLOSE SYMMETRIC KEY SK_DatosPersonales; END;
GO

/* 6. Reportes afectados. Se mantienen nombres originales y parametros esenciales. */
CREATE OR ALTER PROCEDURE mundial.sp_reporte_Goleadores @id_fase INT=NULL,@id_seleccion INT=NULL
AS BEGIN OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 SELECT DENSE_RANK() OVER(ORDER BY COUNT(g.id_gol) DESC) Ranking,CONCAT(CONVERT(VARCHAR(100),DecryptByKey(j.nombres_cifrado)),' ',CONVERT(VARCHAR(100),DecryptByKey(j.apellidos_cifrado))) Jugador,
 pa.nombre Seleccion,pos.descripcion Posicion,c.dorsal,f.nombre_fase Fase,COUNT(*) GolesTotales
 FROM mundial.gol g JOIN mundial.partido pt ON pt.id_partido=g.id_partido JOIN mundial.fase f ON f.id_fase=pt.id_fase JOIN mundial.jugador j ON j.id_jugador=g.id_jugador_autor JOIN mundial.posicion pos ON pos.id_posicion=j.id_posicion_habitual JOIN mundial.seleccion s ON s.id_seleccion=g.id_seleccion_beneficiada JOIN mundial.pais pa ON pa.id_pais=s.id_pais LEFT JOIN mundial.convocatoria c ON c.id_seleccion=s.id_seleccion AND c.id_jugador=j.id_jugador
 WHERE (@id_fase IS NULL OR pt.id_fase=@id_fase) AND (@id_seleccion IS NULL OR s.id_seleccion=@id_seleccion)
 GROUP BY j.id_jugador,j.nombres_cifrado,j.apellidos_cifrado,pa.nombre,pos.descripcion,c.dorsal,f.nombre_fase ORDER BY GolesTotales DESC,Jugador;
 CLOSE SYMMETRIC KEY SK_DatosPersonales; END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_reporte_SeleccionesPlantillas @id_seleccion INT=NULL
AS BEGIN OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 SELECT p.nombre [@pais],p.codigo_iso [@codigo_iso],(SELECT c2.dorsal [@dorsal],CONCAT(CONVERT(VARCHAR(100),DecryptByKey(j.nombres_cifrado)),' ',CONVERT(VARCHAR(100),DecryptByKey(j.apellidos_cifrado))) [@nombre_completo],pos.descripcion [@posicion],cl.nombre_club [@club_origen]
 FROM mundial.convocatoria c2 JOIN mundial.jugador j ON j.id_jugador=c2.id_jugador JOIN mundial.posicion pos ON pos.id_posicion=j.id_posicion_habitual JOIN mundial.club cl ON cl.id_club=j.id_club WHERE c2.id_seleccion=s.id_seleccion ORDER BY c2.dorsal FOR XML PATH('Jugador'),TYPE) PlantillaConvocados
 FROM mundial.seleccion s JOIN mundial.pais p ON p.id_pais=s.id_pais WHERE @id_seleccion IS NULL OR s.id_seleccion=@id_seleccion FOR XML PATH('Seleccion'),ROOT('TorneoMundialFIFA2026');
 CLOSE SYMMETRIC KEY SK_DatosPersonales; END;
GO

/* 7. Eliminar texto plano al final, cuando ya no lo usan estos SP/reportes. */
IF EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'mundial.jugador') AND name=N'UQ_jugador_documento') ALTER TABLE mundial.jugador DROP CONSTRAINT UQ_jugador_documento;
IF EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'mundial.anunciante') AND name=N'UQ_anunciante_identificador') ALTER TABLE mundial.anunciante DROP CONSTRAINT UQ_anunciante_identificador;
IF EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'mundial.anunciante') AND name=N'UQ_anunciante_email') ALTER TABLE mundial.anunciante DROP CONSTRAINT UQ_anunciante_email;
GO
ALTER TABLE mundial.jugador DROP COLUMN nombres,apellidos,fecha_nacimiento,doc_identidad;
ALTER TABLE mundial.arbitro DROP COLUMN nombres,apellidos,fecha_nacimiento;
ALTER TABLE mundial.cuerpo_tecnico DROP COLUMN nombres,apellidos;
ALTER TABLE mundial.anunciante DROP COLUMN identificador_fiscal,email_contacto;
GO
ALTER TABLE mundial.jugador ALTER COLUMN nombres_cifrado VARBINARY(256) NOT NULL;
ALTER TABLE mundial.jugador ALTER COLUMN apellidos_cifrado VARBINARY(256) NOT NULL;
ALTER TABLE mundial.jugador ALTER COLUMN fecha_nacimiento_cifrado VARBINARY(128) NOT NULL;
ALTER TABLE mundial.jugador ALTER COLUMN doc_identidad_cifrado VARBINARY(256) NOT NULL;
ALTER TABLE mundial.jugador ALTER COLUMN doc_identidad_hash BINARY(32) NOT NULL;
ALTER TABLE mundial.arbitro ALTER COLUMN nombres_cifrado VARBINARY(256) NOT NULL;
ALTER TABLE mundial.arbitro ALTER COLUMN apellidos_cifrado VARBINARY(256) NOT NULL;
ALTER TABLE mundial.arbitro ALTER COLUMN fecha_nacimiento_cifrado VARBINARY(128) NOT NULL;
ALTER TABLE mundial.cuerpo_tecnico ALTER COLUMN nombres_cifrado VARBINARY(256) NOT NULL;
ALTER TABLE mundial.cuerpo_tecnico ALTER COLUMN apellidos_cifrado VARBINARY(256) NOT NULL;
ALTER TABLE mundial.anunciante ALTER COLUMN identificador_fiscal_cifrado VARBINARY(256) NOT NULL;
ALTER TABLE mundial.anunciante ALTER COLUMN email_contacto_cifrado VARBINARY(512) NOT NULL;
ALTER TABLE mundial.anunciante ALTER COLUMN identificador_fiscal_hash BINARY(32) NOT NULL;
ALTER TABLE mundial.anunciante ALTER COLUMN email_contacto_hash BINARY(32) NOT NULL;
GO
CREATE UNIQUE INDEX UX_jugador_documento_hash ON mundial.jugador(doc_identidad_hash);
CREATE UNIQUE INDEX UX_anunciante_identificador_hash ON mundial.anunciante(identificador_fiscal_hash);
CREATE UNIQUE INDEX UX_anunciante_email_hash ON mundial.anunciante(email_contacto_hash);
GO

/* 8. Validacion final de tipos y ausencia de columnas planas. */
IF COL_LENGTH(N'mundial.jugador',N'nombres') IS NOT NULL OR COL_LENGTH(N'mundial.arbitro',N'nombres') IS NOT NULL OR COL_LENGTH(N'mundial.cuerpo_tecnico',N'nombres') IS NOT NULL OR COL_LENGTH(N'mundial.anunciante',N'identificador_fiscal') IS NOT NULL
 THROW 55020,N'Quedaron columnas sensibles en texto plano.',1;
IF NOT EXISTS(SELECT 1 FROM sys.columns c JOIN sys.types t ON t.user_type_id=c.user_type_id WHERE c.object_id=OBJECT_ID(N'mundial.jugador') AND c.name=N'fecha_nacimiento_cifrado' AND t.name=N'varbinary')
 THROW 55021,N'jugador.fecha_nacimiento_cifrado no es VARBINARY.',1;
PRINT N'OK: cifrado aplicado y texto plano eliminado.';
GO

/* 9. Recompilacion FINAL de ABM luego de eliminar columnas planas. */
CREATE OR ALTER PROCEDURE mundial.sp_jugador_Alta
 @id_pais_nacionalidad INT,@id_club INT,@id_posicion_habitual INT,@nombres VARCHAR(100),@apellidos VARCHAR(100),@fecha_nacimiento DATE,@doc_identidad VARCHAR(50)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @e NVARCHAR(2048)=N'',@h BINARY(32)=HASHBYTES('SHA2_256',UPPER(LTRIM(RTRIM(@doc_identidad))));
 IF NOT EXISTS(SELECT 1 FROM mundial.pais WHERE id_pais=@id_pais_nacionalidad) SET @e+=N'El pais no existe. ';
 IF NOT EXISTS(SELECT 1 FROM mundial.club WHERE id_club=@id_club) SET @e+=N'El club no existe. ';
 IF NOT EXISTS(SELECT 1 FROM mundial.posicion WHERE id_posicion=@id_posicion_habitual) SET @e+=N'La posicion no existe. ';
 IF NULLIF(LTRIM(RTRIM(@nombres)),'') IS NULL SET @e+=N'Nombres obligatorios. ';
 IF NULLIF(LTRIM(RTRIM(@apellidos)),'') IS NULL SET @e+=N'Apellidos obligatorios. ';
 IF @fecha_nacimiento IS NULL SET @e+=N'Fecha obligatoria. ';
 IF NULLIF(LTRIM(RTRIM(@doc_identidad)),'') IS NULL SET @e+=N'Documento obligatorio. ';
 IF EXISTS(SELECT 1 FROM mundial.jugador WHERE doc_identidad_hash=@h) SET @e+=N'Documento duplicado. ';
 IF LEN(@e)>0 THROW 55010,@e,1;
 BEGIN TRY
  OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
  INSERT mundial.jugador(id_pais_nacionalidad,id_club,id_posicion_habitual,nombres_cifrado,apellidos_cifrado,fecha_nacimiento_cifrado,doc_identidad_cifrado,doc_identidad_hash)
  VALUES(@id_pais_nacionalidad,@id_club,@id_posicion_habitual,
   EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@nombres)),EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@apellidos)),
   EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),CONVERT(CHAR(10),@fecha_nacimiento,23))),EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@doc_identidad)),@h);
  CLOSE SYMMETRIC KEY SK_DatosPersonales;
  SELECT CONVERT(INT,SCOPE_IDENTITY()) id_jugador_creado;
 END TRY BEGIN CATCH
  IF EXISTS(SELECT 1 FROM sys.openkeys WHERE key_name=N'SK_DatosPersonales') CLOSE SYMMETRIC KEY SK_DatosPersonales;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_jugador_Modificar
 @id_jugador INT,@id_pais_nacionalidad INT,@id_club INT,@id_posicion_habitual INT,@nombres VARCHAR(100),@apellidos VARCHAR(100),@fecha_nacimiento DATE,@doc_identidad VARCHAR(50)
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @h BINARY(32)=HASHBYTES('SHA2_256',UPPER(LTRIM(RTRIM(@doc_identidad))));
 IF NOT EXISTS(SELECT 1 FROM mundial.jugador WHERE id_jugador=@id_jugador) THROW 55011,N'Jugador inexistente.',1;
 IF EXISTS(SELECT 1 FROM mundial.jugador WHERE doc_identidad_hash=@h AND id_jugador<>@id_jugador) THROW 55012,N'Documento duplicado.',1;
 OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 UPDATE mundial.jugador SET id_pais_nacionalidad=@id_pais_nacionalidad,id_club=@id_club,id_posicion_habitual=@id_posicion_habitual,
  nombres_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@nombres)),apellidos_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@apellidos)),
  fecha_nacimiento_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),CONVERT(CHAR(10),@fecha_nacimiento,23))),doc_identidad_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@doc_identidad)),doc_identidad_hash=@h
 WHERE id_jugador=@id_jugador;
 CLOSE SYMMETRIC KEY SK_DatosPersonales;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_Alta
 @id_pais_nacionalidad INT,@id_confederacion_afiliacion INT,@nombres VARCHAR(100),@apellidos VARCHAR(100),@fecha_nacimiento DATE,@categoria VARCHAR(50)
AS
BEGIN
 OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 INSERT mundial.arbitro(id_pais_nacionalidad,id_confederacion_afiliacion,nombres_cifrado,apellidos_cifrado,fecha_nacimiento_cifrado,categoria)
 VALUES(@id_pais_nacionalidad,@id_confederacion_afiliacion,EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@nombres)),EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@apellidos)),EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),CONVERT(CHAR(10),@fecha_nacimiento,23))),@categoria);
 CLOSE SYMMETRIC KEY SK_DatosPersonales; SELECT CONVERT(INT,SCOPE_IDENTITY()) id_arbitro_creado;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_arbitro_Modificar
 @id_arbitro INT,@id_pais_nacionalidad INT,@id_confederacion_afiliacion INT,@nombres VARCHAR(100),@apellidos VARCHAR(100),@fecha_nacimiento DATE,@categoria VARCHAR(50)
AS
BEGIN
 IF NOT EXISTS(SELECT 1 FROM mundial.arbitro WHERE id_arbitro=@id_arbitro) THROW 55021,N'El arbitro no existe.',1;
 OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 UPDATE mundial.arbitro SET id_pais_nacionalidad=@id_pais_nacionalidad,id_confederacion_afiliacion=@id_confederacion_afiliacion,
  nombres_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@nombres)),apellidos_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@apellidos)),fecha_nacimiento_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),CONVERT(CHAR(10),@fecha_nacimiento,23))),categoria=@categoria WHERE id_arbitro=@id_arbitro;
 CLOSE SYMMETRIC KEY SK_DatosPersonales;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_cuerpo_tecnico_Alta
 @id_seleccion INT,@id_pais_nacionalidad INT,@id_rol_ct INT,@nombres VARCHAR(100),@apellidos VARCHAR(100)
AS
BEGIN
 OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 INSERT mundial.cuerpo_tecnico(id_seleccion,id_pais_nacionalidad,id_rol_ct,nombres_cifrado,apellidos_cifrado)
 VALUES(@id_seleccion,@id_pais_nacionalidad,@id_rol_ct,EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@nombres)),EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@apellidos)));
 CLOSE SYMMETRIC KEY SK_DatosPersonales; SELECT CONVERT(INT,SCOPE_IDENTITY()) id_miembro_ct_creado;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_cuerpo_tecnico_Modificar
 @id_miembro_ct INT,@id_seleccion INT,@id_pais_nacionalidad INT,@id_rol_ct INT,@nombres VARCHAR(100),@apellidos VARCHAR(100)
AS
BEGIN
 IF NOT EXISTS(SELECT 1 FROM mundial.cuerpo_tecnico WHERE id_miembro_ct=@id_miembro_ct) THROW 55022,N'El miembro no existe.',1;
 OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 UPDATE mundial.cuerpo_tecnico SET id_seleccion=@id_seleccion,id_pais_nacionalidad=@id_pais_nacionalidad,id_rol_ct=@id_rol_ct,
  nombres_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@nombres)),apellidos_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@apellidos)) WHERE id_miembro_ct=@id_miembro_ct;
 CLOSE SYMMETRIC KEY SK_DatosPersonales;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_anunciante_Alta
 @id_pais_origen INT,@razon_social VARCHAR(200),@identificador_fiscal VARCHAR(50),@email_contacto VARCHAR(254)
AS
BEGIN
 DECLARE @hf BINARY(32)=HASHBYTES('SHA2_256',UPPER(LTRIM(RTRIM(@identificador_fiscal)))),@he BINARY(32)=HASHBYTES('SHA2_256',LOWER(LTRIM(RTRIM(@email_contacto))));
 IF EXISTS(SELECT 1 FROM mundial.anunciante WHERE identificador_fiscal_hash=@hf OR email_contacto_hash=@he) THROW 55023,N'Identificador fiscal o email duplicado.',1;
 OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 INSERT mundial.anunciante(id_pais_origen,razon_social,identificador_fiscal_cifrado,email_contacto_cifrado,identificador_fiscal_hash,email_contacto_hash)
 VALUES(@id_pais_origen,@razon_social,EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@identificador_fiscal)),EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@email_contacto)),@hf,@he);
 CLOSE SYMMETRIC KEY SK_DatosPersonales; SELECT CONVERT(INT,SCOPE_IDENTITY()) id_anunciante_creado;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_anunciante_Modificar
 @id_anunciante INT,@id_pais_origen INT,@razon_social VARCHAR(200),@identificador_fiscal VARCHAR(50),@email_contacto VARCHAR(254)
AS
BEGIN
 DECLARE @hf BINARY(32)=HASHBYTES('SHA2_256',UPPER(LTRIM(RTRIM(@identificador_fiscal)))),@he BINARY(32)=HASHBYTES('SHA2_256',LOWER(LTRIM(RTRIM(@email_contacto))));
 IF NOT EXISTS(SELECT 1 FROM mundial.anunciante WHERE id_anunciante=@id_anunciante) THROW 55024,N'El anunciante no existe.',1;
 OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 UPDATE mundial.anunciante SET id_pais_origen=@id_pais_origen,razon_social=@razon_social,
  identificador_fiscal_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@identificador_fiscal)),email_contacto_cifrado=EncryptByKey(Key_GUID(N'SK_DatosPersonales'),CONVERT(VARBINARY(MAX),@email_contacto)),identificador_fiscal_hash=@hf,email_contacto_hash=@he WHERE id_anunciante=@id_anunciante;
 CLOSE SYMMETRIC KEY SK_DatosPersonales;
END;
GO
PRINT N'OK: ABM sensibles recompilados contra columnas cifradas.';
GO

/* 10. Recompilacion final de reportes restantes afectados. */
CREATE OR ALTER PROCEDURE mundial.sp_reporte_Tarjetas @id_seleccion INT=NULL,@solo_con_suspension BIT=0
AS
BEGIN
 SET NOCOUNT ON;
 OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 SELECT pa.nombre seleccion,
  CONCAT(CONVERT(VARCHAR(100),DecryptByKey(j.nombres_cifrado)),' ',CONVERT(VARCHAR(100),DecryptByKey(j.apellidos_cifrado))) jugador,
  SUM(CASE WHEN tt.descripcion='AMARILLA' THEN 1 ELSE 0 END) amarillas,
  SUM(CASE WHEN tt.descripcion='ROJA' THEN 1 ELSE 0 END) rojas,
  MAX(CASE WHEN sj.cumplida=0 THEN 1 ELSE 0 END) suspension_activa
 FROM mundial.convocatoria c
 JOIN mundial.jugador j ON j.id_jugador=c.id_jugador
 JOIN mundial.seleccion s ON s.id_seleccion=c.id_seleccion
 JOIN mundial.pais pa ON pa.id_pais=s.id_pais
 LEFT JOIN mundial.tarjeta t ON t.id_jugador=j.id_jugador
 LEFT JOIN mundial.tipo_tarjeta tt ON tt.id_tipo_tarjeta=t.id_tipo_tarjeta
 LEFT JOIN mundial.suspension_jugador sj ON sj.id_jugador=j.id_jugador
 WHERE (@id_seleccion IS NULL OR s.id_seleccion=@id_seleccion)
   AND (@solo_con_suspension=0 OR sj.cumplida=0)
 GROUP BY pa.nombre,j.id_jugador,j.nombres_cifrado,j.apellidos_cifrado
 FOR XML PATH('Jugador'),ROOT('ReporteDisciplinarioTorneo');
 CLOSE SYMMETRIC KEY SK_DatosPersonales;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_reporte_DesignacionesArbitrales @id_arbitro INT=NULL
AS
BEGIN
 SET NOCOUNT ON;
 OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 SELECT a.id_arbitro,
  CONCAT(CONVERT(VARCHAR(100),DecryptByKey(a.nombres_cifrado)),' ',CONVERT(VARCHAR(100),DecryptByKey(a.apellidos_cifrado))) Arbitro,
  p.nombre Nacionalidad,a.categoria,
  COUNT(DISTINCT da.id_partido) PartidosTotalesAsignados,
  SUM(CASE WHEN ra.descripcion='ARBITRO_PRINCIPAL' THEN 1 ELSE 0 END) PartidosComoPrincipal
 FROM mundial.arbitro a
 JOIN mundial.pais p ON p.id_pais=a.id_pais_nacionalidad
 LEFT JOIN mundial.designacion_arbitral da ON da.id_arbitro=a.id_arbitro
 LEFT JOIN mundial.rol_arbitral ra ON ra.id_rol_arbitral=da.id_rol_arbitral
 WHERE @id_arbitro IS NULL OR a.id_arbitro=@id_arbitro
 GROUP BY a.id_arbitro,a.nombres_cifrado,a.apellidos_cifrado,p.nombre,a.categoria;
 CLOSE SYMMETRIC KEY SK_DatosPersonales;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_reporte_ResultadosEncuentros @id_fase INT=NULL,@id_sede INT=NULL
AS
BEGIN
 SET NOCOUNT ON;
 OPEN SYMMETRIC KEY SK_DatosPersonales DECRYPTION BY CERTIFICATE Cert_DatosPersonales;
 SELECT p.id_partido ID,f.nombre_fase Fase,p.fecha_hora_local,se.nombre_estadio Estadio,
  CONCAT(pl.nombre,' ',ISNULL(p.goles_local,0),' - ',ISNULL(p.goles_visitante,0),' ',pv.nombre) Marcador,
  ga.DetalleGoles
 FROM mundial.partido p
 JOIN mundial.fase f ON f.id_fase=p.id_fase
 JOIN mundial.sede_estadio se ON se.id_sede=p.id_sede
 JOIN mundial.seleccion sl ON sl.id_seleccion=p.id_seleccion_local
 JOIN mundial.pais pl ON pl.id_pais=sl.id_pais
 JOIN mundial.seleccion sv ON sv.id_seleccion=p.id_seleccion_visitante
 JOIN mundial.pais pv ON pv.id_pais=sv.id_pais
 OUTER APPLY
 (
  SELECT STRING_AGG(CONCAT(CONVERT(VARCHAR(100),DecryptByKey(j.apellidos_cifrado)),' (',g.minuto,CHAR(39),')'),', ') DetalleGoles
  FROM mundial.gol g JOIN mundial.jugador j ON j.id_jugador=g.id_jugador_autor
  WHERE g.id_partido=p.id_partido
 ) ga
 WHERE (@id_fase IS NULL OR p.id_fase=@id_fase)
   AND (@id_sede IS NULL OR p.id_sede=@id_sede)
 ORDER BY p.id_partido;
 CLOSE SYMMETRIC KEY SK_DatosPersonales;
END;
GO
PRINT N'OK: reportes afectados recompilados contra columnas cifradas.';
GO
