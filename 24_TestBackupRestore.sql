/* Entrega 8 - Verificacion y restauracion de prueba
 Ajustar MOVE con los nombres logicos devueltos por FILELISTONLY. */
USE master;
GO
RESTORE HEADERONLY FROM DISK=N'C:\SQLServer\Backup\TP2026_FULL_ENCRYPTED.bak';
RESTORE FILELISTONLY FROM DISK=N'C:\SQLServer\Backup\TP2026_FULL_ENCRYPTED.bak';
RESTORE VERIFYONLY FROM DISK=N'C:\SQLServer\Backup\TP2026_FULL_ENCRYPTED.bak' WITH CHECKSUM;
GO
IF DB_ID(N'TP2026_PruebaRestore') IS NOT NULL
BEGIN
 ALTER DATABASE TP2026_PruebaRestore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
 DROP DATABASE TP2026_PruebaRestore;
END;
GO
/* Reemplazar TP2026 y TP2026_log si FILELISTONLY devuelve otros nombres. */
RESTORE DATABASE TP2026_PruebaRestore
 FROM DISK=N'C:\SQLServer\Backup\TP2026_FULL_ENCRYPTED.bak'
 WITH MOVE N'TP2026' TO N'C:\SQLServer\Data\TP2026_PruebaRestore.mdf',
      MOVE N'TP2026_log' TO N'C:\SQLServer\Log\TP2026_PruebaRestore.ldf',
      RECOVERY,REPLACE,STATS=10;
GO
DBCC CHECKDB(N'TP2026_PruebaRestore') WITH NO_INFOMSGS;
GO
SELECT name,state_desc,recovery_model_desc FROM sys.databases WHERE name=N'TP2026_PruebaRestore';
GO
