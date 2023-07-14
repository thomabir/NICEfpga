# Software for the ARM CPU on the Zynq SoC

## Use
1. Open the Vitis IDE, and create a new application project.
2. Use the hardware created from the `../hardware` directory.
3. Use the lwIP Echo Server template.
4. In the created project, replace `echo.c` and `main.c` with the files in this directory.
5. Build and run the project.

The Zynq will now send UDP packets to the IP address defined in `main.c`, variable `RemoteAddr` (default: `192.168.88.254`), and to port `RemotePort` (default: `8`). To receive the data on the remote computer, use
```bash
sudo nc -u -l 8
```
to start listening for UDP packets on port 8.

Alternatively, you can use [NICEcontrol](https://github.com/thomabir/NICEcontrol), which is a GUI for monitoring and controlling the NICE experiment.

## Acknowledgements
The UDP code that sends data from the FPGA is based on the [Zynq_UDP](https://github.com/delhatch/Zynq_UDP) project by [delhatch](https://github.com/delhatch), which is in turn based on [A MicroZed UDP Server for Waveform Centroiding](https://lancesimms.com/Xilinx/MicroZed_UDP_Server_for_Waveform_Centroiding_Table_Of_Contents.html) by [Lance Simms](https://lancesimms.com/).