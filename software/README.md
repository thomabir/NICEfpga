# Software for the ARM CPU on the Zynq SoC

## Use

Make sure `make` is installed (e.g. `sudo apt install make`).

1. Create a new application project in Vitis Unified IDE. TODO Explain in detail.
1. Add the code to the `src` directory.
   1. Replace `echo.c` and `main.c` in the project with the files in this repository.
   1. Add `includes.h` from this repository to the `src` directory of the project.
1. Configure the project and compiler settings
   1. In the Navigation pane, expand the `niceFPGA` application, click on `Settings -> launch.json`.
   1. Under `Bitstream File`, select `${workspaceFolder}/platform/hw/sdt/design_1_wrapper.bit`. This is necessary such that changes in the FPGA design are reflected in the software. This is a [known bug](https://adaptivesupport.amd.com/s/question/0D54U00008GmLxbSAF/workaround-updating-hardware-specifications-in-a-vitis-unified-project-using-xsa-doesnt-work?language=en_US) in Vitis and may be fixed in the future.
   1. In the Navigation pane, click on `niceFPGA [Application] -> Settings -> UserConfig.cmake`.
   1. Under `Compiler Settings -> Optimization`, select `-O3` and add `-ofast` under `Other optimization flags`. This enables the highest level of optimization.
   1. Under `Linker Settings -> Libraries`, add `m` to load the math library.
1. Build and run the platform and the project
   1. In the `Flow` pane on the left select the `Platform` component, and click on `Build` to build the platform.
   1. In the `Flow` pane on the left select the `NICEfpga` component. Click on `Build` to build the project, and then on `Run` to run it.

The Zynq will now send UDP packets to the IP address defined in `main.c`, variable `RemoteAddr` (default: `192.168.88.250`), and to port `RemotePort` (default: `12345`). To receive the data on the remote computer, use

```sh
nc -u -l 12345
```

to start listening for UDP packets on port 12345.

Alternatively, you can use [NICEcontrol](https://github.com/thomabir/NICEcontrol), which is a GUI for monitoring and controlling the NICE experiment.

## How to update when code changes

### If you modify the `.c` code

Restart from step 4 above.

### If you modify the `.sv` code, but not the block design

1. Re-run generate bitstream in Vivado, and export the hardware (`.xsa` file).
1. In Vitis, in the navigation pane, click on `platfom [Platform] -> Settings -> vitis-comp.json`.
1. In the top-level settings (`platform`), click on `Switch XSA` and select the new `.xsa` file.
1. (The following path may change, you may have to look around a bit in the settings.) In the settings, navigate to `platform -> ps7_cortexa9_1 -> test -> Board Support Package`. There, click on `Regenerate BSP`.
1. Go to step 4 under "Use" above.

### If you modify the block design

If you modify the block diagram, then you have to re-create the application project in Vitis IDE, starting from step 1 im "Use" above. This is annoying, but I haven't found a better way yet. The reason is because when generating the example project, Vitis IDE also generates the `xparameters.h` file, which  contains the addresses of the registers of the custom IP blocks, which are generated when synthesizing the block diagram. So, if you change the block diagram, the addresses of the registers may change, and the `xparameters.h` file needs to be updated. This is done automatically when creating a new application project, and as far as I know cannot be done after a project has been created. (Update: the addresses are assigned deterministically as far as I've seen so far, so you may be able to guess the addresses without having to re-create the application project. No guarantee, though.)

## Debugging via UART

All print statements from the Zynq are sent to the UART, which is transmitted over the USB connection between the Zynq and the computer.
To listen to the UART output of the Zynq, use

```sh
screen /dev/ttyUSB1 115200
```

where `/dev/ttyUSB1` is the UART device (check which one is the right one), and `115200` is the baud rate.

### UART/screen troubleshooting

- Sometimes, you may have switch the USB port to which the Zynq UART is connected.
- If you get `screen is terminating`, try the command with `sudo`, or try to connect to an already existing `screen` session with `screen -r`.
- To pause the output from the terminal, press `Ctrl + s`, and to resume press `Ctrl + q`.
- If messages arrive broken or unreliably, make sure the baudrate is correct (115200), and power cycle the FPGA board and the computer.

## Acknowledgements

The UDP code that sends data from the FPGA is based on the [Zynq_UDP](https://github.com/delhatch/Zynq_UDP) project by [delhatch](https://github.com/delhatch), which is in turn based on [A MicroZed UDP Server for Waveform Centroiding](https://lancesimms.com/Xilinx/MicroZed_UDP_Server_for_Waveform_Centroiding_Table_Of_Contents.html) by [Lance Simms](https://lancesimms.com/).
