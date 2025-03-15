// DEFINE STATEMENTS TO INCREASE SPEED
#undef LWIP_TCP
#undef LWIP_DHCP
// #undef CHECKSUM_CHECK_UDP
// #undef LWIP_CHECKSUM_ON_COPY
// #undef CHECKSUM_GEN_UDP

#include <stdint.h>
#include <stdio.h>

#include "metrology.hpp"
#include "network_interface.hpp"
#include "processed_data.hpp"
#include "xil_printf.h"

/**
 * Process the raw metrology data
 *
 * @param raw_data Raw data from the metrology system
 * @param count Current counter value
 * @return Processed data
 */
ProcessedData process_data(const MetrologyData& raw_data, int32_t count) {
  ProcessedData data;

  // Counter
  data.counter = count;

  // ADC readings
  data.adc_shear1 = raw_data.adc_shear1;
  data.adc_shear2 = raw_data.adc_shear2;
  data.adc_shear3 = raw_data.adc_shear3;
  data.adc_shear4 = raw_data.adc_shear4;
  data.adc_point1 = raw_data.adc_point1;
  data.adc_point2 = raw_data.adc_point2;
  data.adc_point3 = raw_data.adc_point3;
  data.adc_point4 = raw_data.adc_point4;
  data.adc_sine_ref = raw_data.adc_sine_ref;
  data.adc_opd_ref = raw_data.adc_opd_ref;

  // OPD
  // TODO: Unwrap the phase
  data.phi_opd = raw_data.phi_opd_int;

  // Shear
  data.shear_x1 = raw_data.shear_x1_int;
  data.shear_x2 = raw_data.shear_x2_int;
  data.shear_y1 = raw_data.shear_y1_int;
  data.shear_y2 = raw_data.shear_y2_int;

  // Pointing
  data.point_x1 = raw_data.point_x1_int;
  data.point_x2 = raw_data.point_x2_int;
  data.point_y1 = raw_data.point_y1_int;
  data.point_y2 = raw_data.point_y2_int;

  // Science beam
  data.adc_sci_null = raw_data.adc_sci_null;
  data.adc_sci_mod = raw_data.adc_sci_mod;

  return data;
}

int main() {
  constexpr int num_channels = 22;
  constexpr int num_timepoints = 10;
  constexpr int num_metrology_xgpios = 13;

  // Initialize the network interface
  NetworkInterface<num_channels, num_timepoints> network;
  if (network.init() != 0) {
    xil_printf("Network setup failed\n\r");
    return -1;
  }

  // Initialize metrology system to read data from the FPGA
  Metrology<num_metrology_xgpios> metrology;
  if (metrology.init() != 0) {
    xil_printf("Metrology setup failed\n\r");
    return -1;
  }

  int32_t count, prev_count;  // keep track whether new data is available
  MetrologyData metrology_data;
  ProcessedData processed_data;

  prev_count = 0;

  xil_printf("Starting loop\n\r");

  while (1) {
    // Get counter from metrology
    count = metrology.read_counter();

    // If the counter has incremented, new data is available
    if (count == prev_count + 1) {
      // Pattern: Sense - Plan - Act

      // SENSE
      metrology_data = metrology.read_data();

      // PLAN
      processed_data = process_data(metrology_data, count);

      // ACT
      network.send(processed_data);
    }

    prev_count = count;
  }

  return 0;
}
