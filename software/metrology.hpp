#pragma once

#include "metrology_data.hpp"
#include "xgpio.h"
#include "xparameters.h"

class Metrology {
 public:
  // Initialize the GPIOs for counter and data
  int init() {
    // Initialise GPIO for counter (single channel)
    if (XGpio_Initialize(&xgpio_counter, XPAR_XGPIO_0_BASEADDR) !=
        XST_SUCCESS) {
      return -1;
    }
    XGpio_SetDataDirection(&xgpio_counter, 1, 1);

    // Initialise GPIO for data (dual channel)
    for (int i = 0; i < NUM_XGPIO_INSTANCES; i++) {
      u32 gpio_baseaddr = XPAR_XGPIO_0_BASEADDR + (i + 1) * 0x10000;
      if (XGpio_Initialize(&xgpio_data[i], gpio_baseaddr) != XST_SUCCESS) {
        return -1;
      }
      XGpio_SetDataDirection(&xgpio_data[i], 1, 1);
      XGpio_SetDataDirection(&xgpio_data[i], 2, 1);
    }

    return 0;
  }

  // Read the counter value
  int32_t read_counter() { return XGpio_DiscreteRead(&xgpio_counter, 1); }

  // Read all metrology data and return it
  MetrologyData read_data() {
    // Read all values from the FPGA into the metrology_data array
    for (int i = 0; i < NUM_READ_VALUES; i++) {
      // Calculate which GPIO instance and channel to read from
      int gpio_idx = i / 2;
      int channel = 1 + (i % 2);  // Channel is either 1 or 2

      // Read the data
      metrology_data.arr[i] =
          XGpio_DiscreteRead(&xgpio_data[gpio_idx], channel);
    }

    return metrology_data;
  }

  // Return the number of values that will be read
  static constexpr int get_data_size() { return NUM_READ_VALUES; }

 private:
  static constexpr int NUM_XGPIO_INSTANCES = 13;
  static constexpr int NUM_READ_VALUES = 2 * NUM_XGPIO_INSTANCES;
  XGpio xgpio_counter;
  XGpio xgpio_data[13];  // Maximum number of instances
  MetrologyData metrology_data;
};
