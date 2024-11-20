-- #region sp_registrar_empleado
-- ############################
-- STORE PROCEDURE PARA REGISTAR EMPLEADOS 
-- Autor: <Emil Jesus Hernandez Avilez>
-- Create Date: <28 de octubre 2024>
-- Description: <Registra Empleados>
-- ############################

CREATE OR ALTER PROCEDURE [dbo].[sp_registrar_empleado]
    @nombre VARCHAR(50),               
    @apellidoPaterno VARCHAR(50),      
    @apellidoMaterno VARCHAR(50),      
    @correo VARCHAR(100),              
    @contrasena VARCHAR(255),          
    @rolId INT,
	@direccionId INT,
    @tiendaId INT,
    @tipoError INT OUTPUT,
    @mensaje VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @tipoError = 0;
    SET @mensaje = '';

    BEGIN TRY
        -- Comienza la transacci�n
        BEGIN TRANSACTION;

        -- Validaci�n del correo electr�nico
        IF dbo.fn_validar_correo(@correo) = 0
        BEGIN
            SET @tipoError = 1; 
            SET @mensaje = 'Formato de correo inv�lido';
            ROLLBACK TRANSACTION;
            SELECT @tipoError AS tipoError, @mensaje AS mensaje;
            RETURN;
        END

        -- Verificar si el correo ya est� registrado
        IF EXISTS (SELECT 1 FROM BSK_Autenticacion WHERE correo = @correo)
        BEGIN
            SET @tipoError = 2; 
            SET @mensaje = 'El correo ya est� registrado';
            ROLLBACK TRANSACTION;
            SELECT @tipoError AS tipoError, @mensaje AS mensaje;
            RETURN;
        END

        -- Inserci�n en la tabla Cliente
        INSERT INTO BSK_Cliente (nombre, apellidoPaterno, apellidoMaterno, rolId, direccionId, tiendaId)
        VALUES (@nombre, @apellidoPaterno, @apellidoMaterno, @rolId, @direccionId, @tiendaId);

        DECLARE @clienteId INT = SCOPE_IDENTITY();
        DECLARE @hashedPassword VARBINARY(64) = HASHBYTES('SHA2_256', @contrasena);

        -- Inserci�n en la tabla Autenticacion
        INSERT INTO BSK_Autenticacion (correo, contrasena, clienteId)
        VALUES (@correo, @hashedPassword, @clienteId);

        -- Confirma la transacci�n
        COMMIT TRANSACTION;

        SET @tipoError = 0;  -- 0 indica operaci�n correcta
        SET @mensaje = 'Operaci�n correcta';

        SELECT @tipoError as tipoError, @mensaje as mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @tipoError = 3;  
        SET @mensaje = ERROR_MESSAGE();

        SELECT @tipoError AS tipoError, @mensaje AS mensaje;
    END CATCH
END
GO
print 'Operacion correcta, Sp_registrar_empledo ejecutado.'
GO


-- #region sp_editar_empleado
-- ############################
-- STORE PROCEDURE PARA EDITAR DATOS DEL EMPLEADO
-- Autor: <Emil Jesus Hernandez Avila>
-- Create Date: <28 de octubre 2024 >
-- Description: <Permitir a los administadores editar su información personal de sus empleados>
-- ############################
CREATE OR ALTER PROCEDURE [dbo].[sp_editar_empleado]
    @clienteId INT,
    @nombre VARCHAR(50),
    @apellidoPaterno VARCHAR(50),
    @apellidoMaterno VARCHAR(50),
    @correo VARCHAR(100),
    @rolId INT,
    @direccionId INT,
    @estado VARCHAR(10), -- solo se puede editar a "Inactivo"
    @tipoError INT OUTPUT,
    @mensaje VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @tipoError = 0;
    SET @mensaje = '';

    BEGIN TRY

    -- Convertir `estado` a minúsculas para evitar inconsistencias
       SET @estado = LOWER(@estado);
        -- Validación de nulos o vacíos
        IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = '' OR 
           @apellidoPaterno IS NULL OR LTRIM(RTRIM(@apellidoPaterno)) = '' OR 
           @apellidoMaterno IS NULL OR LTRIM(RTRIM(@apellidoMaterno)) = '' OR 
           @correo IS NULL OR LTRIM(RTRIM(@correo)) = '' OR 
           @rolId IS NULL OR LTRIM(RTRIM(@rolId)) = '' OR 
           @direccionId IS NULL OR LTRIM(RTRIM(@direccionId)) = '' OR 
           @estado IS NULL OR LTRIM(RTRIM(@estado)) = '' 
        BEGIN
            SET @tipoError = 4;
            SET @mensaje = 'Ninguno de los campos puede estar vacío';
            SELECT @tipoError AS tipoError, @mensaje AS mensaje;
            RETURN;
        END

        -- Validar si el cliente existe
        IF NOT EXISTS (SELECT 1 FROM BSK_Cliente WHERE id = @clienteId)
        BEGIN
            SET @tipoError = 1;
            SET @mensaje = 'Cliente no encontrado';
            SELECT @tipoError AS tipoError, @mensaje AS mensaje;
            RETURN;
        END

        -- Verificar si el correo ya está en uso por otro cliente
        IF EXISTS (SELECT 1 FROM BSK_Autenticacion WHERE correo = @correo AND clienteId != @clienteId)
        BEGIN
            SET @tipoError = 2;
            SET @mensaje = 'El correo ya está en uso por otro cliente';
            SELECT @tipoError AS tipoError, @mensaje AS mensaje;
            RETURN;
        END

        -- Actualizar datos en la tabla Cliente
        UPDATE BSK_Cliente
        SET nombre = @nombre,
            apellidoPaterno = @apellidoPaterno,
            apellidoMaterno = @apellidoMaterno,
            rolId = @rolId,
            direccionId = @direccionId,
            estado = @estado 
        WHERE id = @clienteId;

        -- Actualizar el correo en la tabla Autenticacion
        UPDATE BSK_Autenticacion
        SET correo = @correo
        WHERE clienteId = @clienteId;

        SET @tipoError = 0;
        SET @mensaje = 'Datos actualizados correctamente';
        SELECT @tipoError AS tipoError, @mensaje AS mensaje;
    END TRY
    BEGIN CATCH
        SET @tipoError = 3;
        SET @mensaje = ERROR_MESSAGE();
        SELECT @tipoError AS tipoError, @mensaje AS mensaje;
    END CATCH
END
GO
print 'Operación correcta, sp_editar_empleado ejecutado.';
GO