-- =========================================================
-- SCRIPT: CONSULTAS SELECT
-- Compatible con create_tables.sql e insert_db.sql actuales.
-- =========================================================

-- ---------------------------------------------------------
-- Q1. RESUMEN GENERAL DE VOLUMEN
-- ---------------------------------------------------------
SELECT tabla, registros FROM (
    SELECT 'Tipo_Pago'                    AS tabla, COUNT(*) AS registros FROM Tipo_Pago
    UNION ALL SELECT 'Plan',                        COUNT(*) FROM Plan
    UNION ALL SELECT 'Plan_Tipo_Pago',              COUNT(*) FROM Plan_Tipo_Pago
    UNION ALL SELECT 'Usuario',                     COUNT(*) FROM Usuario
    UNION ALL SELECT 'Detalles_Pago',               COUNT(*) FROM Detalles_Pago
    UNION ALL SELECT 'Fecha_Renovacion',            COUNT(*) FROM Fecha_Renovacion
    UNION ALL SELECT 'Perfil',                      COUNT(*) FROM Perfil
    UNION ALL SELECT 'Historial',                   COUNT(*) FROM Historial
    UNION ALL SELECT 'Listas',                      COUNT(*) FROM Listas
    UNION ALL SELECT 'Contenido',                   COUNT(*) FROM Contenido
    UNION ALL SELECT 'Peliculas',                   COUNT(*) FROM Peliculas
    UNION ALL SELECT 'Series',                      COUNT(*) FROM Series
    UNION ALL SELECT 'Temporadas',                  COUNT(*) FROM Temporadas
    UNION ALL SELECT 'Episodios',                   COUNT(*) FROM Episodios
    UNION ALL SELECT 'Generos',                     COUNT(*) FROM Generos
    UNION ALL SELECT 'Valoracion',                  COUNT(*) FROM Valoracion
    UNION ALL SELECT 'Recomendaciones',             COUNT(*) FROM Recomendaciones
    UNION ALL SELECT 'Perfil_Ve_Contenido',         COUNT(*) FROM Perfil_Ve_Contenido
    UNION ALL SELECT 'Lista_Guarda_Contenido',      COUNT(*) FROM Lista_Guarda_Contenido
    UNION ALL SELECT 'Pelicula_Tiene_Genero',       COUNT(*) FROM Pelicula_Tiene_Genero
    UNION ALL SELECT 'Serie_Tiene_Genero',          COUNT(*) FROM Serie_Tiene_Genero
    UNION ALL SELECT 'Historial_Contenido',         COUNT(*) FROM Historial_Contenido
) t
ORDER BY registros DESC;

-- ---------------------------------------------------------
-- Q2. PLANES MENSUALES Y ANUALES
-- ---------------------------------------------------------
SELECT
    id_plan,
    nombre,
    precio,
    CASE tipo_plan WHEN 1 THEN 'mensual' WHEN 12 THEN 'anual' END AS tipo_plan
FROM Plan
ORDER BY nombre, tipo_plan;

-- ---------------------------------------------------------
-- Q3. USUARIO + PLAN + MEDIO DE PAGO + RENOVACION
-- ---------------------------------------------------------
SELECT
    u.id_usuario,
    u.correo,
    u.region,
    p.nombre AS plan,
    CASE p.tipo_plan WHEN 1 THEN 'mensual' WHEN 12 THEN 'anual' END AS tipo_plan,
    tp.nombre AS tipo_pago,
    dp.numero_cuenta,
    dp.fecha_pago,
    fr.fecha AS fecha_renovacion
FROM Usuario u
JOIN Plan p ON p.id_plan = u.id_plan
JOIN Detalles_Pago dp ON dp.id_usuario = u.id_usuario
JOIN Tipo_Pago tp ON tp.id_tipo_pago = dp.id_tipo_pago
JOIN Fecha_Renovacion fr ON fr.id_detalles_pago = dp.id_detalles_pago
ORDER BY u.id_usuario
LIMIT 20;

-- ---------------------------------------------------------
-- Q4. PLANES Y TIPOS DE PAGO DISPONIBLES
-- ---------------------------------------------------------
SELECT
    p.nombre AS plan,
    CASE p.tipo_plan WHEN 1 THEN 'mensual' WHEN 12 THEN 'anual' END AS tipo_plan,
    tp.nombre AS tipo_pago
FROM Plan_Tipo_Pago pt
JOIN Plan p ON p.id_plan = pt.id_plan
JOIN Tipo_Pago tp ON tp.id_tipo_pago = pt.id_tipo_pago
ORDER BY p.nombre, p.tipo_plan, tp.nombre;

-- ---------------------------------------------------------
-- Q5. CONTENIDO GENERAL
-- ---------------------------------------------------------
SELECT
    id_contenido,
    nombre,
    tipo_contenido,
    clasificacion
FROM Contenido
ORDER BY tipo_contenido, nombre;

-- ---------------------------------------------------------
-- Q6. PELICULAS CON GENEROS
-- ---------------------------------------------------------
SELECT
    c.id_contenido,
    c.nombre,
    c.clasificacion,
    p.duracion,
    p.estudio_animacion,
    STRING_AGG(g.tipo, ', ' ORDER BY g.tipo) AS generos
FROM Contenido c
JOIN Peliculas p ON p.id_contenido = c.id_contenido
LEFT JOIN Pelicula_Tiene_Genero pg ON pg.id_contenido = p.id_contenido
LEFT JOIN Generos g ON g.id_genero = pg.id_genero
GROUP BY c.id_contenido, c.nombre, c.clasificacion, p.duracion, p.estudio_animacion
ORDER BY c.nombre;

-- ---------------------------------------------------------
-- Q7. SERIES CON TEMPORADAS Y CAPITULOS
-- ---------------------------------------------------------
SELECT
    c.id_contenido,
    c.nombre,
    c.clasificacion,
    s.estudio_animacion,
    CASE WHEN s.emision THEN 'en emision' ELSE 'finalizada' END AS estado_emision,
    STRING_AGG(DISTINCT g.tipo, ', ' ORDER BY g.tipo) AS generos,
    COUNT(DISTINCT t.id_temporada) AS total_temporadas,
    COALESCE(SUM(t.cant_capitulos), 0) AS total_capitulos
FROM Contenido c
JOIN Series s ON s.id_contenido = c.id_contenido
LEFT JOIN Serie_Tiene_Genero sg ON sg.id_contenido = s.id_contenido
LEFT JOIN Generos g ON g.id_genero = sg.id_genero
LEFT JOIN Temporadas t ON t.id_contenido = s.id_contenido
GROUP BY c.id_contenido, c.nombre, c.clasificacion, s.estudio_animacion, s.emision
ORDER BY c.nombre;

-- ---------------------------------------------------------
-- Q8. PERFILES CON RESTRICCION
-- ---------------------------------------------------------
SELECT
    u.correo,
    pf.id_perfil,
    pf.nombre AS perfil,
    pf.restriccion,
    pf.foto
FROM Usuario u
JOIN Perfil pf ON pf.id_usuario = u.id_usuario
ORDER BY u.id_usuario, pf.id_perfil
LIMIT 30;

-- ---------------------------------------------------------
-- Q9. LISTAS DE USUARIO
-- ---------------------------------------------------------
SELECT
    u.correo,
    l.id_lista,
    l.nombre_lista,
    COUNT(lgc.id_contenido) AS contenidos_guardados
FROM Usuario u
JOIN Listas l ON l.id_usuario = u.id_usuario
LEFT JOIN Lista_Guarda_Contenido lgc ON lgc.id_lista = l.id_lista
GROUP BY u.correo, l.id_lista, l.nombre_lista
ORDER BY u.correo, l.nombre_lista
LIMIT 30;

-- ---------------------------------------------------------
-- Q10. TOP 10 CONTENIDOS MAS VISTOS
-- ---------------------------------------------------------
SELECT
    c.id_contenido,
    c.nombre,
    c.tipo_contenido,
    c.clasificacion,
    COUNT(*) AS veces_visto
FROM Perfil_Ve_Contenido pvc
JOIN Contenido c ON c.id_contenido = pvc.id_contenido
GROUP BY c.id_contenido, c.nombre, c.tipo_contenido, c.clasificacion
ORDER BY veces_visto DESC
LIMIT 10;

-- ---------------------------------------------------------
-- Q11. TOP 10 CONTENIDOS MEJOR VALORADOS
-- ---------------------------------------------------------
SELECT
    c.id_contenido,
    c.nombre,
    c.tipo_contenido,
    ROUND(AVG(v.puntaje), 2) AS puntaje_promedio,
    COUNT(*) AS total_valoraciones
FROM Valoracion v
JOIN Contenido c ON c.id_contenido = v.id_contenido
GROUP BY c.id_contenido, c.nombre, c.tipo_contenido
ORDER BY puntaje_promedio DESC, total_valoraciones DESC
LIMIT 10;

-- ---------------------------------------------------------
-- Q12. HISTORIAL CON SEGUNDOS REPRODUCIDOS
-- ---------------------------------------------------------
SELECT
    pf.nombre AS perfil,
    hc.nombre AS contenido,
    hc.duracion,
    hc.segundos_reproduccion,
    ROUND((hc.segundos_reproduccion::NUMERIC / (hc.duracion * 60)) * 100, 2) AS porcentaje_visto,
    hc.fecha
FROM Historial_Contenido hc
JOIN Historial h ON h.id_historial = hc.id_historial
JOIN Perfil pf ON pf.id_perfil = h.id_perfil
ORDER BY hc.fecha DESC
LIMIT 30;

-- ---------------------------------------------------------
-- Q13. GENEROS MAS POPULARES POR VISUALIZACIONES
-- ---------------------------------------------------------
SELECT
    g.tipo AS genero,
    COUNT(*) AS visualizaciones
FROM (
    SELECT pvc.id_visualizacion, pg.id_genero
    FROM Perfil_Ve_Contenido pvc
    JOIN Pelicula_Tiene_Genero pg ON pg.id_contenido = pvc.id_contenido
    UNION ALL
    SELECT pvc.id_visualizacion, sg.id_genero
    FROM Perfil_Ve_Contenido pvc
    JOIN Serie_Tiene_Genero sg ON sg.id_contenido = pvc.id_contenido
) sub
JOIN Generos g ON g.id_genero = sub.id_genero
GROUP BY g.tipo
ORDER BY visualizaciones DESC;

-- ---------------------------------------------------------
-- Q14. VISUALIZACIONES POR MES
-- ---------------------------------------------------------
SELECT
    EXTRACT(YEAR FROM fecha)::INT AS anio,
    EXTRACT(MONTH FROM fecha)::INT AS mes,
    COUNT(*) AS visualizaciones
FROM Perfil_Ve_Contenido
GROUP BY EXTRACT(YEAR FROM fecha), EXTRACT(MONTH FROM fecha)
ORDER BY anio, mes;

-- ---------------------------------------------------------
-- Q15. MOTIVOS DE RECOMENDACION
-- ---------------------------------------------------------
SELECT
    atribuye AS motivo,
    COUNT(*) AS cantidad
FROM Recomendaciones
GROUP BY atribuye
ORDER BY cantidad DESC;

-- =========================================================
-- FIN DE CONSULTAS
-- =========================================================
