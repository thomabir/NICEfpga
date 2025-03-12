"""Tests for the delay line module in combination with the Hilbert transformer."""

import cocotb
import matplotlib.pyplot as plt
import numpy as np
import scipy.fftpack as fft
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer


def twos_complement_to_float(value, bits):
    """Convert a two's complement integer to float. Also works with arrays."""

    if isinstance(value, np.ndarray):
        idx = value >= 2 ** (bits - 1)
        value[idx] = value[idx] - 2**bits
        return value / 2 ** (bits - 1)
    if isinstance(value, int):
        if value >= 2 ** (bits - 1):
            value = value - 2**bits
        return value / 2 ** (bits - 1)

    raise TypeError("Input must be int or np.ndarray")


def white_noise(num_samples, dc=0, std=1):
    """Generate white noise."""
    return np.random.normal(dc, std, size=num_samples)


@cocotb.test()  # pylint: disable=E1120
async def test_white(dut):
    """Test the filter with white noise."""
    clock = Clock(dut.clk_i, 10, units="ns")  # 100 MHz clock

    n_steps = 300
    fs = 64e3  # sampling rate, Hz
    dt = 1 / fs  # sampling interval, s
    dt_ns = dt * 1e9  # sampling interval, ns
    dt_ns_approx = (
        np.round(dt_ns / 10) * 10
    )  # sampling interval, rounded to nearest 10 ns, ns
    t = np.arange(n_steps) * dt

    offset = 0.0  # InputFilter already subtract the DC offset
    signal_i = white_noise(n_steps, dc=offset, std=0.1)
    signal_i_int = np.round(signal_i * 2**23)

    signal_delay_o = np.zeros(n_steps)
    signal_hilbert_o = np.zeros(n_steps)
    cocotb.start_soon(clock.start())
    await FallingEdge(dut.clk_i)  # Synchronize with the clock

    # do a reset:
    # dut.reset_i.value = 1
    await FallingEdge(dut.clk_i)
    # dut.reset_i.value = 0
    await FallingEdge(dut.clk_i)

    for i in range(n_steps):
        dut.signal_i.value = int(signal_i_int[i])
        dut.tick_i.value = 1
        signal_delay_o[i] = dut.signal_delay_o.value
        signal_hilbert_o[i] = dut.signal_hilbert_o.value

        await FallingEdge(dut.clk_i)
        dut.tick_i.value = 0

        await Timer(dt_ns_approx, units="ns")
        await FallingEdge(dut.clk_i)

    # decode the output
    signal_delay_o = twos_complement_to_float(signal_delay_o, 24)
    signal_hilbert_o = twos_complement_to_float(signal_hilbert_o, 24)

    # ignore the beginning when the filter is settling
    idx = t > 1e-3
    signal_i = signal_i[idx]
    signal_delay_o = signal_delay_o[idx]
    signal_hilbert_o = signal_hilbert_o[idx]
    t = t[idx]

    # check the output
    plt.plot(t, signal_i)
    plt.plot(t, signal_delay_o)
    plt.plot(t, signal_hilbert_o)
    plt.show()

    # fourier transform of signals
    # signal_i_F = fft.fft(signal_i)
    signal_delay_o_F = fft.fft(signal_delay_o)
    signal_hilbert_o_F = fft.fft(signal_hilbert_o)

    # shift
    signal_delay_o_F = fft.fftshift(signal_delay_o_F)
    signal_hilbert_o_F = fft.fftshift(signal_hilbert_o_F)

    # frequency axis
    f = fft.fftfreq(signal_delay_o_F.size, d=dt)
    f = fft.fftshift(f)

    # remove noise (low signal levels in the fft)
    idx_delay_o = np.abs(signal_delay_o_F) > 1e-3
    idx_hilbert_o = np.abs(signal_hilbert_o_F) > 1e-3
    idx = np.logical_or(idx_delay_o, idx_hilbert_o)
    signal_delay_o_F = signal_delay_o_F[idx]
    signal_hilbert_o_F = signal_hilbert_o_F[idx]
    f = f[idx]

    # gain and phase
    gain = np.abs(signal_delay_o_F / signal_hilbert_o_F)
    phase = np.angle(signal_delay_o_F / signal_hilbert_o_F)

    # plt.semilogy(f, Pxx_i)
    # plt.semilogy(f, Pxx_o)
    plt.semilogy(f, gain)
    plt.show()

    plt.plot(f, phase)
    plt.show()

    # test cases for a filter:
    # passband ripple
    # stopband attenuation
    # phase shift in passband


# # generate white noise, plot its fourier transform

# num_samples = 1000
# sample_rate = 1000
# y = white_noise(num_samples, dc=1, std=1)
