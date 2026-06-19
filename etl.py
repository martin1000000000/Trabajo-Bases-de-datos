"""
ETL - Sistema Crunchyroll
Extrae datos desde la BD transaccional (cru)
y los carga en la BD analitica (cru_olap).

Proceso:
  1. dim_tiempo      <- fechas presentes en los datos
  2. dim_usuario     <- usuarios + plan
  3. dim_contenido   <- contenidos + generos
  4. dim_perfil      <- perfiles vinculados a dim_usuario
  5. fact_visualizaciones <- historial de reproduccion
  6. fact_pagos      <- pagos y renovaciones
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import os
import sys
import io
from datetime import date, timedelta

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# ─── Conexiones ───────────────────────────────────────────
DB_OLTP = {
    "host": os.getenv("DB_HOST", "localhost"),
    "database": "cru",
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "martin2580"),
    "port": int(os.getenv("DB_PORT", "5432")),
}

DB_OLAP = {
    "host": os.getenv("DB_HOST", "localhost"),
    "database": "cru_olap",
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "martin2580"),
    "port": int(os.getenv("DB_PORT", "5432")),
}

NOMBRES_MES = [
    "", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
]
NOMBRES_DIA = ["", "Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo"]


def conectar_oltp():
    return psycopg2.connect(**DB_OLTP)


def conectar_olap():
    return psycopg2.connect(**DB_OLAP)


def log(msg):
    print(f"  {msg}")


def limpiar_olap(conn_olap):
    """Vacia todas las tablas OLAP para recarga completa."""
    print("\n[1/7] Limpiando tablas OLAP...")
    cur = conn_olap.cursor()
    cur.execute("""
        TRUNCATE TABLE
            fact_pagos,
            fact_visualizaciones,
            dim_perfil,
            dim_usuario,
            dim_contenido,
            dim_tiempo
        RESTART IDENTITY CASCADE;
    """)
    conn_olap.commit()
    cur.close()
    log("Tablas vaciadas correctamente.")


# ─── 1. DIM_TIEMPO ────────────────────────────────────────
def cargar_dim_tiempo(conn_oltp, conn_olap):
    """
    Genera una fila por cada fecha distinta que aparece
    en los datos transaccionales (historial y pagos).
    """
    print("\n[2/7] Cargando dim_tiempo...")
    cur_oltp = conn_oltp.cursor()

    # Recolectar todas las fechas unicas de los datos
    cur_oltp.execute("""
        SELECT DISTINCT DATE(fecha) AS f FROM Historial_Contenido
        UNION
        SELECT DISTINCT fecha_pago FROM Detalles_Pago
        UNION
        SELECT DISTINCT DATE(fecha) FROM Perfil_Ve_Contenido
        ORDER BY f;
    """)
    fechas = [row[0] for row in cur_oltp.fetchall()]
    cur_oltp.close()

    cur_olap = conn_olap.cursor()
    insertados = 0
    for f in fechas:
        dia_semana = f.isoweekday()  # 1=lunes ... 7=domingo
        cur_olap.execute("""
            INSERT INTO dim_tiempo
                (fecha, anio, trimestre, mes, nombre_mes,
                 semana, dia, dia_semana, nombre_dia, es_fin_semana)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (fecha) DO NOTHING;
        """, (
            f,
            f.year,
            (f.month - 1) // 3 + 1,
            f.month,
            NOMBRES_MES[f.month],
            f.isocalendar()[1],
            f.day,
            dia_semana,
            NOMBRES_DIA[dia_semana],
            dia_semana >= 6
        ))
        insertados += 1

    conn_olap.commit()
    cur_olap.close()
    log(f"{insertados} fechas cargadas en dim_tiempo.")


# ─── 2. DIM_USUARIO ───────────────────────────────────────
def cargar_dim_usuario(conn_oltp, conn_olap):
    """Carga usuarios con info de su plan de suscripcion."""
    print("\n[3/7] Cargando dim_usuario...")
    cur_oltp = conn_oltp.cursor(cursor_factory=RealDictCursor)
    cur_oltp.execute("""
        SELECT
            u.id_usuario,
            u.correo,
            u.region,
            p.nombre  AS plan_nombre,
            CASE p.tipo_plan WHEN 1 THEN 'mensual' WHEN 12 THEN 'anual' END AS plan_tipo,
            p.precio  AS plan_precio
        FROM Usuario u
        JOIN Plan p ON p.id_plan = u.id_plan
        ORDER BY u.id_usuario;
    """)
    usuarios = cur_oltp.fetchall()
    cur_oltp.close()

    cur_olap = conn_olap.cursor()
    for u in usuarios:
        cur_olap.execute("""
            INSERT INTO dim_usuario
                (id_usuario_oltp, correo, region, plan_nombre, plan_tipo, plan_precio)
            VALUES (%s, %s, %s, %s, %s, %s);
        """, (
            u["id_usuario"], u["correo"], u["region"],
            u["plan_nombre"], u["plan_tipo"], u["plan_precio"]
        ))

    conn_olap.commit()
    cur_olap.close()
    log(f"{len(usuarios)} usuarios cargados en dim_usuario.")


# ─── 3. DIM_CONTENIDO ─────────────────────────────────────
def cargar_dim_contenido(conn_oltp, conn_olap):
    """Carga contenidos con generos concatenados."""
    print("\n[4/7] Cargando dim_contenido...")
    cur_oltp = conn_oltp.cursor(cursor_factory=RealDictCursor)

    # Peliculas
    cur_oltp.execute("""
        SELECT
            c.id_contenido,
            c.nombre,
            c.tipo_contenido,
            c.clasificacion,
            p.estudio_animacion,
            p.duracion AS duracion_minutos,
            NULL::BOOLEAN AS en_emision,
            STRING_AGG(g.tipo, ', ' ORDER BY g.tipo) AS generos
        FROM Contenido c
        JOIN Peliculas p ON p.id_contenido = c.id_contenido
        LEFT JOIN Pelicula_Tiene_Genero ptg ON ptg.id_contenido = c.id_contenido
        LEFT JOIN Generos g ON g.id_genero = ptg.id_genero
        WHERE c.tipo_contenido = 'pelicula'
        GROUP BY c.id_contenido, c.nombre, c.tipo_contenido,
                 c.clasificacion, p.estudio_animacion, p.duracion;
    """)
    peliculas = cur_oltp.fetchall()

    # Series
    cur_oltp.execute("""
        SELECT
            c.id_contenido,
            c.nombre,
            c.tipo_contenido,
            c.clasificacion,
            s.estudio_animacion,
            NULL::INT AS duracion_minutos,
            s.emision AS en_emision,
            STRING_AGG(g.tipo, ', ' ORDER BY g.tipo) AS generos
        FROM Contenido c
        JOIN Series s ON s.id_contenido = c.id_contenido
        LEFT JOIN Serie_Tiene_Genero stg ON stg.id_contenido = c.id_contenido
        LEFT JOIN Generos g ON g.id_genero = stg.id_genero
        WHERE c.tipo_contenido = 'serie'
        GROUP BY c.id_contenido, c.nombre, c.tipo_contenido,
                 c.clasificacion, s.estudio_animacion, s.emision;
    """)
    series = cur_oltp.fetchall()
    cur_oltp.close()

    cur_olap = conn_olap.cursor()
    total = 0
    for item in list(peliculas) + list(series):
        cur_olap.execute("""
            INSERT INTO dim_contenido
                (id_contenido_oltp, nombre, tipo_contenido, clasificacion,
                 estudio_animacion, duracion_minutos, en_emision, generos)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s);
        """, (
            item["id_contenido"], item["nombre"], item["tipo_contenido"],
            item["clasificacion"], item["estudio_animacion"],
            item["duracion_minutos"], item["en_emision"],
            item["generos"] or "Sin genero"
        ))
        total += 1

    conn_olap.commit()
    cur_olap.close()
    log(f"{total} contenidos cargados en dim_contenido.")


# ─── 4. DIM_PERFIL ────────────────────────────────────────
def cargar_dim_perfil(conn_oltp, conn_olap):
    """Carga perfiles vinculados a su dim_usuario correspondiente."""
    print("\n[5/7] Cargando dim_perfil...")
    cur_oltp = conn_oltp.cursor(cursor_factory=RealDictCursor)
    cur_oltp.execute("""
        SELECT id_perfil, nombre, restriccion, id_usuario
        FROM Perfil
        ORDER BY id_perfil;
    """)
    perfiles = cur_oltp.fetchall()
    cur_oltp.close()

    # Construir mapa id_usuario_oltp -> id_dim_usuario
    cur_olap = conn_olap.cursor(cursor_factory=RealDictCursor)
    cur_olap.execute("SELECT id_dim_usuario, id_usuario_oltp FROM dim_usuario;")
    mapa_usuario = {row["id_usuario_oltp"]: row["id_dim_usuario"]
                    for row in cur_olap.fetchall()}

    total = 0
    for p in perfiles:
        id_dim_usuario = mapa_usuario.get(p["id_usuario"])
        if id_dim_usuario is None:
            continue  # usuario no encontrado en dim (raro)
        cur_olap.execute("""
            INSERT INTO dim_perfil
                (id_perfil_oltp, nombre_perfil, restriccion, id_dim_usuario)
            VALUES (%s, %s, %s, %s);
        """, (
            p["id_perfil"], p["nombre"], p["restriccion"], id_dim_usuario
        ))
        total += 1

    conn_olap.commit()
    cur_olap.close()
    log(f"{total} perfiles cargados en dim_perfil.")


# ─── 5. FACT_VISUALIZACIONES ──────────────────────────────
def cargar_fact_visualizaciones(conn_oltp, conn_olap):
    """
    Carga cada evento de reproduccion desde Historial_Contenido.
    Calcula porcentaje completado y si la visualizacion fue completa (>= 90%).
    """
    print("\n[6/7] Cargando fact_visualizaciones...")
    cur_oltp = conn_oltp.cursor(cursor_factory=RealDictCursor)
    cur_oltp.execute("""
        SELECT
            hc.segundos_reproduccion,
            hc.duracion * 60   AS duracion_total_seg,
            DATE(hc.fecha)     AS fecha,
            h.id_perfil,
            hc.id_contenido
        FROM Historial_Contenido hc
        JOIN Historial h ON h.id_historial = hc.id_historial
        ORDER BY hc.fecha;
    """)
    registros = cur_oltp.fetchall()
    cur_oltp.close()

    # Mapas OLTP -> OLAP
    cur_olap = conn_olap.cursor(cursor_factory=RealDictCursor)

    cur_olap.execute("SELECT id_tiempo, fecha FROM dim_tiempo;")
    mapa_tiempo = {row["fecha"]: row["id_tiempo"] for row in cur_olap.fetchall()}

    cur_olap.execute("SELECT id_dim_contenido, id_contenido_oltp FROM dim_contenido;")
    mapa_contenido = {row["id_contenido_oltp"]: row["id_dim_contenido"]
                      for row in cur_olap.fetchall()}

    cur_olap.execute("SELECT id_dim_perfil, id_perfil_oltp, id_dim_usuario FROM dim_perfil;")
    mapa_perfil = {row["id_perfil_oltp"]: (row["id_dim_perfil"], row["id_dim_usuario"])
                   for row in cur_olap.fetchall()}

    total = 0
    omitidos = 0
    for r in registros:
        id_tiempo = mapa_tiempo.get(r["fecha"])
        id_dim_contenido = mapa_contenido.get(r["id_contenido"])
        perfil_data = mapa_perfil.get(r["id_perfil"])

        if not all([id_tiempo, id_dim_contenido, perfil_data]):
            omitidos += 1
            continue

        id_dim_perfil, id_dim_usuario = perfil_data
        dur = r["duracion_total_seg"]
        seg = r["segundos_reproduccion"]
        pct = round((seg / dur * 100), 2) if dur > 0 else 0.0
        completa = pct >= 90

        cur_olap.execute("""
            INSERT INTO fact_visualizaciones
                (id_tiempo, id_dim_contenido, id_dim_perfil, id_dim_usuario,
                 segundos_reproduccion, duracion_total_seg,
                 porcentaje_completado, visualizacion_completa)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s);
        """, (
            id_tiempo, id_dim_contenido, id_dim_perfil, id_dim_usuario,
            seg, dur, pct, completa
        ))
        total += 1

    conn_olap.commit()
    cur_olap.close()
    log(f"{total} visualizaciones cargadas en fact_visualizaciones. ({omitidos} omitidas)")


# ─── 6. FACT_PAGOS ────────────────────────────────────────
def cargar_fact_pagos(conn_oltp, conn_olap):
    """Carga pagos y renovaciones de suscripcion."""
    print("\n[7/7] Cargando fact_pagos...")
    cur_oltp = conn_oltp.cursor(cursor_factory=RealDictCursor)
    cur_oltp.execute("""
        SELECT
            dp.id_usuario,
            dp.fecha_pago,
            p.precio      AS monto,
            tp.nombre     AS tipo_pago,
            FALSE         AS es_renovacion
        FROM Detalles_Pago dp
        JOIN Usuario u   ON u.id_usuario   = dp.id_usuario
        JOIN Plan p      ON p.id_plan      = u.id_plan
        JOIN Tipo_Pago tp ON tp.id_tipo_pago = dp.id_tipo_pago
        ORDER BY dp.fecha_pago;
    """)
    pagos = cur_oltp.fetchall()
    cur_oltp.close()

    cur_olap = conn_olap.cursor(cursor_factory=RealDictCursor)

    cur_olap.execute("SELECT id_tiempo, fecha FROM dim_tiempo;")
    mapa_tiempo = {row["fecha"]: row["id_tiempo"] for row in cur_olap.fetchall()}

    cur_olap.execute("SELECT id_dim_usuario, id_usuario_oltp FROM dim_usuario;")
    mapa_usuario = {row["id_usuario_oltp"]: row["id_dim_usuario"]
                    for row in cur_olap.fetchall()}

    total = 0
    omitidos = 0
    for pago in pagos:
        id_tiempo = mapa_tiempo.get(pago["fecha_pago"])
        id_dim_usuario = mapa_usuario.get(pago["id_usuario"])

        if not all([id_tiempo, id_dim_usuario]):
            omitidos += 1
            continue

        cur_olap.execute("""
            INSERT INTO fact_pagos
                (id_tiempo, id_dim_usuario, monto, tipo_pago, es_renovacion)
            VALUES (%s, %s, %s, %s, %s);
        """, (
            id_tiempo, id_dim_usuario,
            pago["monto"], pago["tipo_pago"], pago["es_renovacion"]
        ))
        total += 1

    conn_olap.commit()
    cur_olap.close()
    log(f"{total} pagos cargados en fact_pagos. ({omitidos} omitidos)")


# ─── MAIN ─────────────────────────────────────────────────
def ejecutar_etl():
    print("=" * 55)
    print("  ETL - Sistema Crunchyroll | OLTP -> OLAP")
    print("=" * 55)

    conn_oltp = conectar_oltp()
    conn_olap = conectar_olap()

    try:
        limpiar_olap(conn_olap)
        cargar_dim_tiempo(conn_oltp, conn_olap)
        cargar_dim_usuario(conn_oltp, conn_olap)
        cargar_dim_contenido(conn_oltp, conn_olap)
        cargar_dim_perfil(conn_oltp, conn_olap)
        cargar_fact_visualizaciones(conn_oltp, conn_olap)
        cargar_fact_pagos(conn_oltp, conn_olap)

        print("\n" + "=" * 55)
        print("  ETL completado exitosamente.")
        print("=" * 55)

    except Exception as e:
        conn_olap.rollback()
        print(f"\n[ERROR] ETL fallido: {e}")
        raise
    finally:
        conn_oltp.close()
        conn_olap.close()


if __name__ == "__main__":
    ejecutar_etl()
