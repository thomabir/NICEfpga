"""Tests for the input bandpass filter."""
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
    fs = 64e3  # Hz
    dt = 1 / fs  # s
    t = np.arange(n_steps) * dt

    offset = 0.5
    # signal_i = 0.2 * np.sin(2 * np.pi * 10e3 * t) + offset
    signal_i = white_noise(n_steps, dc=offset, std=0.1)
    signal_i_int = np.round(signal_i * 2**23)

    signal_o = np.zeros(n_steps)
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
        signal_o[i] = dut.signal_o.value

        await FallingEdge(dut.clk_i)
        dut.tick_i.value = 0

        await Timer(dt * 1e6, units="us")
        await FallingEdge(dut.clk_i)

    # decode the output
    signal_o = twos_complement_to_float(signal_o, 24)

    # ignore the beginning when the filter is settling
    idx = t > 1e-3
    signal_i = signal_i[idx]
    signal_o = signal_o[idx]
    t = t[idx]

    # check the time series of input and output
    plt.plot(t, signal_i)
    plt.plot(t, signal_o)
    plt.show()

    # fourier transforms
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

    # plot gain and phase
    gain = np.abs(signal_o_F / signal_i_F)
    phase = np.angle(signal_o_F / signal_i_F)

    plt.semilogy(f, gain)
    plt.show()

    plt.plot(f, phase)
    plt.show()
