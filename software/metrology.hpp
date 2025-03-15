#pragma once

#include "metrology_data.hpp"
#include "xgpio.h"
#include "xparameters.h"

template <int NUM_XGPIO_INSTANCES>
class Metrology {
 public:
  int init() {
    // Initialise counter GPIO (single channel)
    if (XGpio_Initialize(&counter_gpio, XPAR_XGPIO_0_BASEADDR) != XST_SUCCESS) {
      return -1;
    }
    XGpio_SetDataDirection(&counter_gpio, 1, 1);

    // Initialise data GPIOs (dual channel)
    for (int i = 0; i < NUM_XGPIO_INSTANCES; i++) {
      u32 gpio_baseaddr = XPAR_XGPIO_0_BASEADDR + (i + 1) * 0x10000;
      if (XGpio_Initialize(&data_gpios[i], gpio_baseaddr) != XST_SUCCESS) {
        return -1;
      }
      XGpio_SetDataDirection(&data_gpios[i], 1, 1);
      XGpio_SetDataDirection(&data_gpios[i], 2, 1);
    }

    return 0;
  }

  // Read the counter value
  int32_t read_counter() { return XGpio_DiscreteRead(&counter_gpio, 1); }

  // Read all metrology data and return it
  MetrologyData read_data() {
    // Read all values from the FPGA into the metrology_data array
    for (int i = 0; i < NUM_READ_VALUES; i++) {
      // Calculate which GPIO instance and channel to read from
      int gpio_idx = i / 2;
      int channel = 1 + (i % 2);  // Channel is either 1 or 2

      // Read the data
      metrology_data.arr[i] =
          XGpio_DiscreteRead(&data_gpios[gpio_idx], channel);
    }

    return metrology_data;
  }

 private:
  static constexpr int NUM_READ_VALUES = 2 * NUM_XGPIO_INSTANCES;
  XGpio counter_gpio;
  XGpio data_gpios[NUM_XGPIO_INSTANCES];  // Maximum number of instances
  MetrologyData metrology_data;
};
