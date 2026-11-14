#!/usr/bin/env python3
"""Reproducible original ENIGMA synth score, rain and interaction cues (CC0)."""
from pathlib import Path
import math
import random
import struct
import wave

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
RATE = 22050
rng = random.Random(314159)

def write(name, duration, sample):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as f:
        f.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        f.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, sample(i/RATE))) * 24000)) for i in range(int(RATE*duration))))

# Whole cycles at the loop boundary; low organ harmonics plus distant soft bells.
notes = [220, 261.6256, 329.6276, 293.6648, 220, 196, 246.9417, 164.8138]
def music(t):
    drone = sum(math.sin(2*math.pi*f*t)*a for f,a in [(55,.14),(82.5,.07),(110,.04),(165,.02)])
    beat = int(t / 2)
    u = t % 2
    bell = math.sin(2*math.pi*notes[beat % len(notes)]*u) * math.exp(-u*2.5)*.12
    return (drone + bell) * min(1,t/.15,(16-t)/.15)
write('station_theme',16,music)

low = 0.0
def rain(t):
    global low
    low = .92*low+.08*rng.uniform(-1,1)
    return (low*.65 + rng.uniform(-1,1)*.045) * min(1,t/.1,(8-t)/.1)
write('station_rain',8,rain)
write('touch',.16,lambda t: math.sin(2*math.pi*(700-900*t)*t)*math.exp(-t*35)*.25)
write('success',.9,lambda t: sum(math.sin(2*math.pi*f*t)*.10*math.exp(-max(0,t-o)*5) if t>=o else 0 for f,o in [(440,0),(554.365,.15),(659.255,.30),(880,.45)]))
write('mechanism',.65,lambda t: (math.sin(2*math.pi*(95+30*t)*t)*.10+rng.uniform(-1,1)*.10)*(1-t/.65))
write('train',3,lambda t: (math.sin(2*math.pi*110*t)+.6*math.sin(2*math.pi*146.832*t)+.3*math.sin(2*math.pi*220*t))*.11*min(1,t/.4,(3-t)/.8))
print('Generated six original audio assets.')
