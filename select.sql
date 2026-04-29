-- =========================================================
-- SCRIPT 3: CONSULTAS SELECT - Vista ordenada de la BD
-- Ejecutar cada bloque por separado o todo junto
-- =========================================================

-- ---------------------------------------------------------
-- Q1. RESUMEN GENERAL DE VOLUMEN
-- ---------------------------------------------------------
SELECT tabla, registros FROM (
    SELECT 'Tipo_Pago'                AS tabla, COUNT(*) AS registros FROM Tipo_Pago
    UNION ALL SELECT 'Plan',                    COUNT(*) FROM Plan
    UNION ALL SELECT 'Plan_Tipo_Pago',          COUNT(*) FROM Plan_Tipo_Pago
    UNION ALL SELECT 'Detalles_Pago',           COUNT(*) FROM Detalles_Pago
    UNION ALL SELECT 'Fecha_Renovacion',        COUNT(*) FROM Fecha_Renovacion
    UNION ALL SELECT 'Usuario',                 COUNT(*) FROM Usuario
    UNION ALL SELECT 'Perfil',                  COUNT(*) FROM Perfil
    UNION ALL SELECT 'Historial',               COUNT(*) FROM Historial
    UNION ALL SELECT 'Listas',                  COUNT(*) FROM Listas
    UNION ALL SELECT 'Contenido',               COUNT(*) FROM Contenido
    UNION ALL SELECT 'Peliculas',               COUNT(*) FROM Peliculas
    UNION ALL SELECT 'Series',                  COUNT(*) FROM Series
    UNION ALL SELECT 'Temporadas',              COUNT(*) FROM Temporadas
    UNION ALL SELECT 'Episodios',               COUNT(*) FROM Episodios
    UNION ALL SELECT 'Generos',                 COUNT(*) FROM Generos
    UNION ALL SELECT 'Valoracion',              COUNT(*) FROM Valoracion
    UNION ALL SELECT 'Recomendaciones',         COUNT(*) FROM Recomendaciones
    UNION ALL SELECT 'Perfil_Ve_Contenido',     COUNT(*) FROM Perfil_Ve_Contenido
    UNION ALL SELECT 'Lista_Guarda_Contenido',  COUNT(*) FROM Lista_Guarda_Contenido
    UNION ALL SELECT 'Pelicula_Tiene_Genero',   COUNT(*) FROM Pelicula_Tiene_Genero
    UNION ALL SELECT 'Serie_Tiene_Genero',      COUNT(*) FROM Serie_Tiene_Genero
    UNION ALL SELECT 'Historial_Contenido',     COUNT(*) FROM Historial_Contenido
) t
ORDER BY registros DESC;

-- ---------------------------------------------------------
-- Q2. TIPOS DE PAGO
-- ---------------------------------------------------------
SELECT id_tipo_pago, nombre
FROM Tipo_Pago
ORDER BY id_tipo_pago;

-- ---------------------------------------------------------
-- Q3. PLANES CON SUS PRECIOS
-- ---------------------------------------------------------
SELECT id_plan, nombre, precio
FROM Plan
ORDER BY precio;

-- ---------------------------------------------------------
-- Q4. PLAN ↔ TIPO DE PAGO (N:M)
-- ---------------------------------------------------------
SELECT
    p.nombre   AS plan,
    tp.nombre  AS tipo_pago
FROM Plan_Tipo_Pago pt
JOIN Plan      p  ON p.id_plan       = pt.id_plan
JOIN Tipo_Pago tp ON tp.id_tipo_pago = pt.id_tipo_pago
ORDER BY p.nombre, tp.nombre;

-- ---------------------------------------------------------
-- Q5. GÉNEROS DISPONIBLES
-- ---------------------------------------------------------
SELECT id_genero, tipo
FROM Generos
ORDER BY id_genero;

-- ---------------------------------------------------------
-- Q6. PELÍCULAS CON SUS GÉNEROS
-- ---------------------------------------------------------
SELECT
    p.id_contenido,
    p.estudio_animacion,
    p.clasificacion,
    STRING_AGG(g.tipo, ', ' ORDER BY g.tipo) AS generos
FROM Peliculas p
LEFT JOIN Pelicula_Tiene_Genero pg ON pg.id_contenido = p.id_contenido
LEFT JOIN Generos g                ON g.id_genero     = pg.id_genero
GROUP BY p.id_contenido, p.estudio_animacion, p.clasificacion
ORDER BY p.id_contenido;

-- ---------------------------------------------------------
-- Q7. SERIES CON TEMPORADAS Y CAPÍTULOS
-- ---------------------------------------------------------
SELECT
    s.id_contenido,
    s.estudio_animacion,
    s.emision_sitio,
    STRING_AGG(DISTINCT g.tipo, ', ' ORDER BY g.tipo) AS generos,
    COUNT(DISTINCT t.id_temporada)                     AS total_temporadas,
    COALESCE(SUM(t.cant_capitulos), 0)                 AS total_capitulos
FROM Series s
LEFT JOIN Serie_Tiene_Genero sg ON sg.id_contenido = s.id_contenido
LEFT JOIN Generos g             ON g.id_genero     = sg.id_genero
LEFT JOIN Temporadas t          ON t.id_contenido  = s.id_contenido
GROUP BY s.id_contenido, s.estudio_animacion, s.emision_sitio
ORDER BY s.id_contenido;

-- ---------------------------------------------------------
-- Q8. DETALLE DE TEMPORADAS POR SERIE
-- ---------------------------------------------------------
SELECT
    t.id_temporada,
    s.estudio_animacion AS serie_estudio,
    t.numero            AS num_temporada,
    t.cant_capitulos,
    COUNT(e.id_episodio) AS episodios_reales
FROM Temporadas t
JOIN Series s    ON s.id_contenido = t.id_contenido
JOIN Episodios e ON e.id_temporada = t.id_temporada
GROUP BY t.id_temporada, s.estudio_animacion, t.numero, t.cant_capitulos
ORDER BY s.estudio_animacion, t.numero;

-- ---------------------------------------------------------
-- Q9. USUARIOS POR PLAN
-- ---------------------------------------------------------
SELECT
    p.nombre  AS plan,
    COUNT(*)  AS cantidad_usuarios
FROM Usuario u
JOIN Plan p ON p.id_plan = u.id_plan
GROUP BY p.nombre
ORDER BY cantidad_usuarios DESC;

-- ---------------------------------------------------------
-- Q10. USUARIOS POR REGIÓN
-- ---------------------------------------------------------
SELECT
    region,
    COUNT(*) AS cantidad
FROM Usuario
GROUP BY region
ORDER BY cantidad DESC;

-- ---------------------------------------------------------
-- Q11. MUESTRA: 20 USUARIOS CON SUS PERFILES
-- ---------------------------------------------------------
SELECT
    u.id_usuario,
    u.correo,
    u.region,
    pl.nombre  AS plan,
    pf.id_perfil,
    pf.nombre  AS nombre_perfil,
    pf.foto
FROM Usuario u
JOIN Plan   pl ON pl.id_plan    = u.id_plan
JOIN Perfil pf ON pf.id_usuario = u.id_usuario
ORDER BY u.id_usuario
LIMIT 20;

-- ---------------------------------------------------------
-- Q12. MUESTRA: 15 DETALLES DE PAGO CON RENOVACIÓN
-- ---------------------------------------------------------
SELECT
    dp.id_detalles_pago,
    tp.nombre             AS tipo_pago,
    dp.numero_cuenta,
    fr.fecha              AS fecha_renovacion
FROM Detalles_Pago dp
JOIN Tipo_Pago tp             ON tp.id_tipo_pago     = dp.id_tipo_pago
LEFT JOIN Fecha_Renovacion fr ON fr.id_detalles_pago = dp.id_detalles_pago
ORDER BY dp.id_detalles_pago
LIMIT 15;

-- ---------------------------------------------------------
-- Q13. VISUALIZACIONES POR AÑO (verifica 4 años)
-- ---------------------------------------------------------
SELECT
    EXTRACT(YEAR FROM fecha)::INT AS anio,
    COUNT(*)                      AS total_visualizaciones
FROM Perfil_Ve_Contenido
GROUP BY EXTRACT(YEAR FROM fecha)
ORDER BY anio;

-- ---------------------------------------------------------
-- Q14. VISUALIZACIONES POR MES Y AÑO
-- ---------------------------------------------------------
SELECT
    EXTRACT(YEAR FROM fecha)::INT  AS anio,
    EXTRACT(MONTH FROM fecha)::INT AS mes,
    COUNT(*)                       AS visualizaciones
FROM Perfil_Ve_Contenido
GROUP BY EXTRACT(YEAR FROM fecha), EXTRACT(MONTH FROM fecha)
ORDER BY anio, mes;

-- ---------------------------------------------------------
-- Q15. TOP 10 CONTENIDOS MÁS VISTOS
-- ---------------------------------------------------------
SELECT
    pvc.id_contenido,
    CASE
        WHEN p.id_contenido IS NOT NULL THEN 'Película'
        WHEN s.id_contenido IS NOT NULL THEN 'Serie'
        ELSE 'Desconocido'
    END                                                    AS tipo,
    COALESCE(p.estudio_animacion, s.estudio_animacion)     AS estudio,
    COALESCE(p.clasificacion, '')                           AS clasificacion,
    COUNT(*)                                                AS veces_visto
FROM Perfil_Ve_Contenido pvc
LEFT JOIN Peliculas p ON p.id_contenido = pvc.id_contenido
LEFT JOIN Series    s ON s.id_contenido = pvc.id_contenido
GROUP BY pvc.id_contenido, p.id_contenido, s.id_contenido,
         p.estudio_animacion, s.estudio_animacion, p.clasificacion
ORDER BY veces_visto DESC
LIMIT 10;

-- ---------------------------------------------------------
-- Q16. DISTRIBUCIÓN DE PUNTAJES
-- ---------------------------------------------------------
SELECT
    puntaje,
    COUNT(*) AS cantidad
FROM Valoracion
GROUP BY puntaje
ORDER BY puntaje;

-- ---------------------------------------------------------
-- Q17. TOP 10 CONTENIDOS MEJOR VALORADOS (mínimo 50 votos)
-- ---------------------------------------------------------
SELECT
    v.id_contenido,
    CASE
        WHEN p.id_contenido IS NOT NULL THEN 'Película'
        WHEN s.id_contenido IS NOT NULL THEN 'Serie'
    END                                                AS tipo,
    COALESCE(p.estudio_animacion, s.estudio_animacion) AS estudio,
    ROUND(AVG(v.puntaje), 2)                           AS puntaje_promedio,
    COUNT(*)                                            AS total_valoraciones
FROM Valoracion v
LEFT JOIN Peliculas p ON p.id_contenido = v.id_contenido
LEFT JOIN Series    s ON s.id_contenido = v.id_contenido
GROUP BY v.id_contenido, p.id_contenido, s.id_contenido,
         p.estudio_animacion, s.estudio_animacion
HAVING COUNT(*) >= 50
ORDER BY puntaje_promedio DESC
LIMIT 10;

-- ---------------------------------------------------------
-- Q18. TOP 10 CONTENIDOS MÁS GUARDADOS EN LISTAS
-- ---------------------------------------------------------
SELECT
    lgc.id_contenido,
    CASE
        WHEN p.id_contenido IS NOT NULL THEN 'Película'
        WHEN s.id_contenido IS NOT NULL THEN 'Serie'
    END                                                AS tipo,
    COALESCE(p.estudio_animacion, s.estudio_animacion) AS estudio,
    COUNT(*)                                            AS veces_guardado
FROM Lista_Guarda_Contenido lgc
LEFT JOIN Peliculas p ON p.id_contenido = lgc.id_contenido
LEFT JOIN Series    s ON s.id_contenido = lgc.id_contenido
GROUP BY lgc.id_contenido, p.id_contenido, s.id_contenido,
         p.estudio_animacion, s.estudio_animacion
ORDER BY veces_guardado DESC
LIMIT 10;

-- ---------------------------------------------------------
-- Q19. HISTORIAL_CONTENIDO POR AÑO
-- ---------------------------------------------------------
SELECT
    EXTRACT(YEAR FROM fecha)::INT AS anio,
    COUNT(*)                      AS accesos
FROM Historial_Contenido
GROUP BY EXTRACT(YEAR FROM fecha)
ORDER BY anio;

-- ---------------------------------------------------------
-- Q20. MOTIVOS DE RECOMENDACIÓN
-- ---------------------------------------------------------
SELECT
    atribuye  AS motivo,
    COUNT(*)  AS cantidad
FROM Recomendaciones
GROUP BY atribuye
ORDER BY cantidad DESC;

-- ---------------------------------------------------------
-- Q21. VISUALIZACIONES POR DÍA DE LA SEMANA
-- ---------------------------------------------------------
SELECT
    CASE EXTRACT(DOW FROM fecha)::INT
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
    END                        AS dia_semana,
    COUNT(*)                   AS visualizaciones
FROM Perfil_Ve_Contenido
GROUP BY EXTRACT(DOW FROM fecha)
ORDER BY EXTRACT(DOW FROM fecha);

-- ---------------------------------------------------------
-- Q22. GÉNEROS MÁS POPULARES (por visualizaciones)
-- ---------------------------------------------------------
SELECT
    g.tipo   AS genero,
    COUNT(*) AS visualizaciones
FROM (
    SELECT pg.id_genero
    FROM Perfil_Ve_Contenido pvc
    JOIN Pelicula_Tiene_Genero pg ON pg.id_contenido = pvc.id_contenido
    UNION ALL
    SELECT sg.id_genero
    FROM Perfil_Ve_Contenido pvc
    JOIN Serie_Tiene_Genero sg ON sg.id_contenido = pvc.id_contenido
) sub
JOIN Generos g ON g.id_genero = sub.id_genero
GROUP BY g.tipo
ORDER BY visualizaciones DESC;

-- ---------------------------------------------------------
-- Q23. ESTUDIOS DE ANIMACIÓN MÁS VISTOS
-- ---------------------------------------------------------
SELECT
    estudio,
    COUNT(*) AS visualizaciones
FROM (
    SELECT p.estudio_animacion AS estudio
    FROM Perfil_Ve_Contenido pvc
    JOIN Peliculas p ON p.id_contenido = pvc.id_contenido
    UNION ALL
    SELECT s.estudio_animacion AS estudio
    FROM Perfil_Ve_Contenido pvc
    JOIN Series s ON s.id_contenido = pvc.id_contenido
) sub
WHERE estudio IS NOT NULL
GROUP BY estudio
ORDER BY visualizaciones DESC;

-- ---------------------------------------------------------
-- Q24. RANGO DE FECHAS (confirma 2022-2025)
-- ---------------------------------------------------------
SELECT
    'Perfil_Ve_Contenido'      AS tabla,
    MIN(fecha)::DATE           AS fecha_inicio,
    MAX(fecha)::DATE           AS fecha_fin,
    COUNT(*)                   AS total
FROM Perfil_Ve_Contenido
UNION ALL
SELECT
    'Historial_Contenido',
    MIN(fecha)::DATE,
    MAX(fecha)::DATE,
    COUNT(*)
FROM Historial_Contenido;

-- =========================================================
-- FIN DE CONSULTAS
-- =========================================================
