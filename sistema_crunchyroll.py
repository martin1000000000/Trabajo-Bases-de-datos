"""
Proyecto: Sistema transaccional Crunchyroll
Grupo: Grupo 3
Integrantes: Martin Arrigo, Nicolas Toro, Benjamin Neira, Diego Mora

Entrega 2 - Bases de Datos
Sistema de consola en Python conectado a PostgreSQL.
"""

import os
from datetime import date, datetime

import psycopg2
from psycopg2.extras import RealDictCursor


DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "database": os.getenv("DB_NAME", "cru"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "martin2580"),
    "port": int(os.getenv("DB_PORT", "5432")),
}


def conectar():
    return psycopg2.connect(**DB_CONFIG)


def leer_int(mensaje):
    while True:
        try:
            return int(input(mensaje).strip())
        except ValueError:
            print("Debe ingresar un numero entero.")


def leer_decimal(mensaje):
    while True:
        try:
            return float(input(mensaje).strip())
        except ValueError:
            print("Debe ingresar un numero valido.")


def leer_fecha(mensaje, por_defecto=None):
    texto = input(mensaje).strip()
    if not texto and por_defecto is not None:
        return por_defecto
    try:
        return datetime.strptime(texto, "%Y-%m-%d").date()
    except ValueError:
        print("Formato invalido. Se usara la fecha actual.")
        return date.today()


def sumar_meses(fecha, meses):
    mes = fecha.month - 1 + meses
    anio = fecha.year + mes // 12
    mes = mes % 12 + 1
    dias_mes = [31, 29 if anio % 4 == 0 and (anio % 100 != 0 or anio % 400 == 0) else 28,
                31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    dia = min(fecha.day, dias_mes[mes - 1])
    return date(anio, mes, dia)


def imprimir_filas(titulo, filas):
    print(f"\n--- {titulo} ---")
    if not filas:
        print("Sin registros.")
        return
    for fila in filas:
        print(" | ".join(f"{clave}: {valor}" for clave, valor in fila.items()))


def ejecutar_select(sql, parametros=None):
    conn = conectar()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute(sql, parametros or ())
    filas = cur.fetchall()
    cur.close()
    conn.close()
    return filas


# ---------------------------------------------------------
# CATALOGOS
# ---------------------------------------------------------

def listar_planes():
    filas = ejecutar_select("""
        SELECT
            id_plan,
            nombre,
            precio,
            CASE tipo_plan WHEN 1 THEN 'mensual' WHEN 12 THEN 'anual' END AS tipo_plan
        FROM Plan
        ORDER BY nombre, tipo_plan;
    """)
    imprimir_filas("PLANES", filas)


def listar_tipos_pago():
    filas = ejecutar_select("""
        SELECT id_tipo_pago, nombre
        FROM Tipo_Pago
        ORDER BY id_tipo_pago;
    """)
    imprimir_filas("TIPOS DE PAGO", filas)


def listar_contenidos():
    filas = ejecutar_select("""
        SELECT id_contenido, nombre, tipo_contenido, clasificacion
        FROM Contenido
        ORDER BY id_contenido
        LIMIT 120;
    """)
    imprimir_filas("CONTENIDOS", filas)


# ---------------------------------------------------------
# USUARIO + SUSCRIPCION + PAGO
# ---------------------------------------------------------

def crear_usuario_con_suscripcion():
    print("\n--- CREAR USUARIO CON SUSCRIPCION ---")
    correo = input("Correo: ").strip()
    contrasena = input("Contrasena: ").strip()
    region = input("Region: ").strip()

    listar_planes()
    id_plan = leer_int("ID plan: ")

    listar_tipos_pago()
    id_tipo_pago = leer_int("ID tipo de pago: ")
    numero_cuenta = input("Numero de cuenta/tarjeta: ").strip()
    fecha_pago = leer_fecha("Fecha de pago YYYY-MM-DD (Enter = hoy): ", date.today())

    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("SELECT tipo_plan FROM Plan WHERE id_plan = %s;", (id_plan,))
        resultado = cur.fetchone()
        if not resultado:
            raise ValueError("No existe el plan seleccionado.")

        tipo_plan = resultado[0]
        meses_renovacion = 12 if tipo_plan == 12 else 1
        fecha_renovacion = sumar_meses(fecha_pago, meses_renovacion)

        cur.execute("""
            INSERT INTO Usuario (correo, contrasena, region, id_plan)
            VALUES (%s, md5(%s), %s, %s)
            RETURNING id_usuario;
        """, (correo, contrasena, region, id_plan))
        id_usuario = cur.fetchone()[0]

        cur.execute("""
            INSERT INTO Detalles_Pago
                (numero_cuenta, fecha_pago, id_tipo_pago, id_usuario)
            VALUES (%s, %s, %s, %s)
            RETURNING id_detalles_pago;
        """, (numero_cuenta, fecha_pago, id_tipo_pago, id_usuario))
        id_detalles_pago = cur.fetchone()[0]

        cur.execute("""
            INSERT INTO Fecha_Renovacion (fecha, id_detalles_pago)
            VALUES (%s, %s);
        """, (fecha_renovacion, id_detalles_pago))

        conn.commit()
        print(f"Usuario creado. ID usuario: {id_usuario}")
        print(f"Fecha pago: {fecha_pago} | Fecha renovacion: {fecha_renovacion}")
    except Exception as error:
        conn.rollback()
        print(f"Error al crear usuario: {error}")
    finally:
        cur.close()
        conn.close()


def listar_usuarios():
    filas = ejecutar_select("""
        SELECT
            u.id_usuario,
            u.correo,
            u.region,
            p.nombre AS plan,
            CASE p.tipo_plan WHEN 1 THEN 'mensual' WHEN 12 THEN 'anual' END AS tipo_plan,
            tp.nombre AS tipo_pago,
            dp.fecha_pago,
            fr.fecha AS fecha_renovacion
        FROM Usuario u
        JOIN Plan p ON p.id_plan = u.id_plan
        JOIN Detalles_Pago dp ON dp.id_usuario = u.id_usuario
        JOIN Tipo_Pago tp ON tp.id_tipo_pago = dp.id_tipo_pago
        JOIN Fecha_Renovacion fr ON fr.id_detalles_pago = dp.id_detalles_pago
        ORDER BY u.id_usuario
        LIMIT 50;
    """)
    imprimir_filas("USUARIOS Y SUSCRIPCIONES", filas)


def eliminar_usuario():
    id_usuario = leer_int("ID usuario a eliminar: ")
    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM Usuario WHERE id_usuario = %s;", (id_usuario,))
        conn.commit()
        print("Usuario eliminado correctamente.")
    except Exception as error:
        conn.rollback()
        print(f"Error al eliminar usuario: {error}")
    finally:
        cur.close()
        conn.close()


# ---------------------------------------------------------
# PERFILES
# ---------------------------------------------------------

def crear_perfil():
    print("\n--- CREAR PERFIL ---")
    id_usuario = leer_int("ID usuario: ")
    nombre = input("Nombre perfil: ").strip()
    foto = input("Foto/avatar: ").strip() or "avatar_default.png"
    restriccion = input("Restriccion (Todo publico, supervision parental, 12+, 14+, 16+, 18+): ").strip()

    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO Perfil (nombre, foto, restriccion, id_usuario)
            VALUES (%s, %s, %s, %s)
            RETURNING id_perfil;
        """, (nombre, foto, restriccion, id_usuario))
        id_perfil = cur.fetchone()[0]

        cur.execute("""
            INSERT INTO Historial (id_perfil)
            VALUES (%s);
        """, (id_perfil,))

        conn.commit()
        print(f"Perfil creado correctamente. ID perfil: {id_perfil}")
    except Exception as error:
        conn.rollback()
        print(f"Error al crear perfil: {error}")
    finally:
        cur.close()
        conn.close()


def listar_perfiles():
    filas = ejecutar_select("""
        SELECT
            p.id_perfil,
            p.nombre,
            p.restriccion,
            p.foto,
            u.correo
        FROM Perfil p
        JOIN Usuario u ON u.id_usuario = p.id_usuario
        ORDER BY p.id_perfil
        LIMIT 80;
    """)
    imprimir_filas("PERFILES", filas)


def eliminar_perfil():
    id_perfil = leer_int("ID perfil a eliminar: ")
    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM Perfil WHERE id_perfil = %s;", (id_perfil,))
        conn.commit()
        print("Perfil eliminado correctamente.")
    except Exception as error:
        conn.rollback()
        print(f"Error al eliminar perfil: {error}")
    finally:
        cur.close()
        conn.close()


# ---------------------------------------------------------
# LISTAS Y CONTENIDO GUARDADO
# ---------------------------------------------------------

def crear_lista():
    id_usuario = leer_int("ID usuario: ")
    nombre_lista = input("Nombre de la lista: ").strip()
    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO Listas (nombre_lista, id_usuario)
            VALUES (%s, %s)
            RETURNING id_lista;
        """, (nombre_lista, id_usuario))
        id_lista = cur.fetchone()[0]
        conn.commit()
        print(f"Lista creada correctamente. ID lista: {id_lista}")
    except Exception as error:
        conn.rollback()
        print(f"Error al crear lista: {error}")
    finally:
        cur.close()
        conn.close()


def guardar_contenido_en_lista():
    id_lista = leer_int("ID lista: ")
    id_contenido = leer_int("ID contenido: ")
    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO Lista_Guarda_Contenido (id_lista, id_contenido)
            VALUES (%s, %s)
            ON CONFLICT DO NOTHING;
        """, (id_lista, id_contenido))
        conn.commit()
        print("Contenido guardado en lista.")
    except Exception as error:
        conn.rollback()
        print(f"Error al guardar contenido: {error}")
    finally:
        cur.close()
        conn.close()


def listar_listas():
    filas = ejecutar_select("""
        SELECT
            l.id_lista,
            l.nombre_lista,
            u.correo,
            COUNT(lgc.id_contenido) AS contenidos_guardados
        FROM Listas l
        JOIN Usuario u ON u.id_usuario = l.id_usuario
        LEFT JOIN Lista_Guarda_Contenido lgc ON lgc.id_lista = l.id_lista
        GROUP BY l.id_lista, l.nombre_lista, u.correo
        ORDER BY l.id_lista
        LIMIT 80;
    """)
    imprimir_filas("LISTAS", filas)


def listar_contenidos_de_lista():
    id_lista = leer_int("ID lista: ")
    filas = ejecutar_select("""
        SELECT
            l.nombre_lista,
            c.id_contenido,
            c.nombre,
            c.tipo_contenido,
            c.clasificacion
        FROM Lista_Guarda_Contenido lgc
        JOIN Listas l ON l.id_lista = lgc.id_lista
        JOIN Contenido c ON c.id_contenido = lgc.id_contenido
        WHERE l.id_lista = %s
        ORDER BY c.nombre;
    """, (id_lista,))
    imprimir_filas("CONTENIDOS DE LISTA", filas)


def eliminar_contenido_de_lista():
    id_lista = leer_int("ID lista: ")
    id_contenido = leer_int("ID contenido a quitar: ")
    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("""
            DELETE FROM Lista_Guarda_Contenido
            WHERE id_lista = %s AND id_contenido = %s;
        """, (id_lista, id_contenido))
        conn.commit()
        print("Contenido eliminado de la lista.")
    except Exception as error:
        conn.rollback()
        print(f"Error al eliminar contenido de lista: {error}")
    finally:
        cur.close()
        conn.close()


def eliminar_lista():
    id_lista = leer_int("ID lista a eliminar: ")
    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM Listas WHERE id_lista = %s;", (id_lista,))
        conn.commit()
        print("Lista eliminada correctamente.")
    except Exception as error:
        conn.rollback()
        print(f"Error al eliminar lista: {error}")
    finally:
        cur.close()
        conn.close()


# ---------------------------------------------------------
# VISUALIZACIONES E HISTORIAL
# ---------------------------------------------------------

def registrar_visualizacion():
    print("\n--- REGISTRAR VISUALIZACION ---")
    id_perfil = leer_int("ID perfil: ")
    id_contenido = leer_int("ID contenido: ")
    fecha = datetime.now()

    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT h.id_historial
            FROM Historial h
            WHERE h.id_perfil = %s;
        """, (id_perfil,))
        historial = cur.fetchone()
        if not historial:
            raise ValueError("El perfil no tiene historial asociado.")
        id_historial = historial[0]

        cur.execute("""
            SELECT c.nombre, COALESCE(p.duracion, 24) AS duracion
            FROM Contenido c
            LEFT JOIN Peliculas p ON p.id_contenido = c.id_contenido
            WHERE c.id_contenido = %s;
        """, (id_contenido,))
        contenido = cur.fetchone()
        if not contenido:
            raise ValueError("No existe el contenido indicado.")

        nombre_contenido = contenido[0]
        duracion = contenido[1]
        segundos = leer_int(f"Segundos reproducidos (0 a {duracion * 60}): ")
        segundos = max(0, min(segundos, duracion * 60))

        cur.execute("""
            INSERT INTO Perfil_Ve_Contenido (id_perfil, id_contenido, fecha)
            VALUES (%s, %s, %s)
            RETURNING id_visualizacion;
        """, (id_perfil, id_contenido, fecha))
        id_visualizacion = cur.fetchone()[0]

        cur.execute("""
            INSERT INTO Historial_Contenido
                (id_historial, id_contenido, nombre, duracion, segundos_reproduccion, fecha)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id_historial_contenido;
        """, (id_historial, id_contenido, nombre_contenido, duracion, segundos, fecha))
        id_historial_contenido = cur.fetchone()[0]

        conn.commit()
        print(f"Visualizacion registrada. ID: {id_visualizacion}")
        print(f"Historial contenido registrado. ID: {id_historial_contenido}")
    except Exception as error:
        conn.rollback()
        print(f"Error al registrar visualizacion: {error}")
    finally:
        cur.close()
        conn.close()


def listar_visualizaciones():
    filas = ejecutar_select("""
        SELECT
            pvc.id_visualizacion,
            pf.nombre AS perfil,
            c.nombre AS contenido,
            c.tipo_contenido,
            pvc.fecha
        FROM Perfil_Ve_Contenido pvc
        JOIN Perfil pf ON pf.id_perfil = pvc.id_perfil
        JOIN Contenido c ON c.id_contenido = pvc.id_contenido
        ORDER BY pvc.fecha DESC
        LIMIT 80;
    """)
    imprimir_filas("VISUALIZACIONES", filas)


def listar_historial_perfil():
    id_perfil = leer_int("ID perfil: ")
    filas = ejecutar_select("""
        SELECT
            hc.id_historial_contenido,
            pf.nombre AS perfil,
            hc.nombre AS contenido,
            hc.duracion,
            hc.segundos_reproduccion,
            ROUND((hc.segundos_reproduccion::NUMERIC / (hc.duracion * 60)) * 100, 2) AS porcentaje_visto,
            hc.fecha
        FROM Historial_Contenido hc
        JOIN Historial h ON h.id_historial = hc.id_historial
        JOIN Perfil pf ON pf.id_perfil = h.id_perfil
        WHERE pf.id_perfil = %s
        ORDER BY hc.fecha DESC
        LIMIT 80;
    """, (id_perfil,))
    imprimir_filas("HISTORIAL DEL PERFIL", filas)


def eliminar_visualizacion():
    id_visualizacion = leer_int("ID visualizacion a eliminar: ")
    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM Perfil_Ve_Contenido WHERE id_visualizacion = %s;", (id_visualizacion,))
        conn.commit()
        print("Visualizacion eliminada correctamente.")
    except Exception as error:
        conn.rollback()
        print(f"Error al eliminar visualizacion: {error}")
    finally:
        cur.close()
        conn.close()


def eliminar_historial_contenido():
    id_historial_contenido = leer_int("ID historial_contenido a eliminar: ")
    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("""
            DELETE FROM Historial_Contenido
            WHERE id_historial_contenido = %s;
        """, (id_historial_contenido,))
        conn.commit()
        print("Registro de historial eliminado correctamente.")
    except Exception as error:
        conn.rollback()
        print(f"Error al eliminar historial: {error}")
    finally:
        cur.close()
        conn.close()


# ---------------------------------------------------------
# VALORACIONES
# ---------------------------------------------------------

def crear_valoracion():
    id_perfil = leer_int("ID perfil: ")
    id_contenido = leer_int("ID contenido: ")
    puntaje = leer_decimal("Puntaje (1.0 a 10.0): ")
    while not (1 <= puntaje <= 10):
        print("El puntaje debe estar entre 1 y 10.")
        puntaje = leer_decimal("Puntaje (1.0 a 10.0): ")

    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO Valoracion (puntaje, id_perfil, id_contenido)
            VALUES (%s, %s, %s)
            ON CONFLICT (id_perfil, id_contenido)
            DO UPDATE SET puntaje = EXCLUDED.puntaje
            RETURNING id_valoracion;
        """, (puntaje, id_perfil, id_contenido))
        id_valoracion = cur.fetchone()[0]
        conn.commit()
        print(f"Valoracion guardada correctamente. ID: {id_valoracion}")
    except Exception as error:
        conn.rollback()
        print(f"Error al guardar valoracion: {error}")
    finally:
        cur.close()
        conn.close()


def listar_valoraciones():
    filas = ejecutar_select("""
        SELECT
            v.id_valoracion,
            pf.nombre AS perfil,
            c.nombre AS contenido,
            v.puntaje
        FROM Valoracion v
        JOIN Perfil pf ON pf.id_perfil = v.id_perfil
        JOIN Contenido c ON c.id_contenido = v.id_contenido
        ORDER BY v.id_valoracion DESC
        LIMIT 80;
    """)
    imprimir_filas("VALORACIONES", filas)


def eliminar_valoracion():
    id_valoracion = leer_int("ID valoracion a eliminar: ")
    conn = conectar()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM Valoracion WHERE id_valoracion = %s;", (id_valoracion,))
        conn.commit()
        print("Valoracion eliminada correctamente.")
    except Exception as error:
        conn.rollback()
        print(f"Error al eliminar valoracion: {error}")
    finally:
        cur.close()
        conn.close()


# ---------------------------------------------------------
# DATOS SINTETICOS
# ---------------------------------------------------------

def cargar_datos_sinteticos_desde_sql():
    confirmar = input("Esto ejecutara insert_db.sql y recargara datos. Escriba SI para continuar: ").strip()
    if confirmar != "SI":
        print("Operacion cancelada.")
        return

    ruta = "insert_db.sql"
    if not os.path.exists(ruta):
        print("No se encontro insert_db.sql en la carpeta actual.")
        return

    conn = conectar()
    cur = conn.cursor()
    try:
        with open(ruta, "r", encoding="utf-8") as archivo:
            cur.execute(archivo.read())
        conn.commit()
        print("Datos sinteticos cargados correctamente.")
    except Exception as error:
        conn.rollback()
        print(f"Error al cargar datos sinteticos: {error}")
    finally:
        cur.close()
        conn.close()


# ---------------------------------------------------------
# MENUS
# ---------------------------------------------------------

def menu_usuarios():
    while True:
        print("\n--- MENU USUARIOS Y SUSCRIPCIONES ---")
        print("1. Crear usuario con suscripcion y pago")
        print("2. Listar usuarios")
        print("3. Eliminar usuario")
        print("0. Volver")
        opcion = input("Seleccione una opcion: ").strip()
        if opcion == "1":
            crear_usuario_con_suscripcion()
        elif opcion == "2":
            listar_usuarios()
        elif opcion == "3":
            eliminar_usuario()
        elif opcion == "0":
            break
        else:
            print("Opcion no valida.")


def menu_perfiles():
    while True:
        print("\n--- MENU PERFILES ---")
        print("1. Crear perfil")
        print("2. Listar perfiles")
        print("3. Eliminar perfil")
        print("0. Volver")
        opcion = input("Seleccione una opcion: ").strip()
        if opcion == "1":
            crear_perfil()
        elif opcion == "2":
            listar_perfiles()
        elif opcion == "3":
            eliminar_perfil()
        elif opcion == "0":
            break
        else:
            print("Opcion no valida.")


def menu_listas():
    while True:
        print("\n--- MENU LISTAS ---")
        print("1. Crear lista")
        print("2. Guardar contenido en lista")
        print("3. Listar listas")
        print("4. Listar contenidos de una lista")
        print("5. Quitar contenido de lista")
        print("6. Eliminar lista")
        print("0. Volver")
        opcion = input("Seleccione una opcion: ").strip()
        if opcion == "1":
            crear_lista()
        elif opcion == "2":
            guardar_contenido_en_lista()
        elif opcion == "3":
            listar_listas()
        elif opcion == "4":
            listar_contenidos_de_lista()
        elif opcion == "5":
            eliminar_contenido_de_lista()
        elif opcion == "6":
            eliminar_lista()
        elif opcion == "0":
            break
        else:
            print("Opcion no valida.")


def menu_visualizaciones():
    while True:
        print("\n--- MENU VISUALIZACIONES E HISTORIAL ---")
        print("1. Registrar visualizacion")
        print("2. Listar visualizaciones")
        print("3. Listar historial de perfil")
        print("4. Eliminar visualizacion mal ingresada")
        print("5. Eliminar registro de historial")
        print("0. Volver")
        opcion = input("Seleccione una opcion: ").strip()
        if opcion == "1":
            registrar_visualizacion()
        elif opcion == "2":
            listar_visualizaciones()
        elif opcion == "3":
            listar_historial_perfil()
        elif opcion == "4":
            eliminar_visualizacion()
        elif opcion == "5":
            eliminar_historial_contenido()
        elif opcion == "0":
            break
        else:
            print("Opcion no valida.")


def menu_valoraciones():
    while True:
        print("\n--- MENU VALORACIONES ---")
        print("1. Crear o actualizar valoracion")
        print("2. Listar valoraciones")
        print("3. Eliminar valoracion")
        print("0. Volver")
        opcion = input("Seleccione una opcion: ").strip()
        if opcion == "1":
            crear_valoracion()
        elif opcion == "2":
            listar_valoraciones()
        elif opcion == "3":
            eliminar_valoracion()
        elif opcion == "0":
            break
        else:
            print("Opcion no valida.")


def menu_catalogos():
    while True:
        print("\n--- MENU CATALOGOS ---")
        print("1. Listar planes")
        print("2. Listar tipos de pago")
        print("3. Listar contenidos")
        print("0. Volver")
        opcion = input("Seleccione una opcion: ").strip()
        if opcion == "1":
            listar_planes()
        elif opcion == "2":
            listar_tipos_pago()
        elif opcion == "3":
            listar_contenidos()
        elif opcion == "0":
            break
        else:
            print("Opcion no valida.")


def menu_principal():
    while True:
        print("\n===== SISTEMA TRANSACCIONAL CRUNCHYROLL =====")
        print("1. Usuarios, suscripciones y pagos")
        print("2. Perfiles")
        print("3. Listas")
        print("4. Visualizaciones e historial")
        print("5. Valoraciones")
        print("6. Catalogos")
        print("7. Cargar datos sinteticos desde insert_db.sql")
        print("0. Salir")

        opcion = input("Seleccione una opcion: ").strip()
        if opcion == "1":
            menu_usuarios()
        elif opcion == "2":
            menu_perfiles()
        elif opcion == "3":
            menu_listas()
        elif opcion == "4":
            menu_visualizaciones()
        elif opcion == "5":
            menu_valoraciones()
        elif opcion == "6":
            menu_catalogos()
        elif opcion == "7":
            cargar_datos_sinteticos_desde_sql()
        elif opcion == "0":
            print("Programa finalizado.")
            break
        else:
            print("Opcion no valida.")


if __name__ == "__main__":
    menu_principal()
