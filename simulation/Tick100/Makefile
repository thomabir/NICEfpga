SRC_DIR = $(PWD)/../../hardware/src
VERILOG_SOURCES = $(PWD)/*.sv

TOPLEVEL=Tick100Test # SystemVerilog top module name
MODULE=test # Python file name

SIM=verilator
COCOTB_HDL_TIMEPRECISION = 1ns
COCOTB_HDL_TIMEUNIT = 10ns

EXTRA_ARGS += --trace --trace-structs -Wno-TIMESCALEMOD

include $(shell cocotb-config --makefiles)/Makefile.sim

clean ::
	rm -rf __pycache__
	rm -f results.xml
