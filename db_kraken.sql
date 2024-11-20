-- Base de datos KraenBarberShop
CREATE DATABASE KraenBarberShop;
GO

USE KraenBarberShop;
GO

-- Tabla de Cliente Empleado (Informacion personal de los clientes/usuarios)
CREATE TABLE BSK_Cliente (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellidoPaterno VARCHAR(50) NOT NULL,
    apellidoMaterno VARCHAR(50),
    rolId INT NOT NULL,
    direccionId INT,
    tiendaId INT,
    estado VARCHAR(10) NOT NULL DEFAULT 'Activo',
    fechaCreacion DATETIME NOT NULL DEFAULT GETDATE(), 
    FOREIGN KEY (rolId) REFERENCES BSK_Rol(id)
);
