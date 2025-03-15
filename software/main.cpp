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
  constexpr int num_channels = 22;
  constexpr int num_timepoints = 10;
  int single_payload[num_channels];

  // Initialize the network interface
  NetworkInterface<num_channels, num_timepoints> network;
  if (network.init() != 0) {
    xil_printf("Network setup failed\n\r");
    return -1;
  }

  // Initialize metrology system to read data from the FPGA
  Metrology metrology;
  if (metrology.init() != 0) {
    xil_printf("Metrology setup failed\n\r");
    return -1;
  }

  int32_t count, prev_count;  // keep track whether new data is available
  MetrologyData metrology_data;

  prev_count = 0;

  xil_printf("Starting loop\n\r");

  while (1) {
    // Get counter from metrology
    count = metrology.read_counter();

    // if the counter has incremented, new data is available
    if (count == prev_count + 1) {
      // Pattern: Sense - Plan - Act

      // SENSE
      metrology_data = metrology.read_data();

      // PLAN
      // assemble the payload for a single timepoint

      // counter
      single_payload[0] = count;

      // adc readings metrology
      single_payload[1] = metrology_data.adc_shear1;
      single_payload[2] = metrology_data.adc_shear2;
      single_payload[3] = metrology_data.adc_shear3;
      single_payload[4] = metrology_data.adc_shear4;

      single_payload[5] = metrology_data.adc_point1;
      single_payload[6] = metrology_data.adc_point2;
      single_payload[7] = metrology_data.adc_point3;
      single_payload[8] = metrology_data.adc_point4;

      single_payload[9] = metrology_data.adc_sine_ref;
      single_payload[10] = metrology_data.adc_opd_ref;

      // opd
      single_payload[11] = metrology_data.phi_opd_int;

      // shear
      single_payload[12] = metrology_data.shear_x1_int;
      single_payload[13] = metrology_data.shear_x2_int;
      single_payload[14] = metrology_data.shear_y1_int;
      single_payload[15] = metrology_data.shear_y2_int;

      // pointing
      single_payload[16] = metrology_data.point_x1_int;
      single_payload[17] = metrology_data.point_x2_int;
      single_payload[18] = metrology_data.point_y1_int;
      single_payload[19] = metrology_data.point_y2_int;

      // adc readings science beam
      single_payload[20] = metrology_data.adc_sci_null;
      single_payload[21] = metrology_data.adc_sci_mod;

      // ACT
      network.send(single_payload);
    }

    // set the previous counter to the current counter
    prev_count = count;
  }

  cleanup_platform();
  return 0;
}
