// DEFINE STATEMENTS TO INCREASE SPEED
#undef LWIP_TCP
#undef LWIP_DHCP
// #undef CHECKSUM_CHECK_UDP
// #undef LWIP_CHECKSUM_ON_COPY
// #undef CHECKSUM_GEN_UDP

#include <stdio.h>

#include "math.h"
#include "metrology.hpp"
#include "network_interface.hpp"
#include "platform.h"
#include "platform_config.h"
#include "sleep.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xparameters.h"

int main() {
  xil_printf("Initializing payload containers\n\r");
  const int num_channels = 22;
  const int num_timepoints = 10;
  int payload_size = num_channels * num_timepoints;
  int payload[payload_size];
  int pkg_no = 0;
  int vals_idx = 0;

  // Initialize the network interface and set the payload size
  NetworkInterface network;
  if (network.init(payload_size * sizeof(int)) != 0) {
    xil_printf("Network setup failed\n\r");
    return -1;
  }

  // Initialize metrology system to read data from the FPGA
  Metrology metrology;
  if (metrology.init() != 0) {
    xil_printf("Metrology setup failed\n\r");
    return -1;
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

  MetrologyData metrology_data;

  prev_count_opd = 0;

  xil_printf("Starting loop\n\r");

  while (1) {
    // Get counter from metrology
    count_opd = metrology.read_counter();

    // if the counter has incremented, read the values
    if (count_opd == prev_count_opd + 1) {
      // SENSE
      metrology_data = metrology.read_data();

      // adc_shear1 = metrology_data.arr[0];
      // adc_shear2 = metrology_data.arr[1];
      // adc_shear3 = metrology_data.arr[2];
      // adc_shear4 = metrology_data.arr[3];

      // adc_point1 = metrology_data.arr[4];
      // adc_point2 = metrology_data.arr[5];
      // adc_point3 = metrology_data.arr[6];
      // adc_point4 = metrology_data.arr[7];

      // adc_sine_ref = metrology_data.arr[8];
      // adc_opd_ref = metrology_data.arr[9];

      // phi_opd_int = metrology_data.arr[10];

      // shear_x1_int = metrology_data.arr[12];
      // shear_x2_int = metrology_data.arr[13];
      // shear_y1_int = metrology_data.arr[14];
      // shear_y2_int = metrology_data.arr[15];
      // shear_i1_int = metrology_data.arr[16];
      // shear_i2_int = metrology_data.arr[17];

      // point_x1_int = metrology_data.arr[18];
      // point_x2_int = metrology_data.arr[19];
      // point_y1_int = metrology_data.arr[20];
      // point_y2_int = metrology_data.arr[21];
      // point_i1_int = metrology_data.arr[22];
      // point_i2_int = metrology_data.arr[23];

      // adc_sci_null = metrology_data.arr[24];
      // adc_sci_mod = metrology_data.arr[25];

      // PLAN

      // assemble the payload

      // counter
      payload[num_channels * vals_idx] = count_opd;

      // adc readings metrology
      payload[num_channels * vals_idx + 1] = metrology_data.adc_shear1;
      payload[num_channels * vals_idx + 2] = metrology_data.adc_shear2;
      payload[num_channels * vals_idx + 3] = metrology_data.adc_shear3;
      payload[num_channels * vals_idx + 4] = metrology_data.adc_shear4;

      payload[num_channels * vals_idx + 5] = metrology_data.adc_point1;
      payload[num_channels * vals_idx + 6] = metrology_data.adc_point2;
      payload[num_channels * vals_idx + 7] = metrology_data.adc_point3;
      payload[num_channels * vals_idx + 8] = metrology_data.adc_point4;

      payload[num_channels * vals_idx + 9] = metrology_data.adc_sine_ref;
      payload[num_channels * vals_idx + 10] = metrology_data.adc_opd_ref;

      // opd
      payload[num_channels * vals_idx + 11] = metrology_data.phi_opd_int;

      // shear
      payload[num_channels * vals_idx + 12] = metrology_data.shear_x1_int;
      payload[num_channels * vals_idx + 13] = metrology_data.shear_x2_int;
      payload[num_channels * vals_idx + 14] = metrology_data.shear_y1_int;
      payload[num_channels * vals_idx + 15] = metrology_data.shear_y2_int;

      // pointing
      payload[num_channels * vals_idx + 16] = metrology_data.point_x1_int;
      payload[num_channels * vals_idx + 17] = metrology_data.point_x2_int;
      payload[num_channels * vals_idx + 18] = metrology_data.point_y1_int;
      payload[num_channels * vals_idx + 19] = metrology_data.point_y2_int;

      // adc readings science beam
      payload[num_channels * vals_idx + 20] = metrology_data.adc_sci_null;
      payload[num_channels * vals_idx + 21] = metrology_data.adc_sci_mod;

      // ACT

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
