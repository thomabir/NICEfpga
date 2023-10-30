from scipy import signal
import matplotlib.pyplot as plt
import numpy as np

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
f_sample = 64000  # Sampling frequency in Hz
f0 = 80  # Lower cutoff frequency in Hz
f1 = 120  # Upper cutoff frequency in Hz
order = 2  # Filter order

# Calculate the normalized frequencies
w0 = f0 / (f_sample / 2)
w1 = f1 / (f_sample / 2)

# Design the Butterworth filter
num, denom = signal.butter(order, [w0, w1], btype='band')

# Plot the amplitude and phase response
w, h = signal.freqz(num, denom, worN=2**16)
frequencies = w * (f_sample / (2 * np.pi))

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 6))
fig.suptitle('IIR Bandpass Filter Response')

# Plot the amplitude response
ax1.plot(frequencies, abs(h), 'b')
ax1.set_ylabel('Gain')
ax1.set_xlabel('Frequency (Hz)')
ax1.set_xlim([0, 1000])
ax1.grid()

# Plot the time delay (from phase response)
phases = np.unwrap(np.angle(h))
delays = phases / (2 * np.pi * frequencies)
ax2.plot(frequencies, delays*1e3, 'b')
ax2.set_ylabel('Delay (ms)')
ax2.set_xlabel('Frequency (Hz)')
ax2.set_xlim([0, 1000])
ax2.grid()

# plt.show()

# scale coefficients to 24 bit ints
num = float_to_fixed_arr(num, 24)
denom = float_to_fixed_arr(denom, 24)

# print a, b
print("denominator = ", end="")
print_verilog_array(denom)

print("numerator = ", end="")
print_verilog_array(num)