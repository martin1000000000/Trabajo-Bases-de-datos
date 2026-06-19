-- =====================================================
-- SCRIPT: ESQUEMA OLAP - MODELO ESTRELLA
-- Proyecto: Sistema Crunchyroll
-- Grupo 3: Martin Arrigo, Nicolas Toro, Benjamin Neira, Diego Mora
-- PostgreSQL
-- =====================================================

-- =====================================================
-- LIMPIEZA PREVIA (orden inverso a FK)
-- =====================================================
DROP TABLE IF EXISTS fact_pagos             CASCADE;
DROP TABLE IF EXISTS fact_visualizaciones   CASCADE;
DROP TABLE IF EXISTS dim_perfil             CASCADE;
DROP TABLE IF EXISTS dim_usuario            CASCADE;
DROP TABLE IF EXISTS dim_contenido          CASCADE;
DROP TABLE IF EXISTS dim_tiempo             CASCADE;

-- =====================================================
-- 1. DIMENSION TIEMPO
-- =====================================================
CREATE TABLE dim_tiempo (
    id_tiempo    SERIAL      PRIMARY KEY,
    fecha        DATE        NOT NULL UNIQUE,
    anio         INT         NOT NULL,
    trimestre    INT         NOT NULL CHECK (trimestre BETWEEN 1 AND 4),
    mes          INT         NOT NULL CHECK (mes BETWEEN 1 AND 12),
    nombre_mes   VARCHAR(20) NOT NULL,
    semana       INT         NOT NULL,  -- semana del año (1-53)
    dia          INT         NOT NULL CHECK (dia BETWEEN 1 AND 31),
    dia_semana   INT         NOT NULL CHECK (dia_semana BETWEEN 1 AND 7),  -- 1=lunes ... 7=domingo
    nombre_dia   VARCHAR(20) NOT NULL,
    es_fin_semana BOOLEAN    NOT NULL
);

-- =====================================================
-- 2. DIMENSION CONTENIDO
-- =====================================================
CREATE TABLE dim_contenido (
    id_dim_contenido  SERIAL        PRIMARY KEY,
    id_contenido_oltp INT           NOT NULL,   -- FK logica al OLTP
    nombre            VARCHAR(150)  NOT NULL,
    tipo_contenido    VARCHAR(20)   NOT NULL,   -- 'pelicula' | 'serie'
    clasificacion     VARCHAR(30)   NOT NULL,
    estudio_animacion VARCHAR(100)  NOT NULL,
    duracion_minutos  INT,                      -- solo peliculas; NULL para series
    en_emision        BOOLEAN,                  -- solo series; NULL para peliculas
    generos           TEXT          NOT NULL    -- generos concatenados, ej: 'Accion, Aventura'
);

-- =====================================================
-- 3. DIMENSION USUARIO
-- =====================================================
CREATE TABLE dim_usuario (
    id_dim_usuario  SERIAL       PRIMARY KEY,
    id_usuario_oltp INT          NOT NULL,   -- FK logica al OLTP
    correo          VARCHAR(100) NOT NULL,
    region          VARCHAR(50)  NOT NULL,
    plan_nombre     VARCHAR(50)  NOT NULL,
    plan_tipo       VARCHAR(10)  NOT NULL,   -- 'mensual' | 'anual'
    plan_precio     NUMERIC(10,2) NOT NULL
);

-- =====================================================
-- 4. DIMENSION PERFIL
-- =====================================================
CREATE TABLE dim_perfil (
    id_dim_perfil   SERIAL       PRIMARY KEY,
    id_perfil_oltp  INT          NOT NULL,   -- FK logica al OLTP
    nombre_perfil   VARCHAR(50)  NOT NULL,
    restriccion     VARCHAR(30)  NOT NULL,
    id_dim_usuario  INT          NOT NULL,
    FOREIGN KEY (id_dim_usuario) REFERENCES dim_usuario(id_dim_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- =====================================================
-- 5. TABLA DE HECHOS: VISUALIZACIONES
--    Granularidad: 1 fila = 1 evento de visualizacion
-- =====================================================
CREATE TABLE fact_visualizaciones (
    id_fact_vis       SERIAL         PRIMARY KEY,
    -- Claves foraneas a dimensiones
    id_tiempo         INT            NOT NULL,
    id_dim_contenido  INT            NOT NULL,
    id_dim_perfil     INT            NOT NULL,
    id_dim_usuario    INT            NOT NULL,
    -- Metricas
    segundos_reproduccion  INT       NOT NULL CHECK (segundos_reproduccion >= 0),
    duracion_total_seg     INT       NOT NULL CHECK (duracion_total_seg > 0),
    porcentaje_completado  NUMERIC(5,2) NOT NULL,  -- calculado: seg/duracion*100
    visualizacion_completa BOOLEAN   NOT NULL,     -- TRUE si porcentaje >= 90%
    -- FK
    FOREIGN KEY (id_tiempo)        REFERENCES dim_tiempo(id_tiempo),
    FOREIGN KEY (id_dim_contenido) REFERENCES dim_contenido(id_dim_contenido),
    FOREIGN KEY (id_dim_perfil)    REFERENCES dim_perfil(id_dim_perfil),
    FOREIGN KEY (id_dim_usuario)   REFERENCES dim_usuario(id_dim_usuario)
);

-- =====================================================
-- 6. TABLA DE HECHOS: PAGOS / SUSCRIPCIONES
--    Granularidad: 1 fila = 1 pago / renovacion
-- =====================================================
CREATE TABLE fact_pagos (
    id_fact_pago    SERIAL         PRIMARY KEY,
    -- Claves foraneas a dimensiones
    id_tiempo       INT            NOT NULL,
    id_dim_usuario  INT            NOT NULL,
    -- Metricas
    monto           NUMERIC(10,2)  NOT NULL CHECK (monto >= 0),
    tipo_pago       VARCHAR(50)    NOT NULL,   -- 'Tarjeta', 'Transferencia', etc.
    es_renovacion   BOOLEAN        NOT NULL DEFAULT FALSE,
    -- FK
    FOREIGN KEY (id_tiempo)       REFERENCES dim_tiempo(id_tiempo),
    FOREIGN KEY (id_dim_usuario)  REFERENCES dim_usuario(id_dim_usuario)
);

-- =====================================================
-- INDICES PARA CONSULTAS ANALITICAS
-- =====================================================
CREATE INDEX idx_fact_vis_tiempo      ON fact_visualizaciones(id_tiempo);
CREATE INDEX idx_fact_vis_contenido   ON fact_visualizaciones(id_dim_contenido);
CREATE INDEX idx_fact_vis_usuario     ON fact_visualizaciones(id_dim_usuario);
CREATE INDEX idx_fact_vis_perfil      ON fact_visualizaciones(id_dim_perfil);
CREATE INDEX idx_fact_vis_completa    ON fact_visualizaciones(visualizacion_completa);

CREATE INDEX idx_fact_pagos_tiempo    ON fact_pagos(id_tiempo);
CREATE INDEX idx_fact_pagos_usuario   ON fact_pagos(id_dim_usuario);

CREATE INDEX idx_dim_tiempo_anio_mes  ON dim_tiempo(anio, mes);
CREATE INDEX idx_dim_contenido_tipo   ON dim_contenido(tipo_contenido);
CREATE INDEX idx_dim_usuario_region   ON dim_usuario(region);
CREATE INDEX idx_dim_usuario_plan     ON dim_usuario(plan_nombre, plan_tipo);

-- =====================================================
-- FIN DEL SCRIPT
-- =====================================================
