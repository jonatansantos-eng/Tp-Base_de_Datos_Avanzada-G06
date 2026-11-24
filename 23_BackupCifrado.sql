/* Entrega 8 - Backup completo cifrado AES-256
 Ejecutar como sysadmin. Ajustar rutas y contrasenas. */

:r C:\TP2026\00_Secretos.local.sql

USE master;
GO
ALTER DATABASE TP2026 SET RECOVERY FULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.symmetric_keys WHERE name='##MS_DatabaseMasterKey##')
 CREATE MASTER KEY ENCRYPTION BY PASSWORD= '$(PasswordMasterBackup)';
GO
IF NOT EXISTS(SELECT 1 FROM sys.certificates WHERE name=N'Cert_Backup_TP2026')
 CREATE CERTIFICATE Cert_Backup_TP2026 WITH SUBJECT=N'Certificado backup cifrado TP2026',EXPIRY_DATE='2036-12-31';
GO
IF EXISTS
(
    SELECT 1
    FROM sys.certificates
    WHERE name = N'Cert_Backup_TP2026'
)
BEGIN
    PRINT N'Certificado de backup encontrado.';
END
ELSE
BEGIN
    THROW 55801,
          N'No se encontró el certificado de backup.',
          1;
END;
GO
BACKUP CERTIFICATE Cert_Backup_TP2026
 TO FILE=N'C:\SQLServer\Keys\Cert_Backup_TP2026.cer'
 WITH PRIVATE KEY(FILE=N'C:\SQLServer\Keys\Cert_Backup_TP2026.pvk',ENCRYPTION BY PASSWORD= '$(PasswordCertificado)');
GO
BACKUP DATABASE TP2026
 TO DISK=N'C:\SQLServer\Backup\TP2026_FULL_ENCRYPTED.bak'
 WITH INIT,COMPRESSION,CHECKSUM,ENCRYPTION(ALGORITHM=AES_256,SERVER CERTIFICATE=Cert_Backup_TP2026),STATS=10;
GO
RESTORE VERIFYONLY FROM DISK=N'C:\SQLServer\Backup\TP2026_FULL_ENCRYPTED.bak' WITH CHECKSUM;
GO
