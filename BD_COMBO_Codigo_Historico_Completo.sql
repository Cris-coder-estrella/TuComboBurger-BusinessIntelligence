/* ============================================================================
   PROYECTO DE BUSINESS INTELLIGENCE
   EMPRESA: TU COMBO BURGER
   MOTOR: MICROSOFT SQL SERVER

   ARCHIVO: BD_COMBO_Codigo_Historico_Completo.sql

   PROPOSITO:
   Mostrar de forma ordenada y didactica los codigos utilizados durante el
   desarrollo del proyecto, como si la base de datos se construyera por primera
   vez desde cero.

   IMPORTANTE:
   - Este archivo es material historico, academico y de referencia.
   - No esta pensado para ejecutarse sobre la BD_COMBO actual.
   - No reemplaza al archivo BD_COMBO.sql del repositorio.
   - El CSV utilizado en el ETL debe ubicarse en:
     C:\ETL\Datos_ETL_Tu_Combo_Burges_2025_Limpio.csv
   ============================================================================ */


/* ============================================================================
   1. CREAR LA BASE DE DATOS
   ============================================================================ */

USE master;
GO

CREATE DATABASE BD_COMBO;
GO

USE BD_COMBO;
GO


/* ============================================================================
   2. CREAR LA TABLA STAGINGVENTAS

   Esta tabla recibe la informacion del CSV tal como llega. Los campos se
   almacenan inicialmente como texto para poder validar vacios, formatos y
   conversiones antes de cargar el modelo dimensional.
   ============================================================================ */

CREATE TABLE dbo.StagingVentas
(
    id_venta        VARCHAR(20)  NULL,
    fecha           VARCHAR(20)  NULL,
    cliente         VARCHAR(100) NULL,
    producto        VARCHAR(100) NULL,
    categoria       VARCHAR(50)  NULL,
    cantidad        VARCHAR(20)  NULL,
    precio_unitario VARCHAR(20)  NULL,
    subtotal        VARCHAR(20)  NULL,
    metodo_pago     VARCHAR(30)  NULL,
    empleado        VARCHAR(100) NULL
);
GO


/* ============================================================================
   3. CREAR LA TABLA VENTASTRANSFORMADAS

   Almacena los datos depurados, normalizados y convertidos a sus tipos
   definitivos antes de cargar las dimensiones y FACT_VENTAS.
   ============================================================================ */

CREATE TABLE dbo.VentasTransformadas
(
    id_venta        INT           NOT NULL,
    fecha           DATE          NOT NULL,
    cliente         VARCHAR(100)  NOT NULL,
    producto        VARCHAR(100)  NOT NULL,
    categoria       VARCHAR(50)   NOT NULL,
    cantidad        INT           NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    metodo_pago     VARCHAR(30)   NOT NULL,
    empleado        VARCHAR(100)  NOT NULL,

    CONSTRAINT PK_VentasTransformadas
        PRIMARY KEY (id_venta),

    CONSTRAINT CK_VentasTransformadas_Cantidad
        CHECK (cantidad > 0),

    CONSTRAINT CK_VentasTransformadas_Precio
        CHECK (precio_unitario > 0),

    CONSTRAINT CK_VentasTransformadas_Subtotal
        CHECK (subtotal > 0)
);
GO


/* ============================================================================
   4. CREAR LA DIMENSION CLIENTE
   ============================================================================ */

CREATE TABLE dbo.Dim_Cliente
(
    idCliente INT NOT NULL,
    nombreCliente VARCHAR(100) NOT NULL,

    CONSTRAINT PK_Dim_Cliente
        PRIMARY KEY (idCliente),

    CONSTRAINT UQ_Dim_Cliente_Nombre
        UNIQUE (nombreCliente)
);
GO


/* ============================================================================
   5. CREAR LA DIMENSION PRODUCTO
   ============================================================================ */

CREATE TABLE dbo.Dim_Producto
(
    idProducto INT NOT NULL,
    nombreProducto VARCHAR(100) NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    disponibilidad VARCHAR(20) NOT NULL,

    CONSTRAINT PK_Dim_Producto
        PRIMARY KEY (idProducto),

    CONSTRAINT UQ_Dim_Producto
        UNIQUE (nombreProducto, categoria),

    CONSTRAINT CK_Dim_Producto_Precio
        CHECK (precio > 0)
);
GO


/* ============================================================================
   6. CREAR LA DIMENSION EMPLEADO
   ============================================================================ */

CREATE TABLE dbo.Dim_Empleado
(
    idEmpleado INT NOT NULL,
    nombreEmpleado VARCHAR(100) NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    turno VARCHAR(30) NOT NULL,

    CONSTRAINT PK_Dim_Empleado
        PRIMARY KEY (idEmpleado),

    CONSTRAINT UQ_Dim_Empleado_Nombre
        UNIQUE (nombreEmpleado)
);
GO


/* ============================================================================
   7. CREAR LA DIMENSION TIEMPO
   ============================================================================ */

CREATE TABLE dbo.Dim_Tiempo
(
    idTiempo INT IDENTITY(1,1) NOT NULL,
    Fecha DATE NOT NULL,
    Dia INT NOT NULL,
    Mes INT NOT NULL,
    NombreMes VARCHAR(20) NOT NULL,
    Anio INT NOT NULL,

    CONSTRAINT PK_Dim_Tiempo
        PRIMARY KEY (idTiempo),

    CONSTRAINT UQ_Dim_Tiempo_Fecha
        UNIQUE (Fecha),

    CONSTRAINT CK_Dim_Tiempo_Mes
        CHECK (Mes BETWEEN 1 AND 12)
);
GO


/* ============================================================================
   8. CREAR LA DIMENSION METODO DE PAGO
   ============================================================================ */

CREATE TABLE dbo.Dim_MetodoPago
(
    idMetodoPagoDim INT IDENTITY(1,1) NOT NULL,
    metodoPago VARCHAR(30) NOT NULL,

    CONSTRAINT PK_Dim_MetodoPago
        PRIMARY KEY (idMetodoPagoDim),

    CONSTRAINT UQ_Dim_MetodoPago
        UNIQUE (metodoPago)
);
GO


/* ============================================================================
   9. CREAR LA TABLA DE HECHOS FACT_VENTAS

   Cada registro representa una venta asociada con cliente, producto, empleado,
   fecha y metodo de pago.
   ============================================================================ */

CREATE TABLE dbo.FACT_VENTAS
(
    idFactVenta INT IDENTITY(1,1) NOT NULL,
    idVentaOrigen INT NOT NULL,
    idCliente INT NOT NULL,
    idProducto INT NOT NULL,
    idEmpleado INT NOT NULL,
    idTiempo INT NOT NULL,
    idMetodoPago INT NOT NULL,
    Cantidad_Vendida INT NOT NULL,
    Precio_Unitario DECIMAL(10,2) NOT NULL,
    Subtotal_Venta DECIMAL(10,2) NOT NULL,

    CONSTRAINT PK_FACT_VENTAS
        PRIMARY KEY (idFactVenta),

    CONSTRAINT UQ_FACT_VENTAS_Origen
        UNIQUE (idVentaOrigen),

    CONSTRAINT FK_FACT_VENTAS_Cliente
        FOREIGN KEY (idCliente)
        REFERENCES dbo.Dim_Cliente(idCliente),

    CONSTRAINT FK_FACT_VENTAS_Producto
        FOREIGN KEY (idProducto)
        REFERENCES dbo.Dim_Producto(idProducto),

    CONSTRAINT FK_FACT_VENTAS_Empleado
        FOREIGN KEY (idEmpleado)
        REFERENCES dbo.Dim_Empleado(idEmpleado),

    CONSTRAINT FK_FACT_VENTAS_Tiempo
        FOREIGN KEY (idTiempo)
        REFERENCES dbo.Dim_Tiempo(idTiempo),

    CONSTRAINT FK_FACT_MetodoPago
        FOREIGN KEY (idMetodoPago)
        REFERENCES dbo.Dim_MetodoPago(idMetodoPagoDim),

    CONSTRAINT CK_FACT_VENTAS_Cantidad
        CHECK (Cantidad_Vendida > 0),

    CONSTRAINT CK_FACT_VENTAS_Precio
        CHECK (Precio_Unitario > 0),

    CONSTRAINT CK_FACT_VENTAS_Subtotal
        CHECK (Subtotal_Venta > 0)
);
GO


/* ============================================================================
   10. EXTRACCION DEL PROCESO ETL

   Cargar el archivo CSV limpio hacia StagingVentas mediante BULK INSERT.
   ============================================================================ */

BULK INSERT dbo.StagingVentas
FROM 'C:\ETL\Datos_ETL_Tu_Combo_Burges_2025_Limpio.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO


/* ============================================================================
   11. VERIFICAR LA CANTIDAD CARGADA EN STAGINGVENTAS
   ============================================================================ */

SELECT COUNT(*) AS RegistrosStaging
FROM dbo.StagingVentas;
GO

SELECT
    MIN(TRY_CONVERT(INT, id_venta)) AS PrimerID,
    MAX(TRY_CONVERT(INT, id_venta)) AS UltimoID
FROM dbo.StagingVentas;
GO


/* ============================================================================
   12. PERFILADO Y CALIDAD DE LOS DATOS

   Verificar campos vacios y errores de conversion en los campos criticos.
   ============================================================================ */

SELECT
    COUNT(*) AS TotalRegistros,

    SUM(CASE
        WHEN NULLIF(LTRIM(RTRIM(id_venta)), '') IS NULL
          OR NULLIF(LTRIM(RTRIM(fecha)), '') IS NULL
          OR NULLIF(LTRIM(RTRIM(cliente)), '') IS NULL
          OR NULLIF(LTRIM(RTRIM(producto)), '') IS NULL
          OR NULLIF(LTRIM(RTRIM(categoria)), '') IS NULL
          OR NULLIF(LTRIM(RTRIM(cantidad)), '') IS NULL
          OR NULLIF(LTRIM(RTRIM(precio_unitario)), '') IS NULL
          OR NULLIF(LTRIM(RTRIM(subtotal)), '') IS NULL
          OR NULLIF(LTRIM(RTRIM(metodo_pago)), '') IS NULL
          OR NULLIF(LTRIM(RTRIM(empleado)), '') IS NULL
        THEN 1 ELSE 0
    END) AS RegistrosConVacios,

    SUM(CASE
        WHEN TRY_CONVERT(INT, id_venta) IS NULL
        THEN 1 ELSE 0
    END) AS Error_ID,

    SUM(CASE
        WHEN TRY_CONVERT(DATE, fecha, 103) IS NULL
        THEN 1 ELSE 0
    END) AS Error_Fecha,

    SUM(CASE
        WHEN TRY_CONVERT(INT, cantidad) IS NULL
        THEN 1 ELSE 0
    END) AS Error_Cantidad,

    SUM(CASE
        WHEN TRY_CONVERT(DECIMAL(10,2), precio_unitario) IS NULL
        THEN 1 ELSE 0
    END) AS Error_Precio,

    SUM(CASE
        WHEN TRY_CONVERT(DECIMAL(10,2), subtotal) IS NULL
        THEN 1 ELSE 0
    END) AS Error_Subtotal
FROM dbo.StagingVentas;
GO


/* ============================================================================
   13. VERIFICAR IDENTIFICADORES DUPLICADOS
   Resultado esperado: 0.
   ============================================================================ */

SELECT COUNT(*) AS IDsDuplicados
FROM
(
    SELECT id_venta
    FROM dbo.StagingVentas
    GROUP BY id_venta
    HAVING COUNT(*) > 1
) AS Duplicados;
GO


/* ============================================================================
   14. TRANSFORMACION DE DATOS

   Operaciones aplicadas:
   - TRY_CONVERT: conversion segura de tipos.
   - LTRIM y RTRIM: eliminacion de espacios.
   - UPPER y CASE: normalizacion de metodos de pago.
   - REPLACE: eliminacion de saltos de linea en empleados.
   ============================================================================ */

INSERT INTO dbo.VentasTransformadas
(
    id_venta,
    fecha,
    cliente,
    producto,
    categoria,
    cantidad,
    precio_unitario,
    subtotal,
    metodo_pago,
    empleado
)
SELECT
    TRY_CONVERT(INT, id_venta),
    TRY_CONVERT(DATE, fecha, 103),
    LTRIM(RTRIM(cliente)),
    LTRIM(RTRIM(producto)),
    LTRIM(RTRIM(categoria)),
    TRY_CONVERT(INT, cantidad),
    TRY_CONVERT(DECIMAL(10,2), precio_unitario),
    TRY_CONVERT(DECIMAL(10,2), subtotal),

    CASE UPPER(LTRIM(RTRIM(metodo_pago)))
        WHEN 'YAPE' THEN 'Yape'
        WHEN 'PLIN' THEN 'Plin'
        WHEN 'EFECTIVO' THEN 'Efectivo'
        ELSE LTRIM(RTRIM(metodo_pago))
    END,

    LTRIM(RTRIM(
        REPLACE(REPLACE(empleado, CHAR(13), ''), CHAR(10), '')
    ))
FROM dbo.StagingVentas
WHERE TRY_CONVERT(INT, id_venta) IS NOT NULL
  AND TRY_CONVERT(DATE, fecha, 103) IS NOT NULL
  AND TRY_CONVERT(INT, cantidad) IS NOT NULL
  AND TRY_CONVERT(DECIMAL(10,2), precio_unitario) IS NOT NULL
  AND TRY_CONVERT(DECIMAL(10,2), subtotal) IS NOT NULL;
GO


/* ============================================================================
   15. VERIFICAR LOS REGISTROS TRANSFORMADOS
   ============================================================================ */

SELECT COUNT(*) AS RegistrosTransformados
FROM dbo.VentasTransformadas;
GO

SELECT TOP (10) *
FROM dbo.VentasTransformadas
ORDER BY id_venta;
GO


/* ============================================================================
   16. VALIDAR LA REGLA DEL SUBTOTAL
   Resultado esperado: 0 registros inconsistentes.
   ============================================================================ */

SELECT COUNT(*) AS SubtotalesInconsistentes
FROM dbo.VentasTransformadas
WHERE subtotal <> cantidad * precio_unitario;
GO


/* ============================================================================
   17. CARGAR LA DIMENSION CLIENTE
   ============================================================================ */

INSERT INTO dbo.Dim_Cliente
(
    idCliente,
    nombreCliente
)
SELECT
    ROW_NUMBER() OVER (ORDER BY cliente) AS idCliente,
    cliente
FROM
(
    SELECT DISTINCT LTRIM(RTRIM(cliente)) AS cliente
    FROM dbo.VentasTransformadas
    WHERE cliente IS NOT NULL
      AND LTRIM(RTRIM(cliente)) <> ''
) AS ClientesUnicos;
GO


/* ============================================================================
   18. CARGAR LA DIMENSION PRODUCTO
   ============================================================================ */

INSERT INTO dbo.Dim_Producto
(
    idProducto,
    nombreProducto,
    precio,
    categoria,
    disponibilidad
)
SELECT
    ROW_NUMBER() OVER (ORDER BY producto, categoria) AS idProducto,
    producto,
    MAX(precio_unitario) AS precio,
    categoria,
    'Disponible' AS disponibilidad
FROM dbo.VentasTransformadas
GROUP BY producto, categoria;
GO


/* ============================================================================
   19. CARGAR LA DIMENSION EMPLEADO
   ============================================================================ */

INSERT INTO dbo.Dim_Empleado
(
    idEmpleado,
    nombreEmpleado,
    cargo,
    turno
)
SELECT
    ROW_NUMBER() OVER (ORDER BY empleado) AS idEmpleado,
    empleado,
    'Atencion y ventas' AS cargo,
    'Variable' AS turno
FROM
(
    SELECT DISTINCT LTRIM(RTRIM(empleado)) AS empleado
    FROM dbo.VentasTransformadas
    WHERE empleado IS NOT NULL
      AND LTRIM(RTRIM(empleado)) <> ''
) AS EmpleadosUnicos;
GO


/* ============================================================================
   20. CARGAR LA DIMENSION TIEMPO
   ============================================================================ */

INSERT INTO dbo.Dim_Tiempo
(
    Fecha,
    Dia,
    Mes,
    NombreMes,
    Anio
)
SELECT DISTINCT
    fecha,
    DAY(fecha),
    MONTH(fecha),
    CASE MONTH(fecha)
        WHEN 1 THEN 'Enero'
        WHEN 2 THEN 'Febrero'
        WHEN 3 THEN 'Marzo'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Mayo'
        WHEN 6 THEN 'Junio'
        WHEN 7 THEN 'Julio'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Septiembre'
        WHEN 10 THEN 'Octubre'
        WHEN 11 THEN 'Noviembre'
        WHEN 12 THEN 'Diciembre'
    END,
    YEAR(fecha)
FROM dbo.VentasTransformadas;
GO


/* ============================================================================
   21. CARGAR LA DIMENSION METODO DE PAGO
   ============================================================================ */

INSERT INTO dbo.Dim_MetodoPago
(
    metodoPago
)
SELECT DISTINCT
    metodo_pago
FROM dbo.VentasTransformadas
WHERE metodo_pago IS NOT NULL
  AND LTRIM(RTRIM(metodo_pago)) <> '';
GO


/* ============================================================================
   22. RECONCILIACION PREVIA A LA CARGA DE FACT_VENTAS

   Verifica que cada venta encuentre cliente, producto, empleado, fecha y
   metodo de pago en las dimensiones. Resultado esperado: 0.
   ============================================================================ */

SELECT COUNT(*) AS VentasSinCoincidencia
FROM dbo.VentasTransformadas VT
LEFT JOIN dbo.Dim_Cliente DC
    ON DC.nombreCliente = VT.cliente
LEFT JOIN dbo.Dim_Producto DP
    ON DP.nombreProducto = VT.producto
   AND DP.categoria = VT.categoria
LEFT JOIN dbo.Dim_Empleado DE
    ON DE.nombreEmpleado = VT.empleado
LEFT JOIN dbo.Dim_Tiempo DT
    ON DT.Fecha = VT.fecha
LEFT JOIN dbo.Dim_MetodoPago DM
    ON DM.metodoPago = VT.metodo_pago
WHERE DC.idCliente IS NULL
   OR DP.idProducto IS NULL
   OR DE.idEmpleado IS NULL
   OR DT.idTiempo IS NULL
   OR DM.idMetodoPagoDim IS NULL;
GO


/* ============================================================================
   23. CARGAR LA TABLA DE HECHOS FACT_VENTAS
   ============================================================================ */

INSERT INTO dbo.FACT_VENTAS
(
    idVentaOrigen,
    idCliente,
    idProducto,
    idEmpleado,
    idTiempo,
    idMetodoPago,
    Cantidad_Vendida,
    Precio_Unitario,
    Subtotal_Venta
)
SELECT
    VT.id_venta,
    DC.idCliente,
    DP.idProducto,
    DE.idEmpleado,
    DT.idTiempo,
    DM.idMetodoPagoDim,
    VT.cantidad,
    VT.precio_unitario,
    VT.subtotal
FROM dbo.VentasTransformadas VT
INNER JOIN dbo.Dim_Cliente DC
    ON DC.nombreCliente = VT.cliente
INNER JOIN dbo.Dim_Producto DP
    ON DP.nombreProducto = VT.producto
   AND DP.categoria = VT.categoria
INNER JOIN dbo.Dim_Empleado DE
    ON DE.nombreEmpleado = VT.empleado
INNER JOIN dbo.Dim_Tiempo DT
    ON DT.Fecha = VT.fecha
INNER JOIN dbo.Dim_MetodoPago DM
    ON DM.metodoPago = VT.metodo_pago;
GO


/* ============================================================================
   24. VERIFICAR LA CARGA FINAL DEL DATAMART
   ============================================================================ */

SELECT 'StagingVentas' AS Tabla, COUNT(*) AS Registros
FROM dbo.StagingVentas
UNION ALL
SELECT 'VentasTransformadas', COUNT(*)
FROM dbo.VentasTransformadas
UNION ALL
SELECT 'Dim_Cliente', COUNT(*)
FROM dbo.Dim_Cliente
UNION ALL
SELECT 'Dim_Producto', COUNT(*)
FROM dbo.Dim_Producto
UNION ALL
SELECT 'Dim_Empleado', COUNT(*)
FROM dbo.Dim_Empleado
UNION ALL
SELECT 'Dim_Tiempo', COUNT(*)
FROM dbo.Dim_Tiempo
UNION ALL
SELECT 'Dim_MetodoPago', COUNT(*)
FROM dbo.Dim_MetodoPago
UNION ALL
SELECT 'FACT_VENTAS', COUNT(*)
FROM dbo.FACT_VENTAS;
GO

/* Resultado obtenido con el dataset final:

   StagingVentas         12487
   VentasTransformadas   12487
   Dim_Cliente             260
   Dim_Producto              7
   Dim_Empleado              4
   Dim_Tiempo              313
   Dim_MetodoPago            3
   FACT_VENTAS           12487
*/


/* ============================================================================
   25. VALIDACION FINAL DE FACT_VENTAS
   ============================================================================ */

SELECT
    MIN(idVentaOrigen) AS PrimeraVenta,
    MAX(idVentaOrigen) AS UltimaVenta,
    COUNT(DISTINCT idVentaOrigen) AS VentasUnicas,
    SUM(Cantidad_Vendida) AS UnidadesVendidas,
    SUM(Subtotal_Venta) AS VentasTotales
FROM dbo.FACT_VENTAS;
GO


/* ============================================================================
   26. CONSULTA INTEGRADA DEL MODELO ESTRELLA
   ============================================================================ */

SELECT TOP (20)
    FV.idVentaOrigen,
    DT.Fecha,
    DC.nombreCliente,
    DP.nombreProducto,
    DP.categoria,
    DE.nombreEmpleado,
    DM.metodoPago,
    FV.Cantidad_Vendida,
    FV.Precio_Unitario,
    FV.Subtotal_Venta
FROM dbo.FACT_VENTAS FV
INNER JOIN dbo.Dim_Cliente DC
    ON FV.idCliente = DC.idCliente
INNER JOIN dbo.Dim_Producto DP
    ON FV.idProducto = DP.idProducto
INNER JOIN dbo.Dim_Empleado DE
    ON FV.idEmpleado = DE.idEmpleado
INNER JOIN dbo.Dim_Tiempo DT
    ON FV.idTiempo = DT.idTiempo
INNER JOIN dbo.Dim_MetodoPago DM
    ON FV.idMetodoPago = DM.idMetodoPagoDim
ORDER BY FV.idVentaOrigen;
GO


/* ============================================================================
   27. CONSULTAS SQL BASE PARA LOS KPI
   ============================================================================ */

/* KPI: Ventas Totales */
SELECT SUM(Subtotal_Venta) AS VentasTotales
FROM dbo.FACT_VENTAS;
GO

/* KPI: Unidades Vendidas */
SELECT SUM(Cantidad_Vendida) AS UnidadesVendidas
FROM dbo.FACT_VENTAS;
GO

/* KPI: Numero de Ventas */
SELECT COUNT(DISTINCT idVentaOrigen) AS NumeroDeVentas
FROM dbo.FACT_VENTAS;
GO


/* ============================================================================
   28. MEDIDAS DAX UTILIZADAS EN POWER BI

   Ventas Totales =
   SUM(FACT_VENTAS[Subtotal_Venta])

   Unidades Vendidas =
   SUM(FACT_VENTAS[Cantidad_Vendida])

   Numero de Ventas =
   DISTINCTCOUNT(FACT_VENTAS[idVentaOrigen])
   ============================================================================ */


/* ============================================================================
   FIN DEL CODIGO HISTORICO COMPLETO DEL PROYECTO
   ============================================================================ */
