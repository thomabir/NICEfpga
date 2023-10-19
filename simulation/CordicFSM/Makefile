SRC_DIR = $(PWD)/../../hardware/src
VERILOG_SOURCES = $(PWD)/*.sv $(SRC_DIR)/CordicFSM.sv

TOPLEVEL=CordicFSMTest
MODULE=test

SIM=verilator
COCOTB_HDL_TIMEPRECISION = 1ns
COCOTB_HDL_TIMEUNIT = 10ns

EXTRA_ARGS += --trace --trace-structs -Wno-TIMESCALEMOD

include $(shell cocotb-config --makefiles)/Makefile.sim

clean ::
	rm -rf __pycache__
	rm -f results.xml
