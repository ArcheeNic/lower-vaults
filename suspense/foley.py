"""Create one mono acoustic signature per inhabitant. Requires numpy, scipy, ffmpeg."""
from pathlib import Path
import subprocess

import numpy as np
from scipy.signal import butter, fftconvolve, sosfilt

rate = 32000
rng = np.random.default_rng(80511)
out = Path(__file__).resolve().parent / "voices"


def noise(n, low, high):
    return sosfilt(butter(2, [low, high], fs=rate, btype="bandpass", output="sos"),
                   rng.standard_normal(n))


def contact(when, frequency, decay, gain, band, attack=.004):
    age = np.maximum(0, t - when)
    rasp = noise(len(t), *band)
    body = np.sin(2*np.pi*frequency*age + .64*(1-np.exp(-age/.013)))
    return gain * (1-np.exp(-age/attack))*np.exp(-age/decay) * (.72*body+.81*rasp)


def tone(when, frequency, decay, gain, attack=.018):
    age=np.maximum(0,t-when)
    return gain * np.sin(2*np.pi*frequency*age) * (1-np.exp(-age/attack)) * np.exp(-age/decay)


def brush(when, attack, decay, band, gain):
    age=np.maximum(0,t-when)
    return gain*noise(len(t),*band)*(1-np.exp(-age/attack))*np.exp(-age/decay)


names = ["lamplighter","bell_keeper","collector","pall_bearers","diver","returning_pilgrim",
         "frame_porter","watchman","scribe","spindle"]
t = np.arange(rate*2)/rate
for index, name in enumerate(names):
    sound = np.zeros_like(t)
    if index == 0:
        sound += contact(0,91,.047,.83,(140,1400))
        for i,f in enumerate([1030,1413,1840]): sound += tone(.063+i*.015,f,.059,.19)
    elif index == 1:
        sound += contact(0,59,.09,1,(80,640))
        for f,g in [(139,.56),(306,.32),(421,.15),(651,.14)]:
            sound += tone(.116,f,.64,g)
    elif index == 2:
        for i in range(5):
            sound += contact(.055*i,437+i*51,.018, .65-.07*i,(950,3800),.001)
        sound += brush(.19,.03,.13,(630,2250),.6)
    elif index == 3:
        sound += contact(0,89,.047,1,(130,1200))
        sound += contact(.162,112,.058,.81,(250,1520))
        sound += brush(.09,.03,.15,(1900,4100),.26)
    elif index == 4:
        sound += contact(0,56,.071,1,(95,740))
        sound += brush(.09,.085,.28,(260,880),.61) + tone(.098,194,.24,.22,.11)
        for j,f in enumerate([386,617,794]): sound += tone(.30+j*.08,f,.034,.14,.008)
    elif index == 5:
        sound += brush(0,.02,.13,(390,1700),.85)
        sound += contact(.15,167,.051,.82,(420,2300))
        sound += tone(.17,429,.074,.25)
    elif index == 6:
        for off,f,v in [(0,239,.79),(.075,349,.64),(.19,182,.70)]:
            sound += contact(off,f,.052,v,(300,1440),.002)
            sound += tone(off,f*2.1,.058,v*.27)
    elif index == 7:
        sound += contact(0,398,.023,.56,(660,2300),.002)
        for f,g in [(954,.45),(1474,.28),(2081,.13)]: sound += tone(.03,f,.37,g)
    elif index == 8:
        sound += brush(0,.028,.12,(1010,4070),.92)
        sound += brush(.21,.04,.20,(800,3300),.61)
        sound += contact(.18,190,.034,.38,(350,1800))
    else:
        for j in range(7):
            sound += contact(.032*j+.0015*j*j,246+21*j,.018,.71-.056*j,(420,2400),.002)
        sound += tone(0,141,.19,.24)
    time=np.arange(int(rate*1.5))/rate
    ir=noise(len(time),120,1830)*np.exp(-time/.28)*(1-np.exp(-time/.035))
    ir /= np.linalg.norm(ir)
    tail=fftconvolve(sound,ir)
    tail[:len(sound)] += sound*3.7
    data = .63*tail/max(abs(tail))
    subprocess.run(["ffmpeg","-loglevel","error","-y","-f","f32le","-ar",str(rate),"-ac","1","-i","pipe:0",
                    "-c:a","libvorbis","-q:a","3",str(out/(name+".ogg"))],
                   input=data.astype("<f4").tobytes(),check=True)
