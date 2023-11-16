"""This module calculates the filter coefficients for the FIR bandpass input filter."""
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


fs = 64e3/128  # sampling frequency, Hz
f1 = 0
f2 = 50
num_stages_fir_filter = 41

f = np.linspace(0, fs / 2, 1000)

# desired filter response
desired_gain = np.zeros(len(f))
desired_gain[(f >= f1) & (f <= f2)] = 1

weight = np.zeros(len(f))
weight[(f <= f2)] = 1
weight[(f >= 100)] = 1

# remove every second element from weight
weight_bands = weight[::2]



# use firls to design the filter
fir_filter = sig.firls(num_stages_fir_filter, f, desired_gain, weight_bands, fs=fs)


# get h for plotting
w, H = sig.freqz(fir_filter, worN=1024)
w = w * fs / (2 * np.pi)  # convert to Hz

# log plot of filter response
fig, ax = plt.subplots()
ax.plot(w, abs(H), label="Filter response")
ax.plot(f, desired_gain, label="Desired response")
ax.plot(f, weight, label="Weight", alpha=0.2)
ax.xaxis.set_major_formatter(formatter_hz)
ax.set_title("Filter response")
ax.set_ylabel("Gain")
ax.set_xlabel("Frequency (Hz)")
ax.set_yscale("log")
ax.legend()
# fig.savefig(plot_dir + "filter-response-log.pdf", bbox_inches="tight")
plt.show()

# linear plot of filter response
# fig, ax = plt.subplots()
# ax.plot(w, abs(H), label="Filter response")
# ax.plot(f, desired_gain, label="Desired response")
# ax.plot(f, weight, label="Weight", alpha=0.2)
# ax.xaxis.set_major_formatter(formatter_hz)
# ax.set_title("Filter response")
# ax.set_ylabel("Gain")
# ax.set_xlabel("Frequency (Hz)")
# ax.legend()
# plt.show()


# scale coefficients to 24 bit ints
fir_filter = fir_filter * 2**23 - 1
fir_filter = np.round(fir_filter).astype(int)

# print scaled coefficients
# format: {0, 0, 0, ...}
print("Scaled FIR filter coefficients:")
print("'{", end="")
for i in range(len(fir_filter) - 1):
    print(f"{fir_filter[i]}, ", end="")
print(f"{fir_filter[-1]}}}")
