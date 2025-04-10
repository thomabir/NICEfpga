"""Testing template for a generic FIR filter."""

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
    clock = Clock(dut.clk_i, 100, units="ns")  # 10 MHz clock

    n_steps = 100
    fs = 64e3  # sampling rate, Hz
    dt = 1 / fs  # sampling interval, s
    dt_ns = dt * 1e9  # sampling interval, ns
    dt_ns_approx = (
        np.round(dt_ns / 10) * 10
    )  # sampling interval, rounded to nearest 10 ns, ns
    t = np.arange(n_steps) * dt

    # offset = 0.5
    # signal_i = 0.2 * np.sin(2 * np.pi * 10e3 * t) + offset
    # signal_i = white_noise(n_steps, dc=offset, std=0.1)
    signal_i = np.ones(n_steps) / 10
    signal_i[0:20] = 0
    signal_i_int = np.round(signal_i * (2**23 - 1))

    signal_o_int = np.zeros(n_steps)
    cocotb.start_soon(clock.start())
    await FallingEdge(dut.clk_i)  # Synchronize with the clock

    # do a reset:
    # dut.reset_i.value = 1
    await FallingEdge(dut.clk_i)
    # dut.reset_i.value = 0
    await FallingEdge(dut.clk_i)

    # simple example
    # n_steps = 8
    # signal_i_int = np.array([0, 1, 2, 3, 4, 5, 6, 7])

    for i in range(n_steps):
        dut.signal_i.value = int(signal_i_int[i])
        dut.start_i.value = 1
        signal_o_int[i] = dut.signal_o.value

        await FallingEdge(dut.clk_i)
        dut.start_i.value = 0

        await Timer(dt_ns_approx, units="ns")
        await FallingEdge(dut.clk_i)

    # decode the output
    signal_o = twos_complement_to_float(signal_o_int, 24)

    # ignore the beginning when the filter is settling
    # idx = t > 1e-3
    # signal_i = signal_i[idx]
    # signal_o = signal_o[idx]
    # t = t[idx]

    # check the output
    plt.plot(t, signal_i_int)
    plt.plot(t, signal_o_int)
    plt.show()

    exit()

    # fourier transform of signals
    signal_i_F = fft.fft(signal_i)
    signal_o_F = fft.fft(signal_o)

    # shift
    signal_i_F = fft.fftshift(signal_i_F)
    signal_o_F = fft.fftshift(signal_o_F)

    # frequency axis
    f = fft.fftfreq(signal_i_F.size, d=dt)
    f = fft.fftshift(f)

    # remove noise (low signal levels in the fft)
    idx_i = np.abs(signal_i_F) > 1e-3
    idx_o = np.abs(signal_o_F) > 1e-3
    idx = np.logical_or(idx_i, idx_o)
    signal_i_F = signal_i_F[idx]
    signal_o_F = signal_o_F[idx]
    f = f[idx]

    # gain and phase
    gain = np.abs(signal_o_F / signal_i_F)
    phase = np.angle(signal_o_F / signal_i_F)

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
