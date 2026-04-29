-- =====================================================
-- SCRIPT: CREACIÓN DE TABLAS
-- Generado a partir del diagrama Entidad-Relación
-- =====================================================

-- =====================================================
-- LIMPIEZA PREVIA (orden inverso respetando FK)
-- =====================================================
DROP TABLE IF EXISTS Historial_Contenido       CASCADE;
DROP TABLE IF EXISTS Perfil_Ve_Contenido       CASCADE;
DROP TABLE IF EXISTS Lista_Guarda_Contenido    CASCADE;
DROP TABLE IF EXISTS Serie_Tiene_Genero        CASCADE;
DROP TABLE IF EXISTS Pelicula_Tiene_Genero     CASCADE;
DROP TABLE IF EXISTS Plan_Tipo_Pago            CASCADE;
DROP TABLE IF EXISTS Valoracion                CASCADE;
DROP TABLE IF EXISTS Recomendaciones           CASCADE;
DROP TABLE IF EXISTS Historial                 CASCADE;
DROP TABLE IF EXISTS Listas                    CASCADE;
DROP TABLE IF EXISTS Perfil                    CASCADE;
DROP TABLE IF EXISTS Usuario                   CASCADE;
DROP TABLE IF EXISTS Fecha_Renovacion          CASCADE;
DROP TABLE IF EXISTS Detalles_Pago             CASCADE;
DROP TABLE IF EXISTS Tipo_Pago                 CASCADE;
DROP TABLE IF EXISTS Plan                      CASCADE;
DROP TABLE IF EXISTS Episodios                 CASCADE;
DROP TABLE IF EXISTS Temporadas                CASCADE;
DROP TABLE IF EXISTS Series                    CASCADE;
DROP TABLE IF EXISTS Peliculas                 CASCADE;
DROP TABLE IF EXISTS Generos                   CASCADE;
DROP TABLE IF EXISTS Contenido                 CASCADE;

-- =====================================================
-- 1. ENTIDADES INDEPENDIENTES
-- =====================================================

-- Tipo_Pago: id_tipo_pago (PK), nombre
CREATE TABLE Tipo_Pago (
    id_tipo_pago  SERIAL       PRIMARY KEY,
    nombre        VARCHAR(50)  NOT NULL
);

-- Plan: nombre, precio
CREATE TABLE Plan (
    id_plan  SERIAL         PRIMARY KEY,
    nombre   VARCHAR(50)    NOT NULL,
    precio   DECIMAL(10,2)  NOT NULL
);

-- Géneros: tipo
CREATE TABLE Generos (
    id_genero  SERIAL       PRIMARY KEY,
    tipo       VARCHAR(50)  NOT NULL
);

-- Contenido (supertipo de Peliculas y Series)
CREATE TABLE Contenido (
    id_contenido  SERIAL  PRIMARY KEY
);

-- =====================================================
-- 2. TABLAS DEPENDIENTES 1:N
-- =====================================================

-- Detalles_Pago: id_detalles_pago (PK), numero_cuenta
-- Relación: Tipo_Pago (1) --Tendra--> (N) Detalles_Pago
CREATE TABLE Detalles_Pago (
    id_detalles_pago  SERIAL        PRIMARY KEY,
    numero_cuenta     VARCHAR(100),
    id_tipo_pago      INT           NOT NULL,
    FOREIGN KEY (id_tipo_pago) REFERENCES Tipo_Pago(id_tipo_pago)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Fecha_Renovacion: id_fecha_renovacion (PK), fecha
-- Relación: Detalles_Pago (1) --Tendra--> (N) Fecha_Renovacion
CREATE TABLE Fecha_Renovacion (
    id_fecha_renovacion  SERIAL  PRIMARY KEY,
    fecha                DATE    NOT NULL,
    id_detalles_pago     INT     NOT NULL,
    FOREIGN KEY (id_detalles_pago) REFERENCES Detalles_Pago(id_detalles_pago)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Usuario: correo, contraseña, region
-- Relación: Plan (1) --Contrata--> (N) Usuario
CREATE TABLE Usuario (
    id_usuario   SERIAL        PRIMARY KEY,
    correo       VARCHAR(100)  UNIQUE NOT NULL,
    contrasena   VARCHAR(255)  NOT NULL,
    region       VARCHAR(50),
    id_plan      INT,
    FOREIGN KEY (id_plan) REFERENCES Plan(id_plan)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- Perfil: nombre, foto
-- Relación: Usuario (1) --Crea--> (N) Perfil
CREATE TABLE Perfil (
    id_perfil   SERIAL       PRIMARY KEY,
    nombre      VARCHAR(50)  NOT NULL,
    foto        VARCHAR(255),
    id_usuario  INT          NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Listas
-- Relación: Usuario (N) --Crea--> (N) Listas
-- (Se modela como 1:N desde Usuario, cada lista pertenece a un usuario)
CREATE TABLE Listas (
    id_lista    SERIAL  PRIMARY KEY,
    id_usuario  INT     NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Historial
-- Relación: Perfil (1) --Tiene--> (1) Historial
CREATE TABLE Historial (
    id_historial  SERIAL  PRIMARY KEY,
    id_perfil     INT     UNIQUE NOT NULL,
    FOREIGN KEY (id_perfil) REFERENCES Perfil(id_perfil)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Recomendaciones: atribuye
-- Relación: Historial (1) --Derivan--> (N) Recomendaciones
CREATE TABLE Recomendaciones (
    id_recomendacion  SERIAL  PRIMARY KEY,
    atribuye          TEXT,
    id_historial      INT     NOT NULL,
    FOREIGN KEY (id_historial) REFERENCES Historial(id_historial)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =====================================================
-- 3. SUBTIPOS DE CONTENIDO (Especialización)
-- =====================================================

-- Peliculas: estudio_animacion, clasificacion
-- Relación: Contenido --Clasifica--> Peliculas
CREATE TABLE Peliculas (
    id_contenido       INT          PRIMARY KEY,
    estudio_animacion  VARCHAR(100),
    clasificacion      VARCHAR(50),
    FOREIGN KEY (id_contenido) REFERENCES Contenido(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Series: estudio_animacion, emision_sitio
-- Relación: Contenido --Clasifica--> Series
CREATE TABLE Series (
    id_contenido       INT          PRIMARY KEY,
    estudio_animacion  VARCHAR(100),
    emision_sitio      VARCHAR(100),
    FOREIGN KEY (id_contenido) REFERENCES Contenido(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Temporadas: numero, cant_capitulos
-- Relación: Series (1) --Tiene--> (N) Temporadas
CREATE TABLE Temporadas (
    id_temporada    SERIAL  PRIMARY KEY,
    numero          INT     NOT NULL,
    cant_capitulos  INT,
    id_contenido    INT     NOT NULL,
    FOREIGN KEY (id_contenido) REFERENCES Series(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Episodios: titulo, duracion
-- Relación: Temporadas (1) --Dividen--> (N) Episodios
CREATE TABLE Episodios (
    id_episodio   SERIAL        PRIMARY KEY,
    titulo        VARCHAR(150),
    duracion      INT,
    id_temporada  INT           NOT NULL,
    FOREIGN KEY (id_temporada) REFERENCES Temporadas(id_temporada)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =====================================================
-- 4. RELACIÓN ENTIDAD (Valoracion)
-- Perfil (N) --Puede--> Valoracion --Afecta--> (N) Contenido
-- Atributo: puntaje
-- =====================================================
CREATE TABLE Valoracion (
    id_valoracion  SERIAL         PRIMARY KEY,
    puntaje        DECIMAL(3,1)   NOT NULL CHECK (puntaje BETWEEN 1 AND 10),
    id_perfil      INT            NOT NULL,
    id_contenido   INT            NOT NULL,
    FOREIGN KEY (id_perfil) REFERENCES Perfil(id_perfil)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_contenido) REFERENCES Contenido(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE (id_perfil, id_contenido)
);

-- =====================================================
-- 5. TABLAS INTERMEDIAS (RELACIONES N:M)
-- =====================================================

-- Plan (N) --Tiene--> (N) Tipo_Pago
CREATE TABLE Plan_Tipo_Pago (
    id_plan       INT  NOT NULL,
    id_tipo_pago  INT  NOT NULL,
    PRIMARY KEY (id_plan, id_tipo_pago),
    FOREIGN KEY (id_plan) REFERENCES Plan(id_plan)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_tipo_pago) REFERENCES Tipo_Pago(id_tipo_pago)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Listas (N) --Guarda--> (N) Contenido
CREATE TABLE Lista_Guarda_Contenido (
    id_lista      INT  NOT NULL,
    id_contenido  INT  NOT NULL,
    PRIMARY KEY (id_lista, id_contenido),
    FOREIGN KEY (id_lista) REFERENCES Listas(id_lista)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_contenido) REFERENCES Contenido(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Perfil (N) --Ver--> (N) Contenido
CREATE TABLE Perfil_Ve_Contenido (
    id_perfil     INT        NOT NULL,
    id_contenido  INT        NOT NULL,
    fecha         TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_perfil, id_contenido),
    FOREIGN KEY (id_perfil) REFERENCES Perfil(id_perfil)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_contenido) REFERENCES Contenido(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Peliculas (N) --Filtran--> (N) Generos
CREATE TABLE Pelicula_Tiene_Genero (
    id_contenido  INT  NOT NULL,
    id_genero     INT  NOT NULL,
    PRIMARY KEY (id_contenido, id_genero),
    FOREIGN KEY (id_contenido) REFERENCES Peliculas(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_genero) REFERENCES Generos(id_genero)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Series (N) --Filtran--> (N) Generos
CREATE TABLE Serie_Tiene_Genero (
    id_contenido  INT  NOT NULL,
    id_genero     INT  NOT NULL,
    PRIMARY KEY (id_contenido, id_genero),
    FOREIGN KEY (id_contenido) REFERENCES Series(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_genero) REFERENCES Generos(id_genero)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Historial (N) --Accede--> (N) Contenido
CREATE TABLE Historial_Contenido (
    id_historial  INT        NOT NULL,
    id_contenido  INT        NOT NULL,
    fecha         TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_historial, id_contenido),
    FOREIGN KEY (id_historial) REFERENCES Historial(id_historial)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_contenido) REFERENCES Contenido(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =====================================================
-- FIN DEL SCRIPT
-- =====================================================
