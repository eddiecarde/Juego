#!/usr/bin/env python3
"""Genera los niveles 11..50 de Goods Sort Master.

Curva de dificultad progresiva y solvencia garantizada:
la profundidad se calcula para que la capacidad del tablero
(shelves*columns*depth) siempre albergue triples*3 fichas.
"""
import json
import math
import os

OUT = "/home/user/Juego/levels"
TYPES = ["apple", "banana", "grapes", "milk", "bread", "cheese", "box", "bottle"]

NAMES = {
    11: "Depósito matutino", 12: "Reparto exprés", 13: "Pasillo 3",
    14: "Cámara fría", 15: "Turno de tarde", 16: "Pedido urgente",
    17: "Doble estante", 18: "Almacén central", 19: "Caja registradora",
    20: "Jefe de sección", 21: "Inventario nocturno", 22: "Zona de carga",
    23: "Reposición rápida", 24: "Bodega profunda", 25: "Escaparate",
    26: "Mercado lleno", 27: "Hora pico", 28: "Cinta transportadora",
    29: "Control de stock", 30: "Gerente de tienda", 31: "Gran superficie",
    32: "Liquidación total", 33: "Estantes al límite", 34: "Reparto masivo",
    35: "Caos ordenado", 36: "Torre de cajas", 37: "Maratón de sorteo",
    38: "Sin descanso", 39: "Última entrega", 40: "Supervisor regional",
    41: "Centro logístico", 42: "Almacén infinito", 43: "Rompecabezas de góndola",
    44: "Estrés de estante", 45: "Velocidad máxima", 46: "Frenesí de fichas",
    47: "Desafío profundo", 48: "El gran pedido", 49: "Contra el reloj final",
    50: "Maestro absoluto",
}


def make_level(n: int) -> dict:
    t = n - 10  # 1..40

    # Nº de tríos: crece linealmente de 8 (n=11) a 24 (n=50).
    triples = round(8 + (t - 1) * (24 - 8) / 39)

    # Tipos de mercancía: de 5 a 8 tipos, en aumento suave.
    num_types = min(8, 5 + (n - 11) * 3 // 39)
    goods = TYPES[:num_types]

    # Tamaño del tablero.
    shelves = 4 if n <= 13 else 5
    columns = 6

    # Profundidad mínima para que quepan todas las fichas (+ margen de challenge).
    items = triples * 3
    depth = max(2, math.ceil(items / (shelves * columns)))

    # Bandeja: más estrecha a medida que sube la dificultad.
    # El nivel 5 (la bandeja más pequeña) se reserva al tramo experto (41-50).
    if t <= 6:
        tray_slots = 7
    elif t <= 30:
        tray_slots = 6
    else:
        tray_slots = 5

    # Temporizador: generoso pero con presión; 1 de cada 4 niveles sin reloj.
    if n % 4 == 3:
        time_limit = 0
    else:
        time_limit = int(min(180, max(60, round(items * 2.2))))

    # Economía.
    hint_cost = min(200, 50 + t * 3)
    hint_cost = int(round(hint_cost / 5) * 5)
    reward = 100 + t * 15 + (100 if n % 10 == 0 else 0)

    # Dificultad 5..10.
    difficulty = min(10, 4 + math.ceil(t / 5))

    return {
        "id": n,
        "name": NAMES[n],
        "goods": goods,
        "triples": triples,
        "shelves": shelves,
        "columns": columns,
        "depth": depth,
        "tray_slots": tray_slots,
        "time_limit": time_limit,
        "hint_cost": hint_cost,
        "reward_coins": reward,
        "difficulty": difficulty,
    }


def main() -> None:
    for n in range(11, 51):
        lvl = make_level(n)
        # Chequeo de solvencia: capacidad >= fichas.
        cap = lvl["shelves"] * lvl["columns"] * lvl["depth"]
        assert cap >= lvl["triples"] * 3, "capacidad insuficiente en nivel %d" % n
        path = os.path.join(OUT, "level_%03d.json" % n)
        with open(path, "w", encoding="utf-8") as f:
            f.write(json.dumps(lvl, indent="\t", ensure_ascii=False))
            f.write("\n")
        print("nivel %02d  tipos=%d triples=%2d %dx%dx%d tray=%d time=%3d rew=%d dif=%d"
              % (n, len(lvl["goods"]), lvl["triples"], lvl["shelves"], lvl["columns"],
                 lvl["depth"], lvl["tray_slots"], lvl["time_limit"], lvl["reward_coins"],
                 lvl["difficulty"]))


if __name__ == "__main__":
    main()
