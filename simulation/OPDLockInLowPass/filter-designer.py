"""This module calculates the filter coefficients for an FIR low pass filter."""
import os

import matplotlib.pyplot as plt
import numpy as np
import scipy.signal as sig
from matplotlib import rcParams
from matplotlib.ticker import EngFormatter

rcParams.update({"figure.autolayout": True})
formatter_hz = EngFormatter(unit="Hz")

# create plot directory
plot_dir = "fig/"
if not os.path.exists(plot_dir):
    os.makedirs(plot_dir)

# OPD lock-in amplifier low-pass filter
# fs = 128 kHz
# passband (0.99 < gain < 1.01): DC to 1.5 kHz
# passband (0.7 < gain < 1.01): 1.5 kHz to 4 kHz
# stopband: (gain < 1e-4): 10 kHz to 64 kHz

fs = 128e3  # sampling frequency, Hz

f1 = 1e3  # end of passband, Hz
f2 = 10e3  # start of stopband, Hz

f = np.linspace(0, fs / 2, 1000)


# gain function: 1 until f1, exponentially decreasing after f1
# def gain_func(f, f1, f2):
#     gain = np.zeros(len(f))
#     gain[(f < f1)] = 1
#     f_high = f[f >= f1]
#     f_high_idx = np.where(f >= f1)
#     gain[f_high_idx] = np.exp(- (f_high - f_high[0]) / f2)

#     return gain

desired_gain = np.zeros(len(f))
desired_gain[f < f1] = 1
desired_gain[f > f2] = 0.

weight = np.zeros(len(f))
weight[(f < f1)] = 1
weight[f > f2] = 1

# remove every second element from weight
weight_bands = weight[::2]

num_stages_fir_filter = 61

# use firls to design the filter
fir_filter = sig.firls(numtaps=num_stages_fir_filter, bands=f, desired=desired_gain, weight=weight_bands, fs=fs)


# get h for plotting
w, H = sig.freqz(fir_filter, worN=2**14)
w = w * fs / (2 * np.pi)  # convert to Hz

# log plot of filter response
fig, ax = plt.subplots()
ax.loglog(w, abs(H), label="Filter response")
ax.plot(f, desired_gain, label="Desired response")
ax.plot(f, weight, label="Weight", alpha=0.2)
ax.xaxis.set_major_formatter(formatter_hz)
ax.set_title("Filter response")
ax.set_ylabel("Gain")
ax.set_xlabel("Frequency (Hz)")
ax.legend()
# fig.savefig(plot_dir + "filter-response-log.pdf", bbox_inches="tight")
plt.show()

# linear plot of filter response
fig, ax = plt.subplots()
ax.plot(w, abs(H), label="Filter response")
ax.plot(f, desired_gain, label="Desired response")
ax.plot(f, weight, label="Weight", alpha=0.2)
ax.xaxis.set_major_formatter(formatter_hz)
ax.set_title("Filter response")
ax.set_ylabel("Gain")
ax.set_xlabel("Frequency (Hz)")
ax.legend()
# fig.savefig(plot_dir + "filter-response-lin.pdf", bbox_inches="tight")
plt.show()


# scale coefficients to 32 bit ints
fir_filter = fir_filter * 2**31 - 1
fir_filter = np.round(fir_filter).astype(int)

# print scaled coefficients
# format: {0, 0, 0, ...}
print("Scaled FIR filter coefficients:")
print("'{", end="")
for i in range(len(fir_filter) - 1):
    print(f"{fir_filter[i]}, ", end="")
print(f"{fir_filter[-1]}}}")
