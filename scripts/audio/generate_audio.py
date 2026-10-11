"""Generate Rooftop Rumble's original, deterministic chiptune score and action cues.
Run with python3 scripts/audio/generate_audio.py; no external recordings or packages.
"""
import math
import random
import struct
import wave
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / 'assets/audio'
TAU = 2 * math.pi

def hz(note):
    return 440 * 2 ** ((note - 69) / 12)

def save(name, samples, rate):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / (name + '.wav')), 'wb') as audio:
        audio.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        audio.writeframes(struct.pack('<' + 'h' * len(samples), *[round(max(-.95, min(.95, v)) * 32767) for v in samples]))

def score(name, roots, melody, tempo):
    rate = 11025
    beat = 60 / tempo
    length = 32 * beat
    samples = [0.] * round(length * rate)
    rng = random.Random(17)
    def layer(start, duration, fn, level):
        begin = round(start * rate)
        for j in range(round(duration * rate)):
            i = (begin + j) % len(samples)
            t = j / rate
            envelope = min(1, t / .008) * max(0, 1 - t / duration) ** .7
            samples[i] += level * envelope * fn(t)
    for b in range(32):
        root = roots[(b // 4) % len(roots)]
        # Warm bass, soft offbeat chords, and an original bouncy arpeggio.
        layer(b * beat, beat * .78, lambda t, f=hz(root - 12): math.sin(TAU * f * t), .15)
        for interval in [0, 4 if name != 'neon' else 3, 7]:
            layer((b + .5) * beat, beat * .42, lambda t, f=hz(root + interval): math.sin(TAU * f * t), .038)
        note = melody[b % len(melody)] + (root - roots[0])
        layer(b * beat, beat * .7, lambda t, f=hz(note): math.sin(TAU*f*t) + .22*math.sin(TAU*f*2*t), .105)
        if b % 2 == 0:
            layer(b * beat, .14, lambda t: math.sin(TAU * (72*t - 170*t*t)), .20)
        else:
            layer(b * beat, .08, lambda t: rng.uniform(-1, 1), .09)
        layer((b + .5) * beat, .035, lambda t: rng.uniform(-1, 1), .035)
    # Start/end are exactly silent, preventing clicks at the seamless 8-bar boundary.
    save(name, samples, rate)

score('skyline', [48, 53, 55, 48, 57, 53, 55, 55], [72,76,79,76,74,77,81,77,79,83,81,77,76,74,72,79], 160)
score('neon', [45, 50, 48, 52, 45, 48, 50, 52], [69,72,76,79,76,74,72,76,81,79,76,74,72,71,69,76], 168)
score('garden', [53, 58, 60, 53, 62, 58, 60, 60], [77,81,84,88,84,81,79,77,79,82,86,82,81,79,77,81], 144)
rate = 22050
rng = random.Random(23)
# A short ascending pickup pop and a longer descending airy launch swoosh.
save('grab', [(math.sin(TAU*(420*t+1600*t*t))*.28 + math.sin(TAU*840*t)*.08) * min(1,t/.006) * (1-t/.14)**1.7 for t in (i/rate for i in range(round(.14*rate)))], rate)
save('throw', [(rng.uniform(-1,1)*.24 + math.sin(TAU*(560*t-700*t*t))*.16) * min(1,t/.015) * (1-t/.30)**1.6 for t in (i/rate for i in range(round(.30*rate)))], rate)
