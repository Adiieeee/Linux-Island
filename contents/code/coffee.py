#!/usr/bin/env python3
"""Modo café: mantiene la pantalla despierta mientras este proceso viva.

Por qué un proceso aparte y no un `qdbus` suelto: KDE ata cada inhibición a
la conexión de DBus de quien la pidió, y la suelta apenas esa conexión se
cae. Un `qdbus` termina al instante, así que la inhibición duraba menos que
el comando. Acá se pide y el proceso se queda esperando, con la conexión
abierta.

Se piden tres, porque cada una tapa una cosa distinta:

  ScreenSaver      no apagar ni bloquear la pantalla (la que de verdad
                   importa: es la que usan los reproductores de video)
  PowerManagement  no suspender el equipo
  PolicyAgent      la vía propia de PowerDevil, por las dudas

Encender:  python3 coffee.py &
Apagar:    matar el proceso; las inhibiciones se sueltan solas
"""
import signal
import sys

from gi.repository import Gio, GLib

# Lo que entiende PowerDevil: 1 = no interrumpir la sesión (ni suspender ni
# bloquear), 4 = no tocar la pantalla (ni atenuar ni apagar).
POLICY_SESION_Y_PANTALLA = 1 | 4


def main():
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)

    def proxy(nombre, ruta, interfaz):
        return Gio.DBusProxy.new_sync(bus, Gio.DBusProxyFlags.NONE, None,
                                      nombre, ruta, interfaz, None)

    pedidas = 0

    try:
        ss = proxy("org.freedesktop.ScreenSaver", "/org/freedesktop/ScreenSaver",
                   "org.freedesktop.ScreenSaver")
        ss.Inhibit("(ss)", "Isla", "Modo café")
        pedidas += 1
    except Exception as e:
        print(f"modo café: sin ScreenSaver: {e}", file=sys.stderr)

    try:
        pm = proxy("org.freedesktop.PowerManagement",
                   "/org/freedesktop/PowerManagement/Inhibit",
                   "org.freedesktop.PowerManagement.Inhibit")
        pm.Inhibit("(ss)", "Isla", "Modo café")
        pedidas += 1
    except Exception as e:
        print(f"modo café: sin PowerManagement: {e}", file=sys.stderr)

    try:
        pa = proxy("org.kde.Solid.PowerManagement",
                   "/org/kde/Solid/PowerManagement/PolicyAgent",
                   "org.kde.Solid.PowerManagement.PolicyAgent")
        pa.AddInhibition("(uss)", POLICY_SESION_Y_PANTALLA, "Isla", "Modo café")
        pedidas += 1
    except Exception as e:
        print(f"modo café: sin PolicyAgent: {e}", file=sys.stderr)

    if pedidas == 0:
        print("modo café: no se pudo inhibir nada", file=sys.stderr)
        return 1

    bucle = GLib.MainLoop()

    def salir(*_):
        bucle.quit()
        return False

    for s in (signal.SIGTERM, signal.SIGINT):
        GLib.unix_signal_add(GLib.PRIORITY_HIGH, s, salir)
    bucle.run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
