VERILOG_SOURCES = $(PWD)/*.sv $(PWD)/../../hardware/src/FIRFilter.sv
TOPLEVEL=FIRFilterTest
MODULE=test

SIM=verilator
COCOTB_HDL_TIMEPRECISION = 1ns

EXTRA_ARGS += --trace --trace-structs -Wno-UNOPT -Wno-TIMESCALEMOD  # --timescale 10ns/1ns

include $(shell cocotb-config --makefiles)/Makefile.sim

clean ::
	rm -rf __pycache__
	rm -f results.xml
