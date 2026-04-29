-- =========================================================
-- SCRIPT 2: DATOS SINTÉTICOS - CRUNCHYROLL (Anime)
-- Ajustado al nuevo esquema (01_create_tables.sql)
-- · 50 películas anime + 30 series anime
-- · Géneros reales de anime
-- · Planes reales de Crunchyroll
-- · 4 años de datos transaccionales: 2022-01-01 → 2025-12-31
-- · Volumen estimado: 200k–400k filas únicas finales
-- =========================================================

-- =========================================================
-- 1. CATÁLOGOS BASE
-- =========================================================

-- Tipo_Pago (id_tipo_pago será 1..4)
INSERT INTO Tipo_Pago (nombre) VALUES
    ('Tarjeta de Crédito'),
    ('PayPal'),
    ('Tarjeta de Débito'),
    ('Transferencia Bancaria');

-- Planes reales de Crunchyroll (id_plan será 1..3)
INSERT INTO Plan (nombre, precio) VALUES
    ('Fan',      4500.00),
    ('Mega Fan', 7500.00),
    ('Ultimate', 11000.00);

-- Relación N:M → Plan_Tipo_Pago (todos los planes aceptan todos los tipos de pago)
INSERT INTO Plan_Tipo_Pago (id_plan, id_tipo_pago) VALUES
    (1, 1), (1, 2), (1, 3), (1, 4),
    (2, 1), (2, 2), (2, 3), (2, 4),
    (3, 1), (3, 2), (3, 3), (3, 4);

-- Géneros reales del mundo anime (id_genero será 1..12)
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
-- 2. CONTENIDO: 50 películas anime + 30 series anime
--    Contenido solo tiene id_contenido (supertipo)
--    Peliculas hereda: estudio_animacion, clasificacion
--    Series hereda: estudio_animacion, emision_sitio
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
        'Nausicaä of the Valley of the Wind',
        'The Tale of Princess Kaguya',
        'Grave of the Fireflies',
        'Only Yesterday',
        'Pom Poko',
        'Whisper of the Heart',
        'The Cat Returns',
        'Porco Rosso',
        'Kiki''s Delivery Service',
        'When Marnie Was There',
        'The Wind Rises',
        'Arrietty',
        'From Up on Poppy Hill',
        'Tales from Earthsea',
        'The Red Turtle',
        'Your Name',
        'A Silent Voice',
        'The Garden of Words',
        'Children Who Chase Lost Voices',
        'Voices of a Distant Star',
        '5 Centimeters per Second',
        'The Place Promised in Our Early Days',
        'Weathering With You',
        'Suzume',
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
        'Dragon Ball Super: Broly',
        'One Piece Film: Red',
        'Jujutsu Kaisen 0',
        'My Hero Academia: Heroes Rising',
        'Sword Art Online: Ordinal Scale',
        'Evangelion: 3.0+1.0 Thrice Upon a Time'
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
        'Re:Zero − Starting Life in Another World',
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
        'Sunrise',
        'Kyoto Animation',
        'CloverWorks',
        'A-1 Pictures',
        'Production I.G'
    ];

    v_sitios_emision TEXT[] := ARRAY[
        'Crunchyroll',
        'Funimation',
        'Netflix',
        'Amazon Prime Video',
        'Disney+',
        'HBO Max',
        'Hulu',
        'TV Tokyo',
        'NHK',
        'Fuji TV'
    ];

    v_num_temp INT;
    v_num_ep   INT;
BEGIN
    -- =============================================
    -- 50 PELÍCULAS ANIME
    -- =============================================
    FOR i IN 1..50 LOOP
        -- Insertar supertipo (Contenido solo tiene PK)
        INSERT INTO Contenido DEFAULT VALUES
        RETURNING id_contenido INTO v_contenido_id;

        -- Insertar subtipo Peliculas con estudio_animacion y clasificacion
        INSERT INTO Peliculas (id_contenido, estudio_animacion, clasificacion)
        VALUES (
            v_contenido_id,
            v_estudios[floor(random()*12)+1],
            (ARRAY['PG-13', '+18', 'Apto Todo Público'])[floor(random()*3)+1]
        );

        -- 2 géneros por película
        INSERT INTO Pelicula_Tiene_Genero (id_contenido, id_genero)
        VALUES (v_contenido_id, floor(random()*12)+1)
        ON CONFLICT DO NOTHING;

        INSERT INTO Pelicula_Tiene_Genero (id_contenido, id_genero)
        VALUES (v_contenido_id, floor(random()*12)+1)
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- =============================================
    -- 30 SERIES ANIME con temporadas y episodios
    -- =============================================
    FOR i IN 1..30 LOOP
        -- Insertar supertipo
        INSERT INTO Contenido DEFAULT VALUES
        RETURNING id_contenido INTO v_contenido_id;

        -- Insertar subtipo Series con estudio_animacion y emision_sitio
        INSERT INTO Series (id_contenido, estudio_animacion, emision_sitio)
        VALUES (
            v_contenido_id,
            v_estudios[floor(random()*12)+1],
            v_sitios_emision[floor(random()*10)+1]
        );

        -- 2 géneros por serie
        INSERT INTO Serie_Tiene_Genero (id_contenido, id_genero)
        VALUES (v_contenido_id, floor(random()*12)+1)
        ON CONFLICT DO NOTHING;

        INSERT INTO Serie_Tiene_Genero (id_contenido, id_genero)
        VALUES (v_contenido_id, floor(random()*12)+1)
        ON CONFLICT DO NOTHING;

        -- Entre 2 y 5 temporadas por serie
        v_num_temp := floor(random()*4)+2;
        FOR t IN 1..v_num_temp LOOP
            -- Episodios estándar anime: 12, 13, 24, 25 o 26
            v_num_ep := (ARRAY[12, 13, 24, 25, 26])[floor(random()*5)+1];

            INSERT INTO Temporadas (numero, cant_capitulos, id_contenido)
            VALUES (t, v_num_ep, v_contenido_id)
            RETURNING id_temporada INTO v_temporada_id;

            FOR e IN 1..v_num_ep LOOP
                INSERT INTO Episodios (titulo, duracion, id_temporada)
                VALUES (
                    'Episodio ' || e,
                    24,  -- duración estándar anime TV en minutos
                    v_temporada_id
                );
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- =========================================================
-- 3. USUARIOS, PERFILES, LISTAS E HISTORIAL
--    10.000 usuarios × 2 perfiles = 20.000 perfiles
--    Listas ahora pertenecen a Usuario (id_usuario)
--    Perfil ahora tiene campo foto
-- =========================================================
DO $$
DECLARE
    v_usuario_id       INT;
    v_perfil_id        INT;
    v_historial_id     INT;
    v_detalles_pago_id INT;

    v_regiones TEXT[] := ARRAY[
        'Los Ríos', 'Los Lagos', 'Araucanía', 'Metropolitana',
        'Valparaíso', 'Biobío', 'Coquimbo', 'Maule', 'Atacama'
    ];
    v_nombres_perfil TEXT[] := ARRAY[
        'Otaku', 'Admin', 'Kids', 'Invitado', 'Senpai', 'Familia', 'Adultos', 'Teens'
    ];
    v_fotos TEXT[] := ARRAY[
        'avatar_naruto.png',
        'avatar_luffy.png',
        'avatar_goku.png',
        'avatar_tanjiro.png',
        'avatar_totoro.png',
        'avatar_gojo.png',
        'avatar_levi.png',
        'avatar_mikasa.png',
        'avatar_default.png',
        NULL
    ];
BEGIN
    FOR i IN 1..10000 LOOP
        -- Detalles de pago (FK a Tipo_Pago via id_tipo_pago)
        INSERT INTO Detalles_Pago (numero_cuenta, id_tipo_pago)
        VALUES (
            'XXXX-XXXX-XXXX-' || (floor(random()*9000)+1000)::TEXT,
            floor(random()*4)+1
        ) RETURNING id_detalles_pago INTO v_detalles_pago_id;

        -- Fecha de renovación (FK a Detalles_Pago via id_detalles_pago)
        INSERT INTO Fecha_Renovacion (fecha, id_detalles_pago)
        VALUES (
            CURRENT_DATE + (floor(random()*365) || ' days')::INTERVAL,
            v_detalles_pago_id
        );

        -- Usuario (correo, contrasena, region, id_plan)
        INSERT INTO Usuario (correo, contrasena, region, id_plan)
        VALUES (
            'usuario_' || i || '@correo.com',
            md5('password' || i),
            v_regiones[floor(random()*9)+1],
            floor(random()*3)+1
        ) RETURNING id_usuario INTO v_usuario_id;

        -- 2 listas por usuario (Listas referencia id_usuario, sin nombre)
        INSERT INTO Listas (id_usuario) VALUES (v_usuario_id);
        INSERT INTO Listas (id_usuario) VALUES (v_usuario_id);

        -- 2 perfiles por usuario (con foto)
        FOR p IN 1..2 LOOP
            INSERT INTO Perfil (nombre, foto, id_usuario)
            VALUES (
                v_nombres_perfil[floor(random()*8)+1] || '_' || p,
                v_fotos[floor(random()*10)+1],
                v_usuario_id
            ) RETURNING id_perfil INTO v_perfil_id;

            -- Historial 1:1 con Perfil
            INSERT INTO Historial (id_perfil)
            VALUES (v_perfil_id)
            RETURNING id_historial INTO v_historial_id;
        END LOOP;
    END LOOP;
END $$;

-- =========================================================
-- 4. DATOS TRANSACCIONALES MASIVOS: 4 AÑOS (2022–2025)
--
--  Por día:
--    A) 200–700 visualizaciones  → Perfil_Ve_Contenido
--    B) 15% → Valoracion (puntaje 1–10)
--    C) 10% → Lista_Guarda_Contenido
--    D) 8%  → Historial_Contenido (accede)
--
--  Estimado: ~200k–400k filas únicas finales
-- =========================================================
DO $$
DECLARE
    v_fecha              DATE;
    v_vistas_dia         INT;
    v_perfil_random      INT;
    v_contenido_random   INT;
    v_lista_random       INT;
    v_historial_random   INT;
    v_total_contenidos   INT;
    v_total_perfiles     INT;
    v_total_listas       INT;
    v_total_historiales  INT;
BEGIN
    -- Cachear totales para no hacer COUNT en cada iteración
    SELECT COUNT(*) INTO v_total_contenidos  FROM Contenido;
    SELECT COUNT(*) INTO v_total_perfiles    FROM Perfil;
    SELECT COUNT(*) INTO v_total_listas      FROM Listas;
    SELECT COUNT(*) INTO v_total_historiales FROM Historial;

    FOR v_fecha IN
        SELECT generate_series(
            '2022-01-01'::DATE,
            '2025-12-31'::DATE,
            '1 day'::INTERVAL
        )::DATE
    LOOP
        -- Fines de semana tienen más actividad (realismo)
        IF EXTRACT(DOW FROM v_fecha) IN (0, 6) THEN
            v_vistas_dia := floor(random()*400)+400;   -- 400–800
        ELSE
            v_vistas_dia := floor(random()*300)+200;   -- 200–500
        END IF;

        FOR i IN 1..v_vistas_dia LOOP
            v_perfil_random    := floor(random()*v_total_perfiles)+1;
            v_contenido_random := floor(random()*v_total_contenidos)+1;

            -- A) Visualización (upsert: actualiza la última fecha vista)
            INSERT INTO Perfil_Ve_Contenido (id_perfil, id_contenido, fecha)
            VALUES (
                v_perfil_random,
                v_contenido_random,
                v_fecha + (random() * INTERVAL '23 hours')
            )
            ON CONFLICT (id_perfil, id_contenido)
            DO UPDATE SET fecha = EXCLUDED.fecha;

            -- B) 15% de probabilidad: valorar (puntaje 1–10)
            IF random() < 0.15 THEN
                INSERT INTO Valoracion (puntaje, id_perfil, id_contenido)
                VALUES (
                    (floor(random()*10)+1)::NUMERIC,
                    v_perfil_random,
                    v_contenido_random
                )
                ON CONFLICT (id_perfil, id_contenido) DO NOTHING;
            END IF;

            -- C) 10% de probabilidad: guardar en lista
            IF random() < 0.10 THEN
                v_lista_random := floor(random()*v_total_listas)+1;
                INSERT INTO Lista_Guarda_Contenido (id_lista, id_contenido)
                VALUES (v_lista_random, v_contenido_random)
                ON CONFLICT DO NOTHING;
            END IF;

            -- D) 8% de probabilidad: registrar en historial_contenido (Accede)
            IF random() < 0.08 THEN
                v_historial_random := floor(random()*v_total_historiales)+1;
                INSERT INTO Historial_Contenido (id_historial, id_contenido, fecha)
                VALUES (
                    v_historial_random,
                    v_contenido_random,
                    v_fecha + (random() * INTERVAL '23 hours')
                )
                ON CONFLICT (id_historial, id_contenido)
                DO UPDATE SET fecha = EXCLUDED.fecha;
            END IF;

        END LOOP;
    END LOOP;
END $$;

-- =========================================================
-- 5. RECOMENDACIONES
--    ~3 recomendaciones por perfil basadas en contenidos
--    más vistos globalmente en la plataforma
--    Campo atribuye = motivo de la recomendación
-- =========================================================
DO $$
DECLARE
    v_perfil_id      INT;
    v_historial_id   INT;
    v_contenido_id   INT;
    v_top_contenidos INT[];
    v_motivos TEXT[] := ARRAY[
        'Basado en tu historial de visualización',
        'Usuarios similares también vieron',
        'Popular en tu región',
        'Tendencia esta semana',
        'Porque viste contenido del mismo género',
        'Recomendado por tu puntaje a contenidos similares',
        'Nuevo lanzamiento que te podría gustar',
        'Top valorado por la comunidad'
    ];
BEGIN
    -- Top 20 contenidos más vistos globalmente
    SELECT ARRAY(
        SELECT id_contenido
        FROM Perfil_Ve_Contenido
        GROUP BY id_contenido
        ORDER BY COUNT(*) DESC
        LIMIT 20
    ) INTO v_top_contenidos;

    -- Para cada perfil insertar hasta 3 recomendaciones
    FOR v_perfil_id, v_historial_id IN
        SELECT p.id_perfil, h.id_historial
        FROM Perfil p
        JOIN Historial h ON h.id_perfil = p.id_perfil
    LOOP
        FOR j IN 1..3 LOOP
            v_contenido_id := v_top_contenidos[floor(random()*20)+1];

            INSERT INTO Recomendaciones (atribuye, id_historial)
            VALUES (
                v_motivos[floor(random()*8)+1],
                v_historial_id
            );
        END LOOP;
    END LOOP;
END $$;

-- =========================================================
-- 6. VERIFICACIÓN FINAL DE VOLUMEN
-- =========================================================
SELECT tabla, registros FROM (
    SELECT 'Tipo_Pago'                    AS tabla, COUNT(*) AS registros FROM Tipo_Pago
    UNION ALL SELECT 'Plan',                        COUNT(*) FROM Plan
    UNION ALL SELECT 'Plan_Tipo_Pago',              COUNT(*) FROM Plan_Tipo_Pago
    UNION ALL SELECT 'Detalles_Pago',               COUNT(*) FROM Detalles_Pago
    UNION ALL SELECT 'Fecha_Renovacion',            COUNT(*) FROM Fecha_Renovacion
    UNION ALL SELECT 'Usuario',                     COUNT(*) FROM Usuario
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
