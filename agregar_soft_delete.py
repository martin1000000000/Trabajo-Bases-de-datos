"""Agrega columna 'eliminado' a las tablas Usuario y Perfil (soft delete)."""
import psycopg2
import os
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "database": "cru",
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "martin2580"),
    "port": int(os.getenv("DB_PORT", "5432")),
}

conn = psycopg2.connect(**DB_CONFIG)
conn.autocommit = True
cur = conn.cursor()

try:
    for tabla in ["usuario", "perfil"]:
        cur.execute(f"""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = '{tabla}' AND column_name = 'eliminado';
        """)
        if cur.fetchone():
            print(f"[INFO] '{tabla}' ya tiene columna 'eliminado'.")
        else:
            cur.execute(f"""
                ALTER TABLE {tabla}
                ADD COLUMN eliminado BOOLEAN NOT NULL DEFAULT FALSE;
            """)
            print(f"[OK] Columna 'eliminado' agregada a '{tabla}'.")

    print("\n[OK] Datos existentes no fueron tocados.")
except Exception as e:
    print(f"[ERROR] {e}")
finally:
    cur.close()
    conn.close()
