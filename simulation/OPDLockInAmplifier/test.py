"""Tests for the lock-in amplifier module."""

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


@cocotb.test()  # pylint: disable=E1120
async def test_white(dut):
    """Test the filter with two sine waves, one with a phase shift."""
    clock = Clock(dut.clk_i, 10, units="ns")  # 100 MHz clock

    n_steps = 300
    fs = 64e3  # sampling rate, Hz
    dt = 1 / fs  # sampling interval, s
    dt_ns = dt * 1e9  # sampling interval, ns
    dt_ns_approx = (
        np.round(dt_ns / 10) * 10
    )  # sampling interval, rounded to nearest 10 ns, ns
    t = np.arange(n_steps) * dt

    phi = np.zeros(n_steps)
    # phi smoothly varies from -pi/2 to pi/2
    phi[0:100] = np.linspace(-np.pi / 2, np.pi / 2, 100)
    phi[100:200] = np.linspace(np.pi / 2, -np.pi / 2, 100)
    phi[200:300] = np.linspace(-np.pi / 2, np.pi / 2, 100)
    f = 10e3  # frequency, Hz
    signal_1i = 0.5 * np.sin(2 * np.pi * f * t)
    signal_2i = 0.5 * np.sin(2 * np.pi * f * t + phi)
    signal_1i_int = np.round(signal_1i * 2**23)
    signal_2i_int = np.round(signal_2i * 2**23)

    signal_x_o = np.zeros(n_steps)
    signal_y_o = np.zeros(n_steps)

    cocotb.start_soon(clock.start())
    await FallingEdge(dut.clk_i)  # Synchronize with the clock

    # do a reset:
    # dut.reset_i.value = 1
    await FallingEdge(dut.clk_i)
    # dut.reset_i.value = 0
    await FallingEdge(dut.clk_i)

    for i in range(n_steps):
        dut.ch1_i.value = int(signal_1i_int[i])
        dut.ch2_i.value = int(signal_2i_int[i])
        dut.tick_i.value = 1

        signal_x_o[i] = dut.x_o.value
        signal_y_o[i] = dut.y_o.value

        await FallingEdge(dut.clk_i)
        dut.tick_i.value = 0

        await Timer(dt_ns_approx, units="ns")
        await FallingEdge(dut.clk_i)

    # decode the output
    signal_x_o = twos_complement_to_float(signal_x_o, 24)
    signal_y_o = twos_complement_to_float(signal_y_o, 24)

    phi_meas = -np.arctan2(signal_y_o, signal_x_o)

    # ignore the beginning when the filter is settling
    # idx = t > 1e-3
    # signal_i = signal_i[idx]
    # signal_delay_o = signal_delay_o[idx]
    # signal_hilbert_o = signal_hilbert_o[idx]
    # t = t[idx]

    # plot input and output
    plt.plot(t, signal_1i, label="input 1")
    plt.plot(t, signal_2i, label="input 2")
    # plt.plot(t, signal_x_o, label="output x")
    # plt.plot(t, signal_y_o, label="output y")
    plt.plot(t, phi_meas, label="measured phi")
    plt.plot(t, phi, label="true phi")
    plt.legend()
    plt.show()
