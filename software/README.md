# Software for the ARM CPU on the Zynq SoC

## Use

1. Create a new application project in Vitis IDE.
   1. Click `Create Application Project`.
   2. Ignore the welcome page, click `Next`.
   3. Select `Create a new plaform from hardware (XSA)`, then `Browse`, and select the `.xsa` file you created previously by synthesizing the files in the `../hardware` directory. The default path is `~/code/NICEfpga/NICEfpga-vivado/design_1_wrapper.xsa`. Click `Open`, then `Next`.
   4. Enter the Application project name `NICEfpga`, click `Next`.
   5. Keep the default domain: `standalone_ps7_cortexa9_0`. CLick `Next`.
   6. Select the `lwIP Echo Server` template. Click `Finish`.
2. Add the code to the `src` directory.
   1. Replace `echo.c` and `main.c` in the project with the files in this repository.
   2. Add `includes.h` from this repository to the `src` directory of the project.
3. Add the compile flag `-lm` to the linker flags of the project.
   1. Locate on the `Explorer` tab on the left: `Explorer -> NICEfpga_system -> NICEfpga -> NICEfpga.prj`. Right-click on `NICEfpga.prj` and click on `Properties`.
   2. In the pane on the left, select `C/C++ Build -> Settings -> ARM v7 gcc linker -> Libraries`.
   3. Locate the tab named `Libraries (-l)`, click on the small green plus symbol on the right (`Add ...`) and enter `m`. Click `Ok` and `Apply and Close`.
4. Build and run the project.
   1. In the `Assistant` tab, locate `NICEfpga_system` and make sure it is selected.
   2. Click the hammer symbol in the `Assistant` tab to build the project, and then the green arrow symbol to run it. When running for the first time, select `Launch Hardware` in the dialog that appears. Afterwards, you can reuse the same configuration.

The Zynq will now send UDP packets to the IP address defined in `main.c`, variable `RemoteAddr` (default: `192.168.88.250`), and to port `RemotePort` (default: `12345`). To receive the data on the remote computer, use

```sh
nc -u -l 12345
```

to start listening for UDP packets on port 12345.

Alternatively, you can use [NICEcontrol](https://github.com/thomabir/NICEcontrol), which is a GUI for monitoring and controlling the NICE experiment.

## How to update when code changes

- If you modify the `.c` code, simply re-run the build and compilation.
- If you modify the `.sv` code without affecting the block diagram, then re-run generate bitstream in Vivado, and export the hardware. Then, in Vitis, locate the `Assistant` tab on the left, right-click on `design_1_wrapper`, and `Update hardware specification`. Seleclt the hardware you exportet in Vivado, by default called `design_1_wrapper.xsa`, and click `OK`. Then, re-run the build and compilation.
- If you modify the block diagram, then you have to re-create the application project in Vitis IDE. See above. This is annoying, but I haven't found a better way yet. The reason is because when generating the example project, Vitis IDE also generates the `xparameters.h` file, which  contains the addresses of the registers of the custom IP blocks, which are generated when synthesizing the block diagram. So, if you change the block diagram, the addresses of the registers may change, and the `xparameters.h` file needs to be updated. This is done automatically when creating a new application project, and as far as I know cannot be done after a project has been created.

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
- To pause the output from the terminal, press `Ctrl + q`, and to resume press `Ctrl + s`.

## Acknowledgements

The UDP code that sends data from the FPGA is based on the [Zynq_UDP](https://github.com/delhatch/Zynq_UDP) project by [delhatch](https://github.com/delhatch), which is in turn based on [A MicroZed UDP Server for Waveform Centroiding](https://lancesimms.com/Xilinx/MicroZed_UDP_Server_for_Waveform_Centroiding_Table_Of_Contents.html) by [Lance Simms](https://lancesimms.com/).
