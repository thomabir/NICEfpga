"""This module calculates the filter coefficients for a generic IIR filter."""
import matplotlib.pyplot as plt
import numpy as np
from scipy import signal


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


# Define the filter parameters
fs = 64000  # Sampling frequency in Hz
f0 = 500  # Lower cutoff frequency in Hz
f1 = 2000  # Upper cutoff frequency in Hz
order = 1  # Filter order

# Design the Butterworth filter
num, denom = signal.butter(order, [f0, f1], fs=fs, btype="band")

# Plot the amplitude and phase response
w, h = signal.freqz(num, denom, worN=2**10, fs=fs)
frequencies = w


fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 6), sharex=True)
fig.suptitle("IIR Bandpass Filter Response")

# Plot the amplitude response
ax1.loglog(frequencies, abs(h), "b", label="Ideal")
ax1.set_ylabel("Gain")
ax1.set_xlabel("Frequency (Hz)")
ax1.grid()

# Plot the time delay (from phase response)
phases = np.unwrap(np.angle(h))
delays = phases / (2 * np.pi * frequencies)
ax2.semilogx(frequencies, delays * 1e3, "b")
ax2.set_ylabel("Delay (ms)")
ax2.set_xlabel("Frequency (Hz)")
ax2.grid()

# plt.show()
# exit()

print(num, denom)

# scale coefficients to 24 bit ints
num_total_bits = 24
num_int_bits = 3
num_frac_bits = num_total_bits - num_int_bits
num = float_to_fixed_arr(num, num_frac_bits)
denom = float_to_fixed_arr(denom, num_frac_bits)

# make sure all coefficients are within num_total_bits range
assert max(max(num), max(denom)) < 2 ** (num_total_bits - 1) - 1
assert min(min(num), min(denom)) > -(2 ** (num_total_bits - 1))

# print a, b
print("denominator = ", end="")
print_verilog_array(denom)

print("numerator = ", end="")
print_verilog_array(num)

# determine frequcny response of quantised filter
w, h = signal.freqz(num, denom, worN=2**10, fs=fs)
frequencies = w

# Plot the amplitude response
ax1.semilogy(frequencies, abs(h), "r", label="Quantised")
ax1.legend()

# Plot the time delay (from phase response)
phases = np.unwrap(np.angle(h))
delays = phases / (2 * np.pi * frequencies)
ax2.plot(frequencies, delays * 1e3, "r")

plt.show()
