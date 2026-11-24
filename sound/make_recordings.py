"""Synthesize the original sounds. Run from any directory with numpy, scipy and ffmpeg."""
from pathlib import Path
import subprocess

import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve

RATE = 32000
OUT = Path(__file__).resolve().parent
rng = np.random.default_rng(7331)


def band(noise, low, high):
    return sosfilt(butter(2, [low, high], fs=RATE, btype="bandpass", output="sos"), noise)


def wave(t, frequency):
    return np.sin(2 * np.pi * frequency * t)


def attack(t, seconds):
    return 1 - np.exp(-t / seconds)


def export(name, data, peak):
    signal = data * (peak / np.max(np.abs(data)))
    channels = 1 if signal.ndim == 1 else signal.shape[1]
    command = ["ffmpeg", "-loglevel", "error", "-y", "-f", "f32le", "-ar", str(RATE),
               "-ac", str(channels), "-i", "pipe:0", "-c:a", "libvorbis", "-q:a", "4",
               str(OUT / (name + ".ogg"))]
    subprocess.run(command, input=signal.astype("<f4").tobytes(), check=True)


def periodic_air(length, frequency, envelope):
    # Spectral synthesis gives every air band a seamless loop, including its noise.
    frequencies = np.fft.rfftfreq(length, 1 / RATE)
    response = np.exp(-0.5 * (np.log2((frequencies + 0.001) / frequency) / envelope) ** 2)
    noise = np.fft.rfft(rng.standard_normal(length)) * response
    return np.fft.irfft(noise, n=length) / np.sqrt(np.mean(response ** 2))


def gallery_air():
    duration = 42
    n = RATE * duration
    phase = np.arange(n) * 2 * np.pi / n
    common = periodic_air(n, 82, .53) * (.56 + .14 * np.cos(2 * phase + 1.2))
    common += periodic_air(n, 235, .33) * (.11 + .04 * np.sin(5 * phase))
    channels = []
    for side in [-1, 1]:
        wash = periodic_air(n, 420, .84) * (.15 + .065 * np.sin(3 * phase + side))
        breath = periodic_air(n, 810, .18) * (.024 + .021 * np.cos(phase + side))
        hum = .097 * np.sin(phase * 2184 + .65 * np.sin(phase * 3 + side * .2))
        hum += .043 * np.sin(phase * 5482 + .27 * np.sin(phase * 2))
        channels.append(common + wash + breath + hum)
    export("air", np.stack(channels, axis=1), .42)


def impulse_response(seconds, damp):
    t = np.arange(int(seconds * RATE)) / RATE
    room = band(rng.standard_normal(t.size), 110, damp)
    response = room * attack(t, .055) * np.exp(-t / (seconds / 7.4))
    response /= np.linalg.norm(response)
    return response


def sole():
    t = np.arange(int(.43 * RATE)) / RATE
    grit = band(rng.standard_normal(t.size), 670, 3700)
    heel = .82 * wave(t, 68 + 44 * np.exp(-t / .022)) + .39 * wave(t, 156)
    sound = (heel + .4 * band(rng.standard_normal(t.size), 105, 720)) * attack(t, .004) * np.exp(-t / .034)
    roll = np.maximum(0, t - rng.uniform(.041, .086))
    sound += .48 * (wave(roll, rng.uniform(70, 94)) + .49 * band(rng.standard_normal(t.size), 160, 1400)) * attack(roll, .005) * np.exp(-roll / .044)
    sound += .24 * grit * attack(roll, .012) * np.exp(-roll / .04)
    for when in rng.uniform(.004, .105, 7):
        contact = np.maximum(0, t - when)
        sound += grit * rng.uniform(.07, .16) * attack(contact, .0006) * np.exp(-contact / .004)
    return sound


def footsteps():
    for i in range(4):
        foot = sole()
        tail = fftconvolve(foot, impulse_response(1.25, 1550))
        mixed = np.pad(foot, (0, len(tail) - len(foot))) + .042 * tail
        export("stone_" + str(i + 1), mixed, .75)
    far = band(sole(), 75, 930)
    wet = fftconvolve(far, impulse_response(2.3, 1250))
    wet[:far.size] += far * 1.0
    export("reply", wet, .65)


def distant_sounds():
    t = np.arange(RATE * 3) / RATE
    noise = rng.standard_normal(len(t))
    metal = np.zeros_like(t)
    for f, gain, decay in [(173, .55, 1.15), (236, .22, .76), (441, .18, 1.25), (795, .12, .26), (1084, .07, .37)]:
        rub = .94 + .06 * np.sin(2 * np.pi * 2.2 * t + f)
        metal += np.sin(2 * np.pi * f * t + .22 * wave(t, 2.3)) * gain * rub * np.exp(-t / decay)
    metal *= attack(t, .21)
    metal += .32 * band(noise, 250, 850) * attack(t, .09) * np.exp(-t / .37)
    stone = np.zeros_like(t)
    for when, gain in [(0, .30), (.17, .65), (.51, .17), (.85, .13)]:
        time = np.maximum(0, t - when)
        stone += (wave(time, 97) + .90 * band(noise, 280, 1560)) * attack(time, .003) * np.exp(-time / .075) * gain
    for name, dry in [("strain", metal), ("settling", stone)]:
        wet = fftconvolve(dry, impulse_response(3.9, 1400)) * .30
        wet[:dry.size] += .66 * dry
        export(name, wet, .69)


def realm_layers():
    n = 26 * RATE
    phase = np.arange(n) * 2 * np.pi / n
    water, orbit, works = [], [], []
    for side in [-1, 1]:
        flow = periodic_air(n, 1450, .88) * (.20 + .095 * np.cos(phase * 2 + side))
        flow += periodic_air(n, 330, .58) * .29
        whistle = periodic_air(n, 127, .42) * (.78 + .22 * np.cos(2 * phase + side * .7))
        whistle += periodic_air(n, 870, .14) * (.12 + .09 * np.cos(3 * phase + side))
        whistle += .18 * np.sin(phase * 5901 + 5 * np.sin(phase * 2 + side * .2))
        whistle += .06 * np.sin(phase * 9683 + 4 * np.cos(phase))
        gear = periodic_air(n, 330, .95) * (.18 + .07 * np.cos(phase * 47))
        gear += .20 * np.sin(phase * 2078 + 1.2 * np.sin(phase * 30))
        for i in range(36):
            # Scatter the same gear tooth striking in a repeating cycle.
            start = int(i * n / 36 + rng.uniform(0, .09) * RATE)
            t = np.arange(int(.63 * RATE)) / RATE
            stem = (.8 * wave(t, 172) + .44 * wave(t, 309) + .2 * wave(t, 508))
            stem += .9 * band(rng.standard_normal(t.size), 600, 2350)
            gear[(start + np.arange(t.size)) % n] += stem * attack(t, .012) * np.exp(-t / .093) * (.75 if i % 3 == 0 else .32)
        for i in range(30):
            start = rng.integers(0, n)
            t = np.arange(int(.65 * RATE)) / RATE
            pitch = rng.uniform(430, 1380)
            bubble = np.sin(2*np.pi*pitch*(t+.009*np.exp(-t/.03))) * attack(t,.004) * np.exp(-t/.044)
            bubble += .24*wave(t, pitch*.51) * attack(t,.009) * np.exp(-t/.17)
            flow[(start + np.arange(t.size)) % n] += bubble * rng.uniform(.64, 1.7)
        water.append(flow)
        works.append(gear)
        orbit.append(whistle)
    for name, channels in [("cistern",water),("orbit",orbit),("machine",works)]:
        export(name, np.stack(channels, axis=1), .67)
    pressure = []
    for side in [-1, 1]:
        pulse = (.5-.5*np.cos(phase*6 + .48*np.sin(phase*2)))**2
        breath = periodic_air(n, 580, .75) * (.18 + .55*pulse)
        breath += (.24+.21*pulse) * np.sin(phase*1514 + .36*np.sin(phase*4 + side*.22))
        breath += .20*np.sin(phase*1925 + .42*np.cos(phase))
        breath += .11*periodic_air(n, 141, .45)
        pressure.append(breath)
    export("pressure", np.stack(pressure, axis=1), .64)


if __name__ == "__main__":
    gallery_air()
    footsteps()
    distant_sounds()
    realm_layers()
