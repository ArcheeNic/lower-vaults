"""Render short mono sources for the moving room fixtures (numpy, scipy, ffmpeg)."""
import subprocess
from pathlib import Path

import numpy as np
from scipy.signal import butter, fftconvolve, sosfilt

RATE = 32000
OUT = Path(__file__).resolve().parent / "fixtures"
rng = np.random.default_rng(22850)
t = np.arange(int(RATE * 1.5)) / RATE


def age(when):
    return np.maximum(t - when, 0.)


def envelope(a, attack, decay):
    return (1. - np.exp(-a / attack)) * np.exp(-a / decay)


def noise(low, high, n):
    taps = butter(2, (low, high), fs=RATE, btype="bandpass", output="sos")
    return sosfilt(taps, rng.standard_normal(n))


def tap(when, frequency, decay, gain):
    a = age(when)
    return gain * envelope(a, .0015, decay) * np.sin(2. * np.pi * frequency * a)


def brush(when, low, high, attack, decay):
    return envelope(age(when), attack, decay) * noise(low, high, len(t))


def clock():
    # The escapement catches first, then the wooden case answers.
    return (tap(0, 1970, .011, .8) + tap(.009, 711, .039, .55)
            + tap(.014, 411, .044, .35) + .65 * brush(0, 1700, 6800, .0008, .011))


def machine():
    dry = .8 * brush(0, 260, 1270, .07, .19)
    for i, when in enumerate([.06, .115, .165, .211]):
        dry += tap(when, 209 - 12 * i, .043, .25 + .07 * i)
    return dry + tap(.25, 96, .13, .8) + .45 * brush(.25, 430, 2200, .002, .06)


def water():
    dry = .93 * brush(0, 450, 3900, .02, .18)
    for when, pitch in [(0., 770), (.042, 522), (.098, 870), (.17, 618), (.29, 1050)]:
        a = age(when)
        phase = 2 * np.pi * pitch * (a - .013 * (1 - np.exp(-a / .022)))
        dry += .36 * envelope(a, .003, .032) * np.sin(phase)
    return dry


def rustle():
    dry = np.zeros_like(t)
    for when, gain in [(0., .95), (.09, .53), (.22, .31)]:
        dry += gain * brush(when, 1100, 5700, .028, .092)
        dry += .22 * gain * brush(when + .025, 330, 890, .037, .062)
    return dry


def shuttle():
    # The shuttle hits the wooden box, then the reed settles against the warp.
    return (tap(0, 518, .018, .88) + tap(.004, 264, .035, .72)
            + .9 * brush(0, 620, 3000, .002, .027)
            + .5 * brush(.033, 1150, 3900, .012, .074))


def bell():
    return (tap(0, 291, .42, .70) + tap(0, 689, .30, .35)
            + tap(0, 873, .24, .22) + tap(0, 1266, .14, .20)
            + .22 * brush(0, 850, 4700, .002, .022))


def fork():
    return (tap(0, 440, .55, .72) + tap(.003, 441.9, .46, .49)
            + tap(0, 2741, .029, .18) + .14 * brush(0, 660, 2200, .001, .018))


def vent():
    a = age(.08)
    rising = np.sin(2 * np.pi * (125 * t + 31 * t**2))
    return (.60 * brush(0., 110, 580, .035, .26)
            + 1.1 * brush(.07, 1800, 6800, .05, .24)
            + .19 * rising * envelope(a, .10, .27))


def render(name, dry):
    ir_time = np.arange(int(.46 * RATE)) / RATE
    ir = noise(160, 2400, len(ir_time)) * envelope(ir_time, .023, .075)
    ir /= np.linalg.norm(ir)
    wet = .16 * fftconvolve(dry, ir)
    wet[:len(dry)] += dry
    wet *= .68 / max(abs(wet))
    end = np.flatnonzero(abs(wet) > .0009)[-1] + 192
    wet = wet[:end]
    wet[-192:] *= np.linspace(1., 0., 192)
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", "1",
         "-i", "pipe:0", "-c:a", "libvorbis", "-q:a", "4", str(OUT / (name + ".ogg"))],
        input=wet.astype("<f4").tobytes(), check=True,
    )


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    for make in (clock, machine, water, rustle, shuttle, bell, fork, vent):
        render(make.__name__, make())
