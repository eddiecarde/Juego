#!/usr/bin/env python3
"""Genera efectos de sonido placeholder (WAV 16-bit mono) para el juego."""
import math
import struct
import wave
import os

RATE = 44100
OUT = "/home/user/Juego/assets/audio"
os.makedirs(OUT, exist_ok=True)


def env(i, n, attack=0.01, release=0.25):
    """Envolvente ADSR simple para evitar clics."""
    t = i / n
    a = min(1.0, (i / RATE) / attack) if attack > 0 else 1.0
    r = min(1.0, ((n - i) / RATE) / release) if release > 0 else 1.0
    return a * r


def tone(freq, dur, vol=0.5, wave_type="sine"):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        if wave_type == "sine":
            s = math.sin(2 * math.pi * freq * t)
        elif wave_type == "square":
            s = 1.0 if math.sin(2 * math.pi * freq * t) >= 0 else -1.0
        else:  # triangle
            s = 2 / math.pi * math.asin(math.sin(2 * math.pi * freq * t))
        out.append(s * vol * env(i, n))
    return out


def sequence(notes, wave_type="sine"):
    """notes = [(freq, dur, vol), ...] concatenadas."""
    data = []
    for f, d, v in notes:
        data.extend(tone(f, d, v, wave_type))
    return data


def save(name, samples):
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        )
        w.writeframes(frames)
    print("escrito", path)


# tap: clic corto y agudo
save("tap.wav", tone(880, 0.06, 0.4, "triangle"))

# match: dos notas ascendentes agradables
save("match.wav", sequence([(660, 0.09, 0.45), (988, 0.14, 0.45)]))

# coin: blip rápido tipo moneda
save("coin.wav", sequence([(1200, 0.05, 0.4), (1600, 0.09, 0.4)], "square"))

# win: arpegio ascendente alegre (Do-Mi-Sol-Do)
save("win.wav", sequence([
    (523, 0.11, 0.5), (659, 0.11, 0.5), (784, 0.11, 0.5), (1047, 0.22, 0.5),
]))

# lose: dos notas descendentes
save("lose.wav", sequence([(392, 0.16, 0.5), (262, 0.28, 0.5)], "triangle"))
