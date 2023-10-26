"""Tests for the CORDIC Finite State Machine, which recovers the phase phi given sin(phi) and cos(phi)."""

import cocotb
import matplotlib.pyplot as plt
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cordic_prototype import fixed_to_float, float_to_fixed


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def cordic_test(dut):
    """Supply a range of sines and cosines to the CORDIC FSM and check that the correct phase is recovered, up to a constant multipler."""
    clock = Clock(dut.clk_i, 10, units="ns")  # 100 MHz clock
    cocotb.start_soon(clock.start())

    # generate array of phis
    n_tests = 10
    phis_true = np.linspace(-np.pi / 2, np.pi / 2, n_tests)
    phis_cordic = np.zeros(n_tests)

    for i, phi_true in enumerate(phis_true):
        # convert to fixed point
        x = float_to_fixed(np.cos(phi_true), n_bits=24)
        y = float_to_fixed(np.sin(phi_true), n_bits=24)

        print(f"phi_true = {phi_true}, x = {x}, y = {y}")

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
        phis_cordic[i] = dut.phi_o.value.signed_integer
        phis_cordic[i] = fixed_to_float(phis_cordic[i], n_bits=24)

    # plot
    plt.plot(phis_true, phis_true)
    plt.plot(phis_true, phis_cordic)
    plt.xlabel("True phi")
    plt.ylabel("CORDIC phi")
    plt.show()
