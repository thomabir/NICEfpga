# Software for the ARM CPU on the Zynq SoC

## Use

1. Open the Vitis IDE, and create a new application project.
1. Use the hardware created from the `../hardware` directory.
1. Use the lwIP Echo Server template.
1. In the created project, replace `echo.c` and `main.c` with the files in this directory.
1. Build and run the project.

The Zynq will now send UDP packets to the IP address defined in `main.c`, variable `RemoteAddr` (default: `192.168.88.254`), and to port `RemotePort` (default: `8`). To receive the data on the remote computer, use

```sh
sudo nc -u -l 8
```

to start listening for UDP packets on port 8.

Alternatively, you can use [NICEcontrol](https://github.com/thomabir/NICEcontrol), which is a GUI for monitoring and controlling the NICE experiment.

## Debugging

All print statements from the Zynq are sent to the UART, which is transmitted over the USB connection between the Zynq and the computer.
To listen to the UART output of the Zynq, use

```sh
screen /dev/ttyUSB1 115200
```

where `/dev/ttyUSB1` is the UART device, and `115200` is the baud rate. Sometimes, I have to switch the USB port to which the UART is connected to get this to work.

## Acknowledgements

The UDP code that sends data from the FPGA is based on the [Zynq_UDP](https://github.com/delhatch/Zynq_UDP) project by [delhatch](https://github.com/delhatch), which is in turn based on [A MicroZed UDP Server for Waveform Centroiding](https://lancesimms.com/Xilinx/MicroZed_UDP_Server_for_Waveform_Centroiding_Table_Of_Contents.html) by [Lance Simms](https://lancesimms.com/).
