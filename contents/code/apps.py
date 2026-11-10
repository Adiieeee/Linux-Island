#!/usr/bin/env python3
"""Lista las apps instaladas leyendo los .desktop, para el lanzador."""
import configparser
import json
import os
import sys


def app_dirs():
    dirs = [os.path.expanduser("~/.local/share/applications")]
    xdg = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share")
    dirs += [os.path.join(d, "applications") for d in xdg.split(":") if d]
    return dirs


def scan():
    # se escanea home primero y se deduplica por nombre de archivo, así
    # una copia en ~/.local/share pisa a la del sistema, como manda xdg
    seen = {}
    for d in app_dirs():
        if not os.path.isdir(d):
            continue
        for root, _dirs, files in os.walk(d):
            for f in files:
                if not f.endswith(".desktop") or f in seen:
                    continue
                cfg = configparser.ConfigParser(interpolation=None, strict=False)
                try:
                    cfg.read(os.path.join(root, f), encoding="utf-8")
                except Exception:
                    continue
                if "Desktop Entry" not in cfg:
                    continue
                e = cfg["Desktop Entry"]
                if e.get("Type", "Application") != "Application":
                    continue
                if e.get("NoDisplay", "false").lower() == "true":
                    continue
                if e.get("Hidden", "false").lower() == "true":
                    continue
                name = e.get("Name", "")
                if not name:
                    continue
                seen[f] = {
                    "name": name,
                    "generic": e.get("GenericName", ""),
                    "icon": e.get("Icon", ""),
                    "path": os.path.join(root, f),
                }
    return sorted(seen.values(), key=lambda a: a["name"].lower())


if __name__ == "__main__":
    json.dump(scan(), sys.stdout, ensure_ascii=False)
