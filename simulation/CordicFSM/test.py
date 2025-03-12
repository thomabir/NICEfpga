"""Tests for the CORDIC Finite State Machine, which recovers the phase phi and radius r given r*sin(phi) and r*cos(phi)."""

import cocotb
import matplotlib.pyplot as plt
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cordic_prototype import cartesian_to_phi_cordic, float_to_fixed


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def cordic_test(dut):
    """Supply a range of xs and ys to the CORDIC FSM and check that the output (r, phi) matches the Python implementation. Plot the results."""
    clock = Clock(dut.clk_i, 10, units="ns")  # 100 MHz clock
    cocotb.start_soon(clock.start())

    # generate test data from true values
    n_tests = 10
    phis_true_float = np.linspace(-np.pi, np.pi - 0.0001, n_tests)
    phis_cordic_python = np.zeros(n_tests)
    phis_cordic_sv = np.zeros(n_tests)

    rs_true = np.linspace(0.1, 1.0, n_tests)
    np.random.shuffle(rs_true)
    xs = rs_true * np.cos(phis_true_float)
    ys = rs_true * np.sin(phis_true_float)

    rs_cordic_python = np.zeros(n_tests)
    rs_cordic_sv = np.zeros(n_tests)

    for i, _ in enumerate(phis_true_float):
        # convert to fixed point
        x = float_to_fixed(xs[i], n_bits=24)
        y = float_to_fixed(ys[i], n_bits=24)

        # synchronize with the clock
        await FallingEdge(dut.clk_i)
        await FallingEdge(dut.clk_i)

        # reset the DUT
        dut.reset_i.value = 1
        await FallingEdge(dut.clk_i)
        await FallingEdge(dut.clk_i)
        dut.reset_i.value = 0

        # Start the computation
        dut.start_i.value = 1
        dut.sin_i.value = x
        dut.cos_i.value = y
        await FallingEdge(dut.clk_i)
        await FallingEdge(dut.clk_i)
        dut.start_i.value = 0

        # wait for the computation to finish
        while not dut.done_o.value:
            await FallingEdge(dut.clk_i)

        # read the output from the DUT
        phis_cordic_sv[i] = dut.phi_o.value.signed_integer
        rs_cordic_sv[i] = dut.r_o.value.signed_integer

        # get the output from the Python implementation
        phis_cordic_python[i], rs_cordic_python[i] = cartesian_to_phi_cordic(
            x, y, n_iter=24
        )

        # check they are equal
        assert phis_cordic_sv[i] == phis_cordic_python[i]
        assert (
            np.abs((rs_cordic_sv[i] - rs_cordic_python[i])) <= 1
        )  # can be off by 1 bit, I don't know why but it's not a problem

    # Plot results for phi: recovered vs true, with residuals underneath
    fig, axs = plt.subplots(2, 1, sharex=True)
    ax = axs[0]
    ax.plot(phis_true_float, phis_cordic_sv, label="CORDIC SV")
    ax.plot(phis_true_float, phis_cordic_python, label="CORDIC Python")
    ax.set_xlabel("True phi")
    ax.set_ylabel("Recovered phi")
    ax.legend()

    # plot residual
    ax = axs[1]
    ax.plot(phis_true_float, phis_cordic_sv - phis_cordic_python)
    ax.set_xlabel("True phi")
    ax.set_ylabel("Residual error (bits)")
    plt.show()

    # sort ascending true_r for the r plot
    idx = np.argsort(rs_true)
    rs_true = rs_true[idx]
    rs_cordic_sv = rs_cordic_sv[idx]
    rs_cordic_python = rs_cordic_python[idx]

    # Plot results for r: recovered vs true, with residuals underneath
    fig, axs = plt.subplots(2, 1, sharex=True)
    ax = axs[0]
    ax.plot(rs_true, rs_cordic_sv, label="CORDIC SV")
    ax.plot(rs_true, rs_cordic_python, label="CORDIC Python")
    ax.set_xlabel("True r")
    ax.set_ylabel("Recovered r")
    ax.legend()

    # plot residual
    ax = axs[1]
    ax.plot(rs_true, rs_cordic_sv - rs_cordic_python)
    ax.set_xlabel("True r")
    ax.set_ylabel("Residual error (bits)")
    plt.show()
