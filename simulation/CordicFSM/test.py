"""Tests for the CORDIC Finite State Machine, which recovers the phase phi given sin(phi) and cos(phi)."""

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cordic_prototype import cartesian_to_phi_cordic, float_to_fixed


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def cordic_test(dut):
    """Supply a range of sines and cosines to the CORDIC FSM and check that the correct phase is recovered, up to a constant multipler."""
    clock = Clock(dut.clk_i, 10, units="ns")  # 100 MHz clock
    cocotb.start_soon(clock.start())

    # generate array of phis
    n_tests = 10
    phis_true_float = np.linspace(-np.pi , np.pi - 0.0001, n_tests)
    phis_cordic_python = np.zeros(n_tests)
    phis_cordic_sv = np.zeros(n_tests)

    rs_true = np.linspace(0.1, 1.0, n_tests)
    np.random.shuffle(rs_true)
    xs = rs_true * np.cos(phis_true_float)
    ys = rs_true * np.sin(phis_true_float)

    rs_cordic_python = np.zeros(n_tests)
    rs_cordic_sv = np.zeros(n_tests)

    for i, phi_true_float in enumerate(phis_true_float):
        # convert to fixed point
        x = float_to_fixed(xs[i], n_bits=24)
        y = float_to_fixed(ys[i], n_bits=24)

        # print(f"phi_true = {phi_true_float}, x = {x}, y = {y}")

        # synchronize with the clock
        await FallingEdge(dut.clk_i)
        await FallingEdge(dut.clk_i)

        # reset
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

        # read the output
        phis_cordic_sv[i] = dut.phi_o.value.signed_integer
        rs_cordic_sv[i] = dut.r_o.value.signed_integer

        # get the output from the Python implementation
        phis_cordic_python[i], rs_cordic_python[i] = cartesian_to_phi_cordic(x, y, n_iter=24)

        # check they are equal
        assert phis_cordic_sv[i] == phis_cordic_python[i]
        # assert rs_cordic_sv[i] == rs_cordic_python[i]
        # print(f"phi_sv = {phis_cordic_sv[i]}, phi_python = {phis_cordic_python[i]}")
        print(f"r_sv = {rs_cordic_sv[i]}, r_python = {rs_cordic_python[i]}")

    # plot
    import matplotlib.pyplot as plt

    plt.plot(phis_true_float, phis_cordic_sv, label="CORDIC SV")
    plt.plot(phis_true_float, phis_cordic_python, label="CORDIC Python")
    plt.xlabel("True phi")
    plt.ylabel("Recovered phi")
    plt.legend()
    plt.show()

    # same for r
    plt.plot(rs_true, rs_cordic_sv, label="CORDIC SV")
    plt.plot(rs_true, rs_cordic_python, label="CORDIC Python")
    plt.xlabel("True r")
    plt.ylabel("Recovered r")
    plt.legend()
    plt.show()
