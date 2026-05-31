-- =========================================================
-- SCRIPT: DATOS SINTETICOS MASIVOS
-- Ajustado al esquema de create_tables.sql y a los diagramas.
-- Volumen esperado total: aprox. 300k a 380k filas.
-- PostgreSQL
-- =========================================================

-- Limpia los datos existentes para poder reejecutar este script sin duplicados.
-- Si cambiaste columnas en create_tables.sql, ejecuta create_tables.sql antes.
TRUNCATE TABLE
    Historial_Contenido,
    Perfil_Ve_Contenido,
    Lista_Guarda_Contenido,
    Serie_Tiene_Genero,
    Pelicula_Tiene_Genero,
    Plan_Tipo_Pago,
    Valoracion,
    Recomendaciones,
    Historial,
    Listas,
    Perfil,
    Fecha_Renovacion,
    Detalles_Pago,
    Usuario,
    Tipo_Pago,
    Plan,
    Episodios,
    Temporadas,
    Series,
    Peliculas,
    Generos,
    Contenido
RESTART IDENTITY CASCADE;

-- =========================================================
-- 1. CATALOGOS BASE
-- =========================================================

INSERT INTO Tipo_Pago (nombre) VALUES
    ('Tarjeta de Credito'),
    ('PayPal'),
    ('Tarjeta de Debito'),
    ('Google Play'),
    ('App Store');

INSERT INTO Plan (nombre, precio, tipo_plan) VALUES
    ('Fan',       4500.00, 1),
    ('Fan',      45900.00, 12),
    ('Mega Fan',  7500.00, 1),
    ('Mega Fan', 76500.00, 12),
    ('Ultimate', 11000.00, 1),
    ('Ultimate',112200.00, 12);

INSERT INTO Plan_Tipo_Pago (id_plan, id_tipo_pago)
SELECT p.id_plan, tp.id_tipo_pago
FROM Plan p
CROSS JOIN Tipo_Pago tp;

INSERT INTO Generos (tipo) VALUES
    ('Shonen'),
    ('Shojo'),
    ('Seinen'),
    ('Josei'),
    ('Isekai'),
    ('Mecha'),
    ('Slice of Life'),
    ('Terror'),
    ('Romance'),
    ('Aventura'),
    ('Deportivo'),
    ('Sobrenatural');

-- =========================================================
-- 2. CONTENIDO: 50 PELICULAS + 30 SERIES
-- =========================================================

DO $$
DECLARE
    v_contenido_id INT;
    v_temporada_id INT;
    v_peliculas TEXT[] := ARRAY[
        'Spirited Away',
        'Princess Mononoke',
        'My Neighbor Totoro',
        'Howl''s Moving Castle',
        'Castle in the Sky',
        'Nausicaa of the Valley of the Wind',
        'Kiki''s Delivery Service',
        'Porco Rosso',
        'Whisper of the Heart',
        'The Cat Returns',
        'The Wind Rises',
        'When Marnie Was There',
        'The Tale of Princess Kaguya',
        'Grave of the Fireflies',
        'Only Yesterday',
        'Pom Poko',
        'Arrietty',
        'From Up on Poppy Hill',
        'Tales from Earthsea',
        'The Red Turtle',
        'Your Name',
        'Weathering With You',
        'Suzume',
        'A Silent Voice',
        'The Garden of Words',
        '5 Centimeters per Second',
        'Children Who Chase Lost Voices',
        'Voices of a Distant Star',
        'The Place Promised in Our Early Days',
        'Belle',
        'Mirai',
        'Wolf Children',
        'The Girl Who Leapt Through Time',
        'Summer Wars',
        'The Boy and the Beast',
        'Paprika',
        'Perfect Blue',
        'Millennium Actress',
        'Tokyo Godfathers',
        'Akira',
        'Ghost in the Shell',
        'Jin-Roh: The Wolf Brigade',
        'Ninja Scroll',
        'Demon Slayer: Mugen Train',
        'Jujutsu Kaisen 0',
        'One Piece Film: Red',
        'Dragon Ball Super: Broly',
        'My Hero Academia: Heroes Rising',
        'Sword Art Online: Ordinal Scale',
        'Evangelion: 3.0+1.0 Thrice Upon a Time'
    ];
    v_duraciones INT[] := ARRAY[
        125, 134, 86, 119, 124, 117, 103, 94, 111, 75,
        126, 103, 137, 89, 119, 119, 94, 91, 115, 80,
        106, 112, 122, 130, 46, 63, 116, 25, 91, 121,
        98, 117, 98, 114, 119, 90, 81, 87, 92, 124,
        82, 102, 94, 117, 105, 115, 100, 104, 119, 155
    ];
    v_series TEXT[] := ARRAY[
        'Demon Slayer: Kimetsu no Yaiba',
        'Attack on Titan',
        'One Piece',
        'Naruto Shippuden',
        'Dragon Ball Z',
        'My Hero Academia',
        'Fullmetal Alchemist: Brotherhood',
        'Death Note',
        'Hunter x Hunter',
        'Sword Art Online',
        'Jujutsu Kaisen',
        'Black Clover',
        'Fairy Tail',
        'Bleach: Thousand-Year Blood War',
        'Tokyo Revengers',
        'Vinland Saga',
        'Spy x Family',
        'Chainsaw Man',
        'Mob Psycho 100',
        'One Punch Man',
        'Re:Zero - Starting Life in Another World',
        'That Time I Got Reincarnated as a Slime',
        'Overlord',
        'No Game No Life',
        'Violet Evergarden',
        'Your Lie in April',
        'Clannad',
        'Steins;Gate',
        'Neon Genesis Evangelion',
        'Cowboy Bebop'
    ];
    v_estudios TEXT[] := ARRAY[
        'Studio Ghibli',
        'Ufotable',
        'MAPPA',
        'Wit Studio',
        'Bones',
        'Madhouse',
        'Toei Animation',
        'Kyoto Animation',
        'CloverWorks',
        'A-1 Pictures',
        'Production I.G',
        'Trigger'
    ];
    v_clasificaciones TEXT[] := ARRAY[
        'Todo publico',
        'supervision parental',
        '12+',
        '14+',
        '16+',
        '18+'
    ];
    v_num_ep INT;
BEGIN
    FOR i IN 1..array_length(v_peliculas, 1) LOOP
        INSERT INTO Contenido (nombre, tipo_contenido, clasificacion)
        VALUES (
            v_peliculas[i],
            'pelicula',
            v_clasificaciones[((i - 1) % array_length(v_clasificaciones, 1)) + 1]
        )
        RETURNING id_contenido INTO v_contenido_id;

        INSERT INTO Peliculas (id_contenido, duracion, estudio_animacion)
        VALUES (
            v_contenido_id,
            v_duraciones[i],
            v_estudios[((i - 1) % array_length(v_estudios, 1)) + 1]
        );

        INSERT INTO Pelicula_Tiene_Genero (id_contenido, id_genero) VALUES
            (v_contenido_id, ((i - 1) % 12) + 1),
            (v_contenido_id, (i % 12) + 1),
            (v_contenido_id, ((i + 4) % 12) + 1)
        ON CONFLICT DO NOTHING;
    END LOOP;

    FOR i IN 1..array_length(v_series, 1) LOOP
        INSERT INTO Contenido (nombre, tipo_contenido, clasificacion)
        VALUES (
            v_series[i],
            'serie',
            v_clasificaciones[((i + 1) % array_length(v_clasificaciones, 1)) + 1]
        )
        RETURNING id_contenido INTO v_contenido_id;

        INSERT INTO Series (id_contenido, estudio_animacion, emision)
        VALUES (
            v_contenido_id,
            v_estudios[((i + 2) % array_length(v_estudios, 1)) + 1],
            i % 4 <> 0
        );

        INSERT INTO Serie_Tiene_Genero (id_contenido, id_genero) VALUES
            (v_contenido_id, ((i + 2) % 12) + 1),
            (v_contenido_id, ((i + 5) % 12) + 1),
            (v_contenido_id, ((i + 8) % 12) + 1)
        ON CONFLICT DO NOTHING;

        FOR t IN 1..3 LOOP
            v_num_ep := CASE
                WHEN t = 1 THEN 12
                WHEN t = 2 THEN 13
                ELSE 24
            END;

            INSERT INTO Temporadas (numero, cant_capitulos, id_contenido)
            VALUES (t, v_num_ep, v_contenido_id)
            RETURNING id_temporada INTO v_temporada_id;

            FOR e IN 1..v_num_ep LOOP
                INSERT INTO Episodios (titulo, duracion, id_temporada)
                VALUES ('Episodio ' || e, 22 + (e % 5), v_temporada_id);
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- =========================================================
-- 3. USUARIOS, PAGOS, PERFILES, LISTAS E HISTORIAL
--    4.000 usuarios x 2 perfiles = 8.000 perfiles
-- =========================================================

DO $$
DECLARE
    v_usuario_id       INT;
    v_perfil_id        INT;
    v_detalles_pago_id INT;
    v_plan_id          INT;
    v_tipo_plan        INT;
    v_fecha_pago       DATE;
    v_regiones TEXT[] := ARRAY[
        'Los Rios',
        'Los Lagos',
        'Araucania',
        'Metropolitana',
        'Valparaiso',
        'Biobio',
        'Coquimbo',
        'Maule',
        'Atacama',
        'Tarapaca',
        'Antofagasta',
        'Magallanes'
    ];
    v_nombres_perfil TEXT[] := ARRAY[
        'Otaku',
        'Admin',
        'Kids',
        'Invitado',
        'Senpai',
        'Familia',
        'Adultos',
        'Teens'
    ];
    v_fotos TEXT[] := ARRAY[
        'avatar_naruto.png',
        'avatar_luffy.png',
        'avatar_goku.png',
        'avatar_tanjiro.png',
        'avatar_totoro.png',
        'avatar_gojo.png',
        'avatar_levi.png',
        'avatar_default.png'
    ];
    v_restricciones TEXT[] := ARRAY[
        'Todo publico',
        'supervision parental',
        '12+',
        '14+',
        '16+',
        '18+'
    ];
BEGIN
    FOR i IN 1..4000 LOOP
        SELECT id_plan, tipo_plan
        INTO v_plan_id, v_tipo_plan
        FROM Plan
        ORDER BY random()
        LIMIT 1;

        INSERT INTO Usuario (correo, contrasena, region, id_plan)
        VALUES (
            'usuario_' || i || '@correo.com',
            md5('password' || i),
            v_regiones[((i - 1) % array_length(v_regiones, 1)) + 1],
            v_plan_id
        )
        RETURNING id_usuario INTO v_usuario_id;

        v_fecha_pago := CURRENT_DATE - (((i % 30) + 1) || ' days')::INTERVAL;

        INSERT INTO Detalles_Pago (numero_cuenta, fecha_pago, id_tipo_pago, id_usuario)
        VALUES (
            'XXXX-XXXX-XXXX-' || lpad(i::TEXT, 4, '0'),
            v_fecha_pago,
            ((i - 1) % 5) + 1,
            v_usuario_id
        )
        RETURNING id_detalles_pago INTO v_detalles_pago_id;

        INSERT INTO Fecha_Renovacion (fecha, id_detalles_pago)
        VALUES (
            CASE
                WHEN v_tipo_plan = 12 THEN v_fecha_pago + INTERVAL '12 months'
                ELSE v_fecha_pago + INTERVAL '1 month'
            END,
            v_detalles_pago_id
        );

        INSERT INTO Listas (nombre_lista, id_usuario) VALUES
            ('Favoritos', v_usuario_id),
            ('Pendientes', v_usuario_id);

        FOR p IN 1..2 LOOP
            INSERT INTO Perfil (nombre, foto, restriccion, id_usuario)
            VALUES (
                v_nombres_perfil[((i + p - 2) % array_length(v_nombres_perfil, 1)) + 1] || '_' || p,
                v_fotos[((i + p - 2) % array_length(v_fotos, 1)) + 1],
                v_restricciones[((i + p - 2) % array_length(v_restricciones, 1)) + 1],
                v_usuario_id
            )
            RETURNING id_perfil INTO v_perfil_id;

            INSERT INTO Historial (id_perfil)
            VALUES (v_perfil_id);
        END LOOP;
    END LOOP;
END $$;

-- =========================================================
-- 4. VISUALIZACIONES MASIVAS
--    180.000 filas en Perfil_Ve_Contenido
-- =========================================================

INSERT INTO Perfil_Ve_Contenido (id_perfil, id_contenido, fecha)
SELECT
    (floor(random() * 8000) + 1)::INT AS id_perfil,
    (floor(random() * 80) + 1)::INT AS id_contenido,
    DATE '2024-01-01'
        + ((floor(random() * 730)) || ' days')::INTERVAL
        + ((floor(random() * 24)) || ' hours')::INTERVAL
        + ((floor(random() * 60)) || ' minutes')::INTERVAL AS fecha
FROM generate_series(1, 180000);

-- =========================================================
-- 5. VALORACIONES
--    Hasta 45.000 combinaciones perfil/contenido.
-- =========================================================

INSERT INTO Valoracion (puntaje, id_perfil, id_contenido)
SELECT
    (floor(random() * 10) + 1)::NUMERIC AS puntaje,
    id_perfil,
    id_contenido
FROM (
    SELECT DISTINCT
        (floor(random() * 8000) + 1)::INT AS id_perfil,
        (floor(random() * 80) + 1)::INT AS id_contenido
    FROM generate_series(1, 55000)
) datos
LIMIT 45000
ON CONFLICT (id_perfil, id_contenido) DO NOTHING;

-- =========================================================
-- 6. CONTENIDO GUARDADO EN LISTAS
--    Hasta 35.000 combinaciones lista/contenido.
-- =========================================================

INSERT INTO Lista_Guarda_Contenido (id_lista, id_contenido)
SELECT id_lista, id_contenido
FROM (
    SELECT DISTINCT
        (floor(random() * 8000) + 1)::INT AS id_lista,
        (floor(random() * 80) + 1)::INT AS id_contenido
    FROM generate_series(1, 45000)
) datos
LIMIT 35000
ON CONFLICT DO NOTHING;

-- =========================================================
-- 7. HISTORIAL DE CONTENIDO
--    70.000 filas con duracion y segundos reproducidos.
-- =========================================================

INSERT INTO Historial_Contenido (
    id_historial,
    id_contenido,
    nombre,
    duracion,
    segundos_reproduccion,
    fecha
)
SELECT
    (floor(random() * 8000) + 1)::INT AS id_historial,
    c.id_contenido,
    c.nombre,
    COALESCE(p.duracion, 24) AS duracion,
    floor(random() * (COALESCE(p.duracion, 24) * 60 + 1))::INT AS segundos_reproduccion,
    DATE '2024-01-01'
        + ((floor(random() * 730)) || ' days')::INTERVAL
        + ((floor(random() * 24)) || ' hours')::INTERVAL
        + ((floor(random() * 60)) || ' minutes')::INTERVAL AS fecha
FROM generate_series(1, 70000) AS gs(n)
JOIN Contenido c ON c.id_contenido = ((gs.n * 37) % 80) + 1
LEFT JOIN Peliculas p ON p.id_contenido = c.id_contenido;

-- =========================================================
-- 8. RECOMENDACIONES
--    3 recomendaciones por historial = 24.000 filas.
-- =========================================================

INSERT INTO Recomendaciones (atribuye, id_historial)
SELECT
    CASE (gs.n % 6)
        WHEN 0 THEN 'Basado en tu historial de visualizacion'
        WHEN 1 THEN 'Usuarios similares tambien vieron contenido de este tipo'
        WHEN 2 THEN 'Popular en tu region'
        WHEN 3 THEN 'Tendencia esta semana'
        WHEN 4 THEN 'Porque viste contenido del mismo genero'
        ELSE 'Top valorado por la comunidad'
    END AS atribuye,
    h.id_historial
FROM Historial h
CROSS JOIN generate_series(1, 3) AS gs(n);

-- =========================================================
-- 9. VERIFICACION FINAL
-- =========================================================

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

SELECT
    SUM(registros) AS total_filas_estimadas
FROM (
    SELECT COUNT(*) AS registros FROM Tipo_Pago
    UNION ALL SELECT COUNT(*) FROM Plan
    UNION ALL SELECT COUNT(*) FROM Plan_Tipo_Pago
    UNION ALL SELECT COUNT(*) FROM Usuario
    UNION ALL SELECT COUNT(*) FROM Detalles_Pago
    UNION ALL SELECT COUNT(*) FROM Fecha_Renovacion
    UNION ALL SELECT COUNT(*) FROM Perfil
    UNION ALL SELECT COUNT(*) FROM Historial
    UNION ALL SELECT COUNT(*) FROM Listas
    UNION ALL SELECT COUNT(*) FROM Contenido
    UNION ALL SELECT COUNT(*) FROM Peliculas
    UNION ALL SELECT COUNT(*) FROM Series
    UNION ALL SELECT COUNT(*) FROM Temporadas
    UNION ALL SELECT COUNT(*) FROM Episodios
    UNION ALL SELECT COUNT(*) FROM Generos
    UNION ALL SELECT COUNT(*) FROM Valoracion
    UNION ALL SELECT COUNT(*) FROM Recomendaciones
    UNION ALL SELECT COUNT(*) FROM Perfil_Ve_Contenido
    UNION ALL SELECT COUNT(*) FROM Lista_Guarda_Contenido
    UNION ALL SELECT COUNT(*) FROM Pelicula_Tiene_Genero
    UNION ALL SELECT COUNT(*) FROM Serie_Tiene_Genero
    UNION ALL SELECT COUNT(*) FROM Historial_Contenido
) total;

-- Consulta util para revisar persona + plan + mensual/anual + medio de pago.
SELECT
    u.correo,
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

-- =========================================================
-- FIN DEL SCRIPT
-- =========================================================
