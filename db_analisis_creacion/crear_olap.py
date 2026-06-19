"""
Script OLAP - Sistema Crunchyroll
1. Elimina las tablas dim_* y fact_* mal puestas en la BD 'cru'
2. Crea la BD 'cru_olap' si no existe
3. Crea el esquema estrella en 'cru_olap'
"""
import psycopg2
import os
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# Configuracion base (apunta a cru para el paso de limpieza)
DB_CONFIG_CRU = {
    "host": os.getenv("DB_HOST", "localhost"),
    "database": "cru",
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "martin2580"),
    "port": int(os.getenv("DB_PORT", "5432")),
}

# Configuracion para la nueva BD analitica
DB_CONFIG_OLAP = {
    "host": os.getenv("DB_HOST", "localhost"),
    "database": "cru_olap",
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "martin2580"),
    "port": int(os.getenv("DB_PORT", "5432")),
}

# ─────────────────────────────────────────────
# PASO 1: Limpiar tablas OLAP de la BD 'cru'
# ─────────────────────────────────────────────
print("=" * 50)
print("PASO 1: Limpiando tablas OLAP de la BD 'cru'...")
print("=" * 50)

conn_cru = psycopg2.connect(**DB_CONFIG_CRU)
conn_cru.autocommit = True
cur_cru = conn_cru.cursor()

try:
    cur_cru.execute("""
        DROP TABLE IF EXISTS fact_pagos             CASCADE;
        DROP TABLE IF EXISTS fact_visualizaciones   CASCADE;
        DROP TABLE IF EXISTS dim_perfil             CASCADE;
        DROP TABLE IF EXISTS dim_usuario            CASCADE;
        DROP TABLE IF EXISTS dim_contenido          CASCADE;
        DROP TABLE IF EXISTS dim_tiempo             CASCADE;
    """)
    print("[OK] Tablas dim_* y fact_* eliminadas de 'cru'.")
except Exception as e:
    print(f"[ERROR] Al limpiar 'cru': {e}")
finally:
    cur_cru.close()
    conn_cru.close()

# ─────────────────────────────────────────────
# PASO 2: Crear la BD 'cru_olap' si no existe
# ─────────────────────────────────────────────
print()
print("=" * 50)
print("PASO 2: Creando base de datos 'cru_olap'...")
print("=" * 50)

# Para crear una BD hay que conectarse a 'postgres' (BD por defecto)
conn_admin = psycopg2.connect(**{**DB_CONFIG_CRU, "database": "postgres"})
conn_admin.autocommit = True
cur_admin = conn_admin.cursor()

try:
    cur_admin.execute("SELECT 1 FROM pg_database WHERE datname = 'cru_olap';")
    existe = cur_admin.fetchone()
    if existe:
        print("[INFO] La BD 'cru_olap' ya existe, se usara la existente.")
    else:
        cur_admin.execute("CREATE DATABASE cru_olap;")
        print("[OK] Base de datos 'cru_olap' creada correctamente.")
except Exception as e:
    print(f"[ERROR] Al crear 'cru_olap': {e}")
finally:
    cur_admin.close()
    conn_admin.close()

# ─────────────────────────────────────────────
# PASO 3: Crear esquema estrella en 'cru_olap'
# ─────────────────────────────────────────────
print()
print("=" * 50)
print("PASO 3: Creando esquema OLAP en 'cru_olap'...")
print("=" * 50)

with open("olap_schema.sql", "r", encoding="utf-8") as f:
    sql_olap = f.read()

conn_olap = psycopg2.connect(**DB_CONFIG_OLAP)
conn_olap.autocommit = True
cur_olap = conn_olap.cursor()

try:
    cur_olap.execute(sql_olap)
    print("[OK] Esquema estrella creado en 'cru_olap'.")

    # Verificar tablas
    cur_olap.execute("""
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
          AND (tablename LIKE 'dim_%' OR tablename LIKE 'fact_%')
        ORDER BY tablename;
    """)
    tablas = cur_olap.fetchall()
    print("\nTablas creadas en 'cru_olap':")
    for t in tablas:
        print(f"  - {t[0]}")

except Exception as e:
    print(f"[ERROR] Al crear esquema OLAP: {e}")
finally:
    cur_olap.close()
    conn_olap.close()

print()
print("=" * 50)
print("Listo! OLTP en 'cru' | OLAP en 'cru_olap'")
print("=" * 50)
