// DEFINE STATEMENTS TO INCREASE SPEED
#undef LWIP_TCP
#undef LWIP_DHCP
// #undef CHECKSUM_CHECK_UDP
// #undef LWIP_CHECKSUM_ON_COPY
// #undef CHECKSUM_GEN_UDP

#include <stdio.h>

#include "math.h"
#include "network_interface.hpp"
#include "platform.h"
#include "platform_config.h"
#include "sleep.h"
#include "xgpio.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xparameters.h"

int main() {
  // Initialize the network interface
  NetworkInterface network;

  xil_printf("Initializing payload containers\n\r");
  // max payload size: 1500 bytes = 12000 bits = 375 int (32 bits each)
  const int num_channels = 22;
  const int num_timepoints = 10;
  int payload_size = num_channels * num_timepoints;
  int payload[payload_size];
  int pkg_no = 0;
  int vals_idx = 0;

  // Initialize network with package size only
  if (network.init(payload_size * sizeof(int)) != 0) {
    xil_printf("Network setup failed\n\r");
    return -1;
  }

  // activate the GPIOs, two channels each, data direction: read
  xil_printf("Initializing GPIO\n\r");
  const int num_xgpio_instances = 14;
  XGpio xgpio_in[num_xgpio_instances];

  for (int i = 0; i < num_xgpio_instances; i++) {
    XGpio_Initialize(&xgpio_in[i],
                     XPAR_XGPIO_0_BASEADDR + i * 0x10000);  // works in practice
    XGpio_SetDataDirection(&xgpio_in[i], 1,
                           1);  // (instance pointer, channel, direction mask)
    if (i != 0) {
      XGpio_SetDataDirection(&xgpio_in[i], 2, 1);  // CH0 is single channel
    }
  }

  // counters
  int32_t count_opd, prev_count_opd;

  // fpga: adc measurements
  int32_t adc_shear1, adc_shear2, adc_shear3, adc_shear4;  // shear
  int32_t adc_point1, adc_point2, adc_point3, adc_point4;  // pointing
  int32_t adc_sine_ref, adc_opd_ref;                       // references
  int32_t adc_sci_null, adc_sci_mod;                       // science beam

  // fpga: processed data
  int32_t phi_opd_int;  // opd
  int32_t shear_x1_int, shear_x2_int, shear_y1_int, shear_y2_int, shear_i1_int,
      shear_i2_int;  // shear
  int32_t point_x1_int, point_x2_int, point_y1_int, point_y2_int, point_i1_int,
      point_i2_int;  // pointing

  // intermediate variables
  double shear_x1, shear_x2, shear_y1, shear_y2, shear_i1, shear_i2;  // shear
  double shear_x1d, shear_x2d, shear_y1d, shear_y2d;  // shear corrected

  double point_x1, point_x2, point_y1, point_y2, point_i1,
      point_i2;                                       // pointing
  double point_x1d, point_x2d, point_y1d, point_y2d;  // pointing corrected

  // outputs to be sent to PC
  int32_t shear_x1d_int, shear_x2d_int, shear_y1d_int,
      shear_y2d_int;  // shear corrected
  int32_t point_x1d_int, point_x2d_int, point_y1d_int,
      point_y2d_int;  // pointing corrected

  prev_count_opd = 0;

  xil_printf("Starting loop\n\r");

  while (1) {
    // Get counter from FPGA
    count_opd = XGpio_DiscreteRead(&xgpio_in[0], 1);

    // if the counter has incremented, read the values
    if (count_opd == prev_count_opd + 1) {
      // read the values from the FPGA
      adc_shear1 = XGpio_DiscreteRead(&xgpio_in[1], 1);
      adc_shear2 = XGpio_DiscreteRead(&xgpio_in[1], 2);
      adc_shear3 = XGpio_DiscreteRead(&xgpio_in[2], 1);
      adc_shear4 = XGpio_DiscreteRead(&xgpio_in[2], 2);

      adc_point1 = XGpio_DiscreteRead(&xgpio_in[3], 1);
      adc_point2 = XGpio_DiscreteRead(&xgpio_in[3], 2);
      adc_point3 = XGpio_DiscreteRead(&xgpio_in[4], 1);
      adc_point4 = XGpio_DiscreteRead(&xgpio_in[4], 2);

      adc_sine_ref = XGpio_DiscreteRead(&xgpio_in[5], 1);
      adc_opd_ref = XGpio_DiscreteRead(&xgpio_in[5], 2);

      phi_opd_int = XGpio_DiscreteRead(&xgpio_in[6], 1);
      // r_opd_int = XGpio_DiscreteRead(&xgpio_in[6], 2);

      shear_x1_int = XGpio_DiscreteRead(&xgpio_in[7], 1);
      shear_x2_int = XGpio_DiscreteRead(&xgpio_in[7], 2);
      shear_y1_int = XGpio_DiscreteRead(&xgpio_in[8], 1);
      shear_y2_int = XGpio_DiscreteRead(&xgpio_in[8], 2);
      shear_i1_int = XGpio_DiscreteRead(&xgpio_in[9], 1);
      shear_i2_int = XGpio_DiscreteRead(&xgpio_in[9], 2);

      point_x1_int = XGpio_DiscreteRead(&xgpio_in[10], 1);
      point_x2_int = XGpio_DiscreteRead(&xgpio_in[10], 2);
      point_y1_int = XGpio_DiscreteRead(&xgpio_in[11], 1);
      point_y2_int = XGpio_DiscreteRead(&xgpio_in[11], 2);
      point_i1_int = XGpio_DiscreteRead(&xgpio_in[12], 1);
      point_i2_int = XGpio_DiscreteRead(&xgpio_in[12], 2);

      adc_sci_null = XGpio_DiscreteRead(&xgpio_in[13], 1);
      adc_sci_mod = XGpio_DiscreteRead(&xgpio_in[13], 2);

      shear_x1 = (double)shear_x1_int;  // x1
      shear_x2 = (double)shear_x2_int;  // x2
      shear_y1 = (double)shear_y1_int;  // y1
      shear_y2 = (double)shear_y2_int;  // y2
      shear_i1 = (double)shear_i1_int;  // i1
      shear_i2 = (double)shear_i2_int;  // i2

      point_x1 = (double)point_x1_int;  // x1
      point_x2 = (double)point_x2_int;  // x2
      point_y1 = (double)point_y1_int;  // y1
      point_y2 = (double)point_y2_int;  // y2
      point_i1 = (double)point_i1_int;  // i1
      point_i2 = (double)point_i2_int;  // i2

      // Shear
      shear_x1d = shear_x1 / shear_i1 * 1.11e3;  // um
      shear_x2d = shear_x2 / shear_i2 * 1.11e3;  // um
      shear_y1d = shear_y1 / shear_i1 * 1.11e3;  // um
      shear_y2d = shear_y2 / shear_i2 * 1.11e3;  // um

      shear_x1d_int = (int32_t)(shear_x1d * 1000);  // nm
      shear_x2d_int = (int32_t)(shear_x2d * 1000);  // nm
      shear_y1d_int = (int32_t)(shear_y1d * 1000);  // nm
      shear_y2d_int = (int32_t)(shear_y2d * 1000);  // nm

      // Pointing
      point_x1d = point_x1 / point_i1 * 1.11e3;  // um
      point_x2d = point_x2 / point_i2 * 1.11e3;  // um
      point_y1d = point_y1 / point_i1 * 1.11e3;  // um
      point_y2d = point_y2 / point_i2 * 1.11e3;  // um

      point_x1d_int = (int32_t)(point_x1d * 1000);  // nm
      point_x2d_int = (int32_t)(point_x2d * 1000);  // nm
      point_y1d_int = (int32_t)(point_y1d * 1000);  // nm
      point_y2d_int = (int32_t)(point_y2d * 1000);  // nm

      // assemble the payload

      // counter
      payload[num_channels * vals_idx] = count_opd;

      // adc readings metrology
      payload[num_channels * vals_idx + 1] = adc_shear1;
      payload[num_channels * vals_idx + 2] = adc_shear2;
      payload[num_channels * vals_idx + 3] = adc_shear3;
      payload[num_channels * vals_idx + 4] = adc_shear4;

      payload[num_channels * vals_idx + 5] = adc_point1;
      payload[num_channels * vals_idx + 6] = adc_point2;
      payload[num_channels * vals_idx + 7] = adc_point3;
      payload[num_channels * vals_idx + 8] = adc_point4;

      payload[num_channels * vals_idx + 9] = adc_sine_ref;
      payload[num_channels * vals_idx + 10] = adc_opd_ref;

      // opd
      payload[num_channels * vals_idx + 11] = phi_opd_int;

      // shear
      payload[num_channels * vals_idx + 12] = shear_x1d_int;
      payload[num_channels * vals_idx + 13] = shear_x2d_int;
      payload[num_channels * vals_idx + 14] = shear_y1d_int;
      payload[num_channels * vals_idx + 15] = shear_y2d_int;

      // pointing
      payload[num_channels * vals_idx + 16] = point_x1d_int;
      payload[num_channels * vals_idx + 17] = point_x2d_int;
      payload[num_channels * vals_idx + 18] = point_y1d_int;
      payload[num_channels * vals_idx + 19] = point_y2d_int;

      // adc readings science beam
      payload[num_channels * vals_idx + 20] = adc_sci_null;
      payload[num_channels * vals_idx + 21] = adc_sci_mod;

      // if payload is full, send it
      if (vals_idx == num_timepoints - 1) {
        // send the payload using the network interface
        network.send(payload);

        // reset the vals_idx
        vals_idx = 0;

        // increase the package number
        pkg_no++;
      } else {
        vals_idx++;
      }
    }

    // set the previous counter to the current counter
    prev_count_opd = count_opd;
  }

  cleanup_platform();
  return 0;
}
