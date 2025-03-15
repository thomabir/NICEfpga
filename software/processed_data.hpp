#pragma once

#include <stdint.h>

#include <array>

struct ProcessedData {
  union {
    struct {
      int32_t counter;  // 0

      // ADC readings
      int32_t adc_shear1;    // 1
      int32_t adc_shear2;    // 2
      int32_t adc_shear3;    // 3
      int32_t adc_shear4;    // 4
      int32_t adc_point1;    // 5
      int32_t adc_point2;    // 6
      int32_t adc_point3;    // 7
      int32_t adc_point4;    // 8
      int32_t adc_sine_ref;  // 9
      int32_t adc_opd_ref;   // 10

      // Optical path difference
      int32_t phi_opd;  // 11

      // Shear
      int32_t shear_x1;  // 12
      int32_t shear_x2;  // 13
      int32_t shear_y1;  // 14
      int32_t shear_y2;  // 15

      // Pointing
      int32_t point_x1;  // 16
      int32_t point_x2;  // 17
      int32_t point_y1;  // 18
      int32_t point_y2;  // 19

      // Science beam
      int32_t adc_sci_null;  // 20
      int32_t adc_sci_mod;   // 21
    };
    std::array<int32_t, 22> arr;
  };
};
