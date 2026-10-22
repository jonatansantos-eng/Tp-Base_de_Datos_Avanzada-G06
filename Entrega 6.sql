CREATE DATABASE TP2026
GO

USE TP2026
GO

CREATE SCHEMA mundial
GO

CREATE TABLE mundial.confederacion(
	id_confederacion INT PRIMARY KEY,
	nombre VARCHAR(20),
	sigla VARCHAR(20)
)
GO

CREATE TABLE mundial.pais(
	id_pais INT PRIMARY KEY,
	id_confederacion INT REFERENCES mundial.confederacion(id_confederacion),
	nombre VARCHAR(20),
	codigo_iso VARCHAR(20),
	huso_horario_estandar VARCHAR(10),
	pbi_per_capita DECIMAL(10,2),
	codigo_moneda VARCHAR (10)
)
GO