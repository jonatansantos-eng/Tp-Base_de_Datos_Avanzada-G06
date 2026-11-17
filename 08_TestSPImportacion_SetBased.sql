/*
    Universidad Nacional de La Matanza
    Materia: 3641 - Bases de Datos Aplicada
    Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

    Integrantes:
    - Coria, Lautaro
    - Quispe Barja, Sergio 
    - Santos, Jonatan

    Fecha: 2026-11-16
    Copiar los archivos demo al servidor SQL y ajustar las rutas. */
USE TP2026;
GO
IF EXISTS(SELECT 1 FROM sys.sql_modules WHERE object_id IN(OBJECT_ID('mundial.sp_importar_partidos_csv'),OBJECT_ID('mundial.sp_importar_pbi_xml')) AND (definition LIKE '%CURSOR%' OR definition LIKE '%FETCH NEXT%')) THROW 53200,N'Se detectaron cursores.',1;
DECLARE @csv INT=(SELECT id_fuente FROM mundial.fuente_importacion WHERE nombre='Dataset partidos CSV');
IF @csv IS NULL BEGIN INSERT mundial.fuente_importacion(nombre,tipo_fuente,formato,descripcion,activa) VALUES('Dataset partidos CSV','ARCHIVO','CSV','Prueba academica',1); SET @csv=SCOPE_IDENTITY(); END;
DECLARE @xml INT=(SELECT id_fuente FROM mundial.fuente_importacion WHERE nombre='API PBI XML');
IF @xml IS NULL BEGIN INSERT mundial.fuente_importacion(nombre,tipo_fuente,formato,descripcion,activa) VALUES('API PBI XML','API','XML','Prueba academica',1); SET @xml=SCOPE_IDENTITY(); END;
DECLARE @ruta_csv NVARCHAR(260)=N'C:\Importaciones\import_partidos.csv',@ruta_xml NVARCHAR(260)=N'C:\Importaciones\import_pbi.xml';
EXEC mundial.sp_importar_partidos_csv @csv,@ruta_csv,'PARTIDOS-DEMO-V1';
EXEC mundial.sp_importar_pbi_xml @xml,@ruta_xml,'PBI-DEMO-V1';
SELECT * FROM mundial.lote_importacion WHERE hash_archivo IN('PARTIDOS-DEMO-V1','PBI-DEMO-V1');
SELECT d.*,e.codigo_error,e.campo_error,e.descripcion_error FROM mundial.detalle_importacion d LEFT JOIN mundial.error_importacion e ON e.id_detalle_importacion=d.id_detalle_importacion WHERE d.id_lote IN(SELECT id_lote FROM mundial.lote_importacion WHERE hash_archivo IN('PARTIDOS-DEMO-V1','PBI-DEMO-V1')) ORDER BY d.id_lote,d.numero_fila;
IF NOT EXISTS(SELECT 1 FROM mundial.lote_importacion WHERE hash_archivo='PBI-DEMO-V1' AND estado_lote='PARCIAL' AND cantidad_rechazados>0) THROW 53201,N'No se demostro importacion parcial.',1;
BEGIN TRY EXEC mundial.sp_importar_pbi_xml @xml,@ruta_xml,'PBI-DEMO-V1'; THROW 53999,N'Se permitio duplicar hash.',1; END TRY
BEGIN CATCH IF ERROR_NUMBER()=53999 THROW; IF ERROR_NUMBER()<>53101 THROW; PRINT N'OK: hash duplicado rechazado.'; END CATCH;
PRINT N'OK: pruebas de importacion completadas.';
GO
