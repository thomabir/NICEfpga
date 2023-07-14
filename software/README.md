# Software for the ARM core on the Zynq

## Use
1. Open the Vitis IDE, and create a new application project.
2. Use the lwIP Echo Server template.
3. In the created project, replace `echo.c` and `main.c` with the files in this directory.
4. Build and run the project.

## Acknowledgements
The UDP code that sends data from the FPGA is based on the [Zynq_UDP](https://github.com/delhatch/Zynq_UDP) project by [delhatch](https://github.com/delhatch), which is in turn based on [A MicroZed UDP Server for Waveform Centroiding](https://lancesimms.com/Xilinx/MicroZed_UDP_Server_for_Waveform_Centroiding_Table_Of_Contents.html) by [Lance Simms](https://lancesimms.com/).