# FPGA Usage

I'm following the [Vivado Setup Guide](https://github.com/jhallen/vivado_setup) by [jhallen](https://github.com/jhallen).
This guide provides a reproducible way to set up the project without having to interact with the GUI.

## Directory structure

- `build/`: Contains the exported hardware files which are used in Vitis.
- `cstr/`: Contains the constraints file.
- `ip/`: Contains the wrapper file, which is version controlled, and lots of auto-generated files by Vivado, which are not version controlled and can be ignored.
- `NA/`: Auto-generated directory by Vivado, can be ignored.
- - `prj/`: Contains the Vivado project files. This directory is not version controlled, and is generated automatically with the `create_project.tcl` script, or can be created manually in the GUI.
- `src/`: Contains the real-time-logic `.sv` and `.v.` source files.
- `create_project.tcl`: A script to create the Vivado project.
- `make.tcl`: A script to compile the Vivado project, which outputs the generated hardware to the `build/` directory.

## Create project (GUI mode)

The following instructions are used to create the project from scratch, without using the provided `create_project.tcl` script.

1. Open Vivado

   ```sh
      cd ~/code/niceFPGA/hardware
      vivado
   ```

2. Create the NICEfpga project
   1. Click on `Create Project`.
   2. Click on `Next`.
   3. Enter the project name `prj`, in the project location `~/code/NICEfpga/hardware`.
   4. Select `RTL project`, and enable `Do not specify sources at this time`.
   5. Go to the tab `Boards`.
   6. Refresh the list of boards.
   7. Search for `pynq-z2`.
   8. Download the `pynq-z2` board, select it, and click on `Next`.
   9. Click on `Finish`.
3. **Add the source files**
   1. *Adding the constraints*
      1. Click on `File -> Add Sources`.
      2. Select `Add or create constraints`, then click on `Next`.
      3. Click on `Add Files`
      4. Navigate to `~/code/NICEfpga/hardware/cstr/physical_constr.xdc` and click `OK`.
      5. Make sure to disable `Copy constraint files into project`, then click on `Finish`.
   2. *Adding the design sources*
      1. Click on `File -> Add Sources`.
      2. Select `Add or create design sources`, then click on `Next`.
      3. Click on `Add Directories`
      4. Navigate to `~/code/NICEfpga/hardware/src`, select the `src` directory, and click on `OK`.
      5. Make sure to disable `Copy sources into project`, then click on `Finish`.
4. **Create the block design** (Only do this step if you have to create the block design from scratch. An image of the finalised block design is shown here: [Block Design](bd/bd.png))
   1. In the pane on the left, click on `Create Block Design`.
   2. Change the directory to `~/code/NICEfpga/hardware/ip`, then Click on `OK`.
   3. From the `Sources` tab, expand `Design Sources` and right-click on `MainV`, then click on `Add Module to Block Design`.
   4. Add the following IP blocks with the `+` symbol on the toolbar:
      - `ZYNQ7 Processing System`
      - 13 times: `AXI GPIO` (from `axi_gpio_0` to `axi_gpio_12`)
   5. Double-click on the Zynq processing system, select the tab `MIO Configuration`, expand `Application Processor Unit`, and enable the tick boxes `Timer 0` and `Timer 1`. Then click on `OK`. This is probably necessary to avoid a bug of the new 2024 Xilinx toolchain, see the forum discussions [here](https://adaptivesupport.amd.com/s/question/0D54U00007uv6AvSAI/vitis-unified-ide-202320-fails-to-build-new-freertos-platform-with-cmake-error?language=en_US) and [here](https://adaptivesupport.amd.com/s/question/0D54U00008LEi5jSAD/freertos-running-on-zedboard-has-tick-rate-twice-as-fast?language=en_US).
   6. Double-click on each of the 13 `axi_gpio`, and configure them:
      - Select the tab `IP Configuration`.
      - Under `GPIO`, enable `All Inputs` and `Enable Dual Channel`. Exception: don't enable `Enable Dual Channel` for `axi_gpio_0`.
      - Under `GPIO 2`, enable `All Inputs`. Exception: don't enable `All Inputs` for `axi_gpio_0` (shpuld be greyed out for `GPIO2`).
      - Click on `OK`.
      - In the block design, expand the output pins by clicking on the small plus-sign next `GPIO` and `GPIO2`.
   7. Connect each `axi_gpio` to its corresponding pin on `MainV_0` by clicking on the pin stub next to each pin name and dragging the wire to the corresponding `axi_gpio` block. Use the following list for the correspondances:
      - `axi_gpio_0`: GPIO: `counter`, GPIO2: does not exist
      - `axi_gpio_1`: GPIO: `adc_shear1`, GPIO2: `adc_shear2`
      - `axi_gpio_2`: GPIO: `adc_shear3`, GPIO2: `adc_shear4`
      - `axi_gpio_3`: GPIO: `adc_point1`, GPIO2: `adc_point2`
      - `axi_gpio_4`: GPIO: `adc_point3`, GPIO2: `adc_point4`
      - `axi_gpio_5`: GPIO: `adc_sine_ref`, GPIO2: `adc_opd_ref`
      - `axi_gpio_6`: GPIO: `opd_x`, GPIO2: `opd_y`
      - `axi_gpio_7`: GPIO: `shear_x1`, GPIO2: `shear_x2`
      - `axi_gpio_8`: GPIO: `shear_y1`, GPIO2: `shear_y2`
      - `axi_gpio_9`: GPIO: `shear_i1`, GPIO2: `shear_i2`
      - `axi_gpio_10`: GPIO: `point_x1`, GPIO2: `point_x2`
      - `axi_gpio_11`: GPIO: `point_y1`, GPIO2: `point_y2`
      - `axi_gpio_12`: GPIO: `point_i1`, GPIO2: `point_i2`
   8. Make the following pins of `MainV_0` external (select the small stub of wire next to each pin name in the block design and hit Ctrl-T)
      - `sw[1:0]`
      - `btn[3:0]`
      - `pmodb[7:0]`
      - `pmoda[7:0]`
      - `led[3:0]`
      - Note that a trailing `_0` has to be removed from all the external pin names.
   9. Click on `Run Block Automation` in the toolbar, then click on `OK`.
   10. Click on `Run Connection Automation` in the toolbar, enable all connections, then click on `OK`.
   11. Click on `Regenerate Layout` in the toolbar to make the block design easier to inspect by eye.
   12. Click on `Validate Design` in the toolbar, then click on `OK`. No errors or warnings should be present.
5. **Create the HDL wrapper**
   1. In the sources tab, right-click on `design_1 (design_1.bd)` and click on `Create HDL Wrapper`.
   2. Select `Let Vivado manage wrapper and auto-update`.
   3. Click on `OK`.
   4. Set the wrapper as the top module by right-clicking on `design_1_wrapper` and clicking on `Set as Top`.
6. (Not sure if neccessary) Disable incremental synthesis
   1. Click on `Tools -> Settings`.
   2. Navigate to `Project Settings -> Synthesis`.
   3. Change `Incremental synthesis` to `Not set`.
   4. Click on `OK`.
7. (Optional) Save the project configuration, so it can be rebuilt in CLI mode.
   In the Tcl console at the bottom, enter the command `write_project_tcl -force create_project`.

## Compile project (GUI mode)

1. **Compile the design**
   1. In the top toolbar, click on `Generate Bitstream` (small green arrow pointing downwards).
   2. Click on `OK`. (Optional: Select `Don't show this dialog again`).
   3. Click on `OK`. (Optional: Select `Don't show this dialog again`).
   4. This may take many minutes, status is shown in the top right. (Spinning circle).
   5. It should end with `Bitstream generation sucessfully completed`. Click on `Cancel` when asked what to do next. (Optional: Select `Don't show this dialog again`).
2. **Export the hardware**
   1. In the top toolbar, click on `File -> Export -> Export Hardware`.
   2. Click on `Next`.
   3. Select `Include bitstream` and click on `Next`.
   4. Leave the default file name and export directory, then click on `Finish`.

## Create project and compile (CLI mode)

To generate the project files (this will open the GUI, but it can be closed after the project is created):

```sh
cd NICEfpga/hardware
vivado -source create_project.tcl # -nojournal -nolog
```

To compile the design and generate the hardware files:

```sh
cd NICEfpga/hardware
vivado -mode batch -source make.tcl -nojournal -nolog
```

To delete all the generated files and start over:

```sh
rm -rf .Xil
rm -rf build
rm -rf prj
rm -rf NA
rm -rf ip # delete the IP directory (contains auto-generated files)
git checkout ip # restore the version-controlled IP
```

To delete only the runs (for re-compiling):

```sh
rm -rf prj/prj.runs
```

## How to update when code changes

- In GUI mode, restart from step "Compile the design", and re-export the hardware.
- In CLI mode, restart from step "To compile the design and generate the hardware files"
