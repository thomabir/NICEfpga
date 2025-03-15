#pragma once

#include <stdint.h>

#include <array>

struct MetrologyData {
  union {
    struct {
      int32_t adc_shear1;    // 0
      int32_t adc_shear2;    // 1
      int32_t adc_shear3;    // 2
      int32_t adc_shear4;    // 3
      int32_t adc_point1;    // 4
      int32_t adc_point2;    // 5
      int32_t adc_point3;    // 6
      int32_t adc_point4;    // 7
      int32_t adc_sine_ref;  // 8
      int32_t adc_opd_ref;   // 9
      int32_t phi_opd_int;   // 10
      int32_t r_opd_int;     // 11
      int32_t shear_x1_int;  // 12
      int32_t shear_x2_int;  // 13
      int32_t shear_y1_int;  // 14
      int32_t shear_y2_int;  // 15
      int32_t shear_i1_int;  // 16
      int32_t shear_i2_int;  // 17
      int32_t point_x1_int;  // 18
      int32_t point_x2_int;  // 19
      int32_t point_y1_int;  // 20
      int32_t point_y2_int;  // 21
      int32_t point_i1_int;  // 22
      int32_t point_i2_int;  // 23
      int32_t adc_sci_null;  // 24
      int32_t adc_sci_mod;   // 25
    };
    std::array<int32_t, 26> arr;
  };
};
