"""
Scheduler - Sistema Crunchyroll
Automatiza la ejecucion del ETL cada cierto tiempo.
Ejecuta: python scheduler.py
"""

import sys
import io
from datetime import datetime
# pyrefly: ignore [missing-import]
from apscheduler.schedulers.blocking import BlockingScheduler
# pyrefly: ignore [missing-import]
from apscheduler.triggers.cron import CronTrigger
from etl import ejecutar_etl

try:
    sys.stdout.reconfigure(encoding='utf-8', line_buffering=True)
except AttributeError:
    pass

LINEA  = "=" * 55
LINEA2 = "-" * 55


def mostrar_banner():
    print(LINEA)
    print("   SCHEDULER - Sistema Crunchyroll")
    print("   ETL automatico OLTP (cru) --> OLAP (cru_olap)")
    print(LINEA)
    print()
    print("  Horarios programados:")
    print("    - Todos los dias a las 02:00 AM  (carga nocturna)")
    print("    - Cada 6 horas                   (actualizacion)")
    print()


def job_etl():
    """Funcion que ejecuta el ETL y registra hora de ejecucion."""
    ahora = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print()
    print(LINEA)
    print(f"  [SCHEDULER] Iniciando ETL automatico")
    print(f"  Hora de ejecucion: {ahora}")
    print(LINEA)
    try:
        ejecutar_etl()
        fin = datetime.now().strftime("%H:%M:%S")
        print()
        print(LINEA2)
        print(f"  [OK] ETL finalizado exitosamente a las {fin}")
        print(LINEA2)
    except Exception as e:
        print()
        print(LINEA2)
        print(f"  [ERROR] ETL fallo: {e}")
        print(LINEA2)


def main():
    mostrar_banner()

    scheduler = BlockingScheduler()

    # Tarea 1: Todos los dias a las 02:00 AM (carga nocturna principal)
    scheduler.add_job(
        job_etl,
        trigger=CronTrigger(hour=2, minute=0),
        id="etl_nocturno",
        name="Carga ETL nocturna (02:00 AM)",
        replace_existing=True,
    )

    # Tarea 2: Cada 6 horas para mantener datos frescos
    scheduler.add_job(
        job_etl,
        trigger=CronTrigger(hour="0,6,12,18", minute=0),
        id="etl_6horas",
        name="Actualizacion ETL cada 6 horas",
        replace_existing=True,
    )

    # Mostrar proximas ejecuciones
    print("  Proximas ejecuciones programadas:")
    print(LINEA2)
    for job in scheduler.get_jobs():
        try:
            proxima = job.next_run_time
        except AttributeError:
            from datetime import datetime
            proxima = job.trigger.get_next_fire_time(None, datetime.now(job.trigger.timezone))
            
        print(f"  [{job.id}]")
        print(f"    Nombre  : {job.name}")
        if proxima:
            print(f"    Proxima : {proxima.strftime('%Y-%m-%d %H:%M:%S')}")
        print()

    print(LINEA2)
    print("  Scheduler activo. Presiona Ctrl+C para detener.")
    print(LINEA)
    print()

    try:
        scheduler.start()
    except (KeyboardInterrupt, SystemExit):
        print()
        print(LINEA)
        print("  Scheduler detenido por el usuario.")
        print(LINEA)


if __name__ == "__main__":
    main()
