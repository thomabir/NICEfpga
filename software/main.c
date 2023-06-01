
#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xgpio.h"
#include "xparameters.h"
#include "sleep.h"
#include "math.h"

#define PI 3.14159265359


int main()
{
    init_platform();

    print("Hello World\n\r");


    XGpio oreg1_input, oreg2_input;

    int oreg1_val, oreg2_val;
    double x, y, phase;

    XGpio_Initialize(&oreg1_input, XPAR_AXI_GPIO_0_DEVICE_ID);
    XGpio_SetDataDirection(&oreg1_input, 1, 1);

    XGpio_Initialize(&oreg2_input, XPAR_AXI_GPIO_1_DEVICE_ID);
    XGpio_SetDataDirection(&oreg2_input, 1, 1);

    while(1)
    {
    	oreg1_val = XGpio_DiscreteRead(&oreg1_input, 1);
    	oreg2_val = XGpio_DiscreteRead(&oreg2_input, 1);

    	x = (double) oreg1_val;
    	y = (double) oreg2_val;

    	phase = atan2(y, x);
    	phase = phase * 180. / PI;

//    	printf("%6.6f, %6.6f, %6.6f\n\r", phase, x, y);
    	printf("%6.6f\n\r", phase);
//    	printf("%d, %d, %d\n\r", (int)phase, (int)oreg1_val, (int)oreg2_val);
//    	xil_printf("%d, %d\n\r", oreg1_val, oreg2_val);

//    	usleep(100000); // wait 200 milliseconds
    }

    cleanup_platform();
    return 0;
}
