--drop database DB_GDoc;
USE master;
GO

CREATE DATABASE DB_GDoc;
GO

USE DB_GDoc;


-- =============================================
-- CREATE TABLA: Empresa
-- CREATE INDEX: Empresa 
-- =============================================

CREATE TABLE EMPRESA(
	EmpresaId INT IDENTITY(1,1) NOT NULL,
	Nombre NVARCHAR(200) NOT NULL,
	NIT NVARCHAR(20) NOT NULL,
	Telefono NVARCHAR(50) NOT NULL,
	Direccion NVARCHAR(200) NOT NULL,
	Email NVARCHAR(100) NOT NULL,
	Activo BIT NOT NULL DEFAULT 1,
	FechaCreacion DATETIME NOT NULL DEFAULT GETDATE(),
	FechaModificacion DATETIME NOT NULL,
	
	CONSTRAINT PK_EMPRESA PRIMARY KEY CLUSTERED (EmpresaId),
	CONSTRAINT UK_EMPRESA_NIT UNIQUE(NIT)
);
GO

CREATE NONCLUSTERED INDEX IDX_EMPRESA_NOMBRE ON EMPRESA(Nombre) WHERE Activo = 1;
GO

-- =============================================
-- CREATE TABLA: Documento
-- CREATE INDEX: Documento
-- =============================================

CREATE TABLE DOCUMENTO(
	DocumentoId INT IDENTITY(1,1) NOT NULL,
	EmpresaId INT NOT NULL,
	Titulo NVARCHAR(300) NOT NULL,
	Descripcion NVARCHAR(MAX) NULL,
	TipoDocumento NVARCHAR(50) NOT NULL,
	FlujoValidacionJson NVARCHAR(MAX) NOT NULL,
	Estado NVARCHAR(50) NOT NULL DEFAULT 'Borrador',
	UsuarioCreadorId UNIQUEIDENTIFIER NOT NULL,
	FechaCreacion DATETIME NOT NULL DEFAULT GETDATE(),
	FechaModificacion DATETIME NULL,
	FechaAprobacion DATETIME NULL,

	CONSTRAINT PK_DOCUMENTO PRIMARY KEY CLUSTERED (DocumentoId),
	CONSTRAINT FK_DOCUMENTO_EMPRESA FOREIGN KEY (EmpresaId) REFERENCES EMPRESA(EmpresaId),
	CONSTRAINT CK_DOCUMENTO_FlujoValidacionJson_isJson CHECK (ISJSON(FlujoValidacionJson)=1),
	CONSTRAINT CK_DOCUMENTO_Estado CHECK (Estado IN ('Borrador', 'EnValidacion', 'Aprobado', 'Rechazado', 'Cancelado'))

);
GO

CREATE NONCLUSTERED INDEX IDX_DOCUMENTO_EmpresaId_Estado ON DOCUMENTO(EmpresaId,Estado) INCLUDE (Titulo,FechaCreacion);
GO

CREATE NONCLUSTERED INDEX IDX_DOCUMENTO_UsuarioCreadorId ON DOCUMENTO(UsuarioCreadorId) INCLUDE (Titulo, Estado, FechaCreacion);
GO

CREATE NONCLUSTERED INDEX IDX_DOCUMENTO_TipoDocumento ON DOCUMENTO(TipoDocumento, Estado);
GO

-- =============================================
-- CREATE TABLA: InstanciaValidacion
-- CREATE INDEX: InstanciaValidacion
-- =============================================

CREATE TABLE INSTANCIAVALIDACION(
	InstanciaValidacionId INT IDENTITY(1,1) NOT NULL,
	DocumentoId INT NOT NULL,
	OrdenPaso INT NOT NULL,
	RolValidador NVARCHAR(100) NOT NULL,
	UsuarioValidadorId UNIQUEIDENTIFIER NOT NULL,
	Accion NVARCHAR(50) NOT NULL,
	Observaciones NVARCHAR(MAX) NULL,
	FechaAccion DATETIME NOT NULL DEFAULT GETDATE(),
	DatosAdicionales NVARCHAR(MAX) NULL,
	
	CONSTRAINT PK_INSTANCIAVALIDACION PRIMARY KEY CLUSTERED (InstanciaValidacionId),
	CONSTRAINT FK_INSTANCIAVALIDACION_DOCUMENTO FOREIGN KEY (DocumentoId) REFERENCES DOCUMENTO(DocumentoId) ON DELETE CASCADE,
	CONSTRAINT CK_INSTANCIAVALIDACION_Accion CHECK (Accion IN ('Aprobado', 'Rechazado', 'Pendiente')),
	CONSTRAINT CK_INSTANCIAVALIDACION_DatosAdicionales_IsJson CHECK (DatosAdicionales IS NULL OR ISJSON(DatosAdicionales)=1)

);
GO

CREATE NONCLUSTERED INDEX IDX_INSTANCIAVALIDACION_DocumentoId_OrdenPaso ON INSTANCIAVALIDACION(DocumentoId, OrdenPaso) INCLUDE (Accion, FechaAccion);
GO

CREATE NONCLUSTERED INDEX IDX_INSTANCIAVALIDACION_UsuarioValidadorId ON INSTANCIAVALIDACION(UsuarioValidadorId, Accion) INCLUDE (DocumentoId, FechaAccion);
GO

CREATE UNIQUE NONCLUSTERED INDEX UDX_INSTANCIAVALIDACION_Documento_OrdenPaso ON INSTANCIAVALIDACION(DocumentoId, OrdenPaso, UsuarioValidadorId);
GO

-- =============================================
-- CREATE TABLA: DocumentoAuditoria
-- CREATE INDEX: DocumentoAuditoria
-- =============================================

CREATE TABLE DOCUMENTOAUDITORIA (
    AuditoriaId INT IDENTITY(1,1) NOT NULL,
    DocumentoId INT NOT NULL,
    EstadoAnterior NVARCHAR(50) NULL,
    EstadoNuevo NVARCHAR(50) NOT NULL,
    UsuarioResponsable UNIQUEIDENTIFIER NULL,
    FechaCambio DATETIME2(7) NOT NULL DEFAULT GETDATE(),
    Observaciones NVARCHAR(MAX) NULL,
    
    CONSTRAINT PK_DOCUMENTOAUDITORIA PRIMARY KEY CLUSTERED (AuditoriaId)
);
GO

CREATE NONCLUSTERED INDEX IDX_DOCUMENTOAUDITORIA_DocumentoId ON DOCUMENTOAUDITORIA(DocumentoId, FechaCambio DESC);
GO

-- =============================================
-- SECCIÓN 2: VISTAS
-- =============================================

GO
CREATE OR ALTER VIEW vw_EstadoValidacionDocumento
AS
SELECT 
    d.DocumentoId,
    d.Titulo,
    d.Estado AS EstadoDocumento,
    d.EmpresaId,
    d.TipoDocumento,
    
    (SELECT COUNT(*) 
     FROM OPENJSON(d.FlujoValidacionJson, '$.steps')) AS TotalPasos,
    
    (SELECT COUNT(*) 
     FROM INSTANCIAVALIDACION iv 
     WHERE iv.DocumentoId = d.DocumentoId 
       AND iv.Accion = 'Aprobado') AS PasosAprobados,
    
    (SELECT COUNT(*) 
     FROM INSTANCIAVALIDACION iv 
     WHERE iv.DocumentoId = d.DocumentoId 
       AND iv.Accion = 'Rechazado') AS PasosRechazados,
    
    (SELECT MIN(paso.OrderValue)
     FROM OPENJSON(d.FlujoValidacionJson, '$.steps') 
     WITH (OrderValue INT '$.order') AS paso
     WHERE paso.OrderValue NOT IN (
         SELECT iv.OrdenPaso 
         FROM INSTANCIAVALIDACION iv 
         WHERE iv.DocumentoId = d.DocumentoId 
           AND iv.Accion IN ('Aprobado', 'Rechazado')
     )) AS PasoActual,
    
    d.FechaCreacion,
    d.FechaModificacion
FROM DOCUMENTO d;
GO