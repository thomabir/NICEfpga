import matplotlib.pyplot as plt
import numpy as np
import scipy.signal as sig
from matplotlib import rcParams
from matplotlib.ticker import EngFormatter

rcParams.update({"figure.autolayout": True})
formatter_hz = EngFormatter(unit="Hz")


# the frequency response of the CIC decimator
def H(freqs, ratio, order):
    """
    Implements CIC filter transfer function.

    H = (H_Integrator * H_Comb)^N = ( (1 - z^(-R*M)) / (1 - z^(-1)) )^N

    (The transfer function of an integrator and a decimator are the same)

    freqs: Normalized frequency (f/fs), usually an array
    ratio: R, sample rate change (R = 1, 2, ... etc)
    order: N (N = 1, 2, ... etc)

    here the differential delay M is fixed to 1
    """

    z = np.exp(-2.0j * freqs * np.pi)
    z = z + 1e-10  # hack to avoid divisions by zero
    stage = (1.0 - z ** (-ratio)) / (1.0 - z ** (-1)) / ratio
    return stage**order


def print_verilog_array(array):
    """Prints an array in Verilog format, e.g. {10, 3, 2}"""

    print("{", end="")
    for i, element in enumerate(array):
        print(f"{element}", end="")

        # unless it's the last element, print ", "
        if i != len(array) - 1:
            print(", ", end="")
    print("};")


def float_to_fixed(x, n_bits=16):
    """Converts a floating point number to a signed fixed point number with n_bits bits.

    The range [-1, 1] gets mapped to the range [-2^(n_bits-1)-1, 2^(n_bits-1)-1].
    Note that the most negative signed integer gets mapped to slightly less than -1, because of the assymmetry inherent to standard signed integers.
    """
    return int(x * (2 ** (n_bits - 1) - 1))


def float_to_fixed_arr(arr, n_bits=16):
    """Converts a floating point array to a signed fixed point array with n_bits bits.

    The range [-1, 1] gets mapped to the range [-2^(n_bits-1)-1, 2^(n_bits-1)-1].
    """
    return [int(x * (2 ** (n_bits - 1) - 1)) for x in arr]


# parameters
bits_input = 24
fs_1 = 64e3  # Hz, input sampling freq
decimationRatio = 64  # power of 2
order = 5  # number of stages

#
bits_internal = np.ceil(np.log2(decimationRatio**order)) + bits_input
fs_2 = fs_1 / decimationRatio  # Hz, output sampling freq

# print parameters
print(f"input bits: {bits_input}")
print(f"output bits: {bits_input}")
print(f"input sampling freq: {fs_1} Hz")
print(f"decimation ratio: {decimationRatio}")
print(f"order: {order}")
print(f"output sampling freq: {fs_2} Hz")
print(f"internal bits required: {bits_internal}")


## 1 Freq response of CIC decimator


# input sampling freq
fsn_1 = 1.0  # normalized sampling freq
fn_1 = np.linspace(0, fsn_1 / 2, 1000)  # normalized frequency array
f_1 = fn_1 * fs_1  # actual frequency array

# output sampling freq
fsn_2 = fsn_1 / decimationRatio  # normalized sampling freq
fn_2 = np.linspace(0, fsn_2 / 2, 1000)  # normalized frequency array
f_2 = fn_2 * fs_1  # actual frequency array


H_cic = H(fn_1, decimationRatio, order)

# Bode plot
fig, ax = plt.subplots()
ax.semilogy(f_1, np.abs(H_cic))
ax.xaxis.set_major_formatter(formatter_hz)
# plt.xlim(0, 1)
ax.set_ylim(1e-6, 2)
ax.set_title("Magnitude response of CIC decimator")
ax.set_ylabel("Gain")
ax.set_xlabel("Frequency")
fig.savefig("01-cic-decimator-freq-response.pdf", bbox_inches="tight")


# Zoom into the low freq region of the plot above
fig, ax = plt.subplots()
ax.plot(f_1, np.abs(H_cic))
ax.xaxis.set_major_formatter(formatter_hz)
plt.xlim(0, fs_2)
# ax.set_ylim(1e-6, 2)
ax.set_title("Zoomed in magnitude response of CIC decimator")
ax.set_ylabel("Gain")
ax.set_xlabel("Frequency (Hz)")
fig.savefig("02-cic-decimator-freq-response-zoom.pdf", bbox_inches="tight")


freqResponseCompensation = 1 / np.abs(H(fn_1 / decimationRatio, decimationRatio, order))  # ** 2

# add a high frequency cut-off
pass_high_freq = 280  # Hz
cutoff_high = f_2 > pass_high_freq
freqResponseCompensation[cutoff_high] = 0

# add a low frequency cut-off
pass_low_freq = 230  # Hz
cutoff_low = f_2 < pass_low_freq
freqResponseCompensation[cutoff_low] = 0

# block everything until dc_block_freq
low_block_freq = 150  # Hz
high_block_freq = 400  # Hz

# Plot of the required frequency compensation filter
fig, ax = plt.subplots()
ax.plot(f_2, freqResponseCompensation)


ax.set_title("Frequency response of the required compensation filter")
ax.set_ylabel("Gain")
ax.set_xlabel("Normalized frequency")
fig.savefig("03-compensation-filter-required.pdf", bbox_inches="tight")


num_stages_compFilter = 35
weight = np.zeros((500))
f_weight = np.linspace(0, fs_2 / 2, 500)
weight[f_weight < low_block_freq] = 1
idx_passband = np.logical_and(f_weight > pass_low_freq, f_weight < pass_high_freq)
weight[idx_passband] = 1
weight[f_weight > high_block_freq] = 1
# compFilter = sig.firwin2(num_stages_compFilter, fn_1, freqResponseCompensation, fs=fsn_1)
compFilter = sig.firls(num_stages_compFilter, fn_2, freqResponseCompensation, fs=fsn_2, weight=weight)

# Plot compensation filter and weight

w, h_comp = sig.freqz(compFilter, fs=fsn_2)
f_w = w * fs_1

fig, ax = plt.subplots()
ax.set_title("Compensation filter frequency response")
ax.plot(f_w, abs(h_comp), label="Actual response")
ax.plot(f_2, freqResponseCompensation, ":", label="Desired response")
ax.xaxis.set_major_formatter(formatter_hz)
ax.set_ylabel("Gains")
ax.set_xlabel("Normalized frequency")
# ax.plot(f_weight, weight, label="Weight")
ax.legend()
fig.savefig("04-compensation-filter-freq-response-actual.pdf", bbox_inches="tight")

# plot combined response
H_tot = H(w, decimationRatio, order) * h_comp

fig, ax = plt.subplots()
ax.plot(f_w, abs(H_tot), label="Combined response")
ax.xaxis.set_major_formatter(formatter_hz)
ax.set_xlim(0, fs_2 / 2)
ax.set_title("Combined frequency response")
ax.set_ylabel("Gain")
ax.set_xlabel("Normalized frequency")
ax.legend()
fig.savefig("05-combined-response.pdf", bbox_inches="tight")

# plot combined response log
fig, ax = plt.subplots()
ax.semilogy(f_w, abs(H_tot), label="Combined response (log)")
ax.xaxis.set_major_formatter(formatter_hz)
ax.set_xlim(0, fs_2 / 2)
ax.set_title("Combined frequency response")
ax.set_ylabel("Gain")
ax.set_xlabel("Normalized frequency")
ax.legend()
fig.savefig("06-combined-response-log.pdf", bbox_inches="tight")

print(f"FIR filter order: {len(compFilter)}")

# print attenuation at 50 Hz
idx50Hz = np.argmin(np.abs(f_w - 50))
print(f"Gain at 50 Hz: {np.abs(H_tot[idx50Hz])}")

# print attenuation of the CIC (not the combined response) at 10 kHz
idx10kHz = np.argmin(np.abs(f_1 - 10e3))
print(f"Gain at 10 kHz: {np.abs(H_cic[idx10kHz])}")

# How many bits do we need to represent the weights?
minNumber = np.min(np.abs(compFilter))
print(-np.log(minNumber) / np.log(2))


# Scale from normalized floats to fixed point
signal_bits = bits_input
coeff_int = float_to_fixed_arr(compFilter, signal_bits)

# print verilog array
print_verilog_array(coeff_int)
