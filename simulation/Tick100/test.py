"""Tests the Tick100 module"""
import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer


@cocotb.test()  # pylint: disable=E1120
async def test_delay(dut):
    clock = Clock(dut.clk_i, 10, units="ns")  # 100 MHz clock
    cocotb.start_soon(clock.start())

    await FallingEdge(dut.clk_i)  # Synchronize with the clock

    # do a reset:
    # dut.reset_i.value = 1
    await FallingEdge(dut.clk_i)
    # dut.reset_i.value = 0
    await FallingEdge(dut.clk_i)

    # set tick_i high for one cycle
    dut.tick_i.value = 1
    await FallingEdge(dut.clk_i)
    dut.tick_i.value = 0

    # wait for 200 cycles, and done
    for _ in range(200):
        await FallingEdge(dut.clk_i)
