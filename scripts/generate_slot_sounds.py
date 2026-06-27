#!/usr/bin/env python3
"""Generate slot-machine sound effects as WAV files (procedural, no external assets)."""

import math
import random
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
OUT_DIR = Path(__file__).resolve().parent.parent / "CraveSpin" / "Resources" / "Sounds"
RNG = random.Random(42)


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = max(abs(s) for s in samples) or 1.0
    scale = 32767 * 0.94 / peak
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * scale)))) for s in samples)
        wf.writeframes(frames)


def env(length: int, attack: float, hold: float, release: float) -> list[float]:
    attack_n = int(SAMPLE_RATE * attack)
    hold_n = int(SAMPLE_RATE * hold)
    release_n = int(SAMPLE_RATE * release)
    out = []
    for i in range(length):
        if i < attack_n and attack_n:
            out.append(i / attack_n)
        elif i < attack_n + hold_n:
            out.append(1.0)
        else:
            r = i - attack_n - hold_n
            out.append(max(0.0, 1.0 - r / release_n) if release_n else 0.0)
    return out


def sine(freq: float, duration: float, volume: float = 0.3, phase: float = 0.0) -> list[float]:
    n = int(SAMPLE_RATE * duration)
    return [
        volume * math.sin(2 * math.pi * freq * (i / SAMPLE_RATE) + phase)
        for i in range(n)
    ]


def white_noise(n: int) -> list[float]:
    return [RNG.uniform(-1.0, 1.0) for _ in range(n)]


def lowpass(samples: list[float], cutoff_hz: float) -> list[float]:
    dt = 1.0 / SAMPLE_RATE
    rc = 1.0 / (2 * math.pi * cutoff_hz)
    alpha = dt / (rc + dt)
    out = []
    prev = 0.0
    for s in samples:
        prev = prev + alpha * (s - prev)
        out.append(prev)
    return out


def highpass(samples: list[float], cutoff_hz: float) -> list[float]:
    dt = 1.0 / SAMPLE_RATE
    rc = 1.0 / (2 * math.pi * cutoff_hz)
    alpha = rc / (rc + dt)
    out = []
    prev_in = 0.0
    prev_out = 0.0
    for s in samples:
        out_s = alpha * (prev_out + s - prev_in)
        prev_in = s
        prev_out = out_s
        out.append(out_s)
    return out


def apply_env(samples: list[float], envelope: list[float]) -> list[float]:
    n = min(len(samples), len(envelope))
    return [samples[i] * envelope[i] for i in range(n)]


def pad(track: list[float], offset: int) -> list[float]:
    return [0.0] * offset + track


def mix(*tracks: list[float]) -> list[float]:
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for track in tracks:
        for i, sample in enumerate(track):
            out[i] += sample
    return out


def spin_pull() -> list[float]:
    """Lever yank, latch release, and motor engage."""
    handle = apply_env(
        mix(
            sine(78, 0.09, 0.55),
            sine(156, 0.06, 0.18),
            lowpass(white_noise(int(SAMPLE_RATE * 0.05)), 420),
        ),
        env(int(SAMPLE_RATE * 0.09), 0.001, 0.02, 0.06),
    )

    latch = apply_env(
        mix(
            sine(240, 0.025, 0.35),
            highpass(white_noise(int(SAMPLE_RATE * 0.03)), 1800),
        ),
        env(int(SAMPLE_RATE * 0.03), 0.0005, 0.004, 0.02),
    )

    spring = []
    n = int(SAMPLE_RATE * 0.07)
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 420 - t * 2200
        spring.append(0.22 * math.sin(2 * math.pi * max(80, freq) * t) * math.exp(-t * 28))
    spring = apply_env(spring, env(n, 0.001, 0.01, 0.04))

    motor = apply_env(
        mix(
            sine(58, 0.16, 0.42),
            sine(116, 0.16, 0.16),
            sine(174, 0.16, 0.07),
            lowpass(white_noise(int(SAMPLE_RATE * 0.16)), 180),
        ),
        env(int(SAMPLE_RATE * 0.16), 0.004, 0.08, 0.06),
    )

    return mix(
        pad(handle, 0),
        pad(latch, int(SAMPLE_RATE * 0.055)),
        pad(spring, int(SAMPLE_RATE * 0.04)),
        pad(motor, int(SAMPLE_RATE * 0.11)),
    )


def chime_note(freq: float, duration: float = 0.09, volume: float = 0.38) -> list[float]:
    """Bright music-box / glockenspiel tone with bell harmonics."""
    n = int(SAMPLE_RATE * duration)
    envelope = env(n, 0.001, 0.012, duration - 0.013 if duration > 0.025 else 0.012)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        decay = math.exp(-t * 22)
        tone = (
            math.sin(2 * math.pi * freq * t) * 1.0
            + math.sin(2 * math.pi * freq * 2.0 * t) * 0.32
            + math.sin(2 * math.pi * freq * 3.0 * t) * 0.12
            + math.sin(2 * math.pi * freq * 4.02 * t) * 0.06
        ) * decay
        out.append(volume * tone * envelope[i])
    return out


# C major pentatonic — every tick stays in key.
PENTATONIC = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.50]


def reel_tick(variant: int) -> list[float]:
    """Musical reel clink — pentatonic chime with a soft mechanical tap."""
    freq = PENTATONIC[(variant - 1) % len(PENTATONIC)]
    detune = RNG.uniform(0.998, 1.002)

    chime = chime_note(freq * detune, duration=0.1, volume=0.42)

    sparkle = apply_env(
        sine(freq * 2.0 * detune, 0.045, 0.1),
        env(int(SAMPLE_RATE * 0.045), 0.001, 0.008, 0.034),
    )

    tap = apply_env(
        sine(140, 0.018, 0.08),
        env(int(SAMPLE_RATE * 0.018), 0.0003, 0.002, 0.012),
    )

    return mix(chime, sparkle, tap)


def spin_loop() -> list[float]:
    """Seamless mechanical motor + reel whir (2.0s loop)."""
    length = SAMPLE_RATE * 2
    hum_f = 58.0
    cycles = hum_f * 2.0
    assert abs(cycles - round(cycles)) < 0.001

    out = []
    for i in range(length):
        t = i / SAMPLE_RATE

        motor = (
            math.sin(2 * math.pi * hum_f * t) * 0.26
            + math.sin(2 * math.pi * hum_f * 2 * t) * 0.11
            + math.sin(2 * math.pi * hum_f * 3 * t) * 0.05
        )

        belt = math.sin(2 * math.pi * 13.5 * t) * 0.04
        wobble = 0.85 + 0.15 * math.sin(2 * math.pi * 3.7 * t)

        tooth_rate = 14.0
        tooth = math.sin(2 * math.pi * tooth_rate * t)
        tooth_click = max(0.0, tooth) ** 8 * 0.09
        sample = (motor + belt) * wobble + tooth_click
        out.append(sample)

    friction_track = apply_env(
        [s * 0.045 for s in lowpass(white_noise(length), 420)],
        env(length, 0.05, 1.7, 0.15),
    )

    bearing = [
        0.025 * math.sin(2 * math.pi * 740 * t) * (0.4 + 0.6 * max(0, math.sin(2 * math.pi * 14 * t)))
        for t in (i / SAMPLE_RATE for i in range(length))
    ]

    return mix(out, friction_track, bearing)


def coin_ting(start: int, freq: float, volume: float = 0.16) -> list[float]:
    n = int(SAMPLE_RATE * 0.055)
    body = apply_env(
        mix(
            sine(freq, 0.055, volume),
            sine(freq * 2.01, 0.04, volume * 0.35),
            highpass(white_noise(int(SAMPLE_RATE * 0.012)), 2500),
        ),
        env(n, 0.0005, 0.004, 0.045),
    )
    return pad(body, start)


def happy_chord(freq: float, duration: float, start: float, volume: float = 0.22) -> list[float]:
    """Major triad shimmer."""
    third = freq * 5 / 4
    fifth = freq * 3 / 2
    body = apply_env(
        mix(
            sine(freq, duration, volume),
            sine(third, duration, volume * 0.82),
            sine(fifth, duration, volume * 0.72),
            sine(freq * 2, duration, volume * 0.28),
        ),
        env(int(SAMPLE_RATE * duration), 0.003, duration * 0.55, duration * 0.4),
    )
    return pad(body, int(SAMPLE_RATE * start))


def winner() -> list[float]:
    """Upbeat major-key win — arpeggio, bells, sparkle, coins."""
    # Bright ascending "ta-da!" in C major
    melody = [
        (523.25, 0.00, 0.11),
        (659.25, 0.07, 0.11),
        (783.99, 0.14, 0.11),
        (1046.50, 0.21, 0.14),
        (1318.51, 0.30, 0.16),
    ]
    melody_track: list[float] = []
    for freq, start, dur in melody:
        melody_track = mix(
            melody_track,
            pad(chime_note(freq, duration=dur, volume=0.46), int(SAMPLE_RATE * start)),
        )

    chord_track = mix(
        happy_chord(523.25, 0.55, 0.38, volume=0.24),
        happy_chord(659.25, 0.45, 0.42, volume=0.16),
    )

    sparkle_notes = [(1567.98, 0.34), (1760.0, 0.40), (2093.0, 0.47)]
    sparkle_track: list[float] = []
    for freq, start in sparkle_notes:
        sparkle_track = mix(
            sparkle_track,
            pad(chime_note(freq, duration=0.14, volume=0.28), int(SAMPLE_RATE * start)),
        )

    coin_track: list[float] = []
    coin_times = [0.52, 0.56, 0.60, 0.64, 0.68, 0.72, 0.76, 0.80, 0.84, 0.88, 0.92, 0.96]
    for i, t in enumerate(coin_times):
        freq = PENTATONIC[i % len(PENTATONIC)] * 2.0
        coin_track = mix(
            coin_track,
            coin_ting(int(SAMPLE_RATE * t), freq, volume=RNG.uniform(0.12, 0.18)),
        )

    shower = apply_env(
        highpass(lowpass(white_noise(int(SAMPLE_RATE * 0.5)), 7200), 1400),
        env(int(SAMPLE_RATE * 0.5), 0.008, 0.28, 0.18),
    )
    shower = pad([s * 0.1 for s in shower], int(SAMPLE_RATE * 0.55))

    return mix(melody_track, chord_track, sparkle_track, coin_track, shower)


def main() -> None:
    write_wav(OUT_DIR / "spin_pull.wav", spin_pull())
    write_wav(OUT_DIR / "spin_loop.wav", spin_loop())
    write_wav(OUT_DIR / "winner.wav", winner())
    for i in range(1, 7):
        write_wav(OUT_DIR / f"reel_tick_{i}.wav", reel_tick(i))
    print(f"Wrote sounds to {OUT_DIR}")


if __name__ == "__main__":
    main()
