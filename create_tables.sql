-- =====================================================
-- SCRIPT: CREACION DE TABLAS
-- Modelo ajustado segun los diagramas foto_diagrama_1 y foto_diagrama_2.
-- PostgreSQL
-- =====================================================

-- =====================================================
-- LIMPIEZA PREVIA
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
DROP TABLE IF EXISTS Fecha_Renovacion          CASCADE;
DROP TABLE IF EXISTS Detalles_Pago             CASCADE;
DROP TABLE IF EXISTS Usuario                   CASCADE;
DROP TABLE IF EXISTS Tipo_Pago                 CASCADE;
DROP TABLE IF EXISTS Plan                      CASCADE;
DROP TABLE IF EXISTS Episodios                 CASCADE;
DROP TABLE IF EXISTS Temporadas                CASCADE;
DROP TABLE IF EXISTS Series                    CASCADE;
DROP TABLE IF EXISTS Peliculas                 CASCADE;
DROP TABLE IF EXISTS Generos                   CASCADE;
DROP TABLE IF EXISTS Contenido                 CASCADE;

-- =====================================================
-- 1. CATALOGOS Y ENTIDADES PRINCIPALES
-- =====================================================

CREATE TABLE Tipo_Pago (
    id_tipo_pago  SERIAL       PRIMARY KEY,
    nombre        VARCHAR(50)  NOT NULL UNIQUE
);

CREATE TABLE Plan (
    id_plan    SERIAL         PRIMARY KEY,
    nombre     VARCHAR(50)    NOT NULL,
    precio     NUMERIC(10,2)  NOT NULL CHECK (precio >= 0),
    tipo_plan  INT            NOT NULL CHECK (tipo_plan IN (1, 12)),
    UNIQUE (nombre, tipo_plan)
);

CREATE TABLE Generos (
    id_genero  SERIAL       PRIMARY KEY,
    tipo       VARCHAR(50)  NOT NULL UNIQUE
);

CREATE TABLE Contenido (
    id_contenido    SERIAL        PRIMARY KEY,
    nombre          VARCHAR(150)  NOT NULL,
    tipo_contenido  VARCHAR(20)   NOT NULL CHECK (tipo_contenido IN ('pelicula', 'serie')),
    clasificacion   VARCHAR(30)   NOT NULL CHECK (
        clasificacion IN (
            'Todo publico',
            'supervision parental',
            '12+',
            '14+',
            '16+',
            '18+'
        )
    )
);

-- =====================================================
-- 2. PAGOS, PLANES Y USUARIOS
-- =====================================================

CREATE TABLE Usuario (
    id_usuario  SERIAL        PRIMARY KEY,
    correo      VARCHAR(100)  NOT NULL UNIQUE,
    contrasena  VARCHAR(255)  NOT NULL,
    region      VARCHAR(50)   NOT NULL,
    id_plan     INT           NOT NULL,
    FOREIGN KEY (id_plan) REFERENCES Plan(id_plan)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Detalles_Pago (
    id_detalles_pago  SERIAL        PRIMARY KEY,
    numero_cuenta     VARCHAR(100)  NOT NULL UNIQUE,
    fecha_pago        DATE          NOT NULL,
    id_tipo_pago      INT           NOT NULL,
    id_usuario        INT           NOT NULL UNIQUE,
    FOREIGN KEY (id_tipo_pago) REFERENCES Tipo_Pago(id_tipo_pago)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Fecha_Renovacion (
    id_fecha_renovacion  SERIAL  PRIMARY KEY,
    fecha                DATE    NOT NULL,
    id_detalles_pago     INT     NOT NULL,
    FOREIGN KEY (id_detalles_pago) REFERENCES Detalles_Pago(id_detalles_pago)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Plan_Tipo_Pago (
    id_plan       INT  NOT NULL,
    id_tipo_pago  INT  NOT NULL,
    PRIMARY KEY (id_plan, id_tipo_pago),
    FOREIGN KEY (id_plan) REFERENCES Plan(id_plan)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_tipo_pago) REFERENCES Tipo_Pago(id_tipo_pago)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =====================================================
-- 3. PERFILES, LISTAS, HISTORIAL Y RECOMENDACIONES
-- =====================================================

CREATE TABLE Perfil (
    id_perfil    SERIAL        PRIMARY KEY,
    nombre       VARCHAR(50)   NOT NULL,
    foto         VARCHAR(255),
    restriccion  VARCHAR(30)   NOT NULL CHECK (
        restriccion IN (
            'Todo publico',
            'supervision parental',
            '12+',
            '14+',
            '16+',
            '18+'
        )
    ),
    id_usuario   INT           NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Listas (
    id_lista     SERIAL       PRIMARY KEY,
    nombre_lista VARCHAR(80)  NOT NULL,
    id_usuario   INT          NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Historial (
    id_historial  SERIAL  PRIMARY KEY,
    id_perfil     INT     NOT NULL UNIQUE,
    FOREIGN KEY (id_perfil) REFERENCES Perfil(id_perfil)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Recomendaciones (
    id_recomendacion  SERIAL  PRIMARY KEY,
    atribuye          TEXT    NOT NULL,
    id_historial      INT     NOT NULL,
    FOREIGN KEY (id_historial) REFERENCES Historial(id_historial)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =====================================================
-- 4. SUBTIPOS DE CONTENIDO
-- =====================================================

CREATE TABLE Peliculas (
    id_contenido       INT           PRIMARY KEY,
    duracion           INT           NOT NULL CHECK (duracion > 0),
    estudio_animacion  VARCHAR(100)  NOT NULL,
    FOREIGN KEY (id_contenido) REFERENCES Contenido(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Series (
    id_contenido       INT           PRIMARY KEY,
    estudio_animacion  VARCHAR(100)  NOT NULL,
    emision            BOOLEAN       NOT NULL DEFAULT TRUE,
    FOREIGN KEY (id_contenido) REFERENCES Contenido(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Temporadas (
    id_temporada    SERIAL  PRIMARY KEY,
    numero          INT     NOT NULL CHECK (numero > 0),
    cant_capitulos  INT     NOT NULL CHECK (cant_capitulos > 0),
    id_contenido    INT     NOT NULL,
    FOREIGN KEY (id_contenido) REFERENCES Series(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE (id_contenido, numero)
);

CREATE TABLE Episodios (
    id_episodio   SERIAL        PRIMARY KEY,
    titulo        VARCHAR(150)  NOT NULL,
    duracion      INT           NOT NULL CHECK (duracion > 0),
    id_temporada  INT           NOT NULL,
    FOREIGN KEY (id_temporada) REFERENCES Temporadas(id_temporada)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =====================================================
-- 5. RELACIONES ENTRE ENTIDADES
-- =====================================================

CREATE TABLE Valoracion (
    id_valoracion  SERIAL       PRIMARY KEY,
    puntaje        NUMERIC(3,1) NOT NULL CHECK (puntaje BETWEEN 1 AND 10),
    id_perfil      INT          NOT NULL,
    id_contenido   INT          NOT NULL,
    FOREIGN KEY (id_perfil) REFERENCES Perfil(id_perfil)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_contenido) REFERENCES Contenido(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE (id_perfil, id_contenido)
);

CREATE TABLE Lista_Guarda_Contenido (
    id_lista      INT  NOT NULL,
    id_contenido  INT  NOT NULL,
    PRIMARY KEY (id_lista, id_contenido),
    FOREIGN KEY (id_lista) REFERENCES Listas(id_lista)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_contenido) REFERENCES Contenido(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Perfil_Ve_Contenido (
    id_visualizacion  SERIAL     PRIMARY KEY,
    id_perfil         INT        NOT NULL,
    id_contenido      INT        NOT NULL,
    fecha             TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_perfil) REFERENCES Perfil(id_perfil)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_contenido) REFERENCES Contenido(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Pelicula_Tiene_Genero (
    id_contenido  INT  NOT NULL,
    id_genero     INT  NOT NULL,
    PRIMARY KEY (id_contenido, id_genero),
    FOREIGN KEY (id_contenido) REFERENCES Peliculas(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_genero) REFERENCES Generos(id_genero)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Serie_Tiene_Genero (
    id_contenido  INT  NOT NULL,
    id_genero     INT  NOT NULL,
    PRIMARY KEY (id_contenido, id_genero),
    FOREIGN KEY (id_contenido) REFERENCES Series(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_genero) REFERENCES Generos(id_genero)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Historial_Contenido (
    id_historial_contenido  SERIAL        PRIMARY KEY,
    id_historial            INT           NOT NULL,
    id_contenido            INT           NOT NULL,
    nombre                  VARCHAR(150)  NOT NULL,
    duracion                INT           NOT NULL CHECK (duracion > 0),
    segundos_reproduccion   INT           NOT NULL CHECK (segundos_reproduccion >= 0),
    fecha                   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_historial) REFERENCES Historial(id_historial)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_contenido) REFERENCES Contenido(id_contenido)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =====================================================
-- INDICES UTILES PARA CONSULTAS
-- =====================================================
CREATE INDEX idx_usuario_plan ON Usuario(id_plan);
CREATE INDEX idx_detalles_pago_usuario ON Detalles_Pago(id_usuario);
CREATE INDEX idx_perfil_usuario ON Perfil(id_usuario);
CREATE INDEX idx_contenido_tipo ON Contenido(tipo_contenido);
CREATE INDEX idx_visualizacion_fecha ON Perfil_Ve_Contenido(fecha);
CREATE INDEX idx_historial_contenido_fecha ON Historial_Contenido(fecha);

-- =====================================================
-- FIN DEL SCRIPT
-- =====================================================
