-- ============================================================
--  SISTEMA REGISTRADURÍA MUNICIPAL DE NOBSA · BOYACÁ
--  Motor: SQL Server (Express 2019+ / Azure SQL)
--  Taller Java Web con Servlets – ADSO · CIMM · SENA
--  Ejecutar en: SQL Server Management Studio (SSMS)
--              o DBeaver conectado al puerto 1433
-- ============================================================

-- ── 0. Crear y seleccionar la base de datos ─────────────────
IF NOT EXISTS (
    SELECT name FROM sys.databases WHERE name = 'registraduria_nobsa'
)
    CREATE DATABASE registraduria_nobsa;
GO

USE registraduria_nobsa;
GO

-- ── 1. Tabla CIUDADES ───────────────────────────────────────
--  Municipios del entorno de Nobsa (código DANE oficial)
IF OBJECT_ID('dbo.ciudades', 'U') IS NOT NULL
    DROP TABLE dbo.ciudades;
GO

CREATE TABLE dbo.ciudades (
    id             INT IDENTITY(1,1) PRIMARY KEY,
    nombre         NVARCHAR(80)  NOT NULL,
    departamento   NVARCHAR(60)  NOT NULL DEFAULT 'Boyacá',
    codigo_dane    NVARCHAR(10)  NOT NULL UNIQUE
);
GO

-- ── 2. Tabla ZONAS_VOTACION ─────────────────────────────────
--  Cada zona pertenece a una ciudad y agrupa varias mesas
IF OBJECT_ID('dbo.zonas_votacion', 'U') IS NOT NULL
    DROP TABLE dbo.zonas_votacion;
GO

CREATE TABLE dbo.zonas_votacion (
    id               INT IDENTITY(1,1) PRIMARY KEY,
    id_ciudad        INT           NOT NULL
        REFERENCES dbo.ciudades(id),
    nombre_zona      NVARCHAR(80)  NOT NULL,
    puesto_votacion  NVARCHAR(120) NOT NULL,
    direccion        NVARCHAR(150) NOT NULL
);
GO

-- ── 3. Tabla MESAS_VOTACION ─────────────────────────────────
--  Cada mesa pertenece a una zona de votación
IF OBJECT_ID('dbo.mesas_votacion', 'U') IS NOT NULL
    DROP TABLE dbo.mesas_votacion;
GO

CREATE TABLE dbo.mesas_votacion (
    id           INT IDENTITY(1,1) PRIMARY KEY,
    id_zona      INT NOT NULL
        REFERENCES dbo.zonas_votacion(id),
    numero_mesa  INT NOT NULL,
    capacidad    INT NOT NULL DEFAULT 200
);
GO

-- ── 4. Tabla CIUDADANOS ─────────────────────────────────────
--  Incluye FK opcional a mesas_votacion (NULL = no inscrito)
IF OBJECT_ID('dbo.ciudadanos', 'U') IS NOT NULL
    DROP TABLE dbo.ciudadanos;
GO

CREATE TABLE dbo.ciudadanos (
    id                  INT IDENTITY(1,1) PRIMARY KEY,
    numero_documento    NVARCHAR(20)  NOT NULL UNIQUE,
    nombres             NVARCHAR(80)  NOT NULL,
    apellidos           NVARCHAR(80)  NOT NULL,
    fecha_nacimiento    DATE          NOT NULL,
    vereda_barrio       NVARCHAR(80)  NOT NULL,
    telefono            NVARCHAR(20)  NULL,
    correo              NVARCHAR(100) NULL,
    id_mesa             INT           NULL
        REFERENCES dbo.mesas_votacion(id),
    fecha_registro      DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- ── 5. Tabla DOCUMENTOS_EXPEDIDOS ───────────────────────────
--  Historial de documentos emitidos a cada ciudadano
IF OBJECT_ID('dbo.documentos_expedidos', 'U') IS NOT NULL
    DROP TABLE dbo.documentos_expedidos;
GO

CREATE TABLE dbo.documentos_expedidos (
    id                  INT IDENTITY(1,1) PRIMARY KEY,
    id_ciudadano        INT           NOT NULL
        REFERENCES dbo.ciudadanos(id),
    tipo_documento      NVARCHAR(50)  NOT NULL,
    numero_serie        NVARCHAR(30)  NOT NULL UNIQUE,
    fecha_expedicion    DATE          NOT NULL,
    fecha_vencimiento   DATE          NULL,          -- NULL = sin vencimiento
    estado              NVARCHAR(20)  NOT NULL DEFAULT 'vigente',
    observaciones       NVARCHAR(300) NULL,

    CONSTRAINT chk_estado CHECK (estado IN ('vigente','vencido','cancelado'))
);
GO

-- ============================================================
--  DATOS DE PRUEBA
-- ============================================================

-- ── Ciudades ────────────────────────────────────────────────
INSERT INTO dbo.ciudades (nombre, departamento, codigo_dane) VALUES
    ('Nobsa',    'Boyacá', '15491'),
    ('Sogamoso', 'Boyacá', '15762'),
    ('Duitama',  'Boyacá', '15244');
GO

-- ── Zonas de votación (Nobsa, id_ciudad = 1) ────────────────
INSERT INTO dbo.zonas_votacion (id_ciudad, nombre_zona, puesto_votacion, direccion) VALUES
    (1, 'Zona Centro',  'Institución Educativa Nobsa',          'Calle 5 # 4-32, Centro'),
    (1, 'Zona Heroica', 'Escuela Rural La Heroica',             'Vereda La Heroica s/n'),
    (1, 'Zona Norte',   'Colegio Técnico Industrial de Nobsa',  'Carrera 3 # 8-15, Norte');
GO

-- ── Mesas de votación ───────────────────────────────────────
--   Zona Centro  (id=1): mesas 1, 2, 3
--   Zona Heroica (id=2): mesas 1, 2
--   Zona Norte   (id=3): mesas 1, 2, 3
INSERT INTO dbo.mesas_votacion (id_zona, numero_mesa, capacidad) VALUES
    (1, 1, 200), (1, 2, 200), (1, 3, 180),
    (2, 1, 150), (2, 2, 150),
    (3, 1, 200), (3, 2, 200), (3, 3, 200);
GO

-- ── Ciudadanos de Nobsa (con mesa asignada) ─────────────────
--   ciudadano 1 → mesa id=1  (Zona Centro,  mesa 1)
--   ciudadano 2 → mesa id=2  (Zona Centro,  mesa 2)
--   ciudadano 3 → mesa id=4  (Zona Heroica, mesa 1)
--   ciudadano 4 → mesa id=6  (Zona Norte,   mesa 1)
--   ciudadano 5 → NULL       (no inscrito)
INSERT INTO dbo.ciudadanos
    (numero_documento, nombres, apellidos, fecha_nacimiento,
     vereda_barrio, telefono, correo, id_mesa)
VALUES
    ('1052345678', 'Carlos Ernesto',   'Pedraza Rondón',   '1985-03-12', 'Centro',    '3101234567', NULL,                      1),
    ('1052345679', 'María del Carmen', 'Suárez Cely',      '1992-07-24', 'Heroica',   '3117654321', 'msuarez@correo.com',       2),
    ('1052345680', 'Jorge Hernando',   'Báez Morales',     '1978-11-05', 'San Martín','3124567890', NULL,                      4),
    ('1052345681', 'Luz Amparo',       'Chaparro Torres',  '2001-01-30', 'El Pino',   '3135678901', 'lchaparro@correo.com',     6),
    ('1052345682', 'Pedro Antonio',    'Fonseca Nieto',    '1969-09-18', 'Belén',     NULL,         NULL,                      NULL);
GO

-- ── Documentos expedidos ────────────────────────────────────
INSERT INTO dbo.documentos_expedidos
    (id_ciudadano, tipo_documento, numero_serie,
     fecha_expedicion, fecha_vencimiento, estado)
VALUES
    (1, 'Cédula de Ciudadanía',  'CC-2015-00123', '2015-06-10', NULL,         'vigente'),
    (2, 'Cédula de Ciudadanía',  'CC-2018-00456', '2018-09-22', NULL,         'vigente'),
    (3, 'Cédula de Ciudadanía',  'CC-2010-00789', '2010-03-15', NULL,         'vigente'),
    (4, 'Tarjeta de Identidad',  'TI-2016-01012', '2016-08-01', '2026-08-01', 'vigente'),
    (5, 'Cédula de Ciudadanía',  'CC-2005-01345', '2005-11-30', NULL,         'vigente');
GO

-- ============================================================
--  CONSULTA DE VERIFICACIÓN
--  Ejecuta esto para confirmar que todo quedó bien:
-- ============================================================

-- Ver ciudadanos con su mesa asignada (JOIN de 4 tablas)
SELECT
    c.numero_documento,
    c.nombres + ' ' + c.apellidos   AS ciudadano,
    ci.nombre                        AS ciudad,
    z.nombre_zona,
    z.puesto_votacion,
    m.numero_mesa,
    m.capacidad
FROM dbo.ciudadanos c
LEFT JOIN dbo.mesas_votacion  m  ON c.id_mesa   = m.id
LEFT JOIN dbo.zonas_votacion  z  ON m.id_zona   = z.id
LEFT JOIN dbo.ciudades        ci ON z.id_ciudad = ci.id
ORDER BY c.id;
GO

-- Ver todos los documentos con nombre del ciudadano
SELECT
    d.numero_serie,
    d.tipo_documento,
    c.nombres + ' ' + c.apellidos AS ciudadano,
    d.fecha_expedicion,
    d.fecha_vencimiento,
    d.estado
FROM dbo.documentos_expedidos d
INNER JOIN dbo.ciudadanos c ON d.id_ciudadano = c.id
ORDER BY d.fecha_expedicion DESC;
GO

-- ── BONUS: documentos próximos a vencer (≤ 30 días) ─────────
SELECT
    d.numero_serie,
    d.tipo_documento,
    c.nombres + ' ' + c.apellidos AS ciudadano,
    d.fecha_vencimiento,
    DATEDIFF(DAY, GETDATE(), d.fecha_vencimiento) AS dias_restantes
FROM dbo.documentos_expedidos d
INNER JOIN dbo.ciudadanos c ON d.id_ciudadano = c.id
WHERE d.fecha_vencimiento IS NOT NULL
  AND d.fecha_vencimiento BETWEEN GETDATE() AND DATEADD(DAY, 30, GETDATE())
ORDER BY d.fecha_vencimiento;
GO
