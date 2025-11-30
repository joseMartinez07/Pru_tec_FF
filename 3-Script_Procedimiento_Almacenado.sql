USE DB_GDoc;
GO

-- =============================================
-- PROCEDIMIENTOS ALMACENADOS
-- =============================================
GO
CREATE OR ALTER PROCEDURE sp_ProcesarAccionValidacion
    @DocumentoId INT,
    @ActorUserId UNIQUEIDENTIFIER,
    @Accion NVARCHAR(10),
    @Razon NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @EstadoActual NVARCHAR(50);
    DECLARE @FlujoJson NVARCHAR(MAX);
    DECLARE @OrdenActor INT;
    DECLARE @RolActor NVARCHAR(100);
    DECLARE @SiguientePasoPendiente INT;
    DECLARE @TotalPasos INT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
		SELECT 
            @EstadoActual = Estado,
            @FlujoJson = FlujoValidacionJson
        FROM dbo.Documento
        WHERE DocumentoId = @DocumentoId;
        
        IF @FlujoJson IS NULL
        BEGIN
            SET @ErrorMessage = 'Documento no encontrado con ID: ' + CAST(@DocumentoId AS NVARCHAR(10));
            THROW 50001, @ErrorMessage, 1;
        END
        
        IF @EstadoActual IN ('Aprobado', 'Rechazado', 'Cancelado')
        BEGIN
            SET @ErrorMessage = 'El documento ya está en estado: ' + @EstadoActual;
            THROW 50002, @ErrorMessage, 1;
        END
        
 
        SELECT 
            @OrdenActor = paso.[order],
            @RolActor = paso.[role]
        FROM OPENJSON(@FlujoJson, '$.steps')
        WITH (
            [order] INT '$.order',
            [role] NVARCHAR(100) '$.role',
            userId NVARCHAR(100) '$.userId'
        ) AS paso
        WHERE paso.userId = CAST(@ActorUserId AS NVARCHAR(100));
        
        IF @OrdenActor IS NULL
        BEGIN
            THROW 50003, 'El usuario no tiene permisos para validar este documento', 1;
        END
        
        SELECT @SiguientePasoPendiente = MIN(paso.[order])
        FROM OPENJSON(@FlujoJson, '$.steps')
        WITH ([order] INT '$.order') AS paso
        WHERE paso.[order] NOT IN (
            SELECT OrdenPaso 
            FROM dbo.InstanciaValidacion 
            WHERE DocumentoId = @DocumentoId 
              AND Accion = 'Aprobado'
        );
        
        IF @OrdenActor < @SiguientePasoPendiente
        BEGIN
            SET @ErrorMessage = 'El paso ' + CAST(@OrdenActor AS NVARCHAR(10)) + 
                              ' ya fue procesado. Siguiente paso pendiente: ' + 
                              CAST(@SiguientePasoPendiente AS NVARCHAR(10));
            THROW 50004, @ErrorMessage, 1;
        END
        
        IF @Accion = 'Rechazar'
        BEGIN
            INSERT INTO dbo.InstanciaValidacion (
                DocumentoId, OrdenPaso, RolValidador, 
                UsuarioValidadorId, Accion, Observaciones
            )
            VALUES (
                @DocumentoId, @OrdenActor, @RolActor,
                @ActorUserId, 'Rechazado', @Razon
            );

            UPDATE dbo.Documento
            SET Estado = 'Rechazado',
                FechaModificacion = GETDATE()
            WHERE DocumentoId = @DocumentoId;
            
            COMMIT TRANSACTION;
            RETURN;
        END
        

        IF @Accion = 'Aprobar'
        BEGIN
            SELECT @TotalPasos = COUNT(*)
            FROM OPENJSON(@FlujoJson, '$.steps');
            
            IF @OrdenActor > @SiguientePasoPendiente
            BEGIN
                DECLARE @PasoAnterior INT;
                DECLARE @RolAnterior NVARCHAR(100);
                DECLARE paso_cursor CURSOR FOR
                    SELECT paso.[order], paso.[role]
                    FROM OPENJSON(@FlujoJson, '$.steps')
                    WITH ([order] INT '$.order', [role] NVARCHAR(100) '$.role') AS paso
                    WHERE paso.[order] < @OrdenActor
                      AND paso.[order] NOT IN (
                          SELECT OrdenPaso 
                          FROM dbo.InstanciaValidacion 
                          WHERE DocumentoId = @DocumentoId 
                            AND Accion = 'Aprobado'
                      )
                    ORDER BY paso.[order];
                
                OPEN paso_cursor;
                FETCH NEXT FROM paso_cursor INTO @PasoAnterior, @RolAnterior;
                
                WHILE @@FETCH_STATUS = 0
                BEGIN

                    INSERT INTO dbo.InstanciaValidacion (
                        DocumentoId, OrdenPaso, RolValidador, 
                        UsuarioValidadorId, Accion, Observaciones
                    )
                    VALUES (
                        @DocumentoId, @PasoAnterior, @RolAnterior,
                        @ActorUserId, 'Aprobado', 
                        'Aprobado automáticamente por jerarquía superior (' + @RolActor + ')'
                    );
                    
                    FETCH NEXT FROM paso_cursor INTO @PasoAnterior, @RolAnterior;
                END
                
                CLOSE paso_cursor;
                DEALLOCATE paso_cursor;
            END
           
            INSERT INTO dbo.InstanciaValidacion (
                DocumentoId, OrdenPaso, RolValidador, 
                UsuarioValidadorId, Accion, Observaciones
            )
            VALUES (
                @DocumentoId, @OrdenActor, @RolActor,
                @ActorUserId, 'Aprobado', @Razon
            );
            
            DECLARE @PasosAprobados INT;
            
            SELECT @PasosAprobados = COUNT(*)
            FROM dbo.InstanciaValidacion
            WHERE DocumentoId = @DocumentoId 
              AND Accion = 'Aprobado';
            
            IF @PasosAprobados >= @TotalPasos
            BEGIN
                UPDATE dbo.Documento
                SET Estado = 'Aprobado',
                    FechaAprobacion = GETDATE(),
                    FechaModificacion = GETDATE()
                WHERE DocumentoId = @DocumentoId;
            END
            ELSE
            BEGIN
                UPDATE dbo.Documento
                SET Estado = 'EnValidacion',
                    FechaModificacion = GETDATE()
                WHERE DocumentoId = @DocumentoId;
            END
        END
        ELSE
        BEGIN
            THROW 50005, 'Acción inválida. Use ''Aprobar'' o ''Rechazar''', 1;
        END
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        SET @ErrorMessage = ERROR_MESSAGE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO