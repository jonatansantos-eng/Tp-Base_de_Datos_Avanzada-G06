/*  Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-16
    Importaciones CSV/XML set-based. SQL dinamico solo para parametrizar la ruta fisica. */
USE TP2026;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
CREATE OR ALTER PROCEDURE mundial.sp_importacion_iniciar_lote
 @id_fuente INT,@archivo VARCHAR(260),@entidad VARCHAR(128),@hash VARCHAR(128)=NULL,@id_lote INT OUTPUT
AS
BEGIN
 DECLARE @e NVARCHAR(2048)=N'';
 IF NOT EXISTS(SELECT 1 FROM mundial.fuente_importacion WHERE id_fuente=@id_fuente AND activa=1) SET @e+=N'Fuente inexistente o inactiva. ';
 IF NULLIF(LTRIM(RTRIM(@archivo)),'') IS NULL SET @e+=N'Archivo obligatorio. ';
 IF @archivo LIKE '%..%' SET @e+=N'No se permiten rutas relativas. ';
 IF @hash IS NOT NULL AND EXISTS(SELECT 1 FROM mundial.lote_importacion WHERE hash_archivo=@hash AND estado_lote IN('COMPLETADO','PARCIAL')) SET @e+=N'El archivo ya fue procesado. ';
 IF LEN(@e)>0 THROW 53101,@e,1;
 INSERT mundial.lote_importacion(id_fuente,nombre_archivo,entidad_destino,fecha_inicio,estado_lote,cantidad_leidos,cantidad_insertados,cantidad_actualizados,cantidad_rechazados,hash_archivo)
 VALUES(@id_fuente,@archivo,@entidad,SYSDATETIME(),'EN_PROCESO',0,0,0,0,@hash);
 SET @id_lote=SCOPE_IDENTITY();
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_importacion_finalizar_lote @id_lote INT
AS
BEGIN
 DECLARE @l INT=(SELECT COUNT(*) FROM mundial.detalle_importacion WHERE id_lote=@id_lote),
 @i INT=(SELECT COUNT(*) FROM mundial.detalle_importacion WHERE id_lote=@id_lote AND tipo_operacion='INSERT'),
 @u INT=(SELECT COUNT(*) FROM mundial.detalle_importacion WHERE id_lote=@id_lote AND tipo_operacion='UPDATE'),
 @r INT=(SELECT COUNT(*) FROM mundial.detalle_importacion WHERE id_lote=@id_lote AND estado_registro='RECHAZADO');
 UPDATE mundial.lote_importacion SET fecha_fin=SYSDATETIME(),cantidad_leidos=@l,cantidad_insertados=@i,
 cantidad_actualizados=@u,cantidad_rechazados=@r,
 estado_lote=CASE WHEN @l=0 OR @r=@l THEN 'FALLIDO' WHEN @r>0 THEN 'PARCIAL' ELSE 'COMPLETADO' END WHERE id_lote=@id_lote;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_importar_partidos_csv
 @id_fuente INT,@archivo NVARCHAR(260),@hash VARCHAR(128)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF LOWER(RIGHT(@archivo,4))<>'.csv' THROW 53102,N'Formato esperado: CSV.',1;
  DECLARE @id_lote INT,@sql NVARCHAR(MAX),@archivo_vc VARCHAR(260)=CONVERT(VARCHAR(260),@archivo);
  EXEC mundial.sp_importacion_iniciar_lote @id_fuente,@archivo_vc,'PARTIDO',@hash,@id_lote OUTPUT;
 BEGIN TRY
  CREATE TABLE #raw(clave_externa NVARCHAR(200),fase NVARCHAR(100),estadio NVARCHAR(200),pais_local_iso NVARCHAR(20),pais_visitante_iso NVARCHAR(20),fecha_hora_utc NVARCHAR(100),fecha_hora_local NVARCHAR(100),goles_local NVARCHAR(30),goles_visitante NVARCHAR(30),asistencia_publico NVARCHAR(30),estado_partido NVARCHAR(50));
  SET @sql=N'BULK INSERT #raw FROM '+QUOTENAME(@archivo,'''')+N' WITH (FORMAT=''CSV'',FIRSTROW=2,CODEPAGE=''65001'',TABLOCK);';
  EXEC sys.sp_executesql @sql;
  INSERT mundial.stg_partido(id_lote,numero_fila,clave_externa,fase,estadio,pais_local_iso,pais_visitante_iso,fecha_hora_utc,fecha_hora_local,goles_local,goles_visitante,asistencia_publico,estado_partido)
  SELECT @id_lote,ROW_NUMBER() OVER(ORDER BY (SELECT NULL)),* FROM #raw;
  INSERT mundial.detalle_importacion(id_lote,numero_fila,clave_externa,estado_registro,datos_originales)
  SELECT id_lote,numero_fila,clave_externa,'PENDIENTE',CONCAT_WS('|',clave_externa,fase,estadio,pais_local_iso,pais_visitante_iso,fecha_hora_utc) FROM mundial.stg_partido WHERE id_lote=@id_lote;
  INSERT mundial.error_importacion(id_detalle_importacion,codigo_error,campo_error,descripcion_error,valor_recibido)
  SELECT d.id_detalle_importacion,x.codigo,x.campo,x.mensaje,x.valor
  FROM mundial.stg_partido s JOIN mundial.detalle_importacion d ON d.id_lote=s.id_lote AND d.numero_fila=s.numero_fila
  CROSS APPLY(VALUES
   ('CLAVE','clave_externa',CASE WHEN NULLIF(s.clave_externa,'') IS NULL THEN 'Clave externa obligatoria.' END,s.clave_externa),
   ('FASE','fase',CASE WHEN NOT EXISTS(SELECT 1 FROM mundial.fase f WHERE f.nombre_fase=s.fase) THEN 'Fase inexistente.' END,s.fase),
   ('SEDE','estadio',CASE WHEN NOT EXISTS(SELECT 1 FROM mundial.sede_estadio e WHERE e.nombre_estadio=s.estadio) THEN 'Estadio inexistente.' END,s.estadio),
   ('LOCAL','pais_local_iso',CASE WHEN NOT EXISTS(SELECT 1 FROM mundial.pais p JOIN mundial.seleccion q ON q.id_pais=p.id_pais WHERE p.codigo_iso=s.pais_local_iso) THEN 'Seleccion local inexistente.' END,s.pais_local_iso),
   ('VISITANTE','pais_visitante_iso',CASE WHEN NOT EXISTS(SELECT 1 FROM mundial.pais p JOIN mundial.seleccion q ON q.id_pais=p.id_pais WHERE p.codigo_iso=s.pais_visitante_iso) THEN 'Seleccion visitante inexistente.' END,s.pais_visitante_iso),
   ('EQUIPOS','selecciones',CASE WHEN s.pais_local_iso=s.pais_visitante_iso THEN 'Las selecciones deben ser diferentes.' END,CONCAT(s.pais_local_iso,'/',s.pais_visitante_iso)),
   ('FECHAUTC','fecha_hora_utc',CASE WHEN TRY_CONVERT(DATETIME2(0),s.fecha_hora_utc,126) IS NULL THEN 'Fecha UTC invalida.' END,s.fecha_hora_utc),
   ('FECHALOCAL','fecha_hora_local',CASE WHEN TRY_CONVERT(DATETIME2(0),s.fecha_hora_local,126) IS NULL THEN 'Fecha local invalida.' END,s.fecha_hora_local),
   ('GOLESL','goles_local',CASE WHEN NULLIF(s.goles_local,'') IS NOT NULL AND TRY_CONVERT(TINYINT,s.goles_local) IS NULL THEN 'Goles local invalidos.' END,s.goles_local),
   ('GOLESV','goles_visitante',CASE WHEN NULLIF(s.goles_visitante,'') IS NOT NULL AND TRY_CONVERT(TINYINT,s.goles_visitante) IS NULL THEN 'Goles visitante invalidos.' END,s.goles_visitante),
   ('ASIST','asistencia_publico',CASE WHEN NULLIF(s.asistencia_publico,'') IS NOT NULL AND TRY_CONVERT(INT,s.asistencia_publico) IS NULL THEN 'Asistencia invalida.' END,s.asistencia_publico),
   ('ESTADO','estado_partido',CASE WHEN s.estado_partido NOT IN('PROGRAMADO','EN_CURSO','FINALIZADO','SUSPENDIDO','CANCELADO') THEN 'Estado invalido.' END,s.estado_partido)
  )x(codigo,campo,mensaje,valor) WHERE s.id_lote=@id_lote AND x.mensaje IS NOT NULL;
  UPDATE d SET estado_registro=CASE WHEN e.id_detalle_importacion IS NULL THEN 'VALIDO' ELSE 'RECHAZADO' END,fecha_procesamiento=SYSDATETIME()
  FROM mundial.detalle_importacion d LEFT JOIN(SELECT DISTINCT id_detalle_importacion FROM mundial.error_importacion)e ON e.id_detalle_importacion=d.id_detalle_importacion WHERE d.id_lote=@id_lote;
  SELECT s.*,f.id_fase,se.id_sede,sl.id_seleccion id_local,sv.id_seleccion id_visitante INTO #validos
  FROM mundial.stg_partido s JOIN mundial.detalle_importacion d ON d.id_lote=s.id_lote AND d.numero_fila=s.numero_fila AND d.estado_registro='VALIDO'
  JOIN mundial.fase f ON f.nombre_fase=s.fase JOIN mundial.sede_estadio se ON se.nombre_estadio=s.estadio
  JOIN mundial.pais pl ON pl.codigo_iso=s.pais_local_iso JOIN mundial.seleccion sl ON sl.id_pais=pl.id_pais
  JOIN mundial.pais pv ON pv.codigo_iso=s.pais_visitante_iso JOIN mundial.seleccion sv ON sv.id_pais=pv.id_pais WHERE s.id_lote=@id_lote;
  UPDATE p SET id_fase=v.id_fase,id_sede=v.id_sede,id_seleccion_local=v.id_local,id_seleccion_visitante=v.id_visitante,
   fecha_hora_utc=TRY_CONVERT(DATETIME2(0),v.fecha_hora_utc,126),fecha_hora_local=TRY_CONVERT(DATETIME2(0),v.fecha_hora_local,126),
   goles_local=TRY_CONVERT(TINYINT,NULLIF(v.goles_local,'')),goles_visitante=TRY_CONVERT(TINYINT,NULLIF(v.goles_visitante,'')),
   asistencia_publico=TRY_CONVERT(INT,NULLIF(v.asistencia_publico,'')),estado_partido=v.estado_partido
  FROM mundial.partido p JOIN mundial.registro_externo r ON r.id_registro_destino=p.id_partido AND r.id_fuente=@id_fuente AND r.entidad_destino='PARTIDO' JOIN #validos v ON v.clave_externa=r.clave_externa;
  UPDATE d SET tipo_operacion='UPDATE',estado_registro='PROCESADO' FROM mundial.detalle_importacion d JOIN mundial.stg_partido s ON s.id_lote=d.id_lote AND s.numero_fila=d.numero_fila JOIN mundial.registro_externo r ON r.id_fuente=@id_fuente AND r.entidad_destino='PARTIDO' AND r.clave_externa=s.clave_externa WHERE d.id_lote=@id_lote AND d.estado_registro='VALIDO';
  DECLARE @n TABLE(clave VARCHAR(200),id INT);
  ;WITH nuevos AS(
   SELECT v.* FROM #validos v WHERE NOT EXISTS(SELECT 1 FROM mundial.registro_externo r WHERE r.id_fuente=@id_fuente AND r.entidad_destino='PARTIDO' AND r.clave_externa=v.clave_externa))
  MERGE mundial.partido AS destino USING nuevos AS v ON 1=0
  WHEN NOT MATCHED THEN INSERT(id_fase,id_sede,id_seleccion_local,id_seleccion_visitante,fecha_hora_utc,fecha_hora_local,goles_local,goles_visitante,penales_local,penales_visitante,asistencia_publico,estado_partido)
  VALUES(v.id_fase,v.id_sede,v.id_local,v.id_visitante,TRY_CONVERT(DATETIME2(0),v.fecha_hora_utc,126),TRY_CONVERT(DATETIME2(0),v.fecha_hora_local,126),TRY_CONVERT(TINYINT,NULLIF(v.goles_local,'')),TRY_CONVERT(TINYINT,NULLIF(v.goles_visitante,'')),NULL,NULL,TRY_CONVERT(INT,NULLIF(v.asistencia_publico,'')),v.estado_partido)
  OUTPUT CONVERT(VARCHAR(200),v.clave_externa),inserted.id_partido INTO @n;
  INSERT mundial.registro_externo(id_fuente,entidad_destino,clave_externa,id_registro_destino) SELECT @id_fuente,'PARTIDO',clave,id FROM @n;
  UPDATE d SET tipo_operacion='INSERT',estado_registro='PROCESADO' FROM mundial.detalle_importacion d JOIN mundial.stg_partido s ON s.id_lote=d.id_lote AND s.numero_fila=d.numero_fila JOIN @n n ON n.clave=s.clave_externa WHERE d.id_lote=@id_lote;
  UPDATE mundial.detalle_importacion SET tipo_operacion='RECHAZADO' WHERE id_lote=@id_lote AND estado_registro='RECHAZADO';
  EXEC mundial.sp_importacion_finalizar_lote @id_lote;
  SELECT * FROM mundial.lote_importacion WHERE id_lote=@id_lote;
 END TRY
 BEGIN CATCH
  UPDATE mundial.lote_importacion SET fecha_fin=SYSDATETIME(),estado_lote='FALLIDO' WHERE id_lote=@id_lote;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE mundial.sp_importar_pbi_xml
 @id_fuente INT,@archivo NVARCHAR(260),@hash VARCHAR(128)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF LOWER(RIGHT(@archivo,4))<>'.xml' THROW 53103,N'Formato esperado: XML.',1;
 DECLARE @id_lote INT,@sql NVARCHAR(MAX),@xml XML,@archivo_vc VARCHAR(260)=CONVERT(VARCHAR(260),@archivo);
 EXEC mundial.sp_importacion_iniciar_lote @id_fuente,@archivo_vc,'INDICADOR_ECONOMICO',@hash,@id_lote OUTPUT;
 BEGIN TRY
  CREATE TABLE #rawxml(contenido VARBINARY(MAX));
  SET @sql=N'INSERT #rawxml SELECT BulkColumn FROM OPENROWSET(BULK '+QUOTENAME(@archivo,'''')+N',SINGLE_BLOB)x;';
  EXEC sys.sp_executesql @sql;
  SELECT @xml=CONVERT(XML,contenido) FROM #rawxml;
  INSERT mundial.stg_indicador_economico(id_lote,numero_fila,clave_externa,codigo_pais,codigo_indicador,anio,valor,unidad,fuente)
  SELECT @id_lote,ROW_NUMBER() OVER(ORDER BY (SELECT NULL)),n.value('@key','NVARCHAR(200)'),n.value('@country','NVARCHAR(20)'),n.value('@indicator','NVARCHAR(50)'),n.value('@year','NVARCHAR(20)'),n.value('@value','NVARCHAR(100)'),n.value('@unit','NVARCHAR(50)'),n.value('@source','NVARCHAR(150)')
  FROM @xml.nodes('/indicators/record')t(n);
  INSERT mundial.detalle_importacion(id_lote,numero_fila,clave_externa,estado_registro,datos_originales)
  SELECT id_lote,numero_fila,clave_externa,'PENDIENTE',CONCAT_WS('|',codigo_pais,codigo_indicador,anio,valor,unidad,fuente) FROM mundial.stg_indicador_economico WHERE id_lote=@id_lote;
  INSERT mundial.error_importacion(id_detalle_importacion,codigo_error,campo_error,descripcion_error,valor_recibido)
  SELECT d.id_detalle_importacion,x.codigo,x.campo,x.mensaje,x.valor
  FROM mundial.stg_indicador_economico s JOIN mundial.detalle_importacion d ON d.id_lote=s.id_lote AND d.numero_fila=s.numero_fila
  CROSS APPLY(VALUES
   ('PAIS','codigo_pais',CASE WHEN NOT EXISTS(SELECT 1 FROM mundial.pais p WHERE p.codigo_iso=s.codigo_pais) THEN 'Pais inexistente.' END,s.codigo_pais),
   ('ANIO','anio',CASE WHEN TRY_CONVERT(SMALLINT,s.anio) NOT BETWEEN 1900 AND 2100 THEN 'Anio invalido.' END,s.anio),
   ('VALOR','valor',CASE WHEN TRY_CONVERT(DECIMAL(20,4),s.valor) IS NULL OR TRY_CONVERT(DECIMAL(20,4),s.valor)<0 THEN 'Valor invalido.' END,s.valor),
   ('INDICADOR','codigo_indicador',CASE WHEN NULLIF(s.codigo_indicador,'') IS NULL THEN 'Indicador obligatorio.' END,s.codigo_indicador),
   ('FUENTE','fuente',CASE WHEN NULLIF(s.fuente,'') IS NULL THEN 'Fuente obligatoria.' END,s.fuente)
  )x(codigo,campo,mensaje,valor) WHERE s.id_lote=@id_lote AND x.mensaje IS NOT NULL;
  UPDATE d SET estado_registro=CASE WHEN e.id_detalle_importacion IS NULL THEN 'VALIDO' ELSE 'RECHAZADO' END,fecha_procesamiento=SYSDATETIME()
  FROM mundial.detalle_importacion d LEFT JOIN(SELECT DISTINCT id_detalle_importacion FROM mundial.error_importacion)e ON e.id_detalle_importacion=d.id_detalle_importacion WHERE d.id_lote=@id_lote;
  SELECT s.*,p.id_pais INTO #validos_i FROM mundial.stg_indicador_economico s JOIN mundial.detalle_importacion d ON d.id_lote=s.id_lote AND d.numero_fila=s.numero_fila AND d.estado_registro='VALIDO' JOIN mundial.pais p ON p.codigo_iso=s.codigo_pais WHERE s.id_lote=@id_lote;
  UPDATE i SET valor=TRY_CONVERT(DECIMAL(20,4),v.valor),unidad=v.unidad,id_lote=@id_lote,fecha_importacion=SYSDATETIME()
  FROM mundial.indicador_economico_pais i JOIN #validos_i v ON v.id_pais=i.id_pais AND v.codigo_indicador=i.codigo_indicador AND TRY_CONVERT(SMALLINT,v.anio)=i.anio AND v.fuente=i.fuente;
  UPDATE d SET tipo_operacion='UPDATE',estado_registro='PROCESADO' FROM mundial.detalle_importacion d JOIN mundial.stg_indicador_economico s ON s.id_lote=d.id_lote AND s.numero_fila=d.numero_fila JOIN #validos_i v ON v.id_stg_indicador=s.id_stg_indicador JOIN mundial.indicador_economico_pais i ON i.id_pais=v.id_pais AND i.codigo_indicador=v.codigo_indicador AND i.anio=TRY_CONVERT(SMALLINT,v.anio) AND i.fuente=v.fuente WHERE d.id_lote=@id_lote AND d.estado_registro='VALIDO';
  INSERT mundial.indicador_economico_pais(id_pais,id_lote,codigo_indicador,anio,valor,unidad,fuente)
  SELECT id_pais,@id_lote,codigo_indicador,TRY_CONVERT(SMALLINT,anio),TRY_CONVERT(DECIMAL(20,4),valor),unidad,fuente FROM #validos_i v
  WHERE NOT EXISTS(SELECT 1 FROM mundial.indicador_economico_pais i WHERE i.id_pais=v.id_pais AND i.codigo_indicador=v.codigo_indicador AND i.anio=TRY_CONVERT(SMALLINT,v.anio) AND i.fuente=v.fuente);
  UPDATE d SET tipo_operacion='INSERT',estado_registro='PROCESADO' FROM mundial.detalle_importacion d JOIN mundial.stg_indicador_economico s ON s.id_lote=d.id_lote AND s.numero_fila=d.numero_fila WHERE d.id_lote=@id_lote AND d.estado_registro='VALIDO' AND d.tipo_operacion IS NULL;
  UPDATE mundial.detalle_importacion SET tipo_operacion='RECHAZADO' WHERE id_lote=@id_lote AND estado_registro='RECHAZADO';
  UPDATE p SET p.pbi_per_capita=x.valor FROM mundial.pais p CROSS APPLY(SELECT TOP(1)i.valor FROM mundial.indicador_economico_pais i WHERE i.id_pais=p.id_pais AND i.codigo_indicador='NY.GDP.PCAP.CD' ORDER BY i.anio DESC)x;
  EXEC mundial.sp_importacion_finalizar_lote @id_lote;
  SELECT * FROM mundial.lote_importacion WHERE id_lote=@id_lote;
 END TRY
 BEGIN CATCH
  UPDATE mundial.lote_importacion SET fecha_fin=SYSDATETIME(),estado_lote='FALLIDO' WHERE id_lote=@id_lote;
  THROW;
 END CATCH;
END;
GO
