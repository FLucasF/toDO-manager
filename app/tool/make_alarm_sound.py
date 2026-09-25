"""Generates the "Despertador" sound (a classic digital alarm clock) used by the Pomodoro and the
reminders: bursts of four high beeps and a pause, four times (about 4 s), looping without a click.

Synthesized here, so there is no licence to worry about. Writes the Flutter asset (played by the app
on Windows) and the Android raw resource (the notification channel's sound).

    python tool/make_alarm_sound.py
"""

import math
import os
import shutil
import struct
import wave

RATE = 44100
FREQ = 2900.0  # Hz: the piercing pitch of a digital alarm clock
BEEP = 0.075  # s
GAP = 0.055  # s between the beeps of a burst
PAUSE = 0.48  # s after each burst
BEEPS_PER_BURST = 4
BURSTS = 4
EDGE = 0.004  # s of fade in / out on each beep, so it doesn't click
VOLUME = 0.45


def tone(t):
    # A softened square wave (odd harmonics), brighter than a sine, as a buzzer.
    x = 2 * math.pi * FREQ * t
    return math.sin(x) + math.sin(3 * x) / 3 + math.sin(5 * x) / 8


def beep():
    n = int(BEEP * RATE)
    edge = int(EDGE * RATE)
    out = []
    for i in range(n):
        env = min(1.0, i / edge, (n - 1 - i) / edge)
        out.append(tone(i / RATE) * env)
    return out


def silence(seconds):
    return [0.0] * int(seconds * RATE)


def main():
    samples = []
    for _ in range(BURSTS):
        for b in range(BEEPS_PER_BURST):
            samples += beep()
            samples += silence(GAP if b < BEEPS_PER_BURST - 1 else PAUSE)
    peak = max(abs(s) for s in samples)
    frames = b''.join(struct.pack('<h', int(s / peak * VOLUME * 32767)) for s in samples)

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    asset = os.path.join(root, 'assets', 'sounds', 'despertador.wav')
    os.makedirs(os.path.dirname(asset), exist_ok=True)
    with wave.open(asset, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)
    raw = os.path.join(root, 'android', 'app', 'src', 'main', 'res', 'raw', 'despertador.wav')
    os.makedirs(os.path.dirname(raw), exist_ok=True)
    shutil.copyfile(asset, raw)
    print(f'{asset} ({len(samples) / RATE:.2f} s)')


if __name__ == '__main__':
    main()
