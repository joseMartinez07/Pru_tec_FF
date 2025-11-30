-- ==========================================================
-- SECCIÓN 3: TRIGGERS
-- ==========================================================
USE DB_GDoc;
GO
-- ==========================================================
-- TRIGGER 1: Crear instancia inicial al insertar documento
-- ==========================================================
GO
CREATE OR ALTER TRIGGER  tr_Documento_Insert_InstanciaInicial
ON DOCUMENTO
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		INSERT INTO INSTANCIAVALIDACION(
			DocumentoId,
			OrdenPaso,
			RolValidador,
			UsuarioValidadorId,
			Accion,
			Observaciones
		)
		SELECT
			i.DocumentoId,
            paso.[order],
            paso.[role],
            CAST(paso.userId AS UNIQUEIDENTIFIER),
            'Pendiente',
            'Paso inicial creado automáticamente por trigger'
        FROM INSERTED i
		CROSS APPLY (
            SELECT TOP 1
                paso.[order],
                paso.[role],
                paso.userId
            FROM OPENJSON(i.FlujoValidacionJson, '$.steps')
            WITH (
                [order] INT '$.order',
                [role] NVARCHAR(100) '$.role',
                userId NVARCHAR(100) '$.userId'
            ) AS paso
            ORDER BY paso.[order] ASC
        ) AS paso;
	END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- ==========================================================
-- TRIGGER 2: Auditar cambios de estado
-- ==========================================================

GO
CREATE OR ALTER TRIGGER tr_Documento_Update_AuditoriaEstado
ON dbo.Documento
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(Estado)
    BEGIN
        BEGIN TRY
            INSERT INTO dbo.DocumentoAuditoria (
                DocumentoId,
                EstadoAnterior,
                EstadoNuevo,
                UsuarioResponsable,
                Observaciones
            )
            SELECT 
                i.DocumentoId,
                d.Estado AS EstadoAnterior,
                i.Estado AS EstadoNuevo,
                (SELECT TOP 1 iv.UsuarioValidadorId 
                 FROM dbo.InstanciaValidacion iv 
                 WHERE iv.DocumentoId = i.DocumentoId 
                 ORDER BY iv.FechaAccion DESC) AS UsuarioResponsable,
                'Cambio de estado detectado automáticamente por trigger'
            FROM INSERTED i
            INNER JOIN DELETED d ON i.DocumentoId = d.DocumentoId
            WHERE i.Estado <> d.Estado;
            
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            
            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
            DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
            DECLARE @ErrorState INT = ERROR_STATE();
            
            RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        END CATCH
    END
END;
GO