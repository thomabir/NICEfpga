SRC_DIR = $(PWD)/../../hardware/src
VERILOG_SOURCES = $(PWD)/*.sv $(SRC_DIR)/CompensatedCICFilter.sv $(SRC_DIR)/CICFilter.sv $(SRC_DIR)/FIRFilter.sv

TOPLEVEL=CompensatedCICFilterTest # SystemVerilog top module name
MODULE=test # Python file name

SIM=verilator
COCOTB_HDL_TIMEPRECISION = 1ns
COCOTB_HDL_TIMEUNIT = 10ns

EXTRA_ARGS += --trace --trace-structs -Wno-TIMESCALEMOD -Wno-STMTDLY # last one ignores warnings, TODO fix this

include $(shell cocotb-config --makefiles)/Makefile.sim

clean ::
	rm -rf __pycache__
	rm -f results.xml
