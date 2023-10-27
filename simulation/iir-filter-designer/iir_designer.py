from scipy import signal
import matplotlib.pyplot as plt
import numpy as np

# Define the filter parameters
f_sample = 60000  # Sampling frequency in Hz
f0 = 80  # Lower cutoff frequency in Hz
f1 = 120  # Upper cutoff frequency in Hz
order = 2  # Filter order

# Calculate the normalized frequencies
w0 = f0 / (f_sample / 2)
w1 = f1 / (f_sample / 2)

# Design the Butterworth filter
b, a = signal.butter(order, [w0, w1], btype='band')

# print coefficients
print('b =', b)
print('a =', a)

# Plot the amplitude and phase response
w, h = signal.freqz(b, a, worN=2**16)
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

plt.show()
